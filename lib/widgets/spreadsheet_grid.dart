// lib/widgets/spreadsheet_grid.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_theme.dart';
import '../models/cell_data.dart';

class SpreadsheetGrid extends StatefulWidget {
  final int rowCount;
  final int columnCount;
  final Map<String, CellData> cells;
  final Map<int, double> columnWidths;
  final Map<int, double> rowHeights;
  final Function(int row, int col) onCellSelected;
  final Function(int row, int col, String value) onCellValueChanged;
  final Function(int col, double width) onColumnResize;
  final Function(int row, double height) onRowResize;
  final Function(Set<String> selectedCells)? onMultiCellSelected; // ADD THIS

  const SpreadsheetGrid({
    super.key,
    required this.rowCount,
    required this.columnCount,
    required this.cells,
    required this.columnWidths,
    required this.rowHeights,
    required this.onCellSelected,
    required this.onCellValueChanged,
    required this.onColumnResize,
    required this.onRowResize,
    this.onMultiCellSelected, // ADD THIS
  });

  @override
  State<SpreadsheetGrid> createState() => _SpreadsheetGridState();
}

class _SpreadsheetGridState extends State<SpreadsheetGrid> {
  int? _selectedRow;
  int? _selectedCol;
  int? _editingRow;
  int? _editingCol;
  Set<String> _selectedCells = {};   //calude 
  //Set<String> _selectedCells = {}; // Stores selected cells like "row_col"

  String? _selectionStartCell;
  bool _isSelecting = false;

  
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    _focusNode.dispose();
    super.dispose();
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

  String _getCellAddress(int row, int col) {
    return '${_getColumnLabel(col)}${row + 1}';
  }

  double _getColumnWidth(int col) {
    return widget.columnWidths[col] ?? 100.0;
  }

  double _getRowHeight(int row) {
    return widget.rowHeights[row] ?? 32.0;
  }

  void _selectCell(int row, int col) {
    setState(() {
      _selectedRow = row;
      _selectedCol = col;
      _editingRow = null;
      _editingCol = null;
    });
    widget.onCellSelected(row, col);
    _focusNode.requestFocus();
  }

  void _startEditing(int row, int col) {
    setState(() {
      _selectedRow = row;
      _selectedCol = col;
      _editingRow = row;
      _editingCol = col;
    });
    widget.onCellSelected(row, col);
  }

  void _stopEditing() {
    setState(() {
      _editingRow = null;
      _editingCol = null;
    });
  }
  

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;
    if (_selectedRow == null || _selectedCol == null) return;

    // If editing, don't handle navigation
    if (_editingRow != null && _editingCol != null) return;

    int newRow = _selectedRow!;
    int newCol = _selectedCol!;

    if (event.logicalKey == LogicalKeyboardKey.arrowUp && newRow > 0) {
      newRow--;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown && newRow < widget.rowCount - 1) {
      newRow++;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft && newCol > 0) {
      newCol--;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight && newCol < widget.columnCount - 1) {
      newCol++;
    } else if (event.logicalKey == LogicalKeyboardKey.tab) {
      if (event.isShiftPressed) {
        newCol = newCol > 0 ? newCol - 1 : newCol;
      } else {
        newCol = newCol < widget.columnCount - 1 ? newCol + 1 : newCol;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      newRow = newRow < widget.rowCount - 1 ? newRow + 1 : newRow;
    } else if (event.logicalKey == LogicalKeyboardKey.delete || 
               event.logicalKey == LogicalKeyboardKey.backspace) {
      // Clear cell content
      widget.onCellValueChanged(_selectedRow!, _selectedCol!, '');
      return;
    }

    if (newRow != _selectedRow || newCol != _selectedCol) {
      _selectCell(newRow, newCol);
    }
  }
  void _startSelection(int row, int col) {
  setState(() {
    _isSelecting = true;
    _selectionStartCell = _getCellAddress(row, col);
    _selectedCells.clear();
    _selectedCells.add(_selectionStartCell!);
    _selectedRow = row;
    _selectedCol = col;
  });
  widget.onCellSelected(row, col);
}

void _updateSelection(LongPressMoveUpdateDetails details, int startRow, int startCol) {
  if (!_isSelecting || _selectionStartCell == null) return;
  
  // Calculate which cell the pointer is over
  // This is a simplified version - you may need to adjust based on scroll position
  final localPosition = details.localPosition;
  
  setState(() {
    _selectedCells.clear();
    
    // Add all cells in the selection rectangle
    final startAddr = _selectionStartCell!;
    final startMatch = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(startAddr);
    if (startMatch != null) {
      final startColIdx = _getColumnIndex(startMatch.group(1)!);
      final startRowIdx = int.parse(startMatch.group(2)!) - 1;
      
      final minRow = startRowIdx < startRow ? startRowIdx : startRow;
      final maxRow = startRowIdx > startRow ? startRowIdx : startRow;
      final minCol = startColIdx < startCol ? startColIdx : startCol;
      final maxCol = startColIdx > startCol ? startColIdx : startCol;
      
      for (int r = minRow; r <= maxRow; r++) {
        for (int c = minCol; c <= maxCol; c++) {
          _selectedCells.add(_getCellAddress(r, c));
        }
      }
    }
  });
}

void _endSelection() {
  setState(() {
    _isSelecting = false;
  });
  // ADD THIS
  if (widget.onMultiCellSelected != null && _selectedCells.isNotEmpty) {
    widget.onMultiCellSelected!(_selectedCells);
  }
}

int _getColumnIndex(String label) {
  int index = 0;
  label = label.toUpperCase();
  for (int i = 0; i < label.length; i++) {
    index = index * 26 + (label.codeUnitAt(i) - 64);
  }
  return index - 1;
}

// ADD GETTER FOR SELECTED CELLS
Set<String> get selectedCells => _selectedCells;

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      child: Container(
        color: AppTheme.backgroundLight,
        child: Column(
          children: [
            // Column Headers
            _buildColumnHeaders(),
            
            // Grid Content
            Expanded(
              child: Row(
                children: [
                  // Row Headers
                  _buildRowHeaders(),
                  
                  // Main Grid
                  Expanded(
                    child: _buildMainGrid(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnHeaders() {
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          // Top-left corner cell
          Container(
            width: 50,
            decoration: BoxDecoration(
              color: AppTheme.gridHeaderBg,
              border: Border.all(color: AppTheme.cellBorder),
            ),
          ),
          
          // Column header cells
          Expanded(
            child: ListView.builder(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              itemCount: widget.columnCount,
              itemBuilder: (context, col) {
                return _buildColumnHeader(col);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(int col) {
    return GestureDetector(
      onPanUpdate: (details) {
        final newWidth = (_getColumnWidth(col) + details.delta.dx).clamp(50.0, 500.0);
        widget.onColumnResize(col, newWidth);
      },
      child: Container(
        width: _getColumnWidth(col),
        decoration: BoxDecoration(
          color: AppTheme.gridHeaderBg,
          border: Border.all(color: AppTheme.cellBorder),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                _getColumnLabel(col),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            
            // Resize handle
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: Container(
                  width: 4,
                  color: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowHeaders() {
    return SizedBox(
      width: 50,
      child: ListView.builder(
        controller: _verticalController,
        itemCount: widget.rowCount,
        itemBuilder: (context, row) {
          return _buildRowHeader(row);
        },
      ),
    );
  }

  Widget _buildRowHeader(int row) {
    return GestureDetector(
      onPanUpdate: (details) {
        final newHeight = (_getRowHeight(row) + details.delta.dy).clamp(20.0, 200.0);
        widget.onRowResize(row, newHeight);
      },
      child: Container(
        height: _getRowHeight(row),
        decoration: BoxDecoration(
          color: AppTheme.gridHeaderBg,
          border: Border.all(color: AppTheme.cellBorder),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '${row + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            
            // Resize handle
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeRow,
                child: Container(
                  height: 4,
                  color: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainGrid() {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
      child: Scrollbar(
        controller: _horizontalController,
        child: Scrollbar(
          controller: _verticalController,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              controller: _verticalController,
              child: Column(
                children: List.generate(
                  widget.rowCount,
                  (row) => Row(
                    children: List.generate(
                      widget.columnCount,
                      (col) => _buildCell(row, col),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

Widget _buildCell(int row, int col) {
  final address = _getCellAddress(row, col);
  final cellData = widget.cells[address];
  final isSelected = _selectedRow == row && _selectedCol == col;
  final isInSelection = _selectedCells.contains(address);
  final isEditing = _editingRow == row && _editingCol == col;

  return GestureDetector(
    onTap: () => _selectCell(row, col),
    onDoubleTap: () => _startEditing(row, col),
    onLongPressStart: (details) => _startSelection(row, col),
    onLongPressMoveUpdate: (details) => _updateSelection(details, row, col),
    onLongPressEnd: (details) => _endSelection(),
    
    child: Container(
      width: _getColumnWidth(col),
      height: _getRowHeight(row),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.cellSelected
            : isInSelection
                ? AppTheme.primaryBlue.withOpacity(0.2) // More visible selection
                : cellData?.backgroundColor != null
                    ? Color(int.parse(cellData!.backgroundColor.substring(1), radix: 16) + 0xFF000000)
                    : Colors.white,
        border: Border.all(
          color: isSelected 
              ? AppTheme.primaryBlue 
              : isInSelection
                  ? AppTheme.primaryBlue.withOpacity(0.5)
                  : AppTheme.cellBorder,
          width: (isSelected || isInSelection) ? 2 : 1,
        ),
      ),
      child: isEditing
          ? _buildEditableCell(row, col, cellData)
          : _buildCellContent(row, col, cellData, isSelected),
    ),
  );
}

  Widget _buildEditableCell(int row, int col, CellData? cellData) {
    final controller = TextEditingController(text: cellData?.value ?? '');
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );

    return TextField(
      controller: controller,
      autofocus: true,
      style: TextStyle(
        fontSize: cellData?.fontSize.toDouble() ?? 14,
        fontWeight: cellData?.fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
        fontStyle: cellData?.fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
        decoration: cellData?.textDecoration == 'underline'
            ? TextDecoration.underline
            : TextDecoration.none,
        color: cellData?.fontColor != null
            ? Color(int.parse(cellData!.fontColor.substring(1), radix: 16) + 0xFF000000)
            : Colors.black,
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        isDense: true,
      ),
      onSubmitted: (value) {
        widget.onCellValueChanged(row, col, value);
        _stopEditing();
      },
      onTapOutside: (event) {
        widget.onCellValueChanged(row, col, controller.text);
        _stopEditing();
      },
    );
  }

  Widget _buildCellContent(int row, int col, CellData? cellData, bool isSelected) {
    if (cellData == null || cellData.displayValue == null || cellData.displayValue!.isEmpty) {
      return const SizedBox.shrink();
    }

    final textAlign = cellData.textAlign == 'center'
        ? TextAlign.center
        : cellData.textAlign == 'right'
            ? TextAlign.right
            : TextAlign.left;

    final fontWeight = cellData.fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal;
    final fontStyle = cellData.fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal;
    final decoration = cellData.textDecoration == 'underline'
        ? TextDecoration.underline
        : TextDecoration.none;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Align(
        alignment: cellData.textAlign == 'center'
            ? Alignment.center
            : cellData.textAlign == 'right'
                ? Alignment.centerRight
                : Alignment.centerLeft,
        child: Text(
          cellData.displayValue ?? '',
          style: TextStyle(
            fontSize: cellData.fontSize.toDouble(),
            fontWeight: fontWeight,
            fontStyle: fontStyle,
            decoration: decoration,
            color: Color(int.parse(cellData.fontColor.substring(1), radix: 16) + 0xFF000000),
          ),
          textAlign: textAlign,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}