import 'package:flutter/material.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/schemas.dart';
import 'package:kasie_transie_library/providers/kasie_providers.dart';
import 'package:kasie_transie_library/utils/device_location_bloc.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/prefs.dart';

class CitySearchTwo extends StatefulWidget {
  const CitySearchTwo(
      {Key? key,
      required this.radiusInKM,
      required this.limit,
      required this.onCitySelected})
      : super(key: key);

  final double radiusInKM;
  final int limit;
  final Function(City) onCitySelected;
  @override
  State<CitySearchTwo> createState() => _CitySearchTwoState();
}

class _CitySearchTwoState extends State<CitySearchTwo> {
  bool busy = false;
  User? user;
  List<City> cities = [];
  final mm = '🔷🔷🔷🔷CitySearchTwo 🔷';

  @override
  void initState() {
    super.initState();
    _getCities(widget.radiusInKM);
  }

  void _getCities(double radius) async {
    setState(() {
      busy = true;
    });
    try {
      pp('... starting findCitiesByLocation 1...');
      final loc = await locationBloc.getLocation();
      user = await prefs.getUser();
      pp('... ended location GPS .2..');

      cities = await listApiDog.findCitiesByLocation(LocationFinderParameter(
          associationId: user!.associationId,
          latitude: loc.latitude,
          longitude: loc.longitude,
          limit: 500,
          radiusInKM: radius));
      // _cities.sort((a, b) => a.name!.compareTo(b.name!));
      pp('$mm cities found by location: ${cities.length} cities within $radius km ....');
    } catch (e) {
      pp(e);
    }
    setState(() {
      busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: const Text('City Search'),
        actions: [
          IconButton(
              onPressed: () {
                showSearch(context: context, delegate: CitySearchDelegate(cities));
              },
              icon: const Icon(Icons.search)),
        ],
      ),
    ));
  }
}

class CitySearchDelegate extends SearchDelegate<City> {
  final List<City> cities;

  CitySearchDelegate(this.cities);
  final mm = '🍎🍎🍎🍎🍎CitySearchDelegate 🔷';

  @override
  List<Widget>? buildActions(BuildContext context) {
    pp('$mm buildActions ...');

    return [
      IconButton(
          onPressed: () {
            pp('$mm buildActions on icon clear pressed ...');
            query = '';
          },
          icon: const Icon(Icons.clear)),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    pp('$mm buildLeading ...');

    return IconButton(
        onPressed: () {
          pp('$mm buildLeading on icon back pressed ...');
          close(context, result!);
        },
        icon: const Icon(Icons.arrow_back));
  }

  City? result;
  @override
  Widget buildResults(BuildContext context) {
    pp('$mm buildResults ...');
    var citiesFound = cities
        .where((city) => city.name!.toLowerCase().contains(query.toLowerCase()))
        .toList();
    pp('$mm buildResults ... citiesFound: ${citiesFound.length}');
    return ListView.builder(
        itemCount: citiesFound.length,
        itemBuilder: (ctx, index) {
          final city = citiesFound.elementAt(index);
          return Card(
            child: ListTile(
              leading: const Icon(Icons.location_city),
              title: Text('${city.name}'),
              subtitle: Text('${city.stateName}'),
              onTap: () {
                result = city;
                close(context, city);
              },
            ),
          );
        });
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    pp('$mm buildSuggestions ... cities: ${cities.length}');

    return ListView.builder(
        itemCount: cities.length,
        itemBuilder: (ctx, index) {
          final city = cities.elementAt(index);
          return Card(
            child: ListTile(
              leading: const Icon(Icons.location_city),
              title: Text('${city.name}'),
              subtitle: Text('${city.stateName}'),
            ),
          );
        });
  }
}
