import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  bool _isSystemModeSelected = false;

  ThemeMode get themeMode => _themeMode;
  bool get isSystemModeSelected => _isSystemModeSelected;

  void setThemeMode(ThemeMode themeMode) {
    if (themeMode == ThemeMode.system) {
      _isSystemModeSelected = true;
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _themeMode = brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
    } else {
      _isSystemModeSelected = false;
      _themeMode = themeMode;
    }
    notifyListeners();
  }
}

class ThemeSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Theme Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ThemeOption(
                  label: 'Light',
                  themePreview: ThemePreview(
                    backgroundColor: Colors.white,
                    textColor: Colors.black,
                  ),
                  onSelected: () => themeProvider.setThemeMode(ThemeMode.light),
                  isSelected: !themeProvider.isSystemModeSelected &&
                      themeProvider.themeMode == ThemeMode.light,
                ),
                ThemeOption(
                  label: 'Night',
                  themePreview: ThemePreview(
                    backgroundColor: Colors.black,
                    textColor: Colors.white,
                  ),
                  onSelected: () => themeProvider.setThemeMode(ThemeMode.dark),
                  isSelected: !themeProvider.isSystemModeSelected &&
                      themeProvider.themeMode == ThemeMode.dark,
                ),
                ThemeOption(
                  label: 'System',
                  themePreview: ThemePreview(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    textColor: Theme.of(context).primaryColor,
                  ),
                  onSelected: () => themeProvider.setThemeMode(ThemeMode.system),
                  isSelected: themeProvider.isSystemModeSelected,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



class ThemeOption extends StatelessWidget {
  final String label;
  final ThemePreview themePreview;
  final VoidCallback onSelected;
  final bool isSelected;

  ThemeOption({
    required this.label,
    required this.themePreview,
    required this.onSelected,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: Column(
        children: [
          themePreview,
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.teal : Colors.grey,
                    width: 2,
                  ),
                  color: isSelected ? Colors.teal : Colors.transparent,
                ),
                child: isSelected
                    ? Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              SizedBox(width: 8),
              Text(label),
            ],
          ),
        ],
      ),
    );
  }
}


class ThemePreview extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;

  ThemePreview({ required this.backgroundColor, required this.textColor,});

  @override Widget build(BuildContext context) {
    return Container(width: 50,
      height: 50,
      decoration: BoxDecoration(color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey, width: 1),),
      child: Center(
        child: Text('A', style: TextStyle(color: textColor, fontSize: 24),),),);
  }
}

class ThemeSelectionCircle extends StatelessWidget {
  final VoidCallback onSelected;
  final bool isSelected;

  ThemeSelectionCircle({required this.onSelected, required this.isSelected});

  @override Widget build(BuildContext context) {
    return GestureDetector(onTap: onSelected,
      child: Container(width: 24,
        height: 24,
        decoration: BoxDecoration(shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey, width: 2,),),
        child: isSelected ? Center(
          child: Icon(Icons.check, color: Colors.teal, size: 16,),) : null,),);
  }
}