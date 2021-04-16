import 'package:bus_watch/maps.dart';
import 'package:bus_watch/widgets/bus_stops.dart';
import 'package:flutter/material.dart';

class BusWatch extends StatefulWidget {
  @override
  State<BusWatch> createState() => BusWatchState();
}

class BusWatchState extends State<BusWatch> {
  int _selectedIndex = 0;

  final List<Widget> _widgets = <Widget>[
    BusStops(),
    BusMap(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bus Watch"),
      ),
      body: _widgets[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: "Map")
        ],
        onTap: (value) {
          setState(() {
            _selectedIndex = value;
          });
        },
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
      ),
    );
  }
}
