import 'package:flutter/material.dart'
    show
        BuildContext,
        ElevatedButton,
        Icon,
        Icons,
        OutlinedButton,
        Text,
        TextButton,
        Widget;
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Primary Button', type: ElevatedButton)
Widget primaryButton(BuildContext context) {
  return ElevatedButton(onPressed: () {}, child: const Text('Click me'));
}

@widgetbook.UseCase(name: 'Primary Button with Icon', type: ElevatedButton)
Widget primaryButtonWithIcon(BuildContext context) {
  return ElevatedButton.icon(
    onPressed: () {},
    icon: const Icon(Icons.check),
    label: const Text('Confirm'),
  );
}

@widgetbook.UseCase(name: 'Disabled Button', type: ElevatedButton)
Widget disabledButton(BuildContext context) {
  return const ElevatedButton(onPressed: null, child: Text('Disabled'));
}

@widgetbook.UseCase(name: 'Text Button', type: TextButton)
Widget textButton(BuildContext context) {
  return TextButton(onPressed: () {}, child: const Text('Text Button'));
}

@widgetbook.UseCase(name: 'Outlined Button', type: OutlinedButton)
Widget outlinedButton(BuildContext context) {
  return OutlinedButton(onPressed: () {}, child: const Text('Outlined'));
}
