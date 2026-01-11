import 'package:flutter/material.dart'
    show
        AppBar,
        BottomNavigationBar,
        BottomNavigationBarItem,
        BottomNavigationBarType,
        BuildContext,
        Icon,
        Icons,
        MaterialPageRoute,
        Navigator,
        PopupMenuButton,
        PopupMenuEntry,
        PopupMenuItem,
        Scaffold,
        State,
        StatefulWidget,
        Text,
        Theme,
        Widget;
import '../screens/colors_screen.dart' show ColorsScreen;
import '../screens/home_screen.dart' show HomeScreen;
import '../screens/icons_screen.dart' show IconsScreen;
import '../screens/profile_screen.dart' show ProfileScreen;
import '../screens/settings_screen.dart' show SettingsScreen;

class Layout extends StatefulWidget {
  const Layout({super.key, required this.title});

  final String title;

  @override
  State<Layout> createState() => _LayoutState();
}

class _LayoutState extends State<Layout> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const HomeScreen(),
    const IconsScreen(),
    const ColorsScreen(),
  ];

  static const List<String> _titles = <String>[
    'Home',
    'Icons',
    'Colors',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_titles[_selectedIndex]),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen()),
                );
              } else if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'settings',
                child: Text('Settings'),
              ),
              const PopupMenuItem<String>(
                value: 'profile',
                child: Text('Profile'),
              ),
            ],
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.apps), label: 'Icons'),
          BottomNavigationBarItem(icon: Icon(Icons.palette), label: 'Colors'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
