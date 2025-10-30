import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:excel/excel.dart' as excel_lib;
import '../models/cell_data.dart';

class FileService {
  // Import CSV file
  Future<Map<String, CellData>?> importCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null) return null;

      String csvString;
      
      if (kIsWeb) {
        if (result.files.single.bytes == null) return null;
        csvString = String.fromCharCodes(result.files.single.bytes!);
      } else {
        if (result.files.single.path == null) return null;
        final file = File(result.files.single.path!);
        csvString = await file.readAsString();
      }

      final csvData = const CsvToListConverter().convert(csvString);
      final cells = <String, CellData>{};
      
      for (int row = 0; row < csvData.length; row++) {
        final rowData = csvData[row];
        for (int col = 0; col < rowData.length; col++) {
          final value = rowData[col]?.toString() ?? '';
          if (value.isNotEmpty) {
            final address = '${_getColumnLabel(col)}${row + 1}';
            cells[address] = CellData(
              value: value,
              displayValue: value,
              dataType: _detectDataType(value),
            );
          }
        }
      }

      return cells;
    } catch (e) {
      print('Error importing CSV: $e');
      return null;
    }
  }


  // Import Excel file
  Future<Map<String, CellData>?> importExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null) return null;

      final cells = <String, CellData>{};
      
      if (kIsWeb) {
        if (result.files.single.bytes == null) return null;
        final excel = excel_lib.Excel.decodeBytes(result.files.single.bytes!);
        cells.addAll(_parseExcelData(excel));
      } else {
        if (result.files.single.path == null) return null;
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        final excel = excel_lib.Excel.decodeBytes(bytes);
        cells.addAll(_parseExcelData(excel));
      }

      return cells;
    } catch (e) {
      print('Error importing Excel: $e');
      return null;
    }
  }

  // Parse Excel data into cells
  Map<String, CellData> _parseExcelData(excel_lib.Excel excel) {
    final cells = <String, CellData>{};
    
    // Get first sheet
    final sheet = excel.tables.values.first;
    
    for (int row = 0; row < sheet.rows.length; row++) {
      final rowData = sheet.rows[row];
      for (int col = 0; col < rowData.length; col++) {
        final cell = rowData[col];
        if (cell != null && cell.value != null) {
          final value = cell.value.toString();
          if (value.isNotEmpty) {
            final address = '${_getColumnLabel(col)}${row + 1}';
            cells[address] = CellData(
              value: value,
              displayValue: value,
              dataType: _detectDataType(value),
            );
          }
        }
      }
    }
    
    return cells;
  }
  // Export to CSV
  Future<String?> exportToCSV({
    required Map<String, CellData> cells,
    required String fileName,
    required int maxRows,
    required int maxCols,
  }) async {
    try {
      List<List<String>> csvData = List.generate(
        maxRows,
        (row) => List.generate(maxCols, (col) => ''),
      );

      cells.forEach((address, cellData) {
        final match = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(address);
        if (match != null) {
          final col = _columnLabelToIndex(match.group(1)!);
          final row = int.parse(match.group(2)!) - 1;
          if (row < maxRows && col < maxCols) {
            csvData[row][col] = cellData.displayValue ?? cellData.value ?? '';
          }
        }
      });

      csvData = _trimEmptyRowsAndCols(csvData);
      String csv = const ListToCsvConverter().convert(csvData);

      if (kIsWeb) {
        return csv;
      }

      try {
        String? outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save CSV File',
          fileName: '$fileName.csv',
          type: FileType.custom,
          allowedExtensions: ['csv'],
        );

        if (outputPath != null) {
          if (!outputPath.endsWith('.csv')) {
            outputPath = '$outputPath.csv';
          }
          final file = File(outputPath);
          await file.writeAsString(csv);
          print('CSV exported successfully to: $outputPath');
          return outputPath;
        }
        return null;
      } catch (e) {
        print('Error with file picker: $e');
        try {
          final directory = Directory('/storage/emulated/0/Download');
          if (await directory.exists()) {
            final filePath = '${directory.path}/$fileName.csv';
            final file = File(filePath);
            await file.writeAsString(csv);
            print('CSV saved to Downloads: $filePath');
            return filePath;
          }
        } catch (e2) {
          print('Downloads directory error: $e2');
        }
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName.csv';
        final file = File(filePath);
        await file.writeAsString(csv);
        return filePath;
      }
    } catch (e) {
      print('Error exporting CSV: $e');
      return null;
    }
  }

  // Export to XLSX (proper Excel format)
  Future<String?> exportToXLSX({
    required Map<String, CellData> cells,
    required String fileName,
    required int maxRows,
    required int maxCols,
  }) async {
    try {
      final excel = excel_lib.Excel.createExcel();
      final sheet = excel['Sheet1'];

      cells.forEach((address, cellData) {
        final match = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(address);
        if (match != null) {
          final col = _columnLabelToIndex(match.group(1)!);
          final row = int.parse(match.group(2)!) - 1;
          if (row < maxRows && col < maxCols) {
            final value = cellData.displayValue ?? cellData.value ?? '';
            sheet
                .cell(excel_lib.CellIndex.indexByColumnRow(
                    columnIndex: col, rowIndex: row))
                .value = value as excel_lib.CellValue?;
          }
        }
      });

      final bytes = excel.encode();
      if (bytes == null) return null;

      if (kIsWeb) {
        return 'Excel data ready for download';
      }

      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Excel File',
        fileName: '$fileName.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (outputPath != null) {
        if (!outputPath.endsWith('.xlsx')) {
          outputPath = '$outputPath.xlsx';
        }
        final file = File(outputPath);
        await file.writeAsBytes(bytes);
        return outputPath;
      }
      return null;
    } catch (e) {
      print('Error exporting XLSX: $e');
      return null;
    }
  }

  // Export with file picker (generic for CSV or XLSX)
  Future<String?> exportWithPicker({
    required Map<String, CellData> cells,
    required String fileName,
    required int maxRows,
    required int maxCols,
    required String format, // 'csv' or 'xlsx'
  }) async {
    try {
      if (format == 'csv') {
        return await exportToCSV(
          cells: cells,
          fileName: fileName,
          maxRows: maxRows,
          maxCols: maxCols,
        );
      } else if (format == 'xlsx') {
        return await exportToXLSX(
          cells: cells,
          fileName: fileName,
          maxRows: maxRows,
          maxCols: maxCols,
        );
      }
      return null;
    } catch (e) {
      print('Error exporting with picker: $e');
      return null;
    }
  }

  // Helper: Detect data type from string
  CellDataType _detectDataType(String value) {
    if (double.tryParse(value) != null) {
      return CellDataType.number;
    }
    if (DateTime.tryParse(value) != null) {
      return CellDataType.date;
    }
    if (value.toLowerCase() == 'true' || value.toLowerCase() == 'false') {
      return CellDataType.boolean;
    }
    if (value.startsWith('=')) {
      return CellDataType.formula;
    }
    return CellDataType.text;
  }

  // Helper: Get column label from index
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

  // Helper: Get column index from label
  int _columnLabelToIndex(String label) {
    int index = 0;
    for (int i = 0; i < label.length; i++) {
      index = index * 26 + (label.codeUnitAt(i) - 64);
    }
    return index - 1;
  }

  // Helper: Trim empty rows and columns
  List<List<String>> _trimEmptyRowsAndCols(List<List<String>> data) {
    if (data.isEmpty) return data;
    int lastRow = data.length - 1;
    while (lastRow >= 0 && data[lastRow].every((cell) => cell.isEmpty)) {
      lastRow--;
    }
    if (lastRow < 0) return [[]];
    int lastCol = 0;
    for (var row in data.sublist(0, lastRow + 1)) {
      for (int col = row.length - 1; col >= 0; col--) {
        if (row[col].isNotEmpty && col > lastCol) {
          lastCol = col;
        }
      }
    }
    return data.sublist(0, lastRow + 1).map((row) {
      return row.sublist(0, lastCol + 1);
    }).toList();
  }
}