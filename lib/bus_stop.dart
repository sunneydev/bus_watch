import 'package:hive/hive.dart';

@HiveType()
class BusStop extends HiveObject {
  @HiveField(0)
  String code;
  @HiveField(1)
  String name;
  @HiveField(2)
  double latitude;
  @HiveField(3)
  double longitude;

  BusStop({
    this.code,
    this.name,
    this.latitude,
    this.longitude,
  });

  factory BusStop.fromJson(json) {
    return new BusStop(
        code: json['code'],
        name: json['name'],
        latitude: json['lat'],
        longitude: json['lon']);
  }
}

class BusStopAdapter extends TypeAdapter<BusStop> {
  @override
  final typeId = 0;

  @override
  BusStop read(BinaryReader reader) {
    return BusStop()
      ..code = reader.read()
      ..name = reader.read()
      ..latitude = reader.read()
      ..longitude = reader.read();
  }

  @override
  void write(BinaryWriter writer, BusStop obj) {
    writer
      ..write(obj.code)
      ..write(obj.name)
      ..write(obj.latitude)
      ..write(obj.longitude);
  }
}
