// lib/providers/spreadsheet_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../services/realtime_service.dart';
import '../services/file_service.dart';
import '../models/cell_data.dart';

class SpreadsheetProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final RealtimeService _realtimeService = RealtimeService();
  final FileService _fileService = FileService();

  List<Map<String, dynamic>> _spreadsheets = [];
  Map<String, CellData> _currentCells = {};
  Map<int, double> _columnWidths = {};
  Map<int, double> _rowHeights = {};
  
  String? _currentSpreadsheetId;
  String? _currentSpreadsheetTitle;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  
  StreamSubscription? _realtimeSubscription;
  Timer? _autoSaveTimer;

  // Undo/Redo stacks
  final List<Map<String, CellData>> _undoStack = [];
  final List<Map<String, CellData>> _redoStack = [];
  static const int _maxHistorySize = 50;

  // Getters
  List<Map<String, dynamic>> get spreadsheets => _spreadsheets;
  Map<String, CellData> get currentCells => _currentCells;
  Map<int, double> get columnWidths => _columnWidths;
  Map<int, double> get rowHeights => _rowHeights;
  String? get currentSpreadsheetId => _currentSpreadsheetId;
  String? get currentSpreadsheetTitle => _currentSpreadsheetTitle;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  // Save state for undo/redo
  void _saveStateForUndo() {
    final currentState = Map<String, CellData>.from(_currentCells);
    _undoStack.add(currentState);
    
    if (_undoStack.length > _maxHistorySize) {
      _undoStack.removeAt(0);
    }
    
    _redoStack.clear();
  }

  // Undo last action
  void undo() {
    if (_undoStack.isEmpty) return;
    
    _redoStack.add(Map<String, CellData>.from(_currentCells));
    _currentCells = _undoStack.removeLast();
    notifyListeners();
  }

  // Redo last undone action
  void redo() {
    if (_redoStack.isEmpty) return;
    
    _undoStack.add(Map<String, CellData>.from(_currentCells));
    _currentCells = _redoStack.removeLast();
    notifyListeners();
  }

  // Load all user spreadsheets
  Future<void> loadSpreadsheets() async {
    try {
      _isLoading = true;
      notifyListeners();

      _spreadsheets = await _dbService.getUserSpreadsheets();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Create new spreadsheet
  Future<String?> createSpreadsheet({
    required String title,
    String? description,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final spreadsheet = await _dbService.createSpreadsheet(
        title: title,
        description: description,
      );

      await loadSpreadsheets();
      
      _isLoading = false;
      notifyListeners();

      return spreadsheet['id'];
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Load a specific spreadsheet
  Future<bool> loadSpreadsheet(String spreadsheetId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final spreadsheet = await _dbService.getSpreadsheet(spreadsheetId);
      if (spreadsheet == null) {
        throw Exception('Spreadsheet not found');
      }

      _currentSpreadsheetId = spreadsheetId;
      _currentSpreadsheetTitle = spreadsheet['title'];

      _currentCells = await _dbService.getSpreadsheetCells(spreadsheetId);
      _columnWidths = await _dbService.getColumnSettings(spreadsheetId);
      _rowHeights = await _dbService.getRowSettings(spreadsheetId);

      _undoStack.clear();
      _redoStack.clear();

      await _dbService.updateLastAccessed(spreadsheetId);
      await _subscribeToRealtime(spreadsheetId);
      _startAutoSave();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update cell value (local)
  void updateCell(String address, CellData cellData) {
    _saveStateForUndo();
    _currentCells[address] = cellData;
    notifyListeners();
  }

  // Remove cell (local)
  void removeCell(String address) {
    _saveStateForUndo();
    _currentCells.remove(address);
    notifyListeners();
  }

  // Save current spreadsheet
  Future<bool> saveSpreadsheet() async {
    if (_currentSpreadsheetId == null) return false;

    try {
      _isSaving = true;
      notifyListeners();

      await _dbService.saveCells(_currentSpreadsheetId!, _currentCells);

      for (var entry in _columnWidths.entries) {
        await _dbService.saveColumnSettings(
          spreadsheetId: _currentSpreadsheetId!,
          columnIndex: entry.key,
          width: entry.value,
        );
      }

      for (var entry in _rowHeights.entries) {
        await _dbService.saveRowSettings(
          spreadsheetId: _currentSpreadsheetId!,
          rowIndex: entry.key,
          height: entry.value,
        );
      }

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSaving = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update spreadsheet title
  Future<bool> updateSpreadsheetTitle(String spreadsheetId, String newTitle) async {
    try {
      await _dbService.updateSpreadsheet(spreadsheetId, {'title': newTitle});
      
      if (_currentSpreadsheetId == spreadsheetId) {
        _currentSpreadsheetTitle = newTitle;
      }
      
      await loadSpreadsheets();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete spreadsheet (soft delete - moves to trash)
  Future<bool> deleteSpreadsheet(String spreadsheetId) async {
    try {
      print('Provider: Deleting spreadsheet $spreadsheetId');
      await _dbService.deleteSpreadsheet(spreadsheetId);
      await loadSpreadsheets();
      print('Provider: Spreadsheet deleted and list reloaded');
      notifyListeners();
      return true;
    } catch (e) {
      print('Provider: Error deleting spreadsheet: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Restore spreadsheet from trash
  Future<bool> restoreSpreadsheet(String spreadsheetId) async {
    try {
      print('Provider: Restoring spreadsheet $spreadsheetId');
      await _dbService.restoreSpreadsheet(spreadsheetId);
      await loadSpreadsheets();
      print('Provider: Spreadsheet restored and list reloaded');
      notifyListeners();
      return true;
    } catch (e) {
      print('Provider: Error restoring spreadsheet: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Permanently delete spreadsheet (hard delete)
  Future<bool> permanentlyDeleteSpreadsheet(String spreadsheetId) async {
    try {
      print('Provider: Permanently deleting spreadsheet $spreadsheetId');
      await _dbService.permanentlyDeleteSpreadsheet(spreadsheetId);
      await loadSpreadsheets();
      print('Provider: Spreadsheet permanently deleted and list reloaded');
      notifyListeners();
      return true;
    } catch (e) {
      print('Provider: Error permanently deleting spreadsheet: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update column width
  void updateColumnWidth(int columnIndex, double width) {
    _columnWidths[columnIndex] = width;
    notifyListeners();
  }

  // Update row height
  void updateRowHeight(int rowIndex, double height) {
    _rowHeights[rowIndex] = height;
    notifyListeners();
  }

  // Export to CSV
  Future<String?> exportToCSV(String fileName, int maxRows, int maxCols) async {
    try {
      return await _fileService.exportToCSV(
        cells: _currentCells,
        fileName: fileName,
        maxRows: maxRows,
        maxCols: maxCols,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Export to XLSX
  Future<String?> exportToXLSX(String fileName, int maxRows, int maxCols) async {
    try {
      return await _fileService.exportToXLSX(
        cells: _currentCells,
        fileName: fileName,
        maxRows: maxRows,
        maxCols: maxCols,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Subscribe to real-time updates
  Future<void> _subscribeToRealtime(String spreadsheetId) async {
    try {
      await _realtimeSubscription?.cancel();

      final stream = await _realtimeService.subscribeToSpreadsheet(spreadsheetId);
      
      _realtimeSubscription = stream.listen((update) {
        _handleRealtimeUpdate(update);
      });
    } catch (e) {
      print('Error subscribing to realtime: $e');
    }
  }

  // Handle real-time updates from other users
  void _handleRealtimeUpdate(RealtimeUpdate update) {
    final address = _getCellAddress(update.rowIndex, update.columnIndex);
    
    if (update.eventType == 'DELETE') {
      _currentCells.remove(address);
    } else if (update.cellData != null) {
      _currentCells[address] = update.cellData!;
    }
    
    notifyListeners();
  }

  // Auto-save functionality
  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) => saveSpreadsheet(),
    );
  }

  // Close current spreadsheet
Future<void> closeSpreadsheet() async {
  if (_currentSpreadsheetId != null) {
    await saveSpreadsheet();
  }

  try {
    await _realtimeService.unsubscribe();
  } catch (e) {
    print('Error unsubscribing from realtime: $e');
  }
  
  try {
    await _realtimeSubscription?.cancel();
  } catch (e) {
    print('Error cancelling subscription: $e');
  }
  
  _autoSaveTimer?.cancel();

  _currentSpreadsheetId = null;
  _currentSpreadsheetTitle = null;
  _currentCells.clear();
  _columnWidths.clear();
  _rowHeights.clear();
  _undoStack.clear();
  _redoStack.clear();
  
  notifyListeners();
}

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

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}