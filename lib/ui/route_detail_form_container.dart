
import 'package:flutter/material.dart';
import 'package:kasie_transie_library/data/schemas.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:badges/badges.dart' as bd;
import 'package:kasie_transie_route_builder/ui/widgets/city_widget.dart';

import 'widgets/color_picker.dart';


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
        required this.onRefresh, required this.radiusInKM, required this.numberOfCities})
      : super(key: key);

  final GlobalKey<FormState> formKey;
  final Function onRouteStartSearch;
  final Function onRouteEndSearch, onSubmit;
  final Function(Color, String) onColorSelected;
  final City? nearestStart, nearestEnd;
  final TextEditingController routeNumberController, nameController;
  final Color color;
  final double radiusInKM;
  final int numberOfCities;
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
                  child: Card(
                    shape: getRoundedBorder(radius: 16),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Form(
                        key: formKey,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 28,
                              ),
                              Row(mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text('Tap below to select your start and end of the route',
                                    style: myTextStyleSmall(context),),
                                ],
                              ),
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
                                      hint: Text('Select Search Area', style: myTextStyleSmall(context),),
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
                                      }),
                                  const SizedBox(
                                    width: 28,
                                  ),
                                  Text('$radiusInKM km', style: myTextStyleMediumLargeWithSize(
                                      context, 20)),
                                  const SizedBox(
                                    width: 28,
                                  ),
                                  bd.Badge(
                                      badgeContent: Text('$numberOfCities'),
                                      badgeStyle: const bd.BadgeStyle(
                                        elevation: 8, badgeColor: Colors.teal,
                                        padding: EdgeInsets.all(16.0),
                                      )
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 28,
                              ),
                              SizedBox(width: 420,
                                child: TextFormField(
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
                                  Card(
                                    shape: getRoundedBorder(radius: 8),
                                    elevation: 12,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                        height: 24,
                                        width: 24,
                                        color: color,
                                      ),
                                    ),
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
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
