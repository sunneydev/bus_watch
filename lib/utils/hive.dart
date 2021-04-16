import 'package:bus_watch/objects/bus_stop.dart';
import 'package:hive/hive.dart';

void addBusStop(BusStop busStop) {
  var box = Hive.box("added");
  if (busStop != null && !box.values.contains(busStop.code)) {
    box.add(busStop.code);
  }
}

void removeBusStop(int index) {
  var box = Hive.box("added");
  box.deleteAt(index);
}
