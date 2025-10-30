// lib/models/cell_data.dart

enum CellDataType {
  text,
  number,
  date,
  formula,
  boolean,
}

class CellData {
  String? value;
  String? displayValue;
  CellDataType dataType;
  String? formula;
  
  // Formatting
  String fontWeight;
  String fontStyle;
  String textDecoration;
  String textAlign;
  String backgroundColor;
  String fontColor;
  int fontSize;

  CellData({
    this.value,
    this.displayValue,
    this.dataType = CellDataType.text,
    this.formula,
    this.fontWeight = 'normal',
    this.fontStyle = 'normal',
    this.textDecoration = 'none',
    this.textAlign = 'left',
    this.backgroundColor = '#FFFFFF',
    this.fontColor = '#000000',
    this.fontSize = 14,
  });

  CellData copyWith({
    String? value,
    String? displayValue,
    CellDataType? dataType,
    String? formula,
    String? fontWeight,
    String? fontStyle,
    String? textDecoration,
    String? textAlign,
    String? backgroundColor,
    String? fontColor,
    int? fontSize,
  }) {
    return CellData(
      value: value ?? this.value,
      displayValue: displayValue ?? this.displayValue,
      dataType: dataType ?? this.dataType,
      formula: formula ?? this.formula,
      fontWeight: fontWeight ?? this.fontWeight,
      fontStyle: fontStyle ?? this.fontStyle,
      textDecoration: textDecoration ?? this.textDecoration,
      textAlign: textAlign ?? this.textAlign,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontColor: fontColor ?? this.fontColor,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'displayValue': displayValue,
      'dataType': dataType.toString(),
      'formula': formula,
      'fontWeight': fontWeight,
      'fontStyle': fontStyle,
      'textDecoration': textDecoration,
      'textAlign': textAlign,
      'backgroundColor': backgroundColor,
      'fontColor': fontColor,
      'fontSize': fontSize,
    };
  }

  factory CellData.fromJson(Map<String, dynamic> json) {
    return CellData(
      value: json['value'],
      displayValue: json['displayValue'],
      dataType: CellDataType.values.firstWhere(
        (e) => e.toString() == json['dataType'],
        orElse: () => CellDataType.text,
      ),
      formula: json['formula'],
      fontWeight: json['fontWeight'] ?? 'normal',
      fontStyle: json['fontStyle'] ?? 'normal',
      textDecoration: json['textDecoration'] ?? 'none',
      textAlign: json['textAlign'] ?? 'left',
      backgroundColor: json['backgroundColor'] ?? '#FFFFFF',
      fontColor: json['fontColor'] ?? '#000000',
      fontSize: json['fontSize'] ?? 14,
    );
  }
}