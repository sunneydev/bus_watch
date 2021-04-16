import 'dart:ui';
import 'dart:async';
import 'package:bus_watch/utils/hive.dart';
import 'package:bus_watch/utils/utils.dart';

import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';

import '../objects/bus_stop.dart';

const LIGHT_BLUE_COLOR = Color.fromRGBO(124, 77, 255, 100);
const TBILISI_POSITION = LatLng(41.72708908914995, 44.778447529129004);
const NORTH_EAST_POSITION = LatLng(41.824641216430486, 44.9733045281619);
const SOUTH_WEST_POSITION = LatLng(41.64427627970418, 44.640968104713586);
const double INVISIBLE_PIN_POSITION = -100;
const STOP_CLUSTER_ZOOM = 20.0;
const TBILISI_CAMERA_POSITION = CameraPosition(
  target: TBILISI_POSITION,
  zoom: 13,
);

class BusMap extends StatefulWidget {
  final CameraPosition initialCameraPosition;
  final bool appBar;

  BusMap(
      {this.initialCameraPosition = TBILISI_CAMERA_POSITION,
      this.appBar = false});

  @override
  State<BusMap> createState() =>
      BusMapState(this.initialCameraPosition, this.appBar);
}

class BusMapState extends State<BusMap> {
  final Completer<GoogleMapController> _controller = Completer();
  final CameraPosition initialCameraPosition;
  final bool appBar;
  Set<Marker> _markers = Set();
  BitmapDescriptor mapMarker;
  ClusterManager _manager;
  double pinPillPosition = INVISIBLE_PIN_POSITION;
  BusStop selectedBusStop = BusStop();
  Box box;
  List<ClusterItem<BusStop>> _busStops = [];
  Location _location = Location();

  BusMapState(this.initialCameraPosition, this.appBar);

  @override
  void initState() {
    _checkLocationPermissions();
    _addMarkers();
    _manager = _initClusterManager();
    _getCustomMarker();
    super.initState();
  }

  void _checkLocationPermissions() async {
    await Permission.location.request();
    setState(() {});
  }

  void _getCustomMarker() async {
    final Uint8List markerIcon =
        await getBytesFromAsset('assets/bus-stop-pointer.png', 150, 150);

    mapMarker = BitmapDescriptor.fromBytes(markerIcon);
  }

  void _addMarkers() {
    Hive.openBox<BusStop>('main').then((box) => {
          if (box.isNotEmpty)
            {
              box.toMap().forEach((_, stop) {
                _addBusStopMarker(stop);
              })
            }
        });
  }

  void _addBusStopMarker(BusStop busStop) {
    _busStops.add(ClusterItem(LatLng(busStop.latitude, busStop.longitude),
        item: busStop));
  }

  void _updateMarkers(Set<Marker> markers) {
    setState(() {
      this._markers = markers;
    });
  }

  ClusterManager _initClusterManager() {
    return ClusterManager<BusStop>(_busStops, _updateMarkers,
        markerBuilder: _markerBuilder,
        initialZoom: TBILISI_CAMERA_POSITION.zoom,
        stopClusteringZoom: STOP_CLUSTER_ZOOM);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: this.appBar ? AppBar() : null,
        body: Stack(
          children: [
            Positioned.fill(
                child: GoogleMap(
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                    mapType: MapType.normal,
                    initialCameraPosition: this.initialCameraPosition,
                    markers: _markers,
                    cameraTargetBounds: CameraTargetBounds(LatLngBounds(
                        northeast: NORTH_EAST_POSITION,
                        southwest: SOUTH_WEST_POSITION)),
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                      _manager.setMapController(controller);
                    },
                    onTap: (LatLng loc) {
                      setState(() {
                        this.pinPillPosition = INVISIBLE_PIN_POSITION;
                      });
                    },
                    onCameraMove: _manager.onCameraMove,
                    onCameraIdle: _manager.updateMap)),
            AnimatedPositioned(
                curve: Curves.easeInOut,
                top: this.pinPillPosition,
                left: 0,
                right: 0,
                duration: const Duration(milliseconds: 500),
                child: Container(
                  padding:
                      EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 15),
                  margin:
                      EdgeInsets.only(top: 10, bottom: 10, left: 30, right: 20),
                  decoration: BoxDecoration(
                      color: LIGHT_BLUE_COLOR,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: Offset.zero)
                      ]),
                  child: Row(
                    children: [
                      Container(
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.directions_bus_sharp,
                            size: 40,
                          )),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(this.selectedBusStop.name,
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('#${this.selectedBusStop.code}')
                          ],
                        ),
                      ),
                      IconButton(
                          hoverColor: Colors.red,
                          highlightColor: Colors.red,
                          splashColor: Colors.white,
                          onPressed: () {
                            addBusStop(this.selectedBusStop);
                          },
                          icon: Icon(
                            Icons.add,
                            size: 35,
                            color: Colors.white,
                          )),
                    ],
                  ),
                ))
          ],
        ));
  }

  Future<Marker> Function(Cluster<BusStop>) get _markerBuilder =>
      (cluster) async {
        return Marker(
          markerId: MarkerId(cluster.getId()),
          position: cluster.location,
          onTap: () {
            if (cluster.items.length == 1) {
              setState(() {
                var busStop = cluster.items.first;
                this.selectedBusStop.name = busStop.name;
                this.selectedBusStop.code = busStop.code;
                this.pinPillPosition = MediaQuery.of(context).size.height / 20;
              });
            }
          },
          icon: cluster.isMultiple
              ? await _getMarkerBitmap(cluster.isMultiple ? 125 : 75,
                  text: cluster.isMultiple ? cluster.count.toString() : null)
              : mapMarker,
        );
      };

  Future<BitmapDescriptor> _getMarkerBitmap(int size, {String text}) async {
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint1 = Paint()..color = LIGHT_BLUE_COLOR;
    final Paint paint2 = Paint()..color = Colors.white;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.0, paint1);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.2, paint2);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.8, paint1);

    if (text != null) {
      TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
      painter.text = TextSpan(
        text: text,
        style: TextStyle(
            fontSize: size / 3,
            color: Colors.white,
            fontWeight: FontWeight.normal),
      );
      painter.layout();
      painter.paint(
        canvas,
        Offset(size / 2 - painter.width / 2, size / 2 - painter.height / 2),
      );
    }

    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data.buffer.asUint8List());
  }
}
