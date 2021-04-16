import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:bus_watch/objects/bus_stop.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

import 'api.dart';

Future<Uint8List> getBytesFromAsset(String path, int width, int height) async {
  ByteData data = await rootBundle.load(path);
  ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
      targetWidth: width, targetHeight: height);
  ui.FrameInfo fi = await codec.getNextFrame();
  return (await fi.image.toByteData(format: ui.ImageByteFormat.png))
      .buffer
      .asUint8List();
}

Future<void> cacheBusStops() async {
  Hive.openBox<BusStop>('main').then((box) {
    if (box.isEmpty) {
      fetchBusStops().then((busStops) => busStops.forEach((stop) {
            if (stop.code != null) {
              box.put(stop.code, stop);
            }
          }));
    }
  });
}
