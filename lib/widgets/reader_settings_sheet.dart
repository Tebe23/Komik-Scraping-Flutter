import 'package:flutter/material.dart';

class ReaderSettingsSheet extends StatelessWidget {
  final double brightness;
  final bool autoScroll;
  final double scrollSpeed;
  final Function(double) onBrightnessChanged;
  final Function(bool) onAutoScrollChanged;
  final Function(double) onScrollSpeedChanged;

  const ReaderSettingsSheet({
    Key? key,
    required this.brightness,
    required this.autoScroll,
    required this.scrollSpeed,
    required this.onBrightnessChanged,
    required this.onAutoScrollChanged,
    required this.onScrollSpeedChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Reader Settings', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.brightness_6),
            title: Text('Brightness'),
            subtitle: Slider(
              value: brightness,
              onChanged: onBrightnessChanged,
            ),
          ),
          SwitchListTile(
            title: Text('Auto Scroll'),
            value: autoScroll,
            onChanged: onAutoScrollChanged,
          ),
          if (autoScroll)
            ListTile(
              leading: Icon(Icons.speed),
              title: Text('Scroll Speed'),
              subtitle: Slider(
                value: scrollSpeed,
                min: 0.5,
                max: 3.0,
                onChanged: onScrollSpeedChanged,
              ),
            ),
        ],
      ),
    );
  }
}
