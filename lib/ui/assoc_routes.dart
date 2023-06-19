import 'dart:async';

import 'package:badges/badges.dart' as bd;
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
import 'package:kasie_transie_route_builder/ui/route_detail_form.dart';


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
        setState(() {

        });
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

  @override
  Widget build(BuildContext context) {
    if (user != null) {
      final k = ref.watch(routesProvider(AssociationParameter(user!.associationId!, true)));
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
                                    Text(
                                      'Finding the Association taxi routes ...',
                                      style: myTextStyleMediumWithColor( context, Theme.of(context).primaryColor),
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
                          padding: const EdgeInsets.only(top:16.0),
                          child: ListView.builder(
                              itemCount: routes.length,
                              itemBuilder: (ctx, index) {
                                final rt = routes.elementAt(index);
                                return GestureDetector(
                                  onTap: () {
                                    pp('....... _navigateToDetail with route: ${rt.name}');
                                    navigateWithScale(
                                        RouteDetailForm(
                                            dataApiDog: dataApiDog, prefs: prefs),
                                        context);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 1.0),
                                    child: Card(
                                      shape: getRoundedBorder(radius: 16),
                                      elevation: 6,
                                      child:  Padding(
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
