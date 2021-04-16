import 'dart:ui';
import 'dart:async';
import 'package:bus_watch/utils/hive.dart';
import 'package:bus_watch/utils/utils.dart';

import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';

import 'objects/bus_stop.dart';

const LIGHT_BLUE_COLOR = Color.fromRGBO(33, 150, 243, 50);
const TBILISI_POSITION = LatLng(41.72708908914995, 44.778447529129004);
const NORTH_EAST_POSITION = LatLng(41.824641216430486, 44.9733045281619);
const SOUTH_WEST_POSITION = LatLng(41.64427627970418, 44.640968104713586);
const double INVISIBLE_PIN_POSITION = -100;
const double VISIBLE_PIN_LOCATION = 80;

class BusMap extends StatefulWidget {
  @override
  State<BusMap> createState() => BusMapState();
}

class BusMapState extends State<BusMap> {
  Completer<GoogleMapController> _controller = Completer();
  BitmapDescriptor mapMarker;
  Set<Marker> _markers = {};
  ClusterManager _manager;
  double pinPillPosition = INVISIBLE_PIN_POSITION;
  BusStop selectedBusStop = BusStop(name: "", code: "");
  Box box;

  static final CameraPosition _tbilisiCameraPosition = CameraPosition(
    target: TBILISI_POSITION,
    zoom: 13,
  );

  List<ClusterItem<BusStop>> _busStops = [];

  @override
  void initState() {
    Hive.openBox<BusStop>('main').then((box) => {
          if (box.isNotEmpty)
            {
              box.toMap().forEach((_, stop) {
                _addBusStopMarker(stop);
              })
            }
        });

    _manager = _initClusterManager();
    getCustomMarker();
    super.initState();
  }

  void getCustomMarker() async {
    final Uint8List markerIcon =
        await getBytesFromAsset('assets/bus-stop-pointer.png', 100, 170);

    mapMarker = BitmapDescriptor.fromBytes(markerIcon);
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
        initialZoom: _tbilisiCameraPosition.zoom,
        stopClusteringZoom: 16.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [
        Positioned.fill(
            child: GoogleMap(
                zoomControlsEnabled: false,
                mapType: MapType.normal,
                initialCameraPosition: _tbilisiCameraPosition,
                markers: _markers,
                cameraTargetBounds: CameraTargetBounds(LatLngBounds(
                    northeast: NORTH_EAST_POSITION,
                    southwest: SOUTH_WEST_POSITION)),
                myLocationButtonEnabled: true,
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
              margin: EdgeInsets.only(top: 10, bottom: 10, left: 30, right: 20),
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
                this.pinPillPosition = VISIBLE_PIN_LOCATION;
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
