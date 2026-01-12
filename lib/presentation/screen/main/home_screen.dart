import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:neo_banking/common/constants.dart';
import 'package:neo_banking/data/model/transaction_model.dart';
import 'package:neo_banking/data/model/user_model.dart';
import 'package:neo_banking/data/repository/repository.dart';
import 'package:neo_banking/data/utils/greetings.dart';
import 'package:neo_banking/presentation/widget/components.dart';
import 'package:neo_banking/presentation/widget/shimmer.dart';
import 'package:neo_banking/styles/pallet.dart';
import 'package:neo_banking/styles/typography.dart';
import '../auth/authentication_screen.dart';
import 'package:neo_banking/presentation/screen/main/user_profile.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.id});
  static const routeName = '/home-screen';
  final int id;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final List<Map<String, String>> transactions = [];

  static const platform = MethodChannel('forgerock.com/SampleBridge');

  late TabController tabController;
  late TabController contentController;
  bool isShimmer = true;
  String header = "";
  String subtitle = "";

  void initTabController() {
    tabController = TabController(
      length: homeScreenTabbar.length,
      vsync: this,
      initialIndex: 1,
    );
    contentController = TabController(
      length: homeScreenContentTabbar.length,
      vsync: this,
    );
  }

  void getTransaction() async {
    await initializeDateFormatting();
    final data = await Repository().getUsers();
    //transactions.add({
    //  'name': 'Transaction',
    //  'image': '',
    //});
    for (var i = 0; i < data.length; i++) {
      setState(
        () => transactions.add({'name': data[i].name, 'image': data[i].image}),
      );
    }
  }

  void showAlertDialog(BuildContext context) {
    AlertDialog alert = AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          Container(
            margin: const EdgeInsets.only(left: 5),
            child: const Text("Loading"),
          ),
        ],
      ),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<void> _logoutDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: secondary10,
          title: const Text('Do you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Yes',
                style: TextStyle(color: Colors.black.withValues(alpha: 0.8)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
            ),
            TextButton(
              child: Text(
                'No',
                style: TextStyle(color: Colors.black.withValues(alpha: 0.8)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    //final String result =
    await platform.invokeMethod('logout');
    _navigateToNextScreen(context);
  }

  // SDK Calls -  Note the promise type responses. Handle errors on the UI layer as required
  Future<void> _getUserInfo() async {
    //showAlertDialog(context);
    String response;
    try {
      final String result = await platform.invokeMethod('getUserInfo');
      Map<String, dynamic> userInfoMap = jsonDecode(result);
      response = result;
      header = userInfoMap["name"];
      subtitle = userInfoMap["email"];
    } on PlatformException catch (e) {
      response = "SDK Start Failed: '${e.message}'.";
      Navigator.pop(context);
    }
    debugPrint('SDK: $response');
  }

  //Helper funtions
  void _goHome() {
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
  void initState() {
    Future.delayed(
      const Duration(seconds: 2),
      () => setState(() => isShimmer = false),
    );
    initTabController();
    getTransaction();
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      //Calling the userinfo endpoint is going to give use some user profile information to enrich our UI. Additionally, verifies that we have a valid access token.
      _getUserInfo();
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: primary100,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              children: [
                _buildTabBar(),
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * .95,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    color: secondary0,
                  ),
                  padding: const EdgeInsets.only(top: 24),
                  child: TabBarView(
                    controller: tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: List.generate(homeScreenTabbar.length, (index) {
                      switch (index) {
                        case 1:
                          return FutureBuilder(
                            future: Repository().getUserById(id: widget.id),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return isShimmer
                                    ? _buildShimmer()
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildHeader(snapshot),
                                          _buildContentTabBar(),
                                          _buildContentTabBarView(context),
                                          _customTitle(
                                            title: 'Favourite Transactions',
                                          ),
                                          _customContentTransaction(),
                                          _customTitle(
                                            title: 'Recent Activities',
                                          ),
                                          customRecentActivities(),
                                        ],
                                      );
                              } else {
                                return _buildShimmer();
                              }
                            },
                          );
                        default:
                          return Center(
                            child: LottieBuilder.asset(
                              'lib/assets/lotties/lottieComingSoon.json',
                              width: MediaQuery.of(context).size.width * .5,
                              height: MediaQuery.of(context).size.height * .5,
                            ),
                          );
                      }
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Column _buildShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        shimmerHeader(),
        shimmerCard(),
        _customTitle(title: 'Favorite Transactions'),
        shimmerClip(),
        _customTitle(title: 'Recent Activities'),
        shimmerTile(),
      ],
    );
  }

  FutureBuilder<List<Transactions>> customRecentActivities() {
    return FutureBuilder(
      future: Repository().getTransactions(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.separated(
            scrollDirection: Axis.vertical,
            separatorBuilder: (context, index) => customSpaceVertical(8),
            shrinkWrap: true,
            itemCount: snapshot.data!.length > 3 ? 3 : snapshot.data!.length,
            itemBuilder: (context, listIndex) {
              final data = snapshot.data![listIndex];
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: primary90,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      imageUrl: data.image.toString(),
                      placeholder: (context, url) =>
                          customText(textValue: data.name.split('')[0]),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  ),
                  title: customText(
                    textValue: data.name,
                    textStyle: subHeadline4.copyWith(color: secondary0),
                  ),
                  subtitle: customText(
                    textValue: DateFormat(
                      'dd MMMM yyyy',
                      'id_ID',
                    ).format(data.date),
                    textStyle: bodyText2.copyWith(color: secondary0),
                  ),
                  trailing: customText(
                    textValue: '- GBP ${data.priceGbp}',
                    textStyle: bodyText2.copyWith(color: secondary0),
                  ),
                ),
              );
            },
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  SizedBox _customContentTransaction() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        separatorBuilder: (context, index) => customSpaceHorizontal(8),
        itemCount: transactions.length,
        itemBuilder: (context, transactionIndex) {
          final data = transactions[transactionIndex];
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: secondary20),
              borderRadius: BorderRadius.circular(40),
              color: transactionIndex == 0 ? primary90 : secondary0,
            ),
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Visibility(
                  visible: data['name'] == 'Transaction' ? true : false,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Icon(Icons.add, color: secondary0),
                  ),
                ),
                Visibility(
                  visible: data['name'] == 'Transaction' ? false : true,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image(
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      image: AssetImage(data['image'].toString()),
                    ),
                  ),
                ),
                customSpaceHorizontal(8),
                customText(
                  textValue: data['name'].toString(),
                  textStyle: bodyText2.copyWith(
                    color: transactionIndex == 0 ? secondary0 : text,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Padding _customTitle({required String title}) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 24, bottom: 8),
      child: customText(textValue: title, textStyle: subHeadline3),
    );
  }

  SizedBox _buildContentTabBarView(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * .3,
      child: TabBarView(
        controller: contentController,
        children: List.generate(
          contentController.length,
          (index) => FutureBuilder(
            future: Repository().getBalances(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  separatorBuilder: (context, index) =>
                      customSpaceHorizontal(10),
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, cardIndex) {
                    final data = snapshot.data![cardIndex];
                    return Container(
                      width: MediaQuery.of(context).size.width * .6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [primary100, primary90, primary80],
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              customText(
                                textValue: contentController.index == 0
                                    ? '${data.cardName} Account'
                                    : '${data.cardName} Card',
                                textStyle: headline4.copyWith(
                                  color: secondary0,
                                ),
                              ),
                              customSpaceVertical(4),
                              customText(
                                textValue: data.cardNumber,
                                textStyle: subHeadline5.copyWith(
                                  color: secondary0,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              customText(
                                textValue: 'Balance',
                                textStyle: bodyText1.copyWith(
                                  color: secondary0,
                                ),
                              ),
                              customSpaceVertical(8),
                              customText(
                                textValue: 'GBP ${data.balance}',
                                textStyle: headline4.copyWith(
                                  color: secondary0,
                                ),
                              ),
                              customSpaceVertical(8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(
                                  2,
                                  (index) => customButton(
                                    buttonWidth:
                                        MediaQuery.of(context).size.width * .25,
                                    buttonOnTap: () {},
                                    buttonText: index == 0 ? 'MOVE' : 'QRIS',
                                    buttonFirstGradientColor: secondary0,
                                    buttonSecondGradientColor: secondary0,
                                    buttonPadding: const EdgeInsets.all(8),
                                    buttonBorderRadius: BorderRadius.circular(
                                      8,
                                    ),
                                    buttonLeftIcon: index == 0
                                        ? const Icon(
                                            Icons.wallet_rounded,
                                            color: primary90,
                                          )
                                        : const Icon(
                                            Icons.qr_code_rounded,
                                            color: primary90,
                                          ),
                                    isButtonIcon: true,
                                    textStyles: subHeadline5.copyWith(
                                      color: primary80,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          customText(
                            textValue: 'Exp ${data.expiryDate}',
                            textStyle: bodyText2.copyWith(color: secondary0),
                          ),
                        ],
                      ),
                    );
                  },
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),
    );
  }

  TabBar _buildContentTabBar() {
    return TabBar(
      controller: contentController,
      indicatorPadding: const EdgeInsets.only(bottom: 8),
      indicatorSize: TabBarIndicatorSize.label,
      isScrollable: true,
      labelColor: text,
      unselectedLabelColor: secondary20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      tabAlignment: TabAlignment.start,
      tabs: List.generate(
        homeScreenContentTabbar.length,
        (index) => Tab(text: homeScreenContentTabbar[index]),
      ),
    );
  }

  Padding _buildHeader(AsyncSnapshot<Users?> snapshot) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          PopupMenuButton(
            color: secondary10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Image(
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                image: AssetImage(snapshot.data!.image),
              ),
            ),
            onSelected: (value) {
              if (value == "profile") {
                // add desired output
                Navigator.pushNamed(context, UserProfile.routeName);
              } else if (value == "logout") {
                // add desired output
                _logoutDialog();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry>[
              PopupMenuItem(
                value: "profile",
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.person),
                    ),
                    const Text('Profile', style: TextStyle(fontSize: 15)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: "logout",
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.logout),
                    ),
                    const Text('Logout', style: TextStyle(fontSize: 15)),
                  ],
                ),
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              2,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: customText(
                  textValue:
                      //index == 0 ? greetingsFunction() : snapshot.data!.name,
                      index == 0 ? greetingsFunction() : header,
                  textStyle: index == 0 ? subHeadline5 : headline4,
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () {},
            child: Container(
              decoration: BoxDecoration(
                color: secondary10.withOpacity(.5),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(10),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: primary100,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TabBar _buildTabBar() {
    return TabBar(
      controller: tabController,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      splashBorderRadius: BorderRadius.circular(40),
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        color: secondary0,
      ),
      labelColor: primary80,
      unselectedLabelColor: secondary0,
      tabs: List.generate(
        homeScreenTabbar.length,
        (index) => Tab(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(homeScreenTabbar[index]['icon']),
              customSpaceHorizontal(4),
              customText(
                textValue: homeScreenTabbar[index]['name'].toString(),
                textStyle: subHeadline5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
