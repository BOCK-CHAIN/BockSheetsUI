// lib/screens/spreadsheet/spreadsheet_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/cell_data.dart';
import '../../providers/spreadsheet_provider.dart';
import '../../widgets/spreadsheet_grid.dart';
import '../../widgets/formula_bar.dart';
import '../../widgets/formatting_toolbar.dart';

class SpreadsheetScreen extends StatefulWidget {
  final String spreadsheetId;
  final String title;

  const SpreadsheetScreen({
    super.key,
    required this.spreadsheetId,
    required this.title,
  });

  @override
  State<SpreadsheetScreen> createState() => _SpreadsheetScreenState();
}

class _SpreadsheetScreenState extends State<SpreadsheetScreen> {
  CellData? _selectedCell;
  String _selectedCellAddress = '';
  Set<String> _selectedCells = {}; // ADD THIS
  final TextEditingController _formulaController = TextEditingController();
  
  int _rowCount = 100;
  int _columnCount = 26;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SpreadsheetProvider>();
      provider.loadSpreadsheet(widget.spreadsheetId);
    });
  }

  @override
  void dispose() {
    _formulaController.dispose();
    context.read<SpreadsheetProvider>().closeSpreadsheet();
    super.dispose();
  }

void _onCellSelected(int row, int col) {
  final provider = context.read<SpreadsheetProvider>();
  setState(() {
    _selectedCellAddress = '${_getColumnLabel(col)}${row + 1}';
    _selectedCell = provider.currentCells[_selectedCellAddress];
    _selectedCells.clear(); // Clear multi-selection when single cell selected
    _selectedCells.add(_selectedCellAddress);
    _formulaController.text = _selectedCell?.value ?? '';
  });
}
void _onMultiCellSelected(Set<String> cells) {
  setState(() {
    _selectedCells = cells;
    if (cells.isNotEmpty) {
      _selectedCellAddress = cells.first;
      final provider = context.read<SpreadsheetProvider>();
      _selectedCell = provider.currentCells[_selectedCellAddress];
    }
  });
}

  void _onCellValueChanged(int row, int col, String value) {
    final provider = context.read<SpreadsheetProvider>();
    final address = '${_getColumnLabel(col)}${row + 1}';
    
    if (value.isEmpty) {
      provider.removeCell(address);
    } else {
      final cellData = provider.currentCells[address] ?? CellData();
      
      // Check if it's a formula
      if (value.startsWith('=')) {
        cellData.formula = value;
        cellData.dataType = CellDataType.formula;
        cellData.value = value;
        cellData.displayValue = _evaluateFormula(value, provider.currentCells);
      } else {
        cellData.value = value;
        cellData.displayValue = value;
        cellData.formula = null;
        
        // Auto-detect data type
        if (double.tryParse(value) != null) {
          cellData.dataType = CellDataType.number;
        } else if (DateTime.tryParse(value) != null) {
          cellData.dataType = CellDataType.date;
        } else {
          cellData.dataType = CellDataType.text;
        }
      }
      
      provider.updateCell(address, cellData);
    }
    
    // Recalculate formulas
    _recalculateFormulas(provider);
  }

  String _evaluateFormula(String formula, Map<String, CellData> cells) {
    try {
      String expr = formula.substring(1).toUpperCase().trim();
      if (expr.startsWith('ARRAYSUM(')) {
      return _handleArraySumFunction(expr, cells);
      }
      if (expr.startsWith('ARRAYMULTIPLY(')) {
      return _handleArrayMultiplyFunction(expr, cells);
      }
      if (expr.startsWith('ARRAYDIVIDE(')) {
        return _handleArrayDivideFunction(expr, cells);
      }
      if (expr.startsWith('ARRAYSUBTRACT(')) {
        return _handleArraySubtractFunction(expr, cells);
      }
      if (expr.startsWith('SUM(')) {
        return _handleSumFunction(expr, cells);
      }
      if (expr.startsWith('AVERAGE(') || expr.startsWith('AVG(')) {
        return _handleAverageFunction(expr, cells);
      }
      if (expr.startsWith('MIN(')) {
        return _handleMinFunction(expr, cells);
      }
      if (expr.startsWith('MAX(')) {
        return _handleMaxFunction(expr, cells);
      }
      if (expr.startsWith('COUNT(')) {
        return _handleCountFunction(expr, cells);
      }
      if (expr.startsWith('IF(')) {
        return _handleIfFunction(expr, cells);
      }
      
      // Try to evaluate simple cell references (e.g., =A1)
      if (RegExp(r'^[A-Z]+\d+$').hasMatch(expr)) {
        final cell = cells[expr];
        return cell?.displayValue ?? cell?.value ?? '0';
      }
      
      // Try to evaluate simple arithmetic (e.g., =A1+B1)
      return _evaluateArithmetic(expr, cells);
    } catch (e) {
      print('Error evaluating formula "$formula": $e');
      return '#ERROR';
    }
  }
  String _handleArraySumFunction(String expr, Map<String, CellData> cells) {
  try {
    // Extract the pattern: ARRAYSUM(A, B, C) means A[i] + B[i] = C[i]
    final content = expr.substring(9, expr.length - 1).trim();
    final parts = content.split(',').map((e) => e.trim()).toList();
    
    if (parts.length < 3) return '#ERROR';
    
    final col1 = parts[0]; // e.g., "A"
    final col2 = parts[1]; // e.g., "B"
    final resultCol = parts[2]; // e.g., "C"
    
    // Apply formula to all rows
    int updatedCount = 0;
    for (int row = 0; row < _rowCount; row++) {
      final addr1 = '$col1${row + 1}';
      final addr2 = '$col2${row + 1}';
      final resultAddr = '$resultCol${row + 1}';
      
      final val1 = _getCellNumericValue(addr1, cells);
      final val2 = _getCellNumericValue(addr2, cells);
      
      // Only update if source cells have values
      if (cells.containsKey(addr1) || cells.containsKey(addr2)) {
        final result = val1 + val2;
        
        // Create or update result cell
        final provider = context.read<SpreadsheetProvider>();
        final resultCell = cells[resultAddr] ?? CellData();
        resultCell.value = result.toString();
        resultCell.displayValue = _formatNumber(result);
        resultCell.dataType = CellDataType.number;
        
        provider.updateCell(resultAddr, resultCell);
        updatedCount++;
      }
    }
    
    return 'Applied to $updatedCount rows';
  } catch (e) {
    print('Error in ARRAYSUM: $e');
    return '#ERROR';
  }
}

String _handleArrayMultiplyFunction(String expr, Map<String, CellData> cells) {
  try {
    // ARRAYMULTIPLY(A, B, C) means A[i] * B[i] = C[i]
    final content = expr.substring(14, expr.length - 1).trim();
    final parts = content.split(',').map((e) => e.trim()).toList();
    
    if (parts.length < 3) return '#ERROR';
    
    final col1 = parts[0];
    final col2 = parts[1];
    final resultCol = parts[2];
    
    int updatedCount = 0;
    for (int row = 0; row < _rowCount; row++) {
      final addr1 = '$col1${row + 1}';
      final addr2 = '$col2${row + 1}';
      final resultAddr = '$resultCol${row + 1}';
      
      final val1 = _getCellNumericValue(addr1, cells);
      final val2 = _getCellNumericValue(addr2, cells);
      
      if (cells.containsKey(addr1) || cells.containsKey(addr2)) {
        final result = val1 * val2;
        
        final provider = context.read<SpreadsheetProvider>();
        final resultCell = cells[resultAddr] ?? CellData();
        resultCell.value = result.toString();
        resultCell.displayValue = _formatNumber(result);
        resultCell.dataType = CellDataType.number;
        
        provider.updateCell(resultAddr, resultCell);
        updatedCount++;
      }
    }
    
    return 'Applied to $updatedCount rows';
  } catch (e) {
    print('Error in ARRAYMULTIPLY: $e');
    return '#ERROR';
  }
}

String _handleArrayDivideFunction(String expr, Map<String, CellData> cells) {
  try {
    // ARRAYDIVIDE(A, B, C) means A[i] / B[i] = C[i]
    final content = expr.substring(12, expr.length - 1).trim();
    final parts = content.split(',').map((e) => e.trim()).toList();
    
    if (parts.length < 3) return '#ERROR';
    
    final col1 = parts[0];
    final col2 = parts[1];
    final resultCol = parts[2];
    
    int updatedCount = 0;
    for (int row = 0; row < _rowCount; row++) {
      final addr1 = '$col1${row + 1}';
      final addr2 = '$col2${row + 1}';
      final resultAddr = '$resultCol${row + 1}';
      
      final val1 = _getCellNumericValue(addr1, cells);
      final val2 = _getCellNumericValue(addr2, cells);
      
      if ((cells.containsKey(addr1) || cells.containsKey(addr2)) && val2 != 0) {
        final result = val1 / val2;
        
        final provider = context.read<SpreadsheetProvider>();
        final resultCell = cells[resultAddr] ?? CellData();
        resultCell.value = result.toString();
        resultCell.displayValue = _formatNumber(result);
        resultCell.dataType = CellDataType.number;
        
        provider.updateCell(resultAddr, resultCell);
        updatedCount++;
      }
    }
    
    return 'Applied to $updatedCount rows';
  } catch (e) {
    print('Error in ARRAYDIVIDE: $e');
    return '#ERROR';
  }
}

  String _handleArraySubtractFunction(String expr, Map<String, CellData> cells) {
    try {
      final content = expr.substring(14, expr.length - 1).trim();
      final parts = content.split(',').map((e) => e.trim()).toList();
      
      if (parts.length < 3) return '#ERROR';
      
      final col1 = parts[0];
      final col2 = parts[1];
      final resultCol = parts[2];
      
      int updatedCount = 0;
      for (int row = 0; row < _rowCount; row++) {
        final addr1 = '$col1${row + 1}';
        final addr2 = '$col2${row + 1}';
        final resultAddr = '$resultCol${row + 1}';
        
        final val1 = _getCellNumericValue(addr1, cells);
        final val2 = _getCellNumericValue(addr2, cells);
        
        if (cells.containsKey(addr1) || cells.containsKey(addr2)) {
          final result = val1 - val2;
          
          final provider = context.read<SpreadsheetProvider>();
          final resultCell = cells[resultAddr] ?? CellData();
          resultCell.value = result.toString();
          resultCell.displayValue = _formatNumber(result);
          resultCell.dataType = CellDataType.number;
          
          provider.updateCell(resultAddr, resultCell);
          updatedCount++;
        }
      }
      
      return 'Applied to $updatedCount rows';
    } catch (e) {
      print('Error in ARRAYSUBTRACT: $e');
      return '#ERROR';
    }
  }
  String _handleSumFunction(String expr, Map<String, CellData> cells) {
    try {
      final range = expr.substring(4, expr.length - 1).trim();
      final values = _getRangeValues(range, cells);
      final sum = values.fold<double>(0, (sum, val) => sum + val);
      return _formatNumber(sum);
    } catch (e) {
      print('Error in SUM: $e');
      return '#ERROR';
    }
  }

  String _handleAverageFunction(String expr, Map<String, CellData> cells) {
    try {
      int startIdx = expr.startsWith('AVERAGE(') ? 8 : 4;
      final range = expr.substring(startIdx, expr.length - 1).trim();
      final values = _getRangeValues(range, cells);
      if (values.isEmpty) return '0';
      final avg = values.fold<double>(0, (sum, val) => sum + val) / values.length;
      return _formatNumber(avg);
    } catch (e) {
      print('Error in AVERAGE: $e');
      return '#ERROR';
    }
  }

  String _handleMinFunction(String expr, Map<String, CellData> cells) {
    try {
      final range = expr.substring(4, expr.length - 1).trim();
      final values = _getRangeValues(range, cells);
      if (values.isEmpty) return '0';
      return _formatNumber(values.reduce((a, b) => a < b ? a : b));
    } catch (e) {
      print('Error in MIN: $e');
      return '#ERROR';
    }
  }

  String _handleMaxFunction(String expr, Map<String, CellData> cells) {
    try {
      final range = expr.substring(4, expr.length - 1).trim();
      final values = _getRangeValues(range, cells);
      if (values.isEmpty) return '0';
      return _formatNumber(values.reduce((a, b) => a > b ? a : b));
    } catch (e) {
      print('Error in MAX: $e');
      return '#ERROR';
    }
  }

  String _handleCountFunction(String expr, Map<String, CellData> cells) {
    try {
      final range = expr.substring(6, expr.length - 1).trim();
      final values = _getRangeValues(range, cells);
      return values.length.toString();
    } catch (e) {
      print('Error in COUNT: $e');
      return '#ERROR';
    }
  }

  String _handleIfFunction(String expr, Map<String, CellData> cells) {
    try {
      final content = expr.substring(3, expr.length - 1);
      final parts = _splitFunctionArgs(content);
      if (parts.length != 3) return '#ERROR';
      
      final condition = parts[0].trim();
      final trueValue = parts[1].trim();
      final falseValue = parts[2].trim();
      
      bool result = _evaluateCondition(condition, cells);
      String resultValue = result ? trueValue : falseValue;
      
      // If result is a cell reference, get its value
      if (RegExp(r'^[A-Z]+\d+$').hasMatch(resultValue)) {
        final cell = cells[resultValue];
        return cell?.displayValue ?? cell?.value ?? resultValue;
      }
      
      // Remove quotes if present
      if (resultValue.startsWith('"') && resultValue.endsWith('"')) {
        return resultValue.substring(1, resultValue.length - 1);
      }
      
      return resultValue;
    } catch (e) {
      print('Error in IF: $e');
      return '#ERROR';
    }
  }

  List<String> _splitFunctionArgs(String content) {
    List<String> parts = [];
    int parenthesesLevel = 0;
    int quoteLevel = 0;
    StringBuffer current = StringBuffer();
    
    for (int i = 0; i < content.length; i++) {
      String char = content[i];
      
      if (char == '"') {
        quoteLevel = 1 - quoteLevel;
        current.write(char);
      } else if (char == '(' && quoteLevel == 0) {
        parenthesesLevel++;
        current.write(char);
      } else if (char == ')' && quoteLevel == 0) {
        parenthesesLevel--;
        current.write(char);
      } else if (char == ',' && parenthesesLevel == 0 && quoteLevel == 0) {
        parts.add(current.toString());
        current.clear();
      } else {
        current.write(char);
      }
    }
    
    if (current.isNotEmpty) {
      parts.add(current.toString());
    }
    
    return parts;
  }

  bool _evaluateCondition(String condition, Map<String, CellData> cells) {
    try {
      for (var op in ['>=', '<=', '>', '<', '==', '!=', '=']) {
        if (condition.contains(op)) {
          final parts = condition.split(op);
          if (parts.length == 2) {
            final left = _getCellNumericValue(parts[0].trim(), cells);
            final right = _parseNumericValue(parts[1].trim(), cells);
            
            switch (op) {
              case '>': return left > right;
              case '<': return left < right;
              case '>=': return left >= right;
              case '<=': return left <= right;
              case '==':
              case '=': return (left - right).abs() < 0.0001;
              case '!=': return (left - right).abs() >= 0.0001;
            }
          }
          break;
        }
      }
      return false;
    } catch (e) {
      print('Error evaluating condition: $e');
      return false;
    }
  }

  double _parseNumericValue(String value, Map<String, CellData> cells) {
    // Check if it's a cell reference
    if (RegExp(r'^[A-Z]+\d+$').hasMatch(value)) {
      return _getCellNumericValue(value, cells);
    }
    // Try to parse as number
    return double.tryParse(value) ?? 0;
  }

  double _getCellNumericValue(String address, Map<String, CellData> cells) {
    final cell = cells[address];
    if (cell == null) return 0;
    return double.tryParse(cell.displayValue ?? cell.value ?? '0') ?? 0;
  }

  String _evaluateArithmetic(String expr, Map<String, CellData> cells) {
    try {
      // Replace cell references with their values
      String evaluated = expr;
      final cellPattern = RegExp(r'[A-Z]+\d+');
      final matches = cellPattern.allMatches(expr);
      
      for (var match in matches) {
        final cellRef = match.group(0)!;
        final value = _getCellNumericValue(cellRef, cells);
        evaluated = evaluated.replaceAll(cellRef, value.toString());
      }
      
      // Simple evaluation of +, -, *, /
      evaluated = evaluated.replaceAll(' ', '');
      
      // This is a very basic evaluator - for production, use a proper expression parser
      double result = _evaluateSimpleExpression(evaluated);
      return _formatNumber(result);
    } catch (e) {
      print('Error in arithmetic: $e');
      return '#ERROR';
    }
  }

  double _evaluateSimpleExpression(String expr) {
    // Very basic expression evaluator - handles only simple cases
    // For production, use a proper math expression parser library
    
    try {
      // Handle multiplication and division first
      while (expr.contains('*') || expr.contains('/')) {
        final multMatch = RegExp(r'(\d+\.?\d*)([*/])(\d+\.?\d*)').firstMatch(expr);
        if (multMatch != null) {
          final left = double.parse(multMatch.group(1)!);
          final op = multMatch.group(2)!;
          final right = double.parse(multMatch.group(3)!);
          final result = op == '*' ? left * right : left / right;
          expr = expr.replaceFirst(multMatch.group(0)!, result.toString());
        } else {
          break;
        }
      }
      
      // Handle addition and subtraction
      double result = 0;
      String currentNum = '';
      String currentOp = '+';
      
      for (int i = 0; i < expr.length; i++) {
        String char = expr[i];
        
        if (char == '+' || char == '-') {
          if (currentNum.isNotEmpty) {
            double num = double.parse(currentNum);
            result = currentOp == '+' ? result + num : result - num;
          }
          currentOp = char;
          currentNum = '';
        } else {
          currentNum += char;
        }
      }
      
      if (currentNum.isNotEmpty) {
        double num = double.parse(currentNum);
        result = currentOp == '+' ? result + num : result - num;
      }
      
      return result;
    } catch (e) {
      return 0;
    }
  }

  List<double> _getRangeValues(String range, Map<String, CellData> cells) {
    List<double> values = [];
    
    try {
      range = range.trim();
      
      // Handle column-only references (e.g., A:A, B:B)
      if (RegExp(r'^[A-Z]+:[A-Z]+$').hasMatch(range)) {
        final parts = range.split(':');
        final startCol = _getColumnIndex(parts[0]);
        final endCol = _getColumnIndex(parts[1]);
        
        for (int col = startCol; col <= endCol; col++) {
          for (int row = 0; row < _rowCount; row++) {
            final address = '${_getColumnLabel(col)}${row + 1}';
            final cell = cells[address];
            if (cell != null && cell.value != null && cell.value!.isNotEmpty) {
              final value = double.tryParse(cell.displayValue ?? cell.value ?? '0');
              if (value != null) values.add(value);
            }
          }
        }
        return values;
      }
      
      // Handle row-only references (e.g., 1:1, 2:5)
      if (RegExp(r'^\d+:\d+$').hasMatch(range)) {
        final parts = range.split(':');
        final startRow = int.parse(parts[0]) - 1;
        final endRow = int.parse(parts[1]) - 1;
        
        for (int row = startRow; row <= endRow && row < _rowCount; row++) {
          for (int col = 0; col < _columnCount; col++) {
            final address = '${_getColumnLabel(col)}${row + 1}';
            final cell = cells[address];
            if (cell != null && cell.value != null && cell.value!.isNotEmpty) {
              final value = double.tryParse(cell.displayValue ?? cell.value ?? '0');
              if (value != null) values.add(value);
            }
          }
        }
        return values;
      }
      
      // Handle standard cell ranges (e.g., A1:B5)
      if (range.contains(':')) {
        final parts = range.split(':');
        final startAddr = parts[0].trim();
        final endAddr = parts[1].trim();
        
        final startMatch = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(startAddr);
        final endMatch = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(endAddr);
        
        if (startMatch != null && endMatch != null) {
          final startCol = _getColumnIndex(startMatch.group(1)!);
          final startRow = int.parse(startMatch.group(2)!) - 1;
          final endCol = _getColumnIndex(endMatch.group(1)!);
          final endRow = int.parse(endMatch.group(2)!) - 1;
          
          for (int row = startRow; row <= endRow; row++) {
            for (int col = startCol; col <= endCol; col++) {
              final address = '${_getColumnLabel(col)}${row + 1}';
              final cell = cells[address];
              if (cell != null) {
                final value = double.tryParse(cell.displayValue ?? cell.value ?? '0');
                if (value != null) values.add(value);
              }
            }
          }
        }
      } else {
        // Single cell reference
        final cell = cells[range];
        if (cell != null) {
          final value = double.tryParse(cell.displayValue ?? cell.value ?? '0');
          if (value != null) values.add(value);
        }
      }
    } catch (e) {
      print('Error getting range values for "$range": $e');
    }
    
    return values;
  }

  void _recalculateFormulas(SpreadsheetProvider provider) {
    provider.currentCells.forEach((address, cell) {
      if (cell.formula != null && cell.formula!.isNotEmpty) {
        cell.displayValue = _evaluateFormula(cell.formula!, provider.currentCells);
      }
    });
    provider.notifyListeners();
  }

  String _getColumnLabel(int index) {
    String label = '';
    int num = index;
    while (num >= 0) {
      label = String.fromCharCode(65 + (num % 26)) + label;
      num = (num ~/ 26) - 1;
      if (num < 0) break;
    }
    return label;
  }

  int _getColumnIndex(String label) {
    int index = 0;
    label = label.toUpperCase();
    for (int i = 0; i < label.length; i++) {
      index = index * 26 + (label.codeUnitAt(i) - 64);
    }
    return index - 1;
  }

  String _formatNumber(double num) {
    if (num == num.toInt()) {
      return num.toInt().toString();
    }
    return num.toStringAsFixed(2);
  }

  void _addRow() {
    setState(() => _rowCount++);
  }

  void _addColumn() {
    setState(() => _columnCount++);
  }

  void _applyFormatting(String property, dynamic value) {
  if (_selectedCells.isEmpty) return;
  
  final provider = context.read<SpreadsheetProvider>();
  
  // Apply formatting to all selected cells
  for (String address in _selectedCells) {
    final cell = provider.currentCells[address] ?? CellData();
    
    switch (property) {
      case 'bold':
        cell.fontWeight = cell.fontWeight == 'bold' ? 'normal' : 'bold';
        break;
      case 'italic':
        cell.fontStyle = cell.fontStyle == 'italic' ? 'normal' : 'italic';
        break;
      case 'underline':
        cell.textDecoration = cell.textDecoration == 'underline' ? 'none' : 'underline';
        break;
      case 'align':
        cell.textAlign = value;
        break;
      case 'bgColor':
        cell.backgroundColor = value;
        break;
      case 'fontColor':
        cell.fontColor = value;
        break;
      case 'fontSize': // ADD THIS NEW CASE
        cell.fontSize = value;
        break;
    }
    
    provider.updateCell(address, cell);
  }
  
  // Update selected cell reference
  if (_selectedCellAddress.isNotEmpty) {
    setState(() {
      _selectedCell = provider.currentCells[_selectedCellAddress];
    });
  }
}


Future<void> _handleExport(String format) async {
  final provider = context.read<SpreadsheetProvider>();
  final fileName = provider.currentSpreadsheetTitle ?? 'spreadsheet';
  
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(width: 16),
          Text('Preparing export...'),
        ],
      ),
      duration: Duration(seconds: 2),
    ),
  );
  
  String? filePath;
  try {
    if (format == 'csv') {
      filePath = await provider.exportToCSV(fileName, _rowCount, _columnCount);
    } else {
      filePath = await provider.exportToXLSX(fileName, _rowCount, _columnCount);
    }
    
    if (mounted) {
      if (filePath != null && filePath.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✓ Exported successfully!'),
                const SizedBox(height: 4),
                Text(
                  'File: ${filePath.split('/').last}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Location: ${filePath.split('/').sublist(0, filePath.split('/').length - 1).join('/')}',
                  style: const TextStyle(fontSize: 10),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export cancelled or failed'),
            backgroundColor: AppTheme.warning,
          ),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await context.read<SpreadsheetProvider>().saveSpreadsheet();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<SpreadsheetProvider>(
            builder: (context, provider, child) {
              return Row(
                children: [
                  const Icon(Icons.table_chart, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showRenameDialog(provider),
                      child: Text(
                        provider.currentSpreadsheetTitle ?? widget.title,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  if (provider.isSaving)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              );
            },
          ),
          actions: [
            Consumer<SpreadsheetProvider>(
              builder: (context, provider, child) {
                return IconButton(
                  icon: const Icon(Icons.undo),
                  onPressed: provider.canUndo ? () => provider.undo() : null,
                  tooltip: 'Undo',
                  color: provider.canUndo ? null : Colors.grey.shade400,
                );
              },
            ),
            Consumer<SpreadsheetProvider>(
              builder: (context, provider, child) {
                return IconButton(
                  icon: const Icon(Icons.redo),
                  onPressed: provider.canRedo ? () => provider.redo() : null,
                  tooltip: 'Redo',
                  color: provider.canRedo ? null : Colors.grey.shade400,
                );
              },
            ),
            const VerticalDivider(),
            Consumer<SpreadsheetProvider>(
              builder: (context, provider, child) {
                return IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: provider.isSaving 
                      ? null 
                      : () => provider.saveSpreadsheet(),
                  tooltip: 'Save',
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _showShareDialog(),
              tooltip: 'Share',
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _showExportDialog(),
              tooltip: 'Export',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Consumer<SpreadsheetProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                FormulaBar(
                  controller: _formulaController,
                  selectedCell: _selectedCellAddress,
                  onSubmit: (value) {
                    if (_selectedCellAddress.isNotEmpty) {
                      final match = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(_selectedCellAddress);
                      if (match != null) {
                        final col = _getColumnIndex(match.group(1)!);
                        final row = int.parse(match.group(2)!) - 1;
                        _onCellValueChanged(row, col, value);
                      }
                    }
                  },
                ),
                
                FormattingToolbar(
                  selectedCell: _selectedCell,
                  onFormatChange: _applyFormatting,
                  onAddRow: _addRow,
                  onAddColumn: _addColumn,
                ),
                
                const Divider(height: 1),
                
                Expanded(
                  child: SpreadsheetGrid(
                    rowCount: _rowCount,
                    columnCount: _columnCount,
                    cells: provider.currentCells,
                    columnWidths: provider.columnWidths,
                    rowHeights: provider.rowHeights,
                    onCellSelected: _onCellSelected,
                    onCellValueChanged: _onCellValueChanged,
                    onMultiCellSelected: _onMultiCellSelected, // ADD THIS
                    onColumnResize: (col, width) {
                      provider.updateColumnWidth(col, width);
                    },
                    onRowResize: (row, height) {
                      provider.updateRowHeight(row, height);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showRenameDialog(SpreadsheetProvider provider) {
    final controller = TextEditingController(
      text: provider.currentSpreadsheetTitle ?? widget.title,
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Spreadsheet'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Spreadsheet Name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (provider.currentSpreadsheetId != null) {
                provider.updateSpreadsheetTitle(
                  provider.currentSpreadsheetId!,
                  controller.text,
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Spreadsheet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this spreadsheet with others'),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Share Link',
                hintText: 'https://bocksheets.app/share/${widget.spreadsheetId}',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: 'https://bocksheets.app/share/${widget.spreadsheetId}'),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
              readOnly: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

void _showExportDialog() {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Export Spreadsheet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.file_download, color: AppTheme.primaryBlue),
            title: const Text('Export as CSV'),
            subtitle: const Text('Comma-separated values format'),
            onTap: () {
              Navigator.pop(context);
              _handleExport('csv');
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_download, color: AppTheme.primaryViolet),
            title: const Text('Export as XLSX'),
            subtitle: const Text('Excel spreadsheet format'),
            onTap: () {
              Navigator.pop(context);
              _handleExport('xlsx');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}
}