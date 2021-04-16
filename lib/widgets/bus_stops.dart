import 'package:bus_watch/objects/bus_stop.dart';
import 'package:bus_watch/utils/hive.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'bus_timetable.dart';

class BusStops extends StatelessWidget {
  final Box<String> addedBox = Hive.box('added');
  final Box<BusStop> mainBox = Hive.box('main');

  BusStops();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: addedBox.length,
      itemBuilder: (context, index) {
        var code = addedBox.getAt(index);
        var stop = mainBox.get(code);

        return Dismissible(
          background: Container(
            color: Colors.red,
          ),
          direction: DismissDirection.endToStart,
          key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
          child: ListTile(
            title: Text(stop.name),
            subtitle: Text('#${stop.code}'),
            leading: Image.asset('assets/bus-stop-icon.png'),
            onTap: () => {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => BusTimeTable(stop)))
            },
          ),
          onDismissed: (_) {
            removeBusStop(index);

            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Bus stop #$code removed"),
              duration: Duration(milliseconds: 500),
            ));
          },
        );
      },
    );
  }
}
