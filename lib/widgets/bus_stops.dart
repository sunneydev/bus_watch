import 'package:bus_watch/widgets/maps.dart';
import 'package:bus_watch/objects/bus_stop.dart';
import 'package:bus_watch/utils/hive.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive/hive.dart';

import 'bus_timetable.dart';

class BusStops extends StatefulWidget {
  @override
  _BusStopsState createState() => _BusStopsState();
}

class _BusStopsState extends State<BusStops> {
  final Box<String> addedBox = Hive.box('added');
  final Box<BusStop> mainBox = Hive.box('main');

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
            title: stop.nickname != "" ? Text(stop.nickname) : Text(stop.name),
            subtitle: Text('#${stop.code}'),
            leading: Image.asset('assets/bus-stop-icon.png'),
            onTap: () => {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => BusTimeTable(stop)))
            },
            onLongPress: () {
              showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return Wrap(
                      children: [
                        ListTile(
                          onTap: () {
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text("Enter a new name"),
                                    content: TextField(
                                      autofocus: true,
                                      onSubmitted: (String nickname) {
                                        setState(() {
                                          addBusStopNickname(stop, nickname);
                                        });
                                        Navigator.of(context)..pop()..pop();
                                      },
                                    ),
                                  );
                                });
                          },
                          leading: Icon(Icons.edit),
                          title: Text("Change Name"),
                        ),
                        ListTile(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => BusMap(
                                        appBar: true,
                                        initialCameraPosition: CameraPosition(
                                            zoom: 18.0,
                                            target: LatLng(stop.latitude,
                                                stop.longitude))))).then(
                                (_) => setState(() {}));
                          },
                          leading: Icon(Icons.map),
                          title: Text("Show on map"),
                        )
                      ],
                    );
                  });
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
