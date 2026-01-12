import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:lottie/lottie.dart';
import 'package:neo_banking/presentation/widget/components.dart';
import 'package:neo_banking/styles/pallet.dart';
import 'package:neo_banking/styles/typography.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../utils/images.dart';
import '../auth/authentication_screen.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});
  static const routeName = '/profile';

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile>
    with TickerProviderStateMixin {
  static const platform = MethodChannel('forgerock.com/SampleBridge');

  final TextEditingController searchController = TextEditingController();

  bool isLoading = true;
  bool isDeviceBound = false;

  String? errorText;
  String? userInfo = "";

  @override
  void initState() {
    Future.delayed(
      const Duration(seconds: 2),
      () => setState(() => isLoading = false),
    );
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      //Calling the userinfo endpoint is going to give use some user profile information to enrich our UI. Additionally, verifies that we have a valid access token.
      _getUserInfo();
      _isDeviceBound();
    });
  }

  // SDK Calls -  Note the promise type responses. Handle errors on the UI layer as required
  Future<void> _getUserInfo() async {
    String response;
    try {
      final String result = await platform.invokeMethod('getUserInfo');
      response = result;
      userInfo = result;
    } on PlatformException catch (e) {
      response = "SDK Start Failed: '${e.message}'.";
      Navigator.pop(context);
    }
    debugPrint('SDK: $response');
  }

  // SDK Calls -  Note the promise type responses. Handle errors on the UI layer as required
  Future<void> _isDeviceBound() async {
    String message;
    bool response;
    try {
      final bool result = await platform.invokeMethod('isDeviceBound');
      response = result;
      if (result) {
        message = "true";
        isDeviceBound = true;
      } else {
        message = "false";
        isDeviceBound = false;
      }
      //userInfo = result;
    } on PlatformException catch (e) {
      message = "SDK isDeviceBound Failed: '${e.message}'.";
      Navigator.pop(context);
    }
    debugPrint('SDK isDeviceBound: $message');
  }

  // SDK Calls -  Note the promise type responses. Handle errors on the UI layer as required
  Future<void> _unbindDevice() async {
    String response;
    try {
      final String result = await platform.invokeMethod('unbindDevice');
      response = result;
      debugPrint('SDK device unbind result: $result');
      _logout();
    } on PlatformException catch (e) {
      response =
          "SDK method _unbindDevice() failed with error: '${e.message}'.";
      //Navigator.pop(context);
    }
    debugPrint('SDK method _unbindDevice() result: $response');
  }

  Future<void> _logout() async {
    //final String result =
    await platform.invokeMethod('logout');
    _navigateToNextScreen(context);
  }

  //Helper funtions
  void _goHome() {
    //Navigator.pop(context);

    Navigator.pushNamed(
      context,
      AuthenticationScreen.routeName,
      arguments: null,
    );
  }

  void _navigateToNextScreen(BuildContext context) {
    _goHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: secondary0,
        elevation: 0,
        leadingWidth: 72,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          splashRadius: 20,
          icon: const Icon(Icons.arrow_back_ios),
          color: primary90,
        ),
      ),
      body: isLoading
          ? Center(
              child: LottieBuilder.asset(
                'lib/assets/lotties/lottieLoading.json',
                width: MediaQuery.of(context).size.width * .5,
              ),
            )
          : Container(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    30.height,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Settings',
                          style: boldTextStyle(
                            size: 30,
                            color: textColorPrimary,
                          ),
                        ),
                      ],
                    ),
                    20.height,
                    Container(
                      decoration: boxDecorationWithShadow(
                        backgroundColor: whitePureColour,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ID Info',
                            style: primaryTextStyle(
                              size: 20,
                              fontFamily: fontMedium,
                            ),
                          ),
                          30.height,
                          Row(
                            children: [
                              Image.asset(
                                icPin,
                                height: 30,
                                width: 20,
                                color: palColour,
                              ),
                              15.width,
                              Expanded(
                                child: Text(
                                  userInfo!,
                                  style: primaryTextStyle(
                                    color: textColorSecondary,
                                    size: 10,
                                    fontFamily: fontRegular,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          30.height,
                        ],
                      ),
                    ),
                    20.height,
                    Container(
                      decoration: boxDecorationWithShadow(
                        backgroundColor: whitePureColour,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Device binding",
                            style: primaryTextStyle(
                              size: 18,
                              fontFamily: fontMedium,
                            ),
                          ),
                          20.height,
                          Offstage(
                            offstage: !isDeviceBound,
                            child: Row(
                              children: [
                                Image.asset(
                                  icSecurity,
                                  height: 20,
                                  width: 20,
                                  color: blueColour,
                                ),
                                15.width,
                                customButton(
                                  buttonOnTap: () {
                                    _unbindDevice();
                                  },
                                  textStyles: bodyText2.copyWith(
                                    color: secondary0,
                                  ),
                                  buttonText: 'Unbind device (logs you out)',
                                  buttonFirstGradientColor: primary90,
                                  buttonSecondGradientColor: primary90,
                                  buttonWidth:
                                      MediaQuery.of(context).size.width * 0.65,
                                ),
                              ],
                            ),
                          ),
                          if (isDeviceBound == false)
                            customText(
                              textValue:
                                  'If you have bound your device you will be able to unbind it here.',
                              textStyle: bodyText2.copyWith(color: text),
                              textAlign: TextAlign.justify,
                            ),
                          15.height,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
