import 'package:animations/animations.dart';
import 'package:app/blocs/blocs.dart';
import 'package:app/models/models.dart';
import 'package:app/screens/on_boarding/profile_setup_screen.dart';
import 'package:app/screens/on_boarding/setup_complete_screeen.dart';
import 'package:app/screens/on_boarding/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

import '../../services/app_service.dart';
import '../../services/firebase_service.dart';
import '../../services/local_storage.dart';
import '../../services/location_service.dart';
import '../auth/phone_auth_widget.dart';
import '../home_page.dart';
import 'location_setup_screen.dart';
import 'notifications_setup_screen.dart';
import 'on_boarding_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
  });

  @override
  State<SplashScreen> createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  int _widgetId = 0;
  bool _visible = false;
  final AppService _appService = AppService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageTransitionSwitcher(
        duration: const Duration(seconds: 3),
        transitionBuilder: (
          child,
          animation,
          secondaryAnimation,
        ) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            child: child,
          );
        },
        child: _renderWidget(),
      ),
    );
  }

  Future<void> initialize() async {
    context.read<FeedbackBloc>().add(const ClearFeedback());
    context.read<NearbyLocationBloc>().add(const CheckNearbyLocations());

    final isLoggedIn = CustomAuth.isLoggedIn();

    final nextPage = getOnBoardingPageConstant(
      await SharedPreferencesHelper.getOnBoardingPage(),
    );

    Future.delayed(const Duration(seconds: 1), _updateWidget);

    /// TODO add loading indicator to all onboarding pages
    Future.delayed(
      const Duration(seconds: 5),
      () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) {
            if (!isLoggedIn) {
              return const WelcomeScreen();
            } else {
              switch (nextPage) {
                case OnBoardingPage.signup:
                  return const PhoneSignUpWidget();
                case OnBoardingPage.profile:
                  return const ProfileSetupScreen();
                case OnBoardingPage.notification:
                  return const NotificationsSetupScreen();
                case OnBoardingPage.location:
                  return const LocationSetupScreen();
                case OnBoardingPage.complete:
                  return const SetUpCompleteScreen();
                case OnBoardingPage.home:
                  return const HomePage(refresh: false);
                default:
                  return const WelcomeScreen();
              }
            }
          }),
          (r) => false,
        );
      },
    );

    await _appService.fetchData(context);

    await LocationService.listenToLocationUpdates();
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Widget logoWidget() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icon/splash_image.svg',
              semanticsLabel: 'Share',
              // height: 118,
              // width: 81,
            ),
          ],
        ),
      ),
    );
  }

  Widget taglineWidget() {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      // The green box must be a child of the AnimatedOpacity widget.
      child: Center(
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            Image.asset(
              'assets/images/splash-image.png',
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
              alignment: Alignment.center,
            ),
            Text(
              'Breathe\nClean.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headline4
                  ?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderWidget() {
    return _widgetId == 0 ? logoWidget() : taglineWidget();
  }

  void _updateWidget() {
    setState(
      () {
        _visible = true;
        _widgetId = _widgetId == 0 ? 1 : 0;
      },
    );
  }
}
