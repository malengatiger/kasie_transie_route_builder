import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:badges/badges.dart' as bd;
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_route_builder/ui/tiny_bloc.dart';
import 'package:kasie_transie_route_builder/utils/route_distance_calculator.dart';

class CalculatedDistancesWidget extends StatefulWidget {
  const CalculatedDistancesWidget(
      {Key? key, required this.routeId, required this.routeName})
      : super(key: key);

  final String routeId, routeName;
  @override
  CalculatedDistancesWidgetState createState() =>
      CalculatedDistancesWidgetState();
}

class CalculatedDistancesWidgetState extends State<CalculatedDistancesWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late StreamSubscription<String> sub;
  final mm = '😎😎😎😎😎😎😎😎 RouteInfoWidget: 🍎🍎🍎';

  var calculatedDistances = <lib.CalculatedDistance>[];
  bool busy = false;
  lib.Route? route;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    listen();
    _getData();
  }

  void listen() {
    pp('$mm listen to routeStream .............');
    sub = tinyBloc.routeIdStream.listen((routeId) async {
      pp('$mm tinyBloc.routeIdStream delivered routeId: $routeId ');
      _getData();
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double total = 0.0;
  void _getData() async {
    if (mounted) {
      setState(() {
        busy = true;
      });
    }
    try {
      route = await tinyBloc.getRoute(widget.routeId);
      calculatedDistances =
          await listApiDog.getCalculatedDistances(widget.routeId, false);
      _aggregateDistances();
    } catch (e) {
      pp(e);
    }
    if (mounted) {
      setState(() {
        busy = false;
      });
    }
  }

  void _aggregateDistances() {
    for (var value in calculatedDistances) {
      total += value.distanceInMetres!;
    }
    total = total / 1000;
    total = total.roundToDouble();
  }

  void calculate() async {
    setState(() {
      busy = true;
    });
    route = await tinyBloc.getRoute(widget.routeId);
    calculatedDistances = await routeDistanceCalculator.calculateRouteDistances(
        widget.routeId, route!.associationId!);
    _aggregateDistances();
    setState(() {
      busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.decimalPattern();
    return busy
        ? const Center(
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                backgroundColor: Colors.amber,
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                const SizedBox(
                  height: 8,
                ),
                GestureDetector(
                  onTap: () {
                    calculate();
                  },
                  child: bd.Badge(
                    badgeContent: Text('${calculatedDistances.length + 1}'),
                    position: bd.BadgePosition.topEnd(top: -28, end: -8),
                    badgeStyle: const bd.BadgeStyle(
                        padding: EdgeInsets.all(8.0),
                        badgeColor: Colors.indigo),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Length of route'),
                        const SizedBox(
                          width: 8,
                        ),
                        Text(
                          '$total',
                          style: myTextStyleMediumLargeWithColor(
                              context, Theme.of(context).primaryColor, 20),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        const Text('km'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Expanded(
                  child: ListView.builder(
                      itemCount: calculatedDistances.length,
                      itemBuilder: (ctx, index) {
                        final d = calculatedDistances.elementAt(index);
                        final m =
                            fmt.format(d.distanceInMetres!.round() / 1000);
                        final x =
                            fmt.format(d.distanceFromStart!.round() / 1000);

                        return Card(
                          shape: getRoundedBorder(radius: 12),
                          elevation: 8,
                          child: ListTile(
                            title: Row(
                              children: [
                                Text(
                                  '$m km',
                                  style: myTextStyleSmallBold(context),
                                ),
                                const SizedBox(
                                  width: 12,
                                ),
                                Flexible(
                                    child: Text(
                                  '${d.fromLandmark} - ${d.toLandmark}',
                                  style: myTextStyleSmallPrimaryColor(context),
                                )),
                              ],
                            ),
                            subtitle: Text(
                              '$x km from start of route',
                              style: myTextStyleTiny(context),
                            ),
                          ),
                        );
                      }),
                ),
              ],
            ));
  }
}
