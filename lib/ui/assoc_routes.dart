import 'dart:async';

import 'package:badges/badges.dart' as bd;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_library/messaging/fcm_bloc.dart';
import 'package:kasie_transie_library/providers/kasie_providers.dart';
import 'package:kasie_transie_library/utils/emojis.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/initializer.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_route_builder/ui/maps/city_creator_map.dart';
import 'package:kasie_transie_route_builder/ui/maps/landmark_creator_map.dart';
import 'package:kasie_transie_route_builder/ui/route_detail_form.dart';
import 'package:kasie_transie_route_builder/ui/route_info_widget.dart';
import 'package:kasie_transie_route_builder/ui/tiny_bloc.dart';
import 'package:kasie_transie_route_builder/utils/route_distance_calculator.dart';
import 'package:responsive_builder/responsive_builder.dart';

import 'maps/route_creator_map.dart';
import 'maps/route_creator_map2.dart';
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
  late StreamSubscription<String> routeChangesSub;

  @override
  void initState() {
    super.initState();
    _listen();
    _getInitialData();
    initialize();
  }

  String? routeId;

  Future<void> initialize() async {
    fcmBloc.subscribeToTopics();
    routeChangesSub = fcmBloc.routeChangesStream.listen((event) {
      pp('$mm routeChangesStream delivered a routeId: $event');
      routeId = event;
      setState(() {});
      if (mounted) {
        showSnackBar(
            message:
                "A Route update has been issued. The download will happen automatically.",
            context: context);
      }
    });
  }

  void _listen() {
    _sub = listApiDog.routeStream.listen((routesFromStream) {
      pp('$mm ... listApiDog.routeStream delivered: ${routesFromStream.length}');
      routes = routesFromStream;
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _getInitialData() async {
    setState(() {
      busy = true;
    });
    try {
      user = await prefs.getUser();
      selectedRoute = await prefs.getRoute();
      if (selectedRoute != null) {
        selectedRouteId = selectedRoute!.routeId!;
      }
      routes = await listApiDog
          .getRoutes(AssociationParameter(user!.associationId!, false));
    } catch (e) {
      pp(e);
    }
    setState(() {
      busy = false;
    });
  }

  lib.Route? selectedRoute;
  String? selectedRouteId;

  @override
  void dispose() {
    routeChangesSub.cancel();
    super.dispose();
  }

  void navigateToLandmarks(lib.Route route) async {
    pp('$mm navigateToLandmarksEditor .....  route: ${route.name}');
    tinyBloc.setRouteId(route.routeId!);
    prefs.saveRoute(route);
    setState(() {
      selectedRoute = route;
      selectedRouteId = route.routeId;
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
    tinyBloc.setRouteId(route.routeId!);
    prefs.saveRoute(route);

    setState(() {
      selectedRoute = route;
      selectedRouteId = route.routeId;
    });
    pp('$mm Future.delayed(const Duration(seconds: 2) .....  ');

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      //route = await listApiDog.
      navigateWithScale(
          RouteMapViewer(
            routeId: route.routeId!,
            onRouteUpdated: () {
              pp('\n\n$mm onRouteUpdated ... do something Boss!');
              _refresh(true);
            },
          ),
          context);
    }
  }

  void navigateToCreatorMap(lib.Route route) async {
    pp('$mm navigateToCreatorMap .....  route: ${route.name}');
    tinyBloc.setRouteId(route.routeId!);
    prefs.saveRoute(route);
    setState(() {
      selectedRoute = route;
      selectedRouteId = route.routeId;
    });
    pp('$mm Future.delayed(const Duration(seconds: 2) .....  ');

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      navigateWithScale(
          RouteCreatorMap2(
            route: route,
          ),
          context);
    }
  }

  void _refresh(bool refresh) async {
    setState(() {
      busy = true;
    });
    routes = await listApiDog
        .getRoutes(AssociationParameter(user!.associationId!, refresh));
    setState(() {
      busy = false;
    });
  }

  void updateAssociationRouteLandmarks() async {
    pp('$mm updateAssociationRouteLandmarks requested.... ');
    setState(() {
      busy = true;
    });
    await dataApiDog.updateAssociationRouteLandmarks(user!.associationId!);
    setState(() {
      busy = false;
    });
  }

  bool sendingRouteUpdateMessage = false;

  void onSendRouteUpdateMessage(lib.Route route) async {
    pp("$mm onSendRouteUpdateMessage .........");
    tinyBloc.setRouteId(route.routeId!);
    prefs.saveRoute(route);

    setState(() {
      sendingRouteUpdateMessage = true;
    });
    try {
      await dataApiDog.sendRouteUpdateMessage(
          route.associationId!, route.routeId!);
      pp('$mm onSendRouteUpdateMessage happened OK! ${E.nice}');
    } catch (e) {
      pp(e);
      showToast(
          duration: const Duration(seconds: 5),
          padding: 20,
          textStyle: myTextStyleMedium(context),
          backgroundColor: Colors.amber,
          message: 'Route Update message sent OK',
          context: context);
    }
    setState(() {
      sendingRouteUpdateMessage = false;
    });
  }

  void calculateDistances(lib.Route route) async {
    tinyBloc.setRouteId(route.routeId!);
    prefs.saveRoute(route);

    routeDistanceCalculator.calculateRouteDistances(
        route.routeId!, route.associationId!);
  }

  @override
  Widget build(BuildContext context) {
    if (user != null) {
      final k = ref.watch(
          routesProvider(AssociationParameter(user!.associationId!, false)));
      if (k.hasValue) {
        routes = k.value!;
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
                icon: const Icon(Icons.downloading)),
            IconButton(
                onPressed: () async {
                  pp('$mm updateAssociationRouteLandmarks routes in backend .......');
                  initializer.initialize();
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
                                navigateToCreatorMap: navigateToCreatorMap,
                                routes: routes,
                                onSendRouteUpdateMessage: (route) {
                                  onSendRouteUpdateMessage(route);
                                },
                                onCalculateDistances: (r) {
                                  calculateDistances(r);
                                },
                              );
                            },
                            tablet: (ctx) {
                              return OrientationLayoutBuilder(landscape: (ctx) {
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
                                        routes: routes,
                                        onSendRouteUpdateMessage: (route) {
                                          onSendRouteUpdateMessage(route);
                                        },
                                        onCalculateDistances: (r) {
                                          calculateDistances(r);
                                        },
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 32,
                                    ),
                                    SizedBox(
                                      width: (width / 2),
                                      child: RouteInfoWidget(
                                        routeId: selectedRouteId,
                                        routeName: selectedRoute == null
                                            ? null
                                            : selectedRoute!.name,
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
                                        routes: routes,
                                        onSendRouteUpdateMessage: (route) {
                                          onSendRouteUpdateMessage(route);
                                        },
                                        onCalculateDistances: (r) {
                                          calculateDistances(r);
                                        },
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    SizedBox(
                                      width: (width / 2),
                                      child: RouteInfoWidget(
                                        routeId: selectedRouteId,
                                        routeName: selectedRoute == null
                                            ? null
                                            : selectedRoute!.name,
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
        ),
        drawer: SizedBox(
          width: 400,
          child: Drawer(
            child: ListView(
              children: [
                DrawerHeader(
                    decoration: const BoxDecoration(
                      color: Colors.black12,
                      image: DecorationImage(
                          image: AssetImage('assets/gio.png'), scale: .5),
                    ),
                    child: SizedBox(
                        height: 60,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text('Routes Menu',
                                style: myTextStyleMediumLargeWithColor(
                                    context, Colors.grey, 32)),
                            const SizedBox(
                              height: 48,
                            )
                          ],
                        ))),
                const SizedBox(
                  height: 64,
                ),
                ListTile(
                  title: const Text('Add Place/Town/City'),
                  leading: Icon(
                    Icons.account_balance,
                    color: Theme.of(context).primaryColor,
                  ),
                  subtitle: Text(
                      'Create a new place that wil be used in your routes',
                      style: myTextStyleSmall(context)),
                  onTap: () {
                    pp('$mm navigate to city creator map .......');
                    navigateWithFade(const CityCreatorMap(), context);
                  },
                ),
                const SizedBox(
                  height: 32,
                ),
                ListTile(
                  title: const Text('Add New Route'),
                  leading: Icon(Icons.directions_bus,
                      color: Theme.of(context).primaryColor),
                  subtitle: Text('Create a new route',
                      style: myTextStyleSmall(context)),
                  onTap: () {
                    navigateWithScale(
                        RouteDetailForm(dataApiDog: dataApiDog, prefs: prefs),
                        context);
                  },
                ),
                const SizedBox(
                  height: 32,
                ),
                ListTile(
                  title: const Text('Calculate Route Distances'),
                  leading: Icon(Icons.calculate,
                      color: Theme.of(context).primaryColor),
                  subtitle: Text(
                    'Calculate distances between landmarks in the route',
                    style: myTextStyleSmall(context),
                  ),
                  onTap: () {
                    pp('$mm starting distance calculation ...');
                    routeDistanceCalculator
                        .calculateAssociationRouteDistances();
                  },
                ),
                const SizedBox(
                  height: 32,
                ),
                ListTile(
                  title: const Text('Refresh Route Data'),
                  leading: Icon(Icons.refresh,
                      color: Theme.of(context).primaryColor),
                  subtitle: Text(
                    'Fetch refreshed route data from the Mother Ship',
                    style: myTextStyleSmall(context),
                  ),
                  onTap: () {
                    _refresh(true);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
      this.currentRoute,
      required this.onSendRouteUpdateMessage,
      required this.onCalculateDistances})
      : super(key: key);

  final Function(lib.Route) navigateToMapViewer;
  final Function(lib.Route) navigateToLandmarks;
  final Function(lib.Route) navigateToCreatorMap;
  final Function(lib.Route) onSendRouteUpdateMessage;
  final Function(lib.Route) onCalculateDistances;

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

    list.add(FocusedMenuItem(
        title: Text('Calculate Route Distances',
            style: myTextStyleMediumBlack(context)),
        // backgroundColor: Theme.of(context).primaryColor,
        trailingIcon: Icon(
          Icons.calculate,
          color: Theme.of(context).primaryColor,
        ),
        onPressed: () {
          onCalculateDistances(route);
        }));
    list.add(FocusedMenuItem(
        title: Text('Send Route Update Message',
            style: myTextStyleMediumBlack(context)),
        // backgroundColor: Theme.of(context).primaryColor,
        trailingIcon: Icon(
          Icons.send,
          color: Theme.of(context).primaryColor,
        ),
        onPressed: () {
          onSendRouteUpdateMessage(route);
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
