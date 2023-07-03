import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_library/data/schemas.dart';
import 'package:kasie_transie_library/providers/kasie_providers.dart';
import 'package:kasie_transie_library/utils/device_location_bloc.dart';
import 'package:kasie_transie_library/utils/emojis.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/parsers.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_library/widgets/city_selection.dart';
import 'package:kasie_transie_route_builder/ui/maps/route_creator_map.dart';
import 'package:kasie_transie_route_builder/ui/route_detail_form_container.dart';
import 'package:kasie_transie_route_builder/ui/widgets/route_list_minimum.dart';
import 'package:kasie_transie_route_builder/ui/widgets/searching_cities_busy.dart';
import 'package:realm/realm.dart';
import 'package:responsive_builder/responsive_builder.dart' as responsive;
import 'package:uuid/uuid.dart' as uu;

import 'assoc_routes.dart';
import 'widgets/color_picker.dart';

class RouteDetailForm extends ConsumerStatefulWidget {
  const RouteDetailForm(
      {Key? key, this.route, required this.dataApiDog, required this.prefs})
      : super(key: key);

  final lib.Route? route;
  final DataApiDog dataApiDog;
  final Prefs prefs;

  @override
  ConsumerState createState() => RouteDetailFormState();
}

class RouteDetailFormState extends ConsumerState<RouteDetailForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _controller;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _routeNumberController = TextEditingController();
  final mm = '🔵🔵🔵🔵🔵 RouteDetailForm 🔵🔵';
  lib.Route? route;
  lib.User? user;
  lib.Country? country;
  List<lib.Route> routes = [];

  String colorString = 'black';
  Color color = Colors.black;
  SettingsModel? settingsModel;
  bool busy = false;
  var _cities = <City>[];

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getUser();
    findCitiesByLocation(radiusInKM);
  }

  void _handleRef() async {
    final m = ref.watch(
        routesProvider(AssociationParameter(user!.associationId!, false)));
    if (m.hasValue) {
      pp('$mm routesProvider has done it again! ❤️${m.value!.length} routes delivered');
      routes = m.value!;
      setState(() {});
    }
  }

  void _getUser() async {
    user = await widget.prefs.getUser();
    country = await widget.prefs.getCountry();
    settingsModel = await widget.prefs.getSettings();
    if (settingsModel == null) {
      final res = await listApiDog.getSettings(user!.associationId!, false);
      if (res.isNotEmpty) {
        pp('$mm ${res.length} ${E.redDot} ${E.redDot} settings found.');
        myPrettyJsonPrint(res.first.toJson());
        await widget.prefs.saveSettings(res.first);
        settingsModel = await widget.prefs.getSettings();
        if (settingsModel == null) {
          pp('$mm ${E.redDot} ${E.redDot}${E.redDot} ${E.redDot} settings did not happen!!');
        } else {
          pp('$mm we seem to be good now ${E.leaf2} what the fuck!');
          myPrettyJsonPrint(settingsModel!.toJson());
        }
      }
    } else {
      pp('$mm ${E.nice} ${E.nice} ${E.nice} ${E.nice} -- nice, check sign in widget!!');
    }
    _handleRef();
  }

  void findCitiesByLocation(double radius) async {
    setState(() {
      busy = true;
    });
    try {
      pp('... starting findCitiesByLocation 1...');
      final loc = await locationBloc.getLocation();
      user = await prefs.getUser();
      pp('... ended location GPS .2..');

      _cities = await listApiDog.findCitiesByLocation(LocationFinderParameter(
          associationId: user!.associationId,
          latitude: loc.latitude,
          longitude: loc.longitude,
          limit: 500,
          radiusInKM: radius));
      radiusInKM = radius;
      // _cities.sort((a, b) => a.name!.compareTo(b.name!));
      pp('$mm cities found by location: ${_cities.length} cities within $radius km ....');
    } catch (e) {
      pp(e);
    }
    setState(() {
      busy = false;
    });
  }

  City? startCity, endCity;

  Future<void> findNearestStartCity() async {
    _setRouteName();
    setState(() {
      findStartCity = true;
      findEndCity = false;
      _showTheFuckingSearch = true;
    });
  }

  void _setRouteName() {
    var s = StringBuffer();
    if (startCity != null) {
      s.write(startCity!.name);
      s.write(' - ');
    }
    if (endCity != null) {
      s.write(endCity!.name);
    }
    _nameController.text = s.toString();
    setState(() {});
    ;
  }

  Future<void> findNearestEndCity() async {
    _setRouteName();
    setState(() {
      findStartCity = false;
      findEndCity = true;
      _showTheFuckingSearch = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> onSubmitRequested() async {
    pp('$mm ................................. onSubmitRequested ...');
    //todo - validate!
    if (_formKey.currentState!.validate()) {
      pp('$mm ... validation is OK');
      showToast(
        message: 'Route is on it\'s way!',
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        textStyle: myTextStyleMediumPrimaryColor(context),
        context: context,
        padding: 28.0,
        duration: const Duration(seconds: 5),
      );
    } else {
      return;
    }
    if (startCity == null) {
      showToast(
          message: 'Please select start of route',
          context: context,
          padding: 20.0,
          backgroundColor: Colors.amber,
          textStyle: myTextStyleMediumWithColor(context, Colors.red),
          duration: const Duration(seconds: 5));
      return;
    }
    if (endCity == null) {
      showToast(
          message: 'Please select end of route',
          context: context,
          padding: 20.0,
          backgroundColor: Colors.amber,
          textStyle: myTextStyleMediumWithColor(context, Colors.black),
          duration: const Duration(seconds: 3));
      return;
    }
    final se = lib.RouteStartEnd(
      startCityId: startCity!.cityId!,
      startCityName: startCity!.name,
      endCityId: endCity!.cityId!,
      endCityName: endCity!.name,
      startCityPosition: Position(
        type: point,
        coordinates: startCity!.position!.coordinates,
      ),
      endCityPosition: Position(
        type: point,
        coordinates: endCity!.position!.coordinates,
      ),
    );
    final route = lib.Route(
      ObjectId(),
      routeNumber: _routeNumberController.value.text,
      routeId: const uu.Uuid().v4(),
      associationId: user!.associationId,
      associationName: user!.associationName,
      lengthInMetres: 0,
      routeStartEnd: se,
      created: DateTime.now().toUtc().toIso8601String(),
      color: colorString,
      userId: user!.userId,
      countryId: country!.countryId,
      isActive: true,
      countryName: country!.name,
      userUrl: user!.thumbnailUrl,
      userName: user!.name,
      name: _nameController.value.text,
    );

    try {
      final m = await dataApiDog.addRoute(route);
      if (mounted) {
        _showDialog(m);
      }
    } catch (e) {
      pp(e);
      showSnackBar(
          duration: const Duration(seconds: 15),
          message: 'Route failed: $e',
          context: context);
    }
  }

  void _showDialog(lib.Route route) {
    showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text(
                'Next Step?',
                style: myTextStyleLarge(context),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('No'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Yes'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    navigateWithScale(RouteCreatorMap(route: route), context);
                  },
                )
              ],
              content: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Do you want to start mapping the route?'),
                      ),
                    ],
                  )));
        });
  }

  bool findStartCity = false;
  bool findEndCity = false;
  bool _showTheFuckingSearch = false;

  double radiusInKM = 25;

  bool sendingRouteUpdateMessage = false;
  void onSendRouteUpdateMessage() async {
    pp("$mm onSendRouteUpdateMessage .........");
    setState(() {
      sendingRouteUpdateMessage = true;
    });
    try {
      if (widget.route != null) {
        await dataApiDog.sendRouteUpdateMessage(
            widget.route!.associationId!, widget.route!.routeId!);
        pp('$mm onSendRouteUpdateMessage happened OK! ${E.nice}');
      }
    } catch (e) {
      pp(e);
      showToast(
          duration: const Duration(seconds: 5),
          padding: 20,
          textStyle: myTextStyleMedium(context),
          backgroundColor: Colors.amber,
          message: 'Route Update message sent OK', context: context);
    }
    setState(() {
      sendingRouteUpdateMessage = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var leftPadding = 64.0;
    final type = getDeviceType();
    if (type == 'phone') {
      leftPadding = 2.0;
    }
    final width = MediaQuery.of(context).size.width;
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text(
          'Route Editor',
          style: myTextStyleLarge(context),
        ),
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(8), child: Column()),
      ),
      body: Stack(
        children: [
          responsive.ScreenTypeLayout.builder(
            mobile: (ctx) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: busy
                    ? const SearchingCitiesBusy()
                    : RouteDetailFormContainer(
                        formKey: _formKey,
                        onSendRouteUpdateMessage: onSendRouteUpdateMessage,
                        onRouteStartSearch: findNearestStartCity,
                        onRouteEndSearch: findNearestEndCity,
                        color: color,
                        nameController: _nameController,
                        routeNumberController: _routeNumberController,
                        nearestEnd: endCity,
                        nearestStart: startCity,
                        onSubmit: onSubmitRequested,
                        onColorSelected: (c, s) {
                          setState(() {
                            color = c;
                            colorString = s;
                          });
                        },
                        onRefresh: (radius) {
                          radiusInKM = radius;
                          findCitiesByLocation(radius);
                        },
                        radiusInKM: 20,
                        numberOfCities: _cities.length,
                      ),
              );
            },
            tablet: (ctx) {
              return responsive.OrientationLayoutBuilder(portrait: (ctx) {
                return Row(
                  children: [
                    SizedBox(
                      width: (width / 2) + 48,
                      child: RouteDetailFormContainer(
                        formKey: _formKey,
                        onSendRouteUpdateMessage: onSendRouteUpdateMessage,
                        numberOfCities: _cities.length,
                        onRouteStartSearch: findNearestStartCity,
                        onRouteEndSearch: findNearestEndCity,
                        color: color,
                        radiusInKM: radiusInKM,
                        nameController: _nameController,
                        routeNumberController: _routeNumberController,
                        nearestEnd: endCity,
                        nearestStart: startCity,
                        onSubmit: onSubmitRequested,
                        onColorSelected: (c, s) {
                          setState(() {
                            color = c;
                            colorString = s;
                          });
                        },
                        onRefresh: (radius) {
                          radiusInKM = radius;
                          findCitiesByLocation(radius);
                        },
                      ),
                    ),
                    SizedBox(
                      width: (width / 2) - 48,
                      child: StreamBuilder<List<lib.Route>>(
                          stream: listApiDog.routeStream,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              routes = snapshot.data!;
                            }
                            return const RouteListMinimum();
                          }),
                    ),
                  ],
                );
              });
            },
          ),
          _showTheFuckingSearch
              ? Positioned(
                  top: 8.0,
                  left: leftPadding,
                  child: SizedBox(
                    width: 600,
                    height: 800,
                    child: CitySearch(
                      title: findStartCity ? 'Start of Route' : 'End of Route',
                      showScaffold: true,
                      onCitySelected: (c) {
                        pp('.... city at start: ${c.name}');
                        if (findEndCity) {
                          endCity = c;
                        }
                        if (findStartCity) {
                          startCity = c;
                        }
                        _setRouteName();
                        setState(() {
                          _showTheFuckingSearch = false;
                        });
                      },
                      cities: _cities,
                    ),
                  ))
              : const SizedBox(),
          busy
              ? const Positioned(
                  top: 240, left: 80, child: SearchingCitiesBusy())
              : const SizedBox()
        ],
      ),
    ));
  }
}
