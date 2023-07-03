import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:intl/intl.dart';
import 'package:kasie_transie_route_builder/ui/calculated_distances_widget.dart';
import 'package:kasie_transie_route_builder/ui/tiny_bloc.dart';

class RouteInfoWidget extends StatefulWidget {
  const RouteInfoWidget({Key? key, required this.routeId, this.routeName})
      : super(key: key);
  final String? routeId, routeName;

  @override
  State<RouteInfoWidget> createState() => _RouteInfoWidgetState();
}

class _RouteInfoWidgetState extends State<RouteInfoWidget> {
  lib.Route? route;
  final mm = '😎😎😎😎😎😎😎😎 RouteInfoWidget: 🍎🍎🍎';
  var numberOfPoints = 0;
  var numberOfLandmarks = 0;
  late StreamSubscription<String> sub;
  bool busy = true;

  @override
  void initState() {
    super.initState();
    pp('$mm initState ................... ');
    listen();
    _getData(widget.routeId);
  }

  void listen() {
    pp('$mm listen to routeStream .............');
    sub = tinyBloc.routeIdStream.listen((routeId) async {
      pp('$mm tinyBloc.routeIdStream delivered routeId: $routeId ');
      await _getData(routeId);

      if (mounted) {
        setState(() {});
      }
    });
  }

  Future _getData(String? routeId) async {
    pp('$mm _getData ..... numberOfLandmarks, '
        'numberOfPoints; routeId: $routeId ');

    setState(() {
      busy = true;
    });
    if (routeId != null) {
      numberOfLandmarks = await tinyBloc.getNumberOfLandmarks(routeId);
      numberOfPoints = await tinyBloc.getNumberOfPoints(routeId);
      route = await tinyBloc.getRoute(routeId);

      setState(() {});
    }
    setState(() {
      busy = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.decimalPattern();
    if (route == null) {
      return SizedBox(
        height: 400,
        child: Card(
            shape: getRoundedBorder(radius: 16),
            elevation: 8,
            child: Center(
              child: SizedBox(
                height: 100,
                child: Column(
                  children: [
                    const SizedBox(height: 12,),
                    const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(
                      strokeWidth: 6, backgroundColor: Colors.teal,
                    ),),
                    const SizedBox(height: 12,),
                    Text(
                      'Waiting for Godot',
                      style: myTextStyleMediumLargeWithSize(context, 32),
                    ),
                  ],
                ),
              ),
            )),
      );
    }

    if (route!.isValid) {
    } else {
      pp('$mm build. route is INVALID ...... getting route from cache ... ');
      route = tinyBloc.getRouteFromCache(widget.routeId!);
    }

    return Card(
      shape: getRoundedBorder(radius: 16),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(
              height: 16,
            ),
            Text(
              'Route Details',
              style: myTextStyleMediumLarge(context, 20),
            ),
            const SizedBox(
              height: 48,
            ),
            Text(
              '${route!.name}',
              style: myTextStyleMediumLargeWithSize(context, 16),
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              '${route!.associationName}',
              style: myTextStyleMediumPrimaryColor(context),
            ),
            const SizedBox(
              height: 12,
            ),
            Text(getFormattedDateLong(route!.created!)),
            const SizedBox(
              height: 8,
            ),
            Text(
              '${route!.userName}',
              style: myTextStyleMediumBoldGrey(context),
            ),
            const SizedBox(
              height: 20,
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Route Color',
                  style: myTextStyleSmall(context),
                ),
                const SizedBox(
                  width: 8,
                ),
                Container(
                  width: 200,
                  height: 28,
                  color: getColor(route!.color!),
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),
            SizedBox(
                height: 80,
                child: Column(
                  children: [
                    Text(
                      fmt.format(numberOfLandmarks),
                      style: myNumberStyleLargest(context),
                    ),
                    Text(
                      'Route Landmarks',
                      style: myTextStyleMediumBoldGrey(context),
                    ),
                  ],
                )),
            const SizedBox(
              height: 24,
            ),
            SizedBox(
                height: 80,
                child: Column(
                  children: [
                    Text(
                      fmt.format(numberOfPoints),
                      style: myNumberStyleLargest(context),
                    ),
                    Text(
                      'Route Points Mapped',
                      style: myTextStyleMediumBoldGrey(context),
                    ),
                  ],
                )),
            const SizedBox(
              height: 24,
            ),
            Expanded(
              child: Card(
                shape: getRoundedBorder(radius: 16),
                elevation: 12,
                child: CalculatedDistancesWidget(
                    routeId: widget.routeId!, routeName: widget.routeName!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
