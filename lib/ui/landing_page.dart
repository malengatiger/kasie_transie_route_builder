import 'package:flutter/material.dart';
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/schemas.dart';
import 'package:kasie_transie_library/providers/kasie_providers.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_route_builder/ui/assoc_routes.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;

import '../intro/kasie_intro.dart';

class LandingPage extends StatefulWidget {
  const LandingPage(
      {Key? key,
      required this.listApiDog,
      required this.dataApiDog,
      required this.prefs})
      : super(key: key);

  final ListApiDog listApiDog;
  final DataApiDog dataApiDog;
  final Prefs prefs;
  @override
  LandingPageState createState() => LandingPageState();
}
/*

Flutter Riverpod live templates is a way to enhance the way you use Riverpod. It contains a collection of different snippets such as family or provider.
Snippets
Generator syntax
Shortcut
Description
riverpodGeneratorFutureVariable
Create a future variable using generator
riverpodGeneratorAsyncNotifierProvider
Create a AsyncNotifierProvider using generator
riverpodGeneratorVariable
Create a variable using generator
riverpodGeneratorNotiferProvider
Create a NotifierProvider using generator
Normal syntax
Shortcut
Description
when
Use when on AsyncValue
consumer
New Consumer
consumerWidget
New ConsumerWidget
consumerStatefulWidget
New ConsumerStatefulWidget
hookConsumer
New HookConsumer (must import hooks_riverpod)
hookConsumerWidget
New HookConsumerWidget (must import hooks_riverpod)
changeNotifierProvider*
New ChangeNotifierProvider
provider*
New Provider
futureProvider*
New FutureProvider
streamProvider*
New StreamProvider
stateNotifier
New StateNotifier in state_provider
stateNotifierProvider*
New StateNotifierProvider
stateProvider*
New StateProvider
( * ) is suffix modifier, ex: autoDispose, family
 */
class LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  static const mm = '🥬🥬🥬🥬🥬🥬 LandingPage  🔵🔵';
  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _initialize();
  }

  void _initialize() async {
    pp('$mm ..... check settings and fix if needed!');
    final user = await prefs.getUser();
    if (user != null) {
      var sett = await prefs.getSettings();
      if (sett == null) {
        final settList = await listApiDog.getSettings(user!.associationId!);
        if (settList.isNotEmpty) {
          sett = settList.first;
          await prefs.saveSettings(sett);
        }
        pp('$mm ..... settings fixed!');
      }
    }
  }

  onRouteSelected(lib.Route p1) {
    pp('$mm onRouteSelected .... ${p1.name}');
  }

  onSuccessfulSignIn(User p1) {
    pp('$mm onSuccessfulSignIn .... ${p1.name} - navigating to RouteList ...');

    navigateWithScale(
         AssociationRoutes(AssociationParameter(p1.associationId!, true), p1.associationName!),
        context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(),
      body: ScreenTypeLayout.builder(
        mobile: (ctx) {
          return KasieIntro(
            dataApiDog: widget.dataApiDog,
          );
        },
      ),
    ));
  }
}
