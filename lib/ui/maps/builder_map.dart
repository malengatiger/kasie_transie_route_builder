import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_library/providers/country_provider.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/prefs.dart';

class BuilderMap extends ConsumerStatefulWidget {
  const BuilderMap({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState createState() => _BuilderMapState();
}

class _BuilderMapState extends ConsumerState<BuilderMap> {
  lib.User? user;
  var routes = <lib.Route>[];

  @override
  void initState() {
    super.initState();
    _watch();
  }

  void _watch() async {
    user = await prefs.getUser();
    var m = ref.watch(
        routesProvider(AssociationParameter(user!.associationId!, true)));
    if (m.hasValue) {
      pp(' ........ hey! routesProvider has delivered something!');
      routes = m.value!;
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.pink,);
  }
}
