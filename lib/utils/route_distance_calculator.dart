import 'dart:core';
import 'dart:core' as prefix0;

import 'package:geolocator/geolocator.dart' as geo;
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_library/providers/kasie_providers.dart';
import 'package:kasie_transie_library/utils/emojis.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/parsers.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:realm/realm.dart';

import 'distance.dart';

final RouteDistanceCalculator routeDistanceCalculator = RouteDistanceCalculator();
class RouteDistanceCalculator {

  static const mm = '🌸🌸🌸🌸 RouteDistanceCalculator: 🌸🌸🌸';

   Future calculateAssociationRouteDistances() async {
    final user = await prefs.getUser();
    final routes = await listApiDog.getRoutes(AssociationParameter(user!.associationId!, false));
    final distances = <lib.CalculatedDistance>[];
    for (var value in routes) {
      distances.addAll(await calculateRouteDistances(value.routeId!));
    }
  }

   Future<List<lib.CalculatedDistance>> calculateRouteDistances(
      String routeId) async {
    pp('$mm ... starting calculateRouteDistances for $routeId');
    final routeLandmarks = await listApiDog.getRouteLandmarks(routeId, false);
    final routePoints = await listApiDog.getRoutePoints(routeId, false);
    //
    pp('$mm ... calculateRouteDistances for ${routeLandmarks.length} routeLandmarks');
    pp('$mm ... calculateRouteDistances for ${routePoints.length} points');

    if (routePoints.isEmpty) {
      pp('$mm ... 1. stopping calculateRouteDistances for $routeId');

      return [];
    }
    routePoints.sort((a, b) => a.index!.compareTo(b.index!));

    if (routeLandmarks.isEmpty) {
      pp('$mm ... 2. stopping calculateRouteDistances for $routeId');
      return [];
    }
    final distances = <lib.CalculatedDistance>[];
    lib.RouteLandmark? prevRouteLandmark;
    int index = 0;
    double mDistance = 0;
    for (var routeLandmark in routeLandmarks) {
      if (index == 0) {
        prevRouteLandmark = routeLandmark;
      } else {
        final dist = await _calculateDistanceBetween(
            fromLandmark: prevRouteLandmark!, toLandmark: routeLandmark, routePoints: routePoints);
        mDistance += dist;
        final m = lib.CalculatedDistance(ObjectId(),
          distanceInMetres: dist,
          routeId: routeId,
          index: index - 1,
          routeName: routeLandmark.routeName,
          fromLandmark: prevRouteLandmark.landmarkName,
          fromRoutePointIndex: prevRouteLandmark.index,
          distanceFromStart: mDistance,
          fromLandmarkId: prevRouteLandmark.landmarkId,
          toLandmark: routeLandmark.landmarkName,
          toLandmarkId: routeLandmark.landmarkId,
          toRoutePointIndex: routeLandmark.index,
        );
        distances.add(m);
        prevRouteLandmark = routeLandmark;
        index++;
      }
    }
    pp('$mm update the route with total distance: $mDistance metres');
    pp('$mm update the route with distances between landmarks: ${distances.length}');
    pp('$mm route: ${routeLandmarks.first.routeName}');

    for (var value1 in distances) {
      pp('$mm calculated distance: ${value1.distanceInMetres} - ${value1.distanceFromStart}'
          ' ${E.appleRed} ${value1.fromLandmark} - ${value1.toLandmark}');
    }
    return distances;
  }

   Future<double> _calculateDistanceBetween(
      {required lib.RouteLandmark fromLandmark,
      required lib.RouteLandmark toLandmark,
      required List<lib.RoutePoint> routePoints}) async {
     pp('$mm ... _calculateDistanceBetween ${fromLandmark.landmarkName} and ${toLandmark.landmarkName}');

     var range = routePoints.getRange(fromLandmark.index!, toLandmark.index!);
     pp('$mm ... range of points: ${range.length}');

     lib.RoutePoint? prevPoint;
    double mDistance = 0.0;
    for (var pointBetween in range) {
      if (prevPoint == null) {
        prevPoint = pointBetween;
      } else {
        var distance = geo.GeolocatorPlatform.instance.distanceBetween(
            prevPoint.latitude!,
            prevPoint.longitude!,
            pointBetween.latitude!,
            pointBetween.longitude!);
        mDistance += distance;
        prevPoint = pointBetween;
      }
    }
     pp('$mm ... returning calculate Distance for the pair: $mDistance metres');

     return mDistance;
  }

   Future<List<RoutePointDistance>> calculateFromLocation(
      {required double latitude,
      required double longitude,
      required lib.Route route}) async {
    pp('🥬🥬🥬🥬🥬🥬🥬 calculateFromLocation starting: 💛 ${DateTime.now().toIso8601String()}');
    final routePoints = await listApiDog.getRoutePoints(route.routeId!, false);

    pp('🥬🥬🥬🥬🥬🥬🥬  ${route.name} points: ${routePoints.length}');
    List<RoutePointDistance> rpdList = [];
    // Geolocator geoLocator = Geolocator();

    var index = 0;
    routePoints.forEach((point) async {
      var dist = geo.GeolocatorPlatform.instance.distanceBetween(
          latitude, longitude, point.latitude!, point.longitude!);
      point.index = index;
      rpdList.add(
          RoutePointDistance(index: index, routePoint: point, distance: dist));
      index++;
    });
    pp('...... Distances calculated from each route point to this location:  💙 ${rpdList.length}  💙');
    rpdList.sort((a, b) => a.distance.compareTo(b.distance));
    List<RoutePointDistance> marks = [];
    for (var rpd in rpdList) {
      // if (rpd.routePoint.landmarkId != null) {
      //   marks.add(rpd);
      //   pp('✳️  ✳️ RoutePointDistance that is a Landmark: ${rpd.routePoint.routeName}  🔆 distance: ${rpd.distance} metres');
      // }
    }
    if (marks.isEmpty) {}
    var nearestRoutePoint = rpdList.first;
    pp(
        '🚨 nearestRoutePoint: ${nearestRoutePoint.distance} metres 🍎 index: ${nearestRoutePoint.routePoint.index}');

    pp('💛💛💛💛 ${marks.length} dynamic distances calculated');

    pp('🥬🥬🥬🥬🥬🥬🥬 calculateFromLocation DONE!: 💛 ${DateTime.now().toIso8601String()}');
    return marks;
  }

  Future<List<DynamicDistance>> _traversePoints(
      {required List<lib.RoutePoint> points, required int startIndex}) async {
    pp('_traversePoints :  🔆  🔆  🔆  🔆 calculating distances between points from  🔆 index: $startIndex ...');
    // var geoLocator = Geolocator();
    List<DynamicDistance> list = [];
    List<RoutePointDistance> rpList = [];
    var cnt = 0;
    lib.RoutePoint? prevPoint;
    for (var i = startIndex; i < points.length; i++) {
      if (prevPoint == null) {
        prevPoint = points.elementAt(i);
      } else {
        var distance = geo.GeolocatorPlatform.instance.distanceBetween(
            prevPoint.latitude!,
            prevPoint.longitude!,
            points.elementAt(i).latitude!,
            points.elementAt(i).longitude!);
        rpList.add(RoutePointDistance(
            index: i, routePoint: points.elementAt(i), distance: distance));
        prevPoint = points.elementAt(i);
        cnt++;
      }
    }
    pp('🥬🥬🥬🥬🥬🥬🥬 Calculated 🍎 $cnt 🍎 distances between route points');
    var tot = 0.0;
    cnt = 0;
    for (var rp in rpList) {
      tot += rp.distance;
      cnt++;
      // if (rp.routePoint.landmarkId != null) {
      //   list.add(DynamicDistance(
      //     landmarkId: rp.routePoint.landmarkId,
      //     landmarkName: rp.routePoint.landmarkName,
      //     date: DateTime.now().toLocal().toIso8601String(),
      //   ));
      //   cnt = 0;
      // }
    }

    return list;
  }
}

class RoutePointDistance {
  int index;
  lib.RoutePoint routePoint;
  double distance;

  RoutePointDistance(
      {required this.index, required this.routePoint, required this.distance});
}

class CalculatedDistanceList {
  List<lib.CalculatedDistance>? distances;

  CalculatedDistanceList(this.distances);

  CalculatedDistanceList.fromJson(Map data) {
    List<dynamic> list = data['distances'];
    distances = [];
    for (var m in list) {
      var d = buildCalculatedDistance(m);
      distances!.add(d);
    }
  }

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> listOfMaps = [];
    if (distances != null) {
      for (var ass in distances!) {
        var cMap = ass.toJson();
        listOfMaps.add(cMap);
      }
    }
    var map = {
      'distances': listOfMaps,
    };
    return map;
  }
}
