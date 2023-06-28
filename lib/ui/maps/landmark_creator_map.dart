import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart' as poly;
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_library/isolates/landmark_isolate.dart';
import 'package:kasie_transie_library/utils/device_location_bloc.dart';
import 'package:kasie_transie_library/utils/emojis.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/prefs.dart';

class LandmarkCreatorMap extends StatefulWidget {
  final lib.Route route;

  const LandmarkCreatorMap({
    Key? key,
    required this.route,
  }) : super(key: key);

  @override
  LandmarkCreatorMapState createState() => LandmarkCreatorMapState();
}

class LandmarkCreatorMapState extends State<LandmarkCreatorMap> {
  static const defaultZoom = 16.0;
  final Completer<GoogleMapController> _mapController = Completer();

  CameraPosition? _myCurrentCameraPosition;
  static const mm = '🍐🍐🍐🍐🍐🍐🍐🍐 LandmarkCreatorMap: 💪 ';
  final _key = GlobalKey<ScaffoldState>();
  bool busy = false;
  bool isHybrid = false;
  lib.User? _user;
  geo.Position? _currentPosition;
  final Set<Marker> _markers = HashSet();
  final Set<Circle> _circles = HashSet();
  final Set<Polyline> _polyLines = {};
  BitmapDescriptor? _dotMarker;

  final numberMarkers = <BitmapDescriptor>[];

  // List<BitmapDescriptor> _numberMarkers = [];
  final List<lib.RoutePoint> rpList = [];

  // List<lib.Landmark> _landmarks = [];
  List<lib.RoutePoint> existingRoutePoints = [];
  List<lib.Landmark> landmarksFromLocationSearch = [];

  List<poly.PointLatLng>? polylinePoints;

  int index = 0;
  bool sending = false;
  Timer? timer;
  int totalPoints = 0;
  lib.SettingsModel? settingsModel;
  int radius = 25;
  bool displayLandmark = false;
  late StreamSubscription<lib.RouteLandmark> _sub;
  @override
  void initState() {
    super.initState();
    _listen();
    _setup();
  }

  void _setup() async {
    await _getSettings();
    await _makeDotMarker();
    await _buildLandmarkIcons();
    await _getCurrentLocation();
    _getUser();
  }

  Future _getSettings() async {
    settingsModel = await prefs.getSettings();
    if (settingsModel != null) {
      radius = settingsModel!.vehicleGeoQueryRadius!;
      if (radius == 0) {
        radius = 40;
      }
    }
  }

  Future _buildLandmarkIcons() async {
    for (var i = 0; i < 100; i++) {
      var intList =
          await getBytesFromAsset("assets/numbers/number_${i + 1}.png", 84);
      numberMarkers.add(BitmapDescriptor.fromBytes(intList));
    }
    pp('$mm have built ${numberMarkers.length} markers for landmarks');
  }

  var routeLandmarks = <lib.RouteLandmark>[];
  var landmarkIndex = 0;

  void _listen() async {
    _sub = dataApiDog.routeLandmarkStream.listen((event) {
      pp('\n\n$mm routeLandmarkStream delivered ...  ${E.appleRed} route: ${event.routeName};  ');
      routeLandmarks.add(event);
      if (mounted) {
        _putLandmarksOnMap();
      }
    });

  }
  void _controlReads(bool refresh) async {
    setState(() {
      busy = true;
    });
    try {
      await _getRouteLandmarks();
      _getLandmarksByLocation();

    } catch (e) {
      pp(e);
    }
    setState(() {
      busy = false;
    });
  }

  Future _getRouteLandmarks() async {
    routeLandmarks =
        await listApiDog.getRouteLandmarks(widget.route.routeId!, true);
    pp('\n\n$mm _getRouteLandmarks ...  ${E.appleRed} route: ${widget.route.name}; found: ${routeLandmarks.length} ');
    _putLandmarksOnMap();
    await _getRoutePoints(false);

  }

  void _putLandmarksOnMap() {
    pp('$mm ..._putLandmarksOnMap: routeLandmarks: ${routeLandmarks.length}');

    landmarkIndex = 0;
    if (routeLandmarks.isEmpty) {
      return;
    }
    for (var landmark in routeLandmarks) {
      final latLng = LatLng(landmark.position!.coordinates.last,
          landmark.position!.coordinates.first);
      _markers.add(Marker(
          markerId: MarkerId('${landmark.landmarkId}'),
          icon: numberMarkers.elementAt(landmarkIndex),
          onTap: () {
            pp('$mm .............. landmark marker tapped: $index');
            //_deleteRoutePoint(routePoint);
          },
          infoWindow: InfoWindow(
              snippet: 'This landmark is part of the route.',
              title: '🔵 ${landmark.landmarkName}',
              onTap: () {
                pp('$mm ............. infoWindow tapped, point index: $index');
                //_deleteLandmark(landmark);
              }),
          position: latLng));
      landmarkIndex++;
      pp('$mm ... routeLandmark added to markers: ${_markers.length}');
    }
    pp('$mm ... setting state .... and animating camera ...');
    setState(() {});
    var last = routeLandmarks.last;
    final latLng = LatLng(
        last.position!.coordinates.last, last.position!.coordinates.first);
    totalLandmarks = routeLandmarks.length;
    _animateCamera(latLng);
  }
  int totalLandmarks = 0;
  Future _getLandmarksByLocation() async {
    pp('$mm _getLandmarksByLocation ... use start city and end city landmarks');
    final lat = widget.route.routeStartEnd?.startCityPosition!.coordinates.last;
    final lng =
        widget.route.routeStartEnd?.startCityPosition!.coordinates.first;

    final lat2 = widget.route.routeStartEnd?.endCityPosition!.coordinates.last;
    final lng2 = widget.route.routeStartEnd?.endCityPosition!.coordinates.first;

    final startLandmarks = await listApiDog.findLandmarksByLocation(
        latitude: lat!, longitude: lng!, radiusInKM: 15);
    pp('$mm _getLandmarksByLocation ...  start city: ${startLandmarks.length} landmarks');

    final endLandmarks = await listApiDog.findLandmarksByLocation(
        latitude: lat2!, longitude: lng2!, radiusInKM: 15);
    pp('$mm _getLandmarksByLocation ...  end city: ${startLandmarks.length} landmarks');
    //
    final hashMap = <String, lib.Landmark>{};
    for (var element in startLandmarks) {
      hashMap[element.landmarkId!] = element;
    }
    for (var element in endLandmarks) {
      hashMap[element.landmarkId!] = element;
    }

    landmarksFromLocationSearch.addAll(hashMap.values.toList());
    pp('$mm _getLandmarksByLocation ... found: ${landmarksFromLocationSearch.length} landmarks');
  }

  Future _getRoutePoints(bool refresh) async {

    try {
      _user = await prefs.getUser();
      pp('$mm ...... getting existing RoutePoints .......');
      existingRoutePoints =
          await listApiDog.getRoutePoints(widget.route.routeId!, refresh);

      pp('$mm .......... existingRoutePoints ....  🍎 found: '
          '${existingRoutePoints.length} points');
      _buildExistingRoutePointMarkers();
    } catch (e) {
      pp(e);
    }

  }

  Future<void> _buildExistingRoutePointMarkers() async {
    pp('$mm .......... _buildExistingRoutePointMarkers starting ... ');

    if (existingRoutePoints.isEmpty) {
      pp('$mm route points empty. WTF?');
      return;
    }
    if (_dotMarker == null) {
      await _makeDotMarker();
    }
    totalPoints = existingRoutePoints.length;
    // _clearMap();
    for (var routePoint in existingRoutePoints) {
      var latLng = LatLng(routePoint.position!.coordinates.last,
          routePoint.position!.coordinates.first);
      _markers.add(Marker(
          markerId: MarkerId('${routePoint.routePointId}'),
          icon: _dotMarker!,
          onTap: () {
            pp('$mm .............. ${E.pear}${E.pear}${E.pear} '
                'marker tapped: routePoint: ${routePoint.toJson()}');
            setState(() {
              routePointForLandmark = routePoint;
              _showLandmark = true;
            });
          },
          position: LatLng(latLng.latitude, latLng.longitude)));
    }
    setState(() {});
    //
    var last = existingRoutePoints.last;
    final latLng = LatLng(
        last.position!.coordinates.last, last.position!.coordinates.first);
    totalPoints = existingRoutePoints.length;
    index = existingRoutePoints.length - 1;
    await _animateCamera(latLng);
  }

  Future<void> _animateCamera(LatLng latLng) async {
    var cameraPos = CameraPosition(target: latLng, zoom: 13.0);
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPos));
  }

  bool _showLandmark = false;
  void _clearMap() {
    _polyLines.clear();
    _markers.clear();
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future _getUser() async {
    _user = await prefs.getUser();
  }

  Future _makeDotMarker() async {
    var intList = await getBytesFromAsset("assets/markers/dot2.png", 40);
    _dotMarker = BitmapDescriptor.fromBytes(intList);
    pp('$mm custom marker 💜 assets/markers/dot2.png created');
  }

  Future _getCurrentLocation() async {
    pp('$mm .......... get current location ....');
    _currentPosition = await locationBloc.getLocation();

    pp('$mm .......... get current location ....  🍎 found: ${_currentPosition!.toJson()}');
    _myCurrentCameraPosition = CameraPosition(
      target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      zoom: defaultZoom,
    );
    setState(() {});
  }

  Future<void> _zoomToStartCity() async {
    if (widget.route.routeStartEnd != null) {
      final latLng = LatLng(
          widget.route.routeStartEnd!.startCityPosition!.coordinates.last,
          widget.route.routeStartEnd!.startCityPosition!.coordinates.first);
      await _animateCamera(latLng);
      setState(() {});
    }
  }

  bool checkDistance(LatLng latLng) {
    double? mLat, mLng;
    if (index > 1) {
      mLat = rpList.elementAt(index - 2).position!.coordinates.last;
      mLng = rpList.elementAt(index - 2).position!.coordinates.first;
      var dist = locationBloc.getDistance(
          latitude: latLng.latitude,
          longitude: latLng.longitude,
          toLatitude: mLat,
          toLongitude: mLng);
      if (dist > 20) {
        pp('$mm ... this is probably a rogue routePoint: ${E.redDot} '
            'distance from previous point: $dist metres');
        return false;
      } else {
        pp('$mm distance from previous point: ${E.appleGreen} $dist metres');
      }
    }
    return true;
  }

  TextEditingController nameEditController = TextEditingController();

  final pending = <lib.RoutePoint>[];
  void _addNewLandmark() async {
    if (routePointForLandmark == null) {
      return;
    }
    landmarkIndex++;
    _markers.add(Marker(
        markerId: MarkerId('${routePointForLandmark!.routePointId}'),
        icon: numberMarkers.elementAt(landmarkIndex),
        onTap: () {
          pp('$mm .............. marker tapped: $index');
          //_deleteRoutePoint(routePoint);
        },
        infoWindow: InfoWindow(
            snippet: 'This landmark is part of the route.',
            title: '🔵 $landmarkName',
            onTap: () {
              pp('$mm ............. infoWindow tapped, point index: $index');
              //_deleteLandmark(landmark);
            }),
        position: LatLng(routePointForLandmark!.position!.coordinates.last,
            routePointForLandmark!.position!.coordinates.first)));

    setState(() {});
    var latLng = LatLng(routePointForLandmark!.position!.coordinates.last,
        routePointForLandmark!.position!.coordinates.first);
    var cameraPos = CameraPosition(target: latLng, zoom: defaultZoom);

    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPos));

    //
    pending.add(routePointForLandmark!);
    _processNewLandmark();
  }

  String? landmarkName;

  Future<void> _processNewLandmark() async {
    final parameters = LandmarkParameters(
        latitude: routePointForLandmark!.position!.coordinates.last,
        longitude: routePointForLandmark!.position!.coordinates.first,
        routeId: widget.route.routeId!,
        radius: radius.toDouble(),
        landmarkName: landmarkName!,
        limit: 50,
        index: landmarkIndex,
        routePointId: routePointForLandmark!.routePointId!,
        routePointIndex: routePointForLandmark!.index!,
        associationId: widget.route.associationId!,
        routeName: widget.route.name!,
        authToken: '');

    landmarkIsolate.startIsolate(parameters);
    pp('$mm landmark isolate started! ... 😎😎😎 Good Fucking Luck!!');
  }

  void _deleteLandmark(lib.Landmark point) async {
    setState(() {
      busy = true;
    });
    try {
      var id = point.landmarkId!;
      var res = _markers.remove(Marker(markerId: MarkerId(id)));
      totalPoints--;
      pp('$mm ... removed marker from map: $res, ${E.nice} = true, if not, we fucked!');
      myPrettyJsonPrint(point.toJson());
      try {
        pp('$mm ... start delete ...');
        final result = await dataApiDog.deleteLandmark(id);
        pp('$mm ... removed landmark from database: $result; ${E.nice} 0 is good, Boss!');
        await _getRoutePoints(true);
      } catch (e) {}
    } catch (e) {
      pp('$mm $e');
    }
    setState(() {
      busy = false;
    });
  }

  lib.RoutePoint? routePointForLandmark;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _key,
        body: _myCurrentCameraPosition == null
            ? Center(
                child: SizedBox(
                  height: 100,
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 6,
                          backgroundColor: Colors.pink,
                        ),
                      ),
                      const SizedBox(
                        height: 48,
                      ),
                      Text(
                        'Waiting for GPS location ...',
                        style: myTextStyleMediumBold(context),
                      ),
                    ],
                  ),
                ),
              )
            : Stack(children: [
                GoogleMap(
                  mapType: isHybrid ? MapType.hybrid : MapType.normal,
                  myLocationEnabled: true,
                  markers: _markers,
                  circles: _circles,
                  polylines: _polyLines,
                  initialCameraPosition: _myCurrentCameraPosition!,
                  onMapCreated: (GoogleMapController controller) async {
                    _mapController.complete(controller);
                    _zoomToStartCity();
                    _controlReads(false);
                  },
                ),
                Positioned(
                    right: 12,
                    top: 120,
                    child: Container(
                      color: Colors.black45,
                      child: Padding(
                        padding: const EdgeInsets.all(0.0),
                        child: IconButton(
                            onPressed: () {
                              setState(() {
                                isHybrid = !isHybrid;
                              });
                            },
                            icon: Icon(
                              Icons.album_outlined,
                              color: isHybrid ? Colors.yellow : Colors.white,
                            )),
                      ),
                    )),
                Positioned(
                    left: 12,
                    top: 40,
                    child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Card(
                          color: Colors.black38,
                          shape: getRoundedBorder(radius: 16),
                          elevation: 24,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: SizedBox(
                              height: 108,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'Route Landmarks',
                                          style:
                                              myTextStyleMediumLarge(context),
                                        )
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.arrow_back_ios,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(
                                          width: 2,
                                        ),
                                        Text(
                                          '${widget.route.name}',
                                          style: myTextStyleMediumWithColor(
                                            context,
                                            Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${widget.route.associationName}',
                                      style: myTextStyleTiny(context),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ))),
                Positioned(
                    left: 16,
                    bottom: 40,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(height: 120,
                        child: Column(
                          children: [
                            Text(
                              '$totalLandmarks',
                              style: myNumberStyleLargerWithColor(
                                  Colors.black26, 32, context),
                            ),
                            Text(
                              '$totalPoints',
                              style: myNumberStyleLargerWithColor(
                                  Colors.black26, 24, context),
                            ),
                          ],
                        ),
                      ),
                    )),
                Positioned(
                    right: 12,
                    top: 40,
                    child: Card(
                      elevation: 8,
                      shape: getRoundedBorder(radius: 12),
                      child: Row(
                        children: [
                          IconButton(
                              onPressed: () async {
                                _controlReads(true);
                              },
                              icon: Icon(
                                Icons.toggle_on,
                                color: Theme.of(context).primaryColor,
                              ))
                        ],
                      ),
                    )),
                _showLandmark
                    ? Positioned(
                        bottom: 80,
                        left: 20,
                        right: 20,
                        child: SizedBox(
                          height: 320, width: 400,
                          child: Card(
                            shape: getRoundedBorder(radius: 16),
                            elevation: 12,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                    IconButton(onPressed: (){
                                      setState(() {
                                        _showLandmark = false;
                                      });
                                    }, icon: const Icon(Icons.close, color: Colors.white))
                                  ],),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Text(
                                    'New Landmark',
                                    style: myTextStyleMediumLarge(context),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  TextField(
                                    controller: nameEditController,
                                    decoration: InputDecoration(
                                      label:
                                          const Text('Landmark/Taxi Stop Name'),
                                      labelStyle: myTextStyleSmall(context),
                                      hintText: 'Enter the name of the place',
                                      icon: const Icon(
                                          Icons.water_damage_outlined),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 48,
                                  ),
                                  ElevatedButton(
                                      onPressed: () {
                                        if (nameEditController
                                            .value.text.isEmpty) {
                                          showSnackBar(
                                              message: 'Please enter the name',
                                              context: context,
                                              padding: 16);
                                        } else {
                                          setState(() {
                                            _showLandmark = false;
                                          });
                                          landmarkName =
                                              nameEditController.value.text;
                                          _addNewLandmark();
                                        }
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.only(
                                            left: 28.0,
                                            right: 28,
                                            top: 16,
                                            bottom: 16),
                                        child: Text('Save Landmark'),
                                      )),
                                ],
                              ),
                            ),
                          ),
                        ))
                    : const SizedBox(),
                busy
                    ? const Positioned(
                        left: 300,
                        top: 300,
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 12,
                            backgroundColor: Colors.purple,
                          ),
                        ))
                    : const SizedBox(),
              ]));
  }
}
