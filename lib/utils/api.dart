import 'package:bus_watch/objects/bus_info.dart';
import 'package:bus_watch/objects/bus_stop.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
