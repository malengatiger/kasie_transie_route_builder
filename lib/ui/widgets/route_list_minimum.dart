import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_library/providers/kasie_providers.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:badges/badges.dart' as bd;

class RouteListMinimum extends StatefulWidget {
  const RouteListMinimum({
    Key? key,
  }) : super(key: key);

  @override
  RouteListMinimumState createState() => RouteListMinimumState();
}

class RouteListMinimumState extends State<RouteListMinimum>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  static const mm = '🔷🔷🔷🔷😡😡😡 RouteListMinimum: 🔷🔷';

  var routes = <lib.Route>[];
  bool busy = false;
  late StreamSubscription<List<lib.Route>> _sub;
  lib.User? user;
  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _listen();
    _getRoutes();
  }

  void _listen() async {
    _sub = listApiDog.routeStream.listen((event) {
      routes = event;
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future _getRoutes() async {
    try {
      setState(() {
        busy = true;
      });
      user = await prefs.getUser();
      routes = await listApiDog
          .getRoutes(AssociationParameter(user!.associationId!, true));
      pp('$mm ... found ${routes.length}');
    } catch (e) {
      pp(e);
    }
    setState(() {
      busy = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routes List'),
        leading: const SizedBox(),
      ),
      body: busy
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(),
              ),
            )
          : Column(
              children: [
                const SizedBox(
                  height: 24,
                ),
                Text(
                    user == null ? 'Association Name' : user!.associationName!),
                const SizedBox(
                  height: 24,
                ),
                Expanded(
                    child: bd.Badge(
                      position: bd.BadgePosition.topEnd(end: 12),
                      badgeStyle: const bd.BadgeStyle(padding: EdgeInsets.all(12),

                      ),
                      badgeContent: Text('${routes.length}'),
                      child: ListView.builder(
                          itemCount: routes.length,
                          itemBuilder: (ctx, index) {
                            final r = routes.elementAt(index);
                            return Card(
                              shape: getRoundedBorder(radius: 16),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text('${r.name}'),
                              ),
                            );
                          }),
                    )),
              ],
            ),
    );
  }
}
