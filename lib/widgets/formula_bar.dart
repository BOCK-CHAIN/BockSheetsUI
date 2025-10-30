// lib/widgets/formula_bar.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class FormulaBar extends StatelessWidget {
  final TextEditingController controller;
  final String selectedCell;
  final Function(String) onSubmit;

  const FormulaBar({
    super.key,
    required this.controller,
    required this.selectedCell,
    required this.onSubmit,
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
      child: Row(
        children: [
          // Cell Address Display
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.gridLine),
            ),
            child: Text(
              selectedCell.isEmpty ? '--' : selectedCell,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          
          // Function Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.functions,
              size: 20,
              color: AppTheme.primaryViolet,
            ),
          ),
          const SizedBox(width: 12),
          
          // Formula Input Field
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter value or formula (e.g., =SUM(A1:A5))',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: AppTheme.gridLine),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: AppTheme.gridLine),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              onSubmitted: onSubmit,
            ),
          ),
          const SizedBox(width: 12),
          
          // Submit Button
          IconButton(
            icon: const Icon(Icons.check_circle),
            color: AppTheme.success,
            onPressed: () => onSubmit(controller.text),
            tooltip: 'Apply',
          ),
        ],
      ),
    );
  }
}