import 'package:flutter/material.dart';
import 'package:neo_banking/presentation/screen/auth/authentication_screen.dart';
import 'package:flutter/services.dart';

import 'utils/images.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  static const routeName = '/splash';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  void navigateToOtherScreen() => Future.delayed(
    const Duration(seconds: 3),
    () =>
        Navigator.pushReplacementNamed(context, AuthenticationScreen.routeName),
  );

  //Method channel as defined in the native Bridge code
  static const platform = MethodChannel('forgerock.com/SampleBridge');

  @override
  void initState() {
    super.initState();
    _startSDK();
    navigateToOtherScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Image.asset(logo_2, fit: BoxFit.cover)),
    );
  }

  // SDK Calls -  Note the promise type responses. Handle errors on the UI layer as required
  Future<void> _startSDK() async {
    String response;
    try {
      //Start the SDK. Call the frAuthStart channel method to initialise the native SDKs
      final String result = await platform.invokeMethod('frAuthStart');
      //response = 'SDK Started';
      debugPrint('SDK method _startSDK() executed, result $result');
    } on PlatformException catch (e) {
      response = "SDK Start Failed: '${e.message}'.";
    }
  }
}
