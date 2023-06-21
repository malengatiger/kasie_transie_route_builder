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
import 'package:realm/realm.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:uuid/uuid.dart' as uu;

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

  String colorString = 'black';
  Color color = Colors.white;
  SettingsModel? settingsModel;
  bool busy = false;
  var _cities = <City>[];

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getUser();
    _getCities(100.0);
  }

  void _getUser() async {
    user = await widget.prefs.getUser();
    country = await widget.prefs.getCountry();
    settingsModel = await widget.prefs.getSettings();
    if (settingsModel == null) {
      final res = await listApiDog.getSettings(user!.associationId!);
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
  }

  void _getCities(double radius) async {
    setState(() {
      busy = true;
    });
    pp('... starting findCitiesByLocation 1...');
    final loc = await locationBloc.getLocation();
    user = await prefs.getUser();
    pp('... ended location GPS .2..');

    _cities = await listApiDog.findCitiesByLocation(LocationFinderParameter(
        associationId: user!.associationId,
        latitude: loc.latitude,
        longitude: loc.longitude, limit: 500,
        radiusInKM: radius));
    // _cities.sort((a, b) => a.name!.compareTo(b.name!));
    pp('$mm cities found by location: ${_cities.length} cities within $radius km ....');
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
      calculatedDistances: [],
    );

    try {
      final m = await dataApiDog.addRoute(route);
      if (mounted) {
        navigateWithScale(RouteCreatorMap(route: m), context);
      }
    } catch (e) {
      pp(e);
      showSnackBar(
          duration: const Duration(seconds: 15),
          message: 'Route failed: $e',
          context: context);
    }
  }

  bool findStartCity = false;
  bool findEndCity = false;
  bool _showTheFuckingSearch = false;

  @override
  Widget build(BuildContext context) {
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
          ScreenTypeLayout.builder(
            mobile: (ctx) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: busy
                    ? const Center(
                        child: SizedBox(
                          height: 200,
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                strokeWidth: 6,
                                backgroundColor: Colors.pink,
                              ),
                              SizedBox(
                                height: 24,
                              ),
                              Text(
                                  'Searching for cities, towns and places around you ... ')
                            ],
                          ),
                        ),
                      )
                    : RouteDetailFormContainer(
                        formKey: _formKey,
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
                          _getCities(radius);
                        },
                      ),
              );
            },
          ),
          _showTheFuckingSearch
              ? Positioned(
                  top: 60.0,
                  bottom: 60.0,
                  left: 24,
                  right: 24,
                  child: CitySearch(
                    title: findStartCity ? 'Start of Route' : 'End of Route',
                    showScaffold: false,
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
                  ))
              : const SizedBox(),
        ],
      ),
    ));
  }
}

class RouteDetailFormContainer extends StatelessWidget {
  const RouteDetailFormContainer(
      {Key? key,
      required this.formKey,
      required this.onRouteStartSearch,
      required this.onRouteEndSearch,
      required this.nearestStart,
      required this.nearestEnd,
      required this.routeNumberController,
      required this.nameController,
      required this.color,
      required this.onSubmit,
      required this.onColorSelected,
      required this.onRefresh})
      : super(key: key);

  final GlobalKey<FormState> formKey;
  final Function onRouteStartSearch;
  final Function onRouteEndSearch, onSubmit;
  final Function(Color, String) onColorSelected;
  final City? nearestStart, nearestEnd;
  final TextEditingController routeNumberController, nameController;
  final Color color;
  final Function(double) onRefresh;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: getRoundedBorder(radius: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(
              height: 12,
            ),
            Text(
              'Create or update the taxi Route',
              style: myTextStyleMedium(context),
            ),
            const SizedBox(
              height: 48,
            ),
            Expanded(
                child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    const SizedBox(
                      height: 28,
                    ),
                    GestureDetector(
                      onTap: () {
                        onRouteStartSearch();
                      },
                      child: CityWidget(
                        city: nearestStart,
                        title: 'Route Start',
                      ),
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    GestureDetector(
                        onTap: () {
                          onRouteEndSearch();
                        },
                        child:
                            CityWidget(city: nearestEnd, title: 'Route End')),
                    const SizedBox(
                      height: 28,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DropdownButton<double>(
                            hint: const Text('Select Search Radius'),
                            items: const [
                              DropdownMenuItem(
                                value: 10.0,
                                child: Text('10 km'),
                              ),
                              DropdownMenuItem(
                                value: 20.0,
                                child: Text('20 km'),
                              ),
                              DropdownMenuItem(
                                value: 30.0,
                                child: Text('30 km'),
                              ),
                              DropdownMenuItem(
                                value: 40.0,
                                child: Text('40 km'),
                              ),
                              DropdownMenuItem(
                                value: 50.0,
                                child: Text('50 km'),
                              ),
                              DropdownMenuItem(
                                value: 100.0,
                                child: Text('100 km'),
                              ),
                              DropdownMenuItem(
                                value: 150.0,
                                child: Text('150 km'),
                              ),
                              DropdownMenuItem(
                                value: 200.0,
                                child: Text('200 km'),
                              ),
                              DropdownMenuItem(
                                value: 300.0,
                                child: Text('300 km'),
                              ),
                              DropdownMenuItem(
                                value: 500.0,
                                child: Text('500 km'),
                              ),
                              DropdownMenuItem(
                                value: 750.0,
                                child: Text('750 km'),
                              ),
                              DropdownMenuItem(
                                value: 1000.0,
                                child: Text('1000 km'),
                              ),
                            ],
                            onChanged: (m) {
                              if (m != null) {
                                onRefresh(m);
                              }
                            })
                      ],
                    ),
                    const SizedBox(
                      height: 28,
                    ),
                    TextFormField(
                      controller: nameController,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter name of the taxi Route';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Route Name',
                        hintText: 'Enter Route Name',
                      ),
                    ),
                    const SizedBox(
                      height: 48,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Route Colour'),
                        const SizedBox(
                          width: 24,
                        ),
                        Container(
                          height: 24,
                          width: 24,
                          color: color,
                        ),
                        const SizedBox(
                          width: 24,
                        ),
                        ColorPicker(onColorPicked: (string, clr) {
                          onColorSelected(clr, string);
                        }),
                      ],
                    ),
                    const SizedBox(
                      height: 100,
                    ),
                    ElevatedButton(
                        onPressed: () {
                          onSubmit();
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 40.0, vertical: 20),
                          child: Text('Save Route'),
                        )),
                    const SizedBox(
                      height: 120,
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class ColorPicker extends StatelessWidget {
  const ColorPicker({Key? key, required this.onColorPicked}) : super(key: key);
  final Function(String, Color) onColorPicked;

  @override
  Widget build(BuildContext context) {
    final items = <DropdownMenuItem<int>>[];
    items.add(DropdownMenuItem<int>(
      value: 0,
      child: Container(
        color: Colors.red,
        width: 48,
        height: 48,
      ),
    ));
    items.add(DropdownMenuItem<int>(
      value: 1,
      child: Container(
        color: Colors.black,
        width: 48,
        height: 48,
      ),
    ));
    items.add(DropdownMenuItem<int>(
      value: 2,
      child: Container(
        color: Colors.white,
        width: 48,
        height: 48,
      ),
    ));
    items.add(DropdownMenuItem<int>(
      value: 3,
      child: Container(
        color: Colors.orange,
        width: 48,
        height: 48,
      ),
    ));
    items.add(DropdownMenuItem<int>(
      value: 4,
      child: Container(
        color: Colors.green,
        width: 48,
        height: 48,
      ),
    ));
    items.add(DropdownMenuItem<int>(
      value: 5,
      child: Container(
        color: Colors.indigo,
        width: 48,
        height: 48,
      ),
    ));
    items.add(DropdownMenuItem<int>(
      value: 6,
      child: Container(
        color: Colors.pink,
        width: 48,
        height: 48,
      ),
    ));
    items.add(DropdownMenuItem<int>(
      value: 7,
      child: Container(
        color: Colors.amber,
        width: 48,
        height: 48,
      ),
    ));
    items.add(DropdownMenuItem<int>(
      value: 8,
      child: Container(
        color: Colors.yellow,
        width: 48,
        height: 48,
      ),
    ));
    items.add(DropdownMenuItem<int>(
      value: 9,
      child: Container(
        color: Colors.teal,
        width: 48,
        height: 48,
      ),
    ));
    items.add(
      DropdownMenuItem<int>(
        value: 10,
        child: Container(
          color: Colors.purple,
          width: 48,
          height: 48,
        ),
      ),
    );
    items.add(
      DropdownMenuItem<int>(
        value: 11,
        child: Container(
          color: Colors.blue,
          width: 48,
          height: 48,
        ),
      ),
    );

    return DropdownButton<int>(items: items, onChanged: onChanged);
  }

  void onChanged(int? index) {
    switch (index) {
      case 0:
        onColorPicked('red', Colors.red);
        break;
      case 1:
        onColorPicked('black', Colors.black);
        break;
      case 2:
        onColorPicked('white', Colors.white);
        break;
      case 3:
        onColorPicked('orange', Colors.orange);
        break;
      case 4:
        onColorPicked('green', Colors.green);
        break;
      case 5:
        onColorPicked('indigo', Colors.indigo);
        break;
      case 6:
        onColorPicked('pink', Colors.pink);
        break;
      case 7:
        onColorPicked('amber', Colors.amber);
        break;
      case 8:
        onColorPicked('yellow', Colors.yellow);
        break;
      case 9:
        onColorPicked('teal', Colors.teal);
        break;
      case 10:
        onColorPicked('purple', Colors.purple);
        break;
      case 11:
        onColorPicked('blue', Colors.blue);
        break;
    }
  }
}

class CityWidget extends StatelessWidget {
  const CityWidget({Key? key, this.city, required this.title})
      : super(key: key);
  final City? city;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(title)),
          const SizedBox(
            width: 12,
          ),
          city == null
              ? const SizedBox()
              : Text(
                  '${city!.name}',
                  style: myTextStyleMediumBoldWithColor(
                      context, Theme.of(context).primaryColor),
                )
        ],
      ),
    );
  }
}
