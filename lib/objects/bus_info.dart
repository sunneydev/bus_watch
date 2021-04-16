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
