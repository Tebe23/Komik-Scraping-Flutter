import 'package:flutter/material.dart';
import 'dart:math' as math;

class ReadingProgressBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageSelected;

  const ReadingProgressBar({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Add safety check for totalPages
    if (totalPages <= 1) return SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black54,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Page ${currentPage + 1} of $totalPages',
            style: TextStyle(color: Colors.white),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              overlayColor: Colors.white24,
            ),
            child: Slider(
              value: currentPage.toDouble().clamp(0, (totalPages - 1).toDouble()),
              min: 0,
              max: math.max((totalPages - 1).toDouble(), 1),  // Ensure max is always greater than min
              onChanged: (value) => onPageSelected(value.round()),
            ),
          ),
        ],
      ),
    );
  }
}
