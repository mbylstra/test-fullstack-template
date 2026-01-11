import 'package:flutter/material.dart'
    show BuildContext, MaterialApp, StatelessWidget, Widget, runApp;
import 'layout/layout.dart' as layout;
import 'theme.dart' as theme;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: theme.appTheme,
      home: const layout.Layout(title: 'Flutter Demo Home Page'),
    );
  }
}
