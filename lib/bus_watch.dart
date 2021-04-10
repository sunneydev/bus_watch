import 'package:bus_watch/utils.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'maps.dart';

class BusWatch extends StatefulWidget {
  @override
  State<BusWatch> createState() => BusWatchState();
}

class BusWatchState extends State<BusWatch> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Bus Watch"), backgroundColor: Colors.black38),
      body: ListView.builder(
        itemCount: Hive.box("added").length,
        itemBuilder: (context, index) {
          var code = Hive.box("added").getAt(index);
          var stop = Hive.box("main").get(code);

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
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => BusTimeTable(stop.code)))
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => SimpleDialog(
              title: const Text('Add a new Bus Stop'),
              children: <Widget>[
                DialogItem(
                  icon: Icons.settings_input_antenna,
                  color: Colors.white,
                  text: 'Bus Stop Number',
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop('dialog');
                    showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                              content: new Row(
                                children: [
                                  new Expanded(
                                    child: new TextField(
                                      onSubmitted: (String code) {
                                        setState(() {
                                          var stop = Hive.box("main").get(code);
                                          addBusStop(stop);
                                        });
                                      },
                                      keyboardType: TextInputType.number,
                                      maxLength: 4,
                                      autofocus: true,
                                      decoration: new InputDecoration(
                                          icon: Icon(
                                            Icons.directions_bus_sharp,
                                          ),
                                          prefixText: "#",
                                          counterText: "",
                                          labelStyle: TextStyle(fontSize: 20),
                                          hintText: '1024'),
                                    ),
                                  ),
                                ],
                              ),
                            ));
                  },
                ),
                DialogItem(
                  icon: Icons.map,
                  color: Colors.white,
                  text: 'Map',
                  onPressed: () {
                    Navigator.push(context,
                            MaterialPageRoute(builder: (context) => BusMap()))
                        .then((_) => setState(() {}));
                  },
                ),
              ],
            ),
          );
        },
        tooltip: "Add a new Bus Stop",
        child: Icon(
          Icons.add,
          color: Colors.black,
        ),
        backgroundColor: Colors.white,
      ),
    );
  }
}

class DialogItem extends StatelessWidget {
  const DialogItem({Key key, this.icon, this.color, this.text, this.onPressed})
      : super(key: key);

  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 36.0, color: color),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 16.0),
            child: Text(text),
          ),
        ],
      ),
    );
  }
}

class BusTimeTable extends StatefulWidget {
  final String busStopCode;

  BusTimeTable(this.busStopCode);

  @override
  BusTimeTableState createState() => BusTimeTableState(busStopCode);
}

class BusTimeTableState extends State<BusTimeTable> {
  final String busStopCode;
  BusTimeTableState(this.busStopCode);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('#${this.busStopCode}'),
      ),
      body: FutureBuilder<List<BusInfo>>(
        future: fetchTimeTable(busStopCode),
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
                          style: TextStyle(fontSize: 13),
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
                  onTap: () => {},
                );
              });
        },
      ),
    );
  }
}

class BusInfo {
  final String routeNumber;
  final String destinationStopName;
  final int arrivalTime;

  BusInfo({this.routeNumber, this.destinationStopName, this.arrivalTime});

  factory BusInfo.fromJson(json) {
    return new BusInfo(
      routeNumber: json['RouteNumber'],
      destinationStopName: json['DestinationStopName'],
      arrivalTime: json['ArrivalTime'],
    );
  }
}
