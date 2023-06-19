import 'package:dots_indicator/dots_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:kasie_transie_library/auth/phone_auth_signin.dart';
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/data/schemas.dart';
import 'package:kasie_transie_library/providers/kasie_providers.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/prefs.dart';

import '../ui/assoc_routes.dart';
import 'intro_page_one.dart';

class KasieIntro extends StatefulWidget {
  const KasieIntro({
    Key? key,
    // required this.listApiDog,
    required this.dataApiDog,
  }) : super(key: key);

  // final ListApiDog listApiDog;
  final DataApiDog dataApiDog;

  // final Prefs prefs;

  @override
  KasieIntroState createState() => KasieIntroState();
}

class KasieIntroState extends State<KasieIntro>
    with SingleTickerProviderStateMixin {
  final mm = '🍎🍎 KasieIntro 🍎🍎🍎🍎';
  late AnimationController _controller;
  bool authed = false;
  int currentIndexPage = 0;
  final PageController _pageController = PageController();
  fb.FirebaseAuth firebaseAuth = fb.FirebaseAuth.instance;

  // mrm.User? user;
  String? signInFailed;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getAuthenticationStatus();
  }

  void _getAuthenticationStatus() async {
    pp('\n\n$mm _getAuthenticationStatus ....... '
        'check both Firebase user and Kasie user');
    var user = await prefs.getUser();
    var firebaseUser = firebaseAuth.currentUser;

    if (user != null && firebaseUser != null) {
      pp('$mm _getAuthenticationStatus .......  '
          '🥬🥬🥬auth is DEFINITELY authenticated and OK');
      authed = true;
    } else {
      pp('$mm _getAuthenticationStatus ....... NOT AUTHENTICATED! '
          '🌼🌼🌼 ... will clean house!!');
      authed = false;
      //todo - ensure that the right thing gets done!
      // prefs.deleteUser();
      firebaseAuth.signOut();
      pp('$mm _getAuthenticationStatus .......  '
          '🔴🔴🔴🔴'
          'the device should be ready for sign in or registration');
    }
    pp('$mm ......... _getAuthenticationStatus ....... setting state, authed = $authed ');
    setState(() {});
  }

  void onRegistration() {}

  void onSignIn() async {
    var res = await Navigator.of(context).push(MaterialPageRoute(
        builder: (ctx) => PhoneAuthSignin(
            dataApiDog: widget.dataApiDog,
            onSuccessfulSignIn: onSuccessfulSignIn)));
    pp('$mm ... returned from sign in .... $res');
    if (res is User) {
      pp('$mm ... returned from sign in .... $res');
      pp('$mm ... User is fine to this point');

      onSuccessfulSignIn(res);
    }
  }

  void onSuccessfulSignIn(User p1) {
    pp('$mm ... onSuccessfulSignIn .... ${p1.name}');
    Navigator.of(context).pop(p1);
    navigateWithScale(
        AssociationRoutes(AssociationParameter(p1.associationId!, true), p1.associationName!),
        context);
  }

  void _onPageChanged(int value) {}

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;
    var color = getTextColorForBackground(Theme.of(context).primaryColor);

    if (isDarkMode) {
      color = Theme.of(context).primaryColor;
    }
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text(
          'KasieTransie',
          style: myTextStyleLargeWithColor(context, color),
        ),
        bottom: PreferredSize(
            preferredSize: Size.fromHeight(authed ? 80 : 124),
            child: Column(
              children: [
                Card(
                  elevation: 4,
                  color: Colors.black26,
                  // shape: getRoundedBorder(radius: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                              onPressed: onSignIn,
                              child: Text(
                                'Sign In',
                                style:
                                    myTextStyleMediumWithColor(context, color),
                              )),
                          TextButton(
                              onPressed: onRegistration,
                              child: Text(
                                'Register Organization',
                                style:
                                    myTextStyleMediumWithColor(context, color),
                              )),
                        ],
                      ),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.end,
                      //   children: [
                      //     LocaleChooser(
                      //         onSelected: onLanguageSelected,
                      //         color: color,
                      //         hint: introStrings == null
                      //             ? 'Select Language'
                      //             : introStrings!.hint),
                      //   ],
                      // )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
              ],
            )),
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: const [
              IntroPage(
                title: 'KasieTransie',
                assetPath: 'assets/intro/pic2.jpg',
                text: lorem,
              ),
              IntroPage(
                  title: 'Organizations',
                  assetPath: 'assets/intro/pic5.jpg',
                  text: lorem),
              IntroPage(
                  title: 'People',
                  assetPath: 'assets/intro/pic1.jpg',
                  text: lorem),
              IntroPage(
                title: 'Field Monitors',
                assetPath: 'assets/intro/pic5.jpg',
                text: lorem,
              ),
              IntroPage(
                title: 'Thank You',
                assetPath: 'assets/intro/pic3.webp',
                text: lorem,
              ),
            ],
          ),
          Positioned(
            bottom: 2,
            left: 48,
            right: 40,
            child: SizedBox(
              width: 200,
              height: 48,
              child: Card(
                color: Colors.black12,
                shape: getRoundedBorder(radius: 8),
                child: DotsIndicator(
                  dotsCount: 5,
                  position: currentIndexPage,
                  decorator: const DotsDecorator(
                    colors: [
                      Colors.grey,
                      Colors.grey,
                      Colors.grey,
                      Colors.grey,
                      Colors.grey,
                    ], // Inactive dot colors
                    activeColors: [
                      Colors.pink,
                      Colors.blue,
                      Colors.teal,
                      Colors.indigo,
                      Colors.deepOrange,
                    ], // Àctive dot colors
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ));
  }
}
