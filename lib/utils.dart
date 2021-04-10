import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'bus_stop.dart';
import 'bus_watch.dart';

Future<Uint8List> getBytesFromAsset(String path, int width, int height) async {
  ByteData data = await rootBundle.load(path);
  ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
      targetWidth: width, targetHeight: height);
  ui.FrameInfo fi = await codec.getNextFrame();
  return (await fi.image.toByteData(format: ui.ImageByteFormat.png))
      .buffer
      .asUint8List();
}

Future<List<BusStop>> fetchBusStops() async {
  List<BusStop> busStops;

  http.Response resp = await http.get(Uri.https("gist.githubusercontent.com",
      "/Sunney-X/8f56a57a9044fa5bed17bf951208647a/raw/bf4857c03a63731eae951bc3a350399ea2dc7be3/stops.json"));
  if (resp.statusCode == 200) {
    busStops = (json.decode(resp.body) as List)
        .map((i) => BusStop.fromJson(i))
        .toList();
  }

  return busStops;
}

Future<void> cacheBusStops() async {
  Hive.openBox('main').then((box) {
    if (box.isEmpty) {
      fetchBusStops().then((busStops) => busStops.forEach((stop) {
            if (stop.code != null) {
              box.put(stop.code, stop);
            }
          }));
    }
  });
}

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

Future<List<BusInfo>> fetchTimeTable(String stopCode) async {
  List<BusInfo> busesInfo;

  final response = await http.get(
      Uri.http("transfer.ttc.com.ge:8080", "/otp/routers/ttc/stopArrivalTimes",
          {"stopId": stopCode}),
      headers: {'Accept': 'application/json; charset=UTF-8'});

  if (response.statusCode == 200) {
    Map<String, dynamic> resp = json.decode(response.body);

    busesInfo =
        (resp['ArrivalTime'] as List).map((i) => BusInfo.fromJson(i)).toList();
  }

  return busesInfo;
}
