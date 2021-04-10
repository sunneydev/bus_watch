import 'package:bus_watch/bus_stop.dart';
import 'package:bus_watch/utils.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import 'bus_watch.dart';
import 'package:flutter/material.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(BusStopAdapter());
  await cacheBusStops();
  await Hive.openBox('added');

  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Bus Watch', theme: ThemeData.dark(), home: BusWatch());
  }
}
