import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/cell_data.dart';

class RealtimeService {
  final SupabaseClient _client = SupabaseConfig.client;
  dynamic _channel;
  StreamController<RealtimeUpdate>? _updateController;

  // Subscribe to spreadsheet changes
Future<Stream<RealtimeUpdate>> subscribeToSpreadsheet(String spreadsheetId) async {
  _updateController = StreamController<RealtimeUpdate>.broadcast();

  try {
    _channel = _client
        .channel('spreadsheet:$spreadsheetId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'cells',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'spreadsheet_id',
            value: spreadsheetId,
          ),
          callback: (payload) {
            _handleCellUpdate(payload);
          },
        )
        .subscribe();
  } catch (e) {
    print('Error subscribing to realtime: $e');
  }

  return _updateController!.stream;
}

void _handleCellUpdate(PostgresChangePayload payload) {
  try {
    final record = payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord;

    if (record.isEmpty) return;

    final update = RealtimeUpdate(
      eventType: payload.eventType.toString().split('.').last,
      rowIndex: record['row_index'] as int,
      columnIndex: record['column_index'] as int,
      cellData: _parseCellData(record),
    );

    _updateController?.add(update);
  } catch (e) {
    print('Error handling realtime update: $e');
  }
}

  // void _handleCellUpdate(dynamic payload) {
  //   try {
  //     final eventType = payload['eventType'] as String?;
  //     final record = payload['new'] ?? payload['old'];

  //     if (record == null) return;

  //     final update = RealtimeUpdate(
  //       eventType: eventType ?? 'UNKNOWN',
  //       rowIndex: record['row_index'],
  //       columnIndex: record['column_index'],
  //       cellData: _parseCellData(record),
  //     );

  //     _updateController?.add(update);
  //   } catch (e) {
  //     print('Error handling realtime update: $e');
  //   }
  // }

  CellData? _parseCellData(Map<String, dynamic> record) {
    try {
      return CellData(
        value: record['value'],
        displayValue: record['display_value'],
        dataType: _parseDataType(record['data_type']),
        formula: record['formula'],
        fontWeight: record['font_weight'] ?? 'normal',
        fontStyle: record['font_style'] ?? 'normal',
        textDecoration: record['text_decoration'] ?? 'none',
        textAlign: record['text_align'] ?? 'left',
        backgroundColor: record['background_color'] ?? '#FFFFFF',
        fontColor:  record['font_color'] ?? '#000000',
        fontSize: record['font_size'] ?? 14,
      );
    } catch (e) {
      print('Error parsing cell data: $e');
      return null;
    }
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

  // Unsubscribe from changes
  Future<void> unsubscribe() async {
    await _channel?.unsubscribe();
    _channel = null;
    await _updateController?.close();
    _updateController = null;
  }

  // Send presence data (for showing active users)
  Future<void> sendPresence({
    required String spreadsheetId,
    required String userId,
    required String username,
    int? selectedRow,
    int? selectedCol,
  }) async {
    try {
      if (_channel == null) return;

      await _channel!.track({
        'user_id': userId,
        'username': username,
        'selected_row': selectedRow,
        'selected_col': selectedCol,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error sending presence: $e');
    }
  }

  // Listen to presence changes (other users' cursors)
  Stream<List<PresenceData>> get presenceStream {
    final controller = StreamController<List<PresenceData>>.broadcast();

    _channel?.on('presence', {'event': 'sync'}, (payload) {
      final presenceState = _channel?.presenceState();
      if (presenceState != null) {
        final presenceList = <PresenceData>[];

        presenceState.forEach((key, value) {
          if (value.isNotEmpty) {
            // Ensure value is a list and safely access the first item
            final presenceData = value.first;
            if (presenceData is Map<String, dynamic>) {
              presenceList.add(PresenceData(
                userId: presenceData['user_id'] as String? ?? '',
                username: presenceData['username'] as String? ?? '',
                selectedRow: presenceData['selected_row'] as int?,
                selectedCol: presenceData['selected_col'] as int?,
              ));
            }
          }
        });

        controller.add(presenceList);
      }
    });

    return controller.stream;
  }
}

// Model for realtime cell updates
class RealtimeUpdate {
  final String eventType; // INSERT, UPDATE, DELETE
  final int rowIndex;
  final int columnIndex;
  final CellData? cellData;

  RealtimeUpdate({
    required this.eventType,
    required this.rowIndex,
    required this.columnIndex,
    this.cellData,
  });
}

// Model for user presence data
class PresenceData {
  final String userId;
  final String username;
  final int? selectedRow;
  final int? selectedCol;

  PresenceData({
    required this.userId,
    required this.username,
    this.selectedRow,
    this.selectedCol,
  });
}