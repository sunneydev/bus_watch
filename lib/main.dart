import 'package:bus_watch/utils/utils.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import 'bus_watch.dart';
import 'package:flutter/material.dart';

import 'objects/bus_stop.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(BusStopAdapter());
  await cacheBusStops();
  await Hive.openBox<String>('added');

  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bus Watch',
      home: BusWatch(),
      theme: ThemeData.dark(),
    );
  }
}
