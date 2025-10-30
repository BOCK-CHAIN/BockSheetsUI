// lib/services/database_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/cell_data.dart';

class DatabaseService {
  final SupabaseClient _client = SupabaseConfig.client;

  // Returns a list of spreadsheets (id/title/updated_at)
  // Returns a list of spreadsheets including deleted ones (for trash)
  Future<List<Map<String, dynamic>>> getUserSpreadsheets() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('spreadsheets')
          .select('id, title, description, is_deleted, created_at, updated_at, last_accessed_at')
          .eq('owner_id', userId)
          // Remove the is_deleted filter to get all sheets including deleted ones
          .order('updated_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching spreadsheets: $e');
      return [];
    }
  }

  // Create a new spreadsheet record and return it
  Future<Map<String, dynamic>> createSpreadsheet({
    required String title,
    String? description,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('No user logged in');

      final response = await _client
          .from('spreadsheets')
          .insert({
            'owner_id': userId,
            'title': title,
            'description': description,
            'row_count': 100,
            'column_count': 26,
            'is_deleted': false,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'last_accessed_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return response;
    } catch (e) {
      print('Error creating spreadsheet: $e');
      rethrow;
    }
  }

  // Get spreadsheet metadata by id
  Future<Map<String, dynamic>?> getSpreadsheet(String spreadsheetId) async {
    try {
      final response = await _client
          .from('spreadsheets')
          .select()
          .eq('id', spreadsheetId)
          .eq('is_deleted', false)
          .single();

      return response;
    } catch (e) {
      print('Error fetching spreadsheet: $e');
      return null;
    }
  }

  // Get cells for a spreadsheet as a map address -> CellData
  Future<Map<String, CellData>> getSpreadsheetCells(String spreadsheetId) async {
    try {
      final response = await _client
          .from('cells')
          .select()
          .eq('spreadsheet_id', spreadsheetId);

      final cells = <String, CellData>{};
      
      for (var row in List<Map<String, dynamic>>.from(response)) {
        final address = _getCellAddress(row['row_index'], row['column_index']);
        cells[address] = CellData(
          value: row['value'],
          displayValue: row['display_value'],
          dataType: _parseDataType(row['data_type']),
          formula: row['formula'],
          fontWeight: row['font_weight'] ?? 'normal',
          fontStyle: row['font_style'] ?? 'normal',
          textDecoration: row['text_decoration'] ?? 'none',
          textAlign: row['text_align'] ?? 'left',
          backgroundColor: row['background_color'] ?? '#FFFFFF',
          fontColor: row['font_color'] ?? '#000000',
          fontSize: row['font_size'] ?? 12,
        );
      }

      return cells;
    } catch (e) {
      print('Error fetching cells: $e');
      return {};
    }
  }

  // Column/row settings
  Future<Map<int, double>> getColumnSettings(String spreadsheetId) async {
    try {
      final response = await _client
          .from('column_settings')
          .select()
          .eq('spreadsheet_id', spreadsheetId);

      final settings = <int, double>{};
      for (var row in List<Map<String, dynamic>>.from(response)) {
        settings[row['column_index']] = (row['width'] as num).toDouble();
      }
      return settings;
    } catch (e) {
      print('Error fetching column settings: $e');
      return {};
    }
  }

  Future<Map<int, double>> getRowSettings(String spreadsheetId) async {
    try {
      final response = await _client
          .from('row_settings')
          .select()
          .eq('spreadsheet_id', spreadsheetId);

      final settings = <int, double>{};
      for (var row in List<Map<String, dynamic>>.from(response)) {
        settings[row['row_index']] = (row['height'] as num).toDouble();
      }
      return settings;
    } catch (e) {
      print('Error fetching row settings: $e');
      return {};
    }
  }

  Future<void> updateLastAccessed(String spreadsheetId) async {
    try {
      await _client
          .from('spreadsheets')
          .update({
            'last_accessed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', spreadsheetId);
    } catch (e) {
      print('Error updating last accessed: $e');
    }
  }

  // Save cells and settings
  Future<void> saveCells(String spreadsheetId, Map<String, CellData> cells) async {
    try {
      // Delete all existing cells for this spreadsheet first
      await _client
          .from('cells')
          .delete()
          .eq('spreadsheet_id', spreadsheetId);

      // Insert new cells
      final cellsToInsert = <Map<String, dynamic>>[];
      
      cells.forEach((address, cellData) {
        final match = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(address);
        if (match != null) {
          final col = _columnLabelToIndex(match.group(1)!);
          final row = int.parse(match.group(2)!) - 1;
          
          cellsToInsert.add({
            'spreadsheet_id': spreadsheetId,
            'row_index': row,
            'column_index': col,
            'value': cellData.value,
            'display_value': cellData.displayValue,
            'data_type': cellData.dataType.toString().split('.').last,
            'formula': cellData.formula,
            'font_weight': cellData.fontWeight,
            'font_style': cellData.fontStyle,
            'text_decoration': cellData.textDecoration,
            'text_align': cellData.textAlign,
            'background_color': cellData.backgroundColor,
            'font_color': cellData.fontColor,
            'font_size': cellData.fontSize,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      });

      if (cellsToInsert.isNotEmpty) {
        await _client.from('cells').insert(cellsToInsert);
      }

      // Update spreadsheet timestamp
      await updateLastAccessed(spreadsheetId);
    } catch (e) {
      print('Error saving cells: $e');
      rethrow;
    }
  }

  Future<void> saveColumnSettings({
    required String spreadsheetId,
    required int columnIndex,
    required double width,
  }) async {
    try {
      // Check if column setting exists
      final existing = await _client
          .from('column_settings')
          .select()
          .eq('spreadsheet_id', spreadsheetId)
          .eq('column_index', columnIndex)
          .maybeSingle();

      if (existing != null) {
        // Update existing
        await _client
            .from('column_settings')
            .update({
              'width': width.toInt(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('spreadsheet_id', spreadsheetId)
            .eq('column_index', columnIndex);
      } else {
        // Insert new
        await _client.from('column_settings').insert({
          'spreadsheet_id': spreadsheetId,
          'column_index': columnIndex,
          'width': width.toInt(),
          'is_hidden': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error saving column settings: $e');
    }
  }

  Future<void> saveRowSettings({
    required String spreadsheetId,
    required int rowIndex,
    required double height,
  }) async {
    try {
      // Check if row setting exists
      final existing = await _client
          .from('row_settings')
          .select()
          .eq('spreadsheet_id', spreadsheetId)
          .eq('row_index', rowIndex)
          .maybeSingle();

      if (existing != null) {
        // Update existing
        await _client
            .from('row_settings')
            .update({
              'height': height.toInt(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('spreadsheet_id', spreadsheetId)
            .eq('row_index', rowIndex);
      } else {
        // Insert new
        await _client.from('row_settings').insert({
          'spreadsheet_id': spreadsheetId,
          'row_index': rowIndex,
          'height': height.toInt(),
          'is_hidden': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error saving row settings: $e');
    }
  }
  
  Future<void> updateSpreadsheet(String spreadsheetId, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      await _client
          .from('spreadsheets')
          .update(updates)
          .eq('id', spreadsheetId);
    } catch (e) {
      print('Error updating spreadsheet: $e');
      rethrow;
    }
  }

  Future<void> deleteSpreadsheet(String spreadsheetId) async {
    try {
      print('Attempting to delete spreadsheet: $spreadsheetId');
      
      // Soft delete by setting is_deleted flag
      final response = await _client
          .from('spreadsheets')
          .update({
            'is_deleted': true,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', spreadsheetId)
          .select();
      
      print('Delete response: $response');
      print('Spreadsheet moved to trash successfully');
    } catch (e) {
      print('Error deleting spreadsheet: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Restore spreadsheet from trash
  Future<void> restoreSpreadsheet(String spreadsheetId) async {
    try {
      print('Restoring spreadsheet: $spreadsheetId');
      
      await _client
          .from('spreadsheets')
          .update({
            'is_deleted': false,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', spreadsheetId);
      
      print('Spreadsheet restored successfully');
    } catch (e) {
      print('Error restoring spreadsheet: $e');
      rethrow;
    }
  }

  // Permanently delete spreadsheet (hard delete)
  Future<void> permanentlyDeleteSpreadsheet(String spreadsheetId) async {
    try {
      print('Permanently deleting spreadsheet: $spreadsheetId');
      
      // Hard delete - remove from database
      await _client.from('cells').delete().eq('spreadsheet_id', spreadsheetId);
      await _client.from('column_settings').delete().eq('spreadsheet_id', spreadsheetId);
      await _client.from('row_settings').delete().eq('spreadsheet_id', spreadsheetId);
      await _client.from('share_links').delete().eq('spreadsheet_id', spreadsheetId);
      await _client.from('collaborators').delete().eq('spreadsheet_id', spreadsheetId);
      await _client.from('activity_log').delete().eq('spreadsheet_id', spreadsheetId);
      await _client.from('spreadsheets').delete().eq('id', spreadsheetId);
      
      print('Spreadsheet permanently deleted successfully');
    } catch (e) {
      print('Error permanently deleting spreadsheet: $e');
      rethrow;
    }
  }

  // =====================================================
  // SHARING FUNCTIONALITY (using your schema)
  // =====================================================
  
  Future<String> createShareLink({
    required String spreadsheetId,
    String permissionLevel = 'view',
    DateTime? expiresAt,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('No user logged in');

      final response = await _client
          .from('share_links')
          .insert({
            'spreadsheet_id': spreadsheetId,
            'created_by': userId,
            'permission_level': permissionLevel,
            'is_active': true,
            'expires_at': expiresAt?.toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return response['share_token'];
    } catch (e) {
      print('Error creating share link: $e');
      rethrow;
    }
  }

  Future<void> addCollaborator({
    required String spreadsheetId,
    required String userId,
    String permissionLevel = 'view',
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('No user logged in');

      await _client.from('collaborators').insert({
        'spreadsheet_id': spreadsheetId,
        'user_id': userId,
        'permission_level': permissionLevel,
        'invited_by': currentUserId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error adding collaborator: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCollaborators(String spreadsheetId) async {
    try {
      final response = await _client
          .from('collaborators')
          .select('*, profiles!collaborators_user_id_fkey(username, email)')
          .eq('spreadsheet_id', spreadsheetId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching collaborators: $e');
      return [];
    }
  }

  // =====================================================
  // ACTIVITY LOG
  // =====================================================
  
  Future<void> logActivity({
    required String spreadsheetId,
    required String actionType,
    Map<String, dynamic>? details,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      
      await _client.from('activity_log').insert({
        'spreadsheet_id': spreadsheetId,
        'user_id': userId,
        'action_type': actionType,
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error logging activity: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getActivityLog(String spreadsheetId, {int limit = 50}) async {
    try {
      final response = await _client
          .from('activity_log')
          .select('*, profiles!activity_log_user_id_fkey(username)')
          .eq('spreadsheet_id', spreadsheetId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching activity log: $e');
      return [];
    }
  }

  // =====================================================
  // HELPER METHODS
  // =====================================================
  
  String _getCellAddress(int row, int col) {
    String label = '';
    int num = col;
    while (num >= 0) {
      label = String.fromCharCode(65 + (num % 26)) + label;
      num = (num ~/ 26) - 1;
      if (num < 0) break;
    }
    return '$label${row + 1}';
  }

  int _columnLabelToIndex(String label) {
    int index = 0;
    for (int i = 0; i < label.length; i++) {
      index = index * 26 + (label.codeUnitAt(i) - 64);
    }
    return index - 1;
  }

  CellDataType _parseDataType(String? type) {
    switch (type) {
      case 'number':
        return CellDataType.number;
      case 'date':
        return CellDataType.date;
      case 'formula':
        return CellDataType.formula;
      case 'boolean':
        return CellDataType.boolean;
      default:
        return CellDataType.text;
    }
  }
}