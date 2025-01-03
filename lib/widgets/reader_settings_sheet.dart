import 'package:flutter/material.dart';

class ReaderSettingsSheet extends StatefulWidget {
  final double brightness;
  final bool autoScroll;
  final double scrollSpeed;
  final double minScrollSpeed;
  final double maxScrollSpeed;
  final double maxBrightnessMultiplier;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<bool> onAutoScrollChanged;
  final ValueChanged<double> onScrollSpeedChanged;

  const ReaderSettingsSheet({
    Key? key,
    required this.brightness,
    required this.autoScroll,
    required this.scrollSpeed,
    this.minScrollSpeed = 0.5,
    this.maxScrollSpeed = 10.0,
    this.maxBrightnessMultiplier = 9.0, // Increased from 3.0 to 9.0 (3x)
    required this.onBrightnessChanged,
    required this.onAutoScrollChanged,
    required this.onScrollSpeedChanged,
  }) : super(key: key);

  @override
  State<ReaderSettingsSheet> createState() => _ReaderSettingsSheetState();
}

class _ReaderSettingsSheetState extends State<ReaderSettingsSheet> {
  late double _currentBrightness;
  late double _currentSpeed;
  
  static const List<double> brightnessPresets = [0.25, 0.5, 1.0];
  static const List<String> presetLabels = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    _currentBrightness = widget.brightness;
    _currentSpeed = widget.scrollSpeed;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Brightness Controls
            ListTile(
              leading: Icon(Icons.brightness_6),
              title: Text('Screen Brightness'),
              trailing: Text('${(_currentBrightness * 100).round()}%'),
            ),
            // Quick Presets
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                brightnessPresets.length,
                (index) => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentBrightness == brightnessPresets[index] 
                      ? Theme.of(context).primaryColor 
                      : null,
                  ),
                  child: Text(presetLabels[index]),
                  onPressed: () {
                    setState(() => _currentBrightness = brightnessPresets[index]);
                    widget.onBrightnessChanged(brightnessPresets[index]);
                  },
                ),
              ),
            ),
            SizedBox(height: 8),
            // Brightness Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                overlayShape: SliderComponentShape.noOverlay,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 4,
              ),
              child: Slider(
                value: _currentBrightness,
                min: 0.0,
                max: 1.0,
                divisions: 100,
                onChanged: (value) {
                  setState(() => _currentBrightness = value);
                  widget.onBrightnessChanged(value);
                },
              ),
            ),
            Divider(),
            // Auto-scroll Controls
            SwitchListTile(
              title: Text('Auto-scroll'),
              value: widget.autoScroll,
              onChanged: widget.onAutoScrollChanged,
            ),
            if (widget.autoScroll) Row(
              children: [
                Icon(Icons.speed),
                SizedBox(width: 16),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: _currentSpeed,
                      min: widget.minScrollSpeed,
                      max: widget.maxScrollSpeed,
                      divisions: 19,
                      label: '${_currentSpeed.toStringAsFixed(1)}x',
                      onChanged: (value) {
                        setState(() => _currentSpeed = value);
                        widget.onScrollSpeedChanged(value);
                      },
                    ),
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
