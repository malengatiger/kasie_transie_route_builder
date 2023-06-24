import 'package:flutter/material.dart';
import 'package:kasie_transie_library/utils/functions.dart';

class SearchingCitiesBusy extends StatelessWidget {
  const SearchingCitiesBusy({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return  Center(
      child: SizedBox(
        height: 160,
        child: Card(
          shape: getRoundedBorder(radius: 16),
          elevation: 16,
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(height:18,width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    backgroundColor: Colors.pink,
                  ),
                ),
                SizedBox(
                  height: 24,
                ),
                Text('Searching for cities, towns and places around you ... ')
              ],
            ),
          ),
        ),
      ),
    );
  }
}
