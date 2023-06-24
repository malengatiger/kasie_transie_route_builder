import 'package:flutter/material.dart';
import 'package:kasie_transie_library/utils/functions.dart';

class ColorPad extends StatelessWidget {
  const ColorPad({Key? key, required this.onColorPicked}) : super(key: key);
  final Function(Color, String) onColorPicked;

  @override
  Widget build(BuildContext context) {
    final colors = <Color>[
      Colors.red,
      Colors.black,
      Colors.white,
      Colors.orange,
      Colors.green,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.yellow,
      Colors.teal,
      Colors.purple,
      Colors.blue,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
          shape: getRoundedBorder(radius: 16),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 320,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 48.0),
                child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisSpacing: 1.8, crossAxisCount: 6, mainAxisSpacing: 1.8),
                    itemCount: colors.length,
                    itemBuilder: (context, index) {
                      var color = colors.elementAt(index);
                      var stringColor = getStringColor(color);

                      return GestureDetector(
                        onTap: () {
                          pp('....... 🍎🍎🍎🍎🍎🍎 color picked ... $stringColor');
                          onColorPicked(color, stringColor);
                        },
                        child: Card(
                          elevation: 4,
                          child: Container(
                            width: 32,
                            height: 32,
                            color: color,
                          ),
                        ),
                      );
                    }),
              ),
            ),
          )),
    );
  }
}

String getStringColor(Color color) {
  var stringColor = 'black';
  switch (color) {
    case Colors.white:
      stringColor = 'white';
      break;
    case Colors.red:
      stringColor = 'red';
      break;
    case Colors.black:
      stringColor = 'black';
      break;
    case Colors.amber:
      stringColor = 'amber';
      break;
    case Colors.yellow:
      stringColor = 'yellow';
      break;
    case Colors.pink:
      stringColor = 'pink';
      break;
    case Colors.purple:
      stringColor = 'purple';
      break;
    case Colors.green:
      stringColor = 'green';
      break;
    case Colors.teal:
      stringColor = 'teal';
      break;
    case Colors.indigo:
      stringColor = 'indigo';
      break;
    case Colors.blue:
      stringColor = 'blue';
      break;
    case Colors.orange:
      stringColor = 'orange';
      break;

    default:
      stringColor = 'black';
      break;
  }
  return stringColor;
}

Color getColor(String stringColor) {
  switch (stringColor) {
    case 'white':
      return Colors.white;
    case 'red':
      return Colors.red;
    case 'black':
      return Colors.black;
    case 'amber':
      return Colors.amber;
    case 'yellow':
      return Colors.yellow;
    case 'pink':
      return Colors.pink;
    case 'purple':
      return Colors.purple;
    case 'green':
      return Colors.green;
    case 'teal':
      return Colors.teal;
    case 'indigo':
      return Colors.indigo;
    case 'blue':
      return Colors.blue;
    case 'orange':
      return Colors.orange;
    default:
      return Colors.black;
  }
}

