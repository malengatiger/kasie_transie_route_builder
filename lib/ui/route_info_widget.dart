import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:intl/intl.dart';
import 'package:kasie_transie_route_builder/ui/tiny_bloc.dart';

class RouteInfoWidget extends StatefulWidget {
  const RouteInfoWidget({Key? key, required this.routeId}) : super(key: key);
  final String? routeId;

  @override
  State<RouteInfoWidget> createState() => _RouteInfoWidgetState();
}

class _RouteInfoWidgetState extends State<RouteInfoWidget> {
  lib.Route? route;
  final mm = '😎😎😎😎😎😎😎😎 RouteInfoWidget: 🍎🍎🍎';
  var numberOfPoints = 0;
  var numberOfLandmarks = 0;
  late StreamSubscription<lib.Route> sub;

  @override
  void initState() {
    super.initState();
    pp('$mm initState ................... ');
    listen();
  }

  void listen() {
    pp('$mm listen to routeStream .............');

    sub = tinyBloc.routeStream.listen((event) async {
      pp('$mm routeStream delivered route: ${event.name} ');
      if (mounted) {
        route = event;
        setState(() {});
        _getData(route!.routeId!);
      }
    });
  }

  Future _getData(String routeId) async {
    pp('$mm _getData ..... numberOfLandmarks, numberOfPoints ');

    numberOfLandmarks = await tinyBloc.getNumberOfLandmarks(routeId);
    numberOfPoints = await tinyBloc.getNumberOfPoints(routeId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    pp('$mm build method ..... ');

    final fmt = NumberFormat.decimalPattern();
    if (route == null) {
      return SizedBox(
        height: 400,
        child: Card(
            shape: getRoundedBorder(radius: 16),
            elevation: 8,
            child: Center(
              child: SizedBox(
                height: 60,
                child: Text(
                  'Waiting for Godot',
                  style: myTextStyleMediumLargeWithSize(context, 32),
                ),
              ),
            )),
      );
    }

    pp('$mm build. route is valid: ${route!.name} .....  ');

    return Card(
      shape: getRoundedBorder(radius: 16),
      elevation: 8,
      child: Column(
        children: [
          const SizedBox(
            height: 20,
          ),
          Text(
            'Route Details',
            style: myTextStyleMediumLarge(context),
          ),
          const SizedBox(
            height: 80,
          ),
          Text(
            '${route!.name}',
            style: myTextStyleMediumLargeWithSize(context, 20),
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            '${route!.associationName}',
            style: myTextStyleMediumPrimaryColor(context),
          ),
          const SizedBox(
            height: 48,
          ),
          Text(getFormattedDateLong(route!.created!)),
          const SizedBox(
            height: 24,
          ),
          Text(
            '${route!.userName}',
            style: myTextStyleMediumBoldGrey(context),
          ),
          const SizedBox(
            height: 48,
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
        ],
      ),
    );
  }
}
