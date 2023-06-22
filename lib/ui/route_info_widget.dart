import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasie_transie_library/providers/kasie_providers.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:intl/intl.dart';

class RouteInfoWidget extends ConsumerWidget {
  const RouteInfoWidget({Key? key, required this.route}) : super(key: key);
  final lib.Route? route;
  final mm = '😎😎😎😎 RouteInfoWidget: 😎';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var numberOfPoints = 0;
    var numberOfLandmarks = 0;

    if (route != null) {
      final res = ref.watch(routePointProvider(route!.routeId!));
      final res2 = ref.watch(routeLandmarkProvider(route!.routeId!));

      if (res.hasValue) {
        pp('$mm RiverPod delivered ${res.value!.length} route points to build method');
        numberOfPoints = res.value!.length;
      } else {
        pp('$mm RiverPod - no cigar! no route points ');
      }
      if (res2.hasValue) {
        pp('$mm RiverPod delivered ${res2.value!.length} RouteLandmarks to build method');
        numberOfLandmarks = res2.value!.length;
      } else {
        pp('$mm RiverPod - no cigar! no landmarks');
      }
    } else {
      return  SizedBox(height: 400,
        child: Card(
            shape: getRoundedBorder(radius: 16),
            elevation: 8,
            child:  Center(
              child: SizedBox(height: 60, child: Text('Waiting for Godot', style: myTextStyleMediumLargeWithSize(context, 32),),),
            )
        ),
      );
    }

    final fmt = NumberFormat.decimalPattern();
    final ori = MediaQuery.of(context).orientation;

    return Card(
      shape: getRoundedBorder(radius: 16),
      elevation: 8,
      child: Column(
        children: [
          const SizedBox(height: 20,),

          Text('Route Details', style: myTextStyleMediumLarge(context),),

          const SizedBox(height: 80,),
          Text('${route!.name}', style: myTextStyleMediumLargeWithSize(context, 20),),
          const SizedBox(height: 16,),
          Text('${route!.associationName}',style: myTextStyleMediumPrimaryColor(context),),
          const SizedBox(height: 48,),
          Text(getFormattedDateLong(route!.created!)),
          const SizedBox(height: 24,),
          Text('${route!.userName}', style: myTextStyleMediumBoldGrey(context),),
          const SizedBox(height: 48,),

          SizedBox(
              height: 80,
              child: Column(
                children: [
                  Text(fmt.format(numberOfLandmarks),style: myNumberStyleLargest(context),),
                  Text('Route Landmarks', style: myTextStyleMediumBoldGrey(context),),
                ],
              )),

          const SizedBox(height: 24,),
          SizedBox(
              height: 80,
              child: Column(
                children: [
                  Text(fmt.format(numberOfPoints),style: myNumberStyleLargest(context),),
                  Text('Route Points Mapped', style: myTextStyleMediumBoldGrey(context),),
                ],
              )),


        ],
      ),
    );
  }
}
