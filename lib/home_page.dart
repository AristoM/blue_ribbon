import 'package:flutter/material.dart';

import 'ask_a_question.dart';
import 'history.dart';
import 'my_installation.dart';

import 'menu_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = <Widget>[
    const MyInstallation(),
    const History(),
    const AskAQuestion(),
    const MenuPage(),
  ];

  static const List<String> _titles = <String>[
    "Home",
    "History",
    "Ask a Question",
    "Menu",
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedIndex != 0) {
          _onItemTapped(0);
        }
      },
      child: Scaffold(
        appBar: _selectedIndex == 0
            ? null
            : AppBar(
                forceMaterialTransparency: true,
                title: Text(
                  _titles[_selectedIndex],
                ),
              ),
        body: _widgetOptions.elementAt(_selectedIndex),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: Colors.white,
          indicatorColor: Colors.transparent,
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.home),
              selectedIcon: Icon(Icons.home_filled, color: Colors.black),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history, color: Colors.black),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.question_answer_outlined),
              selectedIcon: Icon(Icons.question_answer, color: Colors.black),
              label: 'Ask',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_outlined),
              selectedIcon: Icon(Icons.menu, color: Colors.black),
              label: 'Menu',
            ),
          ],
        ),
      ),
    );
  }
}
