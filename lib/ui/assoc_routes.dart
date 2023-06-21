import 'dart:async';

import 'package:badges/badges.dart' as bd;
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_library/providers/kasie_providers.dart';
import 'package:kasie_transie_library/utils/emojis.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_route_builder/ui/maps/landmark_creator_map.dart';
import 'package:kasie_transie_route_builder/ui/route_detail_form.dart';
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
  lib.User? user;
  late StreamSubscription<List<lib.Route>> _sub;
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
    } catch (e) {
      pp(e);
    }
    setState(() {
      busy = false;
    });
  }

  List<FocusedMenuItem> _getMenuItems(BuildContext context, lib.Route route) {
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

  void navigateToLandmarks(lib.Route route) {
    pp('$mm navigateToLandmarksEditor .....  ');
    navigateWithScale(
        LandmarkCreatorMap(
          route: route,
        ),
        context);
  }

  void navigateToMapViewer(lib.Route route) {
    pp('$mm navigateToMapViewer .....  ');
    navigateWithScale(
        RouteMapViewer(
          route: route,
        ),
        context);
  }

  void navigateToCreatorMap(lib.Route route) {
    pp('$mm navigateToCreatorMap .....  ');
    navigateWithScale(
        RouteCreatorMap(
          route: route,
        ),
        context);
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
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: bd.Badge(
              badgeContent: Text('${routes.length}'),
              badgeStyle: const bd.BadgeStyle(padding: EdgeInsets.all(16)),
              child: routes.isEmpty
                  ? Center(
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
                                    const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(
                                      strokeWidth: 8, backgroundColor: Colors.teal,
                                    ),),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Text(
                                      'Finding the Association taxi routes ...',
                                      style: myTextStyleSmallWithColor(context,
                                          Theme.of(context).primaryColor),
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
                    )
                  : Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Card(
                        elevation: 2,
                        shape: getRoundedBorder(radius: 16),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: ListView.builder(
                              itemCount: routes.length,
                              itemBuilder: (ctx, index) {
                                final rt = routes.elementAt(index);
                                return FocusedMenuHolder(
                                  menuOffset: 24,
                                  duration: const Duration(milliseconds: 300),
                                  menuItems: _getMenuItems(context, rt),
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
                                      elevation: 6,
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
            ),
          ),
        ],
      ),
    ));
  }

  void _navigateToDetail(lib.Route rt) {}
}
