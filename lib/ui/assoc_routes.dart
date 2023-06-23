import 'dart:async';

import 'package:badges/badges.dart' as bd;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_library/providers/kasie_providers.dart';
import 'package:kasie_transie_library/utils/emojis.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_route_builder/ui/maps/city_creator_map.dart';
import 'package:kasie_transie_route_builder/ui/maps/landmark_creator_map.dart';
import 'package:kasie_transie_route_builder/ui/route_detail_form.dart';
import 'package:kasie_transie_route_builder/ui/route_info_widget.dart';
import 'package:kasie_transie_route_builder/ui/tiny_bloc.dart';
import 'package:responsive_builder/responsive_builder.dart';

import 'maps/route_creator_map.dart';
import 'maps/route_map_viewer.dart';

class AssociationRoutes extends ConsumerStatefulWidget {
  final AssociationParameter parameter;
  final String associationName;

  const AssociationRoutes(
    this.parameter,
    this.associationName, {
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<AssociationRoutes> createState() => AssociationRoutesState();
}

class AssociationRoutesState extends ConsumerState<AssociationRoutes> {
  final mm = '🔆🔆🔆🔆🔆 AssociationRoutes 🔵🔵 ';
  bool busy = false;
  var routes = <lib.Route>[];
  late StreamSubscription<List<lib.Route>> _sub;
  lib.User? user;
  final StreamController<String> _streamController =
      StreamController.broadcast();
  Stream<String> get routeIdStream => _streamController.stream;

  @override
  void initState() {
    super.initState();
    _listen();
    _getUser();
  }

  void _listen() {
    _sub = listApiDog.routeStream.listen((routesFromStream) {
      pp('$mm listApiDog.routeStream delivered: ${routesFromStream.length}');
      routes = routesFromStream;
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _getUser() async {
    setState(() {
      busy = true;
    });
    try {
      user = await prefs.getUser();
      _refresh(false);
    } catch (e) {
      pp(e);
    }
    setState(() {
      busy = false;
    });
  }

  lib.Route? selectedRoute;

  void navigateToLandmarks(lib.Route route) async {
    pp('$mm navigateToLandmarksEditor .....  route: ${route.name}');
    tinyBloc.setRoute(route);

    setState(() {
      selectedRoute = route;
    });
    pp('$mm Future.delayed(const Duration(seconds: 2) .....  ');

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      navigateWithScale(
          LandmarkCreatorMap(
            route: route,
          ),
          context);
    }
  }

  void navigateToMapViewer(lib.Route route) async {
    pp('$mm navigateToMapViewer .....  route: ${route.name}');
    tinyBloc.setRoute(route);

    setState(() {
      selectedRoute = route;
    });
    pp('$mm Future.delayed(const Duration(seconds: 2) .....  ');

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      navigateWithScale(
          RouteMapViewer(
            route: route,
          ),
          context);
    }
  }

  void navigateToCreatorMap(lib.Route route) async {
    pp('$mm navigateToCreatorMap .....  route: ${route.name}');
    tinyBloc.setRoute(route);
    setState(() {
      selectedRoute = route;
    });
    pp('$mm Future.delayed(const Duration(seconds: 2) .....  ');

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      navigateWithScale(
          RouteCreatorMap(
            route: route,
          ),
          context);
    }
  }

  void _refresh(bool refresh) async {
    setState(() {
      busy = true;
    });
    await listApiDog
        .getRoutes(AssociationParameter(user!.associationId!, refresh));
    setState(() {
      busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (user != null) {
      final k = ref.watch(
          routesProvider(AssociationParameter(user!.associationId!, false)));
      if (k.hasValue) {
        routes = k.value!;
        pp('$mm routesProvider.ref delivered: ${routes.length}');
      } else {
        pp('$mm routesProvider has no value yet; ${E.redDot} delivered nothing');
      }
    }
    final width = MediaQuery.of(context).size.width;
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: Text(
                'Taxi Routes',
                style: myTextStyleLarge(context),
              ),
              bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(64),
                  child: Column(
                    children: [
                      Text(
                        widget.associationName,
                        style: myTextStyleMediumBold(context),
                      ),
                      const SizedBox(
                        height: 16,
                      )
                    ],
                  )),
              actions: [
                IconButton(
                    onPressed: () async {
                      pp('$mm refresh routes from backend .......');
                      selectedRoute = null;
                      _refresh(true);
                    },
                    icon: const Icon(Icons.refresh)),
                IconButton(
                    onPressed: () async {
                      pp('$mm navigate to city creator map .......');
                      navigateWithFade(const CityCreatorMap(), context);
                    },
                    icon: const Icon(Icons.account_balance)),
                IconButton(
                    onPressed: () {
                      navigateWithScale(
                          RouteDetailForm(dataApiDog: dataApiDog, prefs: prefs),
                          context);
                    },
                    icon: const Icon(Icons.add)),
              ],
            ),
            body: Stack(
              children: [
                StreamBuilder<List<lib.Route>>(
                    stream: listApiDog.routeStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        routes = snapshot.data!;
                      }
                      return Stack(children: [
                        routes.isEmpty
                            ? const WaitingForGodot()
                            : ScreenTypeLayout.builder(
                                mobile: (ctx) {
                                  return RouteList(
                                      navigateToMapViewer: navigateToMapViewer,
                                      navigateToLandmarks: navigateToLandmarks,
                                      navigateToCreatorMap:
                                          navigateToCreatorMap,
                                      routes: routes);
                                },
                                tablet: (ctx) {
                                  return OrientationLayoutBuilder(
                                      landscape: (ctx) {
                                    return Row(
                                      children: [
                                        const SizedBox(
                                          width: 16,
                                        ),
                                        SizedBox(
                                          width: (width / 2) - 60,
                                          child: RouteList(
                                              navigateToMapViewer:
                                                  navigateToMapViewer,
                                              navigateToLandmarks:
                                                  navigateToLandmarks,
                                              navigateToCreatorMap:
                                                  navigateToCreatorMap,
                                              routes: routes),
                                        ),
                                        const SizedBox(
                                          width: 32,
                                        ),
                                        SizedBox(
                                          width: (width / 2),
                                          child: RouteInfoWidget(
                                            routeId: selectedRoute == null
                                                ? null
                                                : selectedRoute!.routeId,
                                          ),
                                        ),
                                      ],
                                    );
                                  }, portrait: (ctx) {
                                    return Row(
                                      children: [
                                        SizedBox(
                                          width: (width / 2) - 24,
                                          child: RouteList(
                                              navigateToMapViewer:
                                                  navigateToMapViewer,
                                              navigateToLandmarks:
                                                  navigateToLandmarks,
                                              navigateToCreatorMap:
                                                  navigateToCreatorMap,
                                              currentRoute: selectedRoute,
                                              routes: routes),
                                        ),
                                        const SizedBox(
                                          width: 8,
                                        ),
                                        SizedBox(
                                          width: (width / 2),
                                          child: RouteInfoWidget(
                                            routeId: selectedRoute == null
                                                ? null
                                                : selectedRoute!.routeId,
                                          ),
                                        ),
                                      ],
                                    );
                                  });
                                },
                              )
                      ]);
                    }),
                busy
                    ? const Positioned(
                        child: Center(
                        child: SizedBox(
                          height: 32,
                          width: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 8,
                            backgroundColor: Colors.amber,
                          ),
                        ),
                      ))
                    : const SizedBox(),
              ],
            )));
  }

  void _navigateToDetail(lib.Route rt) {}
}

class WaitingForGodot extends StatelessWidget {
  const WaitingForGodot({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Card(
          elevation: 8,
          shape: getRoundedBorder(radius: 16),
          child: SizedBox(
              height: 160,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 8,
                        backgroundColor: Colors.teal,
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                      'Finding the Association taxi routes ...',
                      style: myTextStyleSmallWithColor(
                          context, Theme.of(context).primaryColor),
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    Text(
                      'Tap the + icon at top right!',
                      style: myTextStyleMedium(context),
                    ),
                  ],
                ),
              )),
        ),
      ),
    );
  }
}

class RouteList extends StatelessWidget {
  const RouteList(
      {Key? key,
      required this.navigateToMapViewer,
      required this.navigateToLandmarks,
      required this.navigateToCreatorMap,
      required this.routes,
      this.currentRoute})
      : super(key: key);

  final Function(lib.Route) navigateToMapViewer;
  final Function(lib.Route) navigateToLandmarks;
  final Function(lib.Route) navigateToCreatorMap;
  final List<lib.Route> routes;

  final lib.Route? currentRoute;

  List<FocusedMenuItem> _getMenuItems(lib.Route route, BuildContext context) {
    List<FocusedMenuItem> list = [];

    list.add(FocusedMenuItem(
        title: Text('View Route Map', style: myTextStyleMediumBlack(context)),
        // backgroundColor: Theme.of(context).primaryColor,
        trailingIcon: Icon(
          Icons.map,
          color: Theme.of(context).primaryColor,
        ),
        onPressed: () {
          navigateToMapViewer(route);
        }));
    //
    list.add(FocusedMenuItem(
        title: Text('Route Landmarks', style: myTextStyleMediumBlack(context)),
        trailingIcon: Icon(
          Icons.water_damage_outlined,
          color: Theme.of(context).primaryColor,
        ),
        onPressed: () {
          navigateToLandmarks(route);
        }));
    //
    list.add(FocusedMenuItem(
        title: Text('Update Route', style: myTextStyleMediumBlack(context)),
        // backgroundColor: Theme.of(context).primaryColor,
        trailingIcon: Icon(
          Icons.edit,
          color: Theme.of(context).primaryColor,
        ),
        onPressed: () {
          navigateToCreatorMap(route);
        }));

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Card(
        elevation: 2,
        shape: getRoundedBorder(radius: 16),
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: bd.Badge(
            badgeContent: Text('${routes.length}'),
            badgeStyle: const bd.BadgeStyle(padding: EdgeInsets.all(16)),
            child: ListView.builder(
                itemCount: routes.length,
                itemBuilder: (ctx, index) {
                  var elevation = 6.0;
                  final rt = routes.elementAt(index);

                  return FocusedMenuHolder(
                    menuOffset: 24,
                    duration: const Duration(milliseconds: 300),
                    menuItems: _getMenuItems(rt, context),
                    animateMenuItems: true,
                    openWithTap: true,
                    onPressed: () {
                      pp('💛️️ tapped FocusedMenuHolder ...');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 1.0),
                      child: Card(
                        shape: getRoundedBorder(radius: 16),
                        elevation: elevation,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('${rt.name}'),
                        ),
                      ),
                    ),
                  );
                }),
          ),
        ),
      ),
    );
  }
}
