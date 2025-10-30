// lib/widgets/formatting_toolbar.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/cell_data.dart';

class FormattingToolbar extends StatelessWidget {
  final CellData? selectedCell;
  final Function(String, dynamic) onFormatChange;
  final VoidCallback onAddRow;
  final VoidCallback onAddColumn;

  const FormattingToolbar({
    super.key,
    required this.selectedCell,
    required this.onFormatChange,
    required this.onAddRow,
    required this.onAddColumn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.gridLine),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Text Formatting
            _buildIconButton(
              icon: Icons.format_bold,
              tooltip: 'Bold',
              isActive: selectedCell?.fontWeight == 'bold',
              onPressed: () => onFormatChange('bold', null),
            ),
            _buildIconButton(
              icon: Icons.format_italic,
              tooltip: 'Italic',
              isActive: selectedCell?.fontStyle == 'italic',
              onPressed: () => onFormatChange('italic', null),
            ),
            _buildIconButton(
              icon: Icons.format_underlined,
              tooltip: 'Underline',
              isActive: selectedCell?.textDecoration == 'underline',
              onPressed: () => onFormatChange('underline', null),
            ),
            
            const VerticalDivider(width: 24),
            
            // Text Alignment
            _buildIconButton(
              icon: Icons.format_align_left,
              tooltip: 'Align Left',
              isActive: selectedCell?.textAlign == 'left',
              onPressed: () => onFormatChange('align', 'left'),
            ),
            _buildIconButton(
              icon: Icons.format_align_center,
              tooltip: 'Align Center',
              isActive: selectedCell?.textAlign == 'center',
              onPressed: () => onFormatChange('align', 'center'),
            ),
            _buildIconButton(
              icon: Icons.format_align_right,
              tooltip: 'Align Right',
              isActive: selectedCell?.textAlign == 'right',
              onPressed: () => onFormatChange('align', 'right'),
            ),
            
            const VerticalDivider(width: 24),
            
            // Colors
            _buildColorPicker(
              icon: Icons.format_color_fill,
              tooltip: 'Background Color',
              currentColor: selectedCell?.backgroundColor ?? '#FFFFFF',
              onColorSelected: (color) => onFormatChange('bgColor', color),
            ),
            _buildColorPicker(
              icon: Icons.format_color_text,
              tooltip: 'Text Color',
              currentColor: selectedCell?.fontColor ?? '#000000',
              onColorSelected: (color) => onFormatChange('fontColor', color),
            ),
            // Add this after the color pickers in the toolbar
            const VerticalDivider(width: 24),

            // Font Size Picker
            _buildFontSizePicker(
              currentSize: selectedCell?.fontSize ?? 14,
              onSizeSelected: (size) => onFormatChange('fontSize', size),
            ),
            const VerticalDivider(width: 24),
            
            // Row/Column Management
            _buildTextButton(
              icon: Icons.add,
              label: 'Add Row',
              onPressed: onAddRow,
            ),
            const SizedBox(width: 8),
            _buildTextButton(
              icon: Icons.add,
              label: 'Add Column',
              onPressed: onAddColumn,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
        color: isActive ? AppTheme.primaryBlue : AppTheme.textSecondary,
        style: IconButton.styleFrom(
          backgroundColor: isActive ? AppTheme.cellSelected : null,
        ),
      ),
    );
  }

  Widget _buildColorPicker({
    required IconData icon,
    required String tooltip,
    required String currentColor,
    required Function(String) onColorSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: PopupMenuButton<String>(
        tooltip: tooltip,
        icon: Icon(icon, color: AppTheme.textSecondary),
        onSelected: onColorSelected,
        itemBuilder: (context) => [
          _buildColorMenuItem('#FFFFFF', 'White'),
          _buildColorMenuItem('#000000', 'Black'),
          _buildColorMenuItem('#FF0000', 'Red'),
          _buildColorMenuItem('#00FF00', 'Green'),
          _buildColorMenuItem('#0000FF', 'Blue'),
          _buildColorMenuItem('#FFFF00', 'Yellow'),
          _buildColorMenuItem('#FF00FF', 'Magenta'),
          _buildColorMenuItem('#00FFFF', 'Cyan'),
          _buildColorMenuItem('#FFA500', 'Orange'),
          _buildColorMenuItem('#800080', 'Purple'),
          _buildColorMenuItem('#4A90E2', 'Light Blue'),
          _buildColorMenuItem('#7B68EE', 'Medium Violet'),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildColorMenuItem(String colorHex, String label) {
    return PopupMenuItem<String>(
      value: colorHex,
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000),
              border: Border.all(color: AppTheme.gridLine),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
  Widget _buildFontSizePicker({
  required int currentSize,
  required Function(int) onSizeSelected,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: PopupMenuButton<int>(
      tooltip: 'Font Size',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.gridLine),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$currentSize',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
      onSelected: onSizeSelected,
      itemBuilder: (context) => [
        _buildFontSizeMenuItem(8),
        _buildFontSizeMenuItem(10),
        _buildFontSizeMenuItem(12),
        _buildFontSizeMenuItem(14),
        _buildFontSizeMenuItem(16),
        _buildFontSizeMenuItem(18),
        _buildFontSizeMenuItem(20),
        _buildFontSizeMenuItem(24),
        _buildFontSizeMenuItem(28),
        _buildFontSizeMenuItem(32),
        _buildFontSizeMenuItem(36),
        _buildFontSizeMenuItem(48),
        _buildFontSizeMenuItem(72),
      ],
    ),
  );
}

PopupMenuItem<int> _buildFontSizeMenuItem(int size) {
  return PopupMenuItem<int>(
    value: size,
    child: Text(
      '$size pt',
      style: TextStyle(fontSize: size.toDouble().clamp(10, 20)),
    ),
  );
}
  Widget _buildTextButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(color: AppTheme.gridLine),
      ),
    );
  }
}