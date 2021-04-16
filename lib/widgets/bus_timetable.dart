import 'dart:async';

import 'package:bus_watch/objects/bus_info.dart';
import 'package:bus_watch/objects/bus_stop.dart';
import 'package:bus_watch/utils/api.dart';
import 'package:flutter/material.dart';

class BusTimeTable extends StatefulWidget {
  final BusStop stop;

  BusTimeTable(this.stop);

  @override
  _BusTimeTableState createState() => _BusTimeTableState(stop);
}

class _BusTimeTableState extends State<BusTimeTable> {
  final BusStop stop;

  _BusTimeTableState(this.stop);

  @override
  void initState() {
    super.initState();
    new Timer.periodic(Duration(seconds: 10), (_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: this.stop.nickname != ""
            ? Text('${this.stop.nickname} — #${this.stop.code}')
            : Text('${this.stop.name} — #${this.stop.code}'),
      ),
      body: new FutureBuilder<List<BusInfo>>(
        future: fetchTimeTable(this.stop.code),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Error occured"),
            );
          } else if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (context, count) {
                var busInfo = snapshot.data[count];

                return ListTile(
                  title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          busInfo.destinationStopName,
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.start,
                        ),
                        Text(
                          busInfo.arrivalTime.toString(),
                          textAlign: TextAlign.end,
                        )
                      ]),
                  subtitle: Text('#${busInfo.routeNumber}'),
                  leading: Icon(
                    Icons.directions_bus,
                    size: 50,
                  ),
                );
              });
        },
      ),
    );
  }
}
