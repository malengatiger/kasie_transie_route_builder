import 'dart:async';
import 'package:kasie_transie_library/data/schemas.dart' as lib;

import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/providers/kasie_providers.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/prefs.dart';

final TinyBloc tinyBloc = TinyBloc();

class TinyBloc {
  final mm = '🧩🧩🧩🧩🧩🧩 RouteInfoWidget: 😎';

  final StreamController<lib.Route> _streamController = StreamController.broadcast();
  Stream<lib.Route> get routeStream  => _streamController.stream;

  final StreamController<String> _streamIdController = StreamController.broadcast();
  Stream<String> get routeIdStream  => _streamIdController.stream;

  void setRouteId(String routeId) {
    pp('$mm ... putting routeId on _streamIdController...');

    _streamIdController.sink.add(routeId);
  }

  lib.Route? getRouteFromCache(String routeId)  {
    pp('$mm ... getting cached route ...');
    var r = listApiDog.realm
        .query<lib.Route>('routeId == \$0', [routeId]);
    lib.Route? route;
    if (r.isNotEmpty) {
      route = r.first;
      _streamController.sink.add(route);
    }
    return route;
  }
  Future<lib.Route?> getRoute(String routeId) async {
    pp('$mm ... getting cached route ...');
    var r = listApiDog.realm
        .query<lib.Route>('routeId == \$0', [routeId]);
    lib.Route? route;
    if (r.isNotEmpty) {
      route = r.first;
      _streamController.sink.add(route);
    } else {
      final user = await prefs.getUser();
      if (user != null) {
      final list = await listApiDog.getRoutes(AssociationParameter(user.associationId!, true));
      if (list.isNotEmpty) {
        lib.Route? u;
        for (var value in list) {
          if (value.routeId == routeId) {
            u = value;
            _streamController.sink.add(u);
          }
        }
      }
      }
    }
    return route;
  }
  Future<int> getNumberOfLandmarks(String routeId) async {
    pp('$mm ... getNumberOfLandmarks cached  ...');
    final res =
    await listApiDog.getRouteLandmarks(routeId, true);
    final m = res.length;
    return m;
  }
  Future<int> getNumberOfPoints(String routeId) async {
    pp('$mm ... getNumberOfPoints cached ...');
    final res = await listApiDog.getRoutePoints(routeId, false);
    final m = res.length;
    return m;
  }
}
