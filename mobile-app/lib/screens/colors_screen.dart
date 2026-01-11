import 'package:flutter/material.dart'
    show
        BuildContext,
        Center,
        Colors,
        Column,
        Container,
        CrossAxisAlignment,
        EdgeInsets,
        FontWeight,
        GridView,
        ListView,
        MaterialColor,
        NeverScrollableScrollPhysics,
        Padding,
        SizedBox,
        SliverGridDelegateWithFixedCrossAxisCount,
        StatelessWidget,
        Text,
        TextStyle,
        Widget;

class ColorsScreen extends StatelessWidget {
  const ColorsScreen({super.key});

  static final List<MaterialColor> _colors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  static final List<int> _shades = [
    50,
    100,
    200,
    300,
    400,
    500,
    600,
    700,
    800,
    900,
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _colors.length,
      itemBuilder: (context, index) {
        final color = _colors[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _getColorName(color),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
                childAspectRatio: 1.5,
              ),
              itemCount: _shades.length,
              itemBuilder: (context, shadeIndex) {
                final shade = _shades[shadeIndex];
                return Container(
                  color: color[shade],
                  child: Center(
                    child: Text(
                      '$shade',
                      style: TextStyle(
                        color: shade >= 500 ? Colors.white : Colors.black,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  String _getColorName(MaterialColor color) {
    if (color == Colors.red) return 'Red';
    if (color == Colors.pink) return 'Pink';
    if (color == Colors.purple) return 'Purple';
    if (color == Colors.deepPurple) return 'Deep Purple';
    if (color == Colors.indigo) return 'Indigo';
    if (color == Colors.blue) return 'Blue';
    if (color == Colors.lightBlue) return 'Light Blue';
    if (color == Colors.cyan) return 'Cyan';
    if (color == Colors.teal) return 'Teal';
    if (color == Colors.green) return 'Green';
    if (color == Colors.lightGreen) return 'Light Green';
    if (color == Colors.lime) return 'Lime';
    if (color == Colors.yellow) return 'Yellow';
    if (color == Colors.amber) return 'Amber';
    if (color == Colors.orange) return 'Orange';
    if (color == Colors.deepOrange) return 'Deep Orange';
    if (color == Colors.brown) return 'Brown';
    if (color == Colors.grey) return 'Grey';
    if (color == Colors.blueGrey) return 'Blue Grey';
    return 'Unknown';
  }
}
