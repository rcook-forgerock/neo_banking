// ignore_for_file: use_build_context_synchronously

//import 'dart:nativewrappers/_internal/vm/lib/ffi_allocation_patch.dart';

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:focus_detector/focus_detector.dart';

import 'package:neo_banking/aic/fr_callback.dart';
import 'package:neo_banking/aic/fr_node.dart';

import 'package:neo_banking/common/constants.dart';
import 'package:neo_banking/presentation/screen/main/home_screen.dart';
import 'package:neo_banking/presentation/screen/utils/images.dart';
import 'package:neo_banking/presentation/widget/components.dart';
import 'package:neo_banking/styles/pallet.dart';
import 'package:neo_banking/styles/typography.dart';

import 'package:loader_overlay/loader_overlay.dart';

class AuthTypeLabel {
  String? value;
  String? label;
}

class DropdownChoice {
  final String code;
  final int choice;

  DropdownChoice({required this.code, required this.choice});
}

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});
  static const routeName = '/authentication';

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

//typedef MenuEntry = DropdownMenuEntry<String>;
//typedef AuthTypeEntry = DropdownMenuEntry<AuthTypeLabel>;
//final List<String> dropDownEntries = <String>[];
List<DropdownChoice> menuChoices = [];

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final PageController pageController = PageController();
  final List<TextEditingController> logInControllers = List.generate(
    logInTextFieldProperties.length,
    (_) => TextEditingController(),
  );
  final List<TextEditingController> signUpControllers = List.generate(
    signUpTextFieldProperties.length,
    (_) => TextEditingController(),
  );

  final List<TextEditingController> _controllers = [];

  //int choiceValue = 0;
  //bool isChecked = false;
  bool checkboxValue1 = false;
  bool journeyStarted = false;

  List<String> logInErrorTexts = List.generate(
    logInTextFieldProperties.length,
    (_) => '',
  );
  List<String> signUpErrorTexts = List.generate(
    signUpTextFieldProperties.length,
    (_) => '',
  );
  int pageIndex = 0;
  bool isPasswordObscure = true;

  //Flutter bridge method channel
  static const platform = MethodChannel(
    'forgerock.com/SampleBridge',
  ); //Method channel as defined in the native Bridge code

  //Object for parsing journey callbacks
  FRNode? currentNode;

  //final List<TextField> _fields = [];
  final List<Text> _messages = [];
  final List<Widget> _choiceButtons = [];
  final List<Widget> _uiWidgets = [];

  // Vital for identifying our FocusDetector when a rebuild occurs.
  final Key _focusDetectorKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return FocusDetector(
      key: _focusDetectorKey,
      onFocusGained: () {
        print('CharacterListPage gains focus');
        currentNode = null;
        //_fields.clear();
        //_controllers.clear();
        //_startSDK();
        _login();
      },
      onFocusLost: () {
        print('CharacterListPage lost focus');
      },
      child: LoaderOverlay(
        child: Scaffold(
          body: SafeArea(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Visibility(
                    visible: MediaQuery.of(context).viewInsets.bottom == 0,
                    child: Column(
                      children: [
                        //Image.asset('lib/assets/images/logo.png'),
                        Image.asset(logo_2),
                        Visibility(
                          visible: pageIndex == 0 || pageIndex == 1,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Column(
                              children: [
                                /** 
                              customText(
                                textValue: pageIndex == 0
                                    ? 'Log in Now'
                                    : 'Sign Up Now',
                                textStyle: headline2.copyWith(color: text),
                                textAlign: TextAlign.center,
                              ),
                              customSpaceVertical(8),
                              customText(
                                textValue: pageIndex == 0
                                    ? 'Please log in to continue using app'
                                    : 'Please fill details to create an account',
                                textStyle: bodyText2.copyWith(color: text),
                                textAlign: TextAlign.center,
                              ),
                              */
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: pageController,
                      onPageChanged: (newPageIndex) =>
                          setState(() => pageIndex = newPageIndex),
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 3,
                      itemBuilder: (context, index) => Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          //_buildFRLogin(index),
                          _buildContent(index),
                          //_buildButton(context),
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                    visible: MediaQuery.of(context).viewInsets.bottom == 0,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        height: 10,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          separatorBuilder: (context, index) =>
                              customSpaceHorizontal(8),
                          shrinkWrap: true,
                          itemCount: 2,
                          itemBuilder: (context, index) => Container(
                            width: 30,
                            height: 10,
                            decoration: BoxDecoration(
                              color: pageIndex == index
                                  ? primary100
                                  : secondary20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // SDK Calls -  Note the promise type responses. Handle errors on the UI layer as required
  Future<void> _startSDK() async {
    //String response;
    try {
      //Start the SDK. Call the frAuthStart channel method to initialise the native SDKs
      await platform.invokeMethod('frAuthStart');
      //response = 'SDK Started';
      debugPrint('SDK Started');
    } on PlatformException catch (e) {
      //response = "SDK Start Failed: '${e.message}'.";
      debugPrint('SDK Start Failed: ${e.message}.');
    }
  }

  // SDK Calls -  Note the promise type responses. Handle errors on the UI layer as required
  Future<void> _startRegisterUserJourney() async {
    String response;
    try {
      //Start the SDK. Call the frAuthStart channel method to initialise the native SDKs

      debugPrint('_startRegisterSDKJourney called');
      //_fields.clear();
      _controllers.clear();
      _messages.clear();
      _choiceButtons.clear();
      _uiWidgets.clear();

      //Call the default login tree.
      final String result = await platform.invokeMethod('register');

      Map<String, dynamic> frNodeMap = jsonDecode(result);
      var frNode = FRNode.fromJson(frNodeMap);
      currentNode = frNode;

      debugPrint(
        'Flutter ran the _startRegisterSDKJourney method and got: $frNode',
      );

      //Upon completion, a node with callbacks will be returned, handle that node and present the callbacks to UI as needed.
      _handleNode(frNode);

      response = 'SDK frRegisterStart started';
    } on PlatformException catch (e) {
      response = "SDK frRegisterStart Failed: '${e.message}'.";
    }
  }

  Padding _buildFRLogin() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [_messageListView(), _uiWidgetListView()]),
    );
  }

  Padding _buildFRRegister(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [_messageListView(), _listView(), _messageButtonListView()],
      ),
    );
  }

  Padding _buildContent(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Visibility(
            visible: pageIndex == 0,
            child: Column(
              children: [
                _buildFRLogin(),
                customSpaceVertical(10),
                Visibility(
                  visible: journeyStarted == false,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      customText(
                        textValue: pageIndex == 0
                            ? 'Don\'t have an account?'
                            : 'Already have an account?',
                        textStyle: bodyText2.copyWith(color: text),
                      ),
                      customSpaceHorizontal(4),
                      InkWell(
                        onTap: () {
                          _startRegisterUserJourney();
                          pageController.animateToPage(
                            1,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        },
                        child: customText(
                          textValue: 'Sign Up',
                          textStyle: subHeadline5.copyWith(color: primary100),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Visibility(
            visible: pageIndex == 1,
            child: Column(
              children: [
                _buildFRLogin(),
                customSpaceVertical(16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    customText(
                      textValue: 'Already have an account?',
                      textStyle: bodyText2.copyWith(color: text),
                    ),
                    customSpaceHorizontal(4),
                    InkWell(
                      onTap: () {
                        pageController.animateToPage(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                        _startSDK();
                        _login();
                      },
                      child: customText(
                        textValue: 'Log in',
                        textStyle: subHeadline5.copyWith(color: primary100),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    try {
      //_fields.clear();
      _controllers.clear();
      _messages.clear();
      _choiceButtons.clear();
      _uiWidgets.clear();
      context.loaderOverlay.show();

      //Call the default login tree.
      final String result = await platform.invokeMethod('login');

      Map<String, dynamic> frNodeMap = jsonDecode(result);
      var frNode = FRNode.fromJson(frNodeMap);
      currentNode = frNode;
      debugPrint('Flutter ran the _login method and got: $frNode');

      //Upon completion, a node with callbacks will be returned, handle that node and present the callbacks to UI as needed.
      _handleNode(frNode);

      context.loaderOverlay.hide();
    } on PlatformException catch (e) {
      debugPrint('SDK Error from _login: $e');
      Navigator.pop(context);
    }
  }

  Future<void> _handleButtonChoice(int choiceValue) async {
    currentNode?.callbacks.asMap().forEach((index, frCallback) {
      if (frCallback.type == "ChoiceCallback") {
        debugPrint('ChoiceCallback value: $choiceValue');
        frCallback.input[0].value = choiceValue;
      }
    });
  }

  Future<void> _handleConfirmationCallbackChoice(int choiceValue) async {
    currentNode?.callbacks.asMap().forEach((index, frCallback) {
      if (frCallback.type == "ConfirmationCallback") {
        debugPrint('ConfirmationCallback value: $choiceValue');
        frCallback.input[0].value = choiceValue;
        _next();
      }
    });
  }

  void printWrapped(String text) {
    final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(text).forEach((match) => print(match.group(0)));
  }

  Future<void> _next() async {
    if (!journeyStarted) {
      journeyStarted = true;
    }
    final isVisible = context.loaderOverlay.visible;

    if (!isVisible) {
      context.loaderOverlay.show();
    }

    // Capture the User Inputs from the UI, populate the currentNode callbacks and submit back to AM
    currentNode?.callbacks.asMap().forEach((index, frCallback) {
      _controllers.asMap().forEach((controllerIndex, controller) {
        if (controllerIndex == index) {
          frCallback.input[0].value = controller.text;
        }
      });
    });

    String jsonResponse = jsonEncode(currentNode);

    //Uncomment to see payload to be sent
    //debugPrint('Callback output after: $jsonResponse');

    try {
      // Call the SDK next method, to submit the User Inputs to AM. This will return the next Node or a Success/Failure
      String result = await platform.invokeMethod('next', jsonResponse);

      //Uncomment to see result of callback
      //printWrapped('Callback output after next bridge method: $result');

      if (result.contains("webAuthnOutcome")) {
        debugPrint(
          'The response from the next method contains a webAuthnOutcome, calling next method to handle WebAuthn request.',
        );

        context.loaderOverlay.hide();

        _next();
      } else {
        Map<String, dynamic> response = jsonDecode(result);

        if (response["type"] == "LoginSuccess") {
          context.loaderOverlay.hide();

          showLoadingDialog(context);

          showSuccessDialog(
            context,
            message: 'Login Success',
            onAction: () => Navigator.pushNamed(
              context,
              HomeScreen.routeName,
              arguments: 5,
            ),
          );
        } else {
          //If a new node is returned, handle this in a similar way and resubmit the user inputs as needed.
          var frNode = FRNode.fromJson(response);
          currentNode = frNode;
          _controllers.clear();
          _messages.clear();
          _choiceButtons.clear();
          _uiWidgets.clear();
          _handleNode(frNode);
        }
      }
    } catch (e) {
      debugPrint('SDK Error _next: $e');
      showErrorDialog(
        context,
        message: 'Sorry, we could not authenticate you.',
      );
      _login();
    }
  }

  // Handling methods
  Future<void> _handleNode(FRNode frNode) async {
    context.loaderOverlay.hide();

    String? description = frNode.description;
    if (description != null) {
      setState(() {
        _messages.add(
          customText(
            textValue: description,
            textStyle: bodyText1.copyWith(color: text),
            textAlign: TextAlign.left,
          ),
        );
      });
    }

    Iterable types = frNode.callbacks.toList().map((element) => element.type);
    String? stage = frNode.stage;
    bool addNextButton = false;

    if (!types.contains("ConfirmationCallback") &&
        !types.contains("DeviceBindingCallback") &&
        !types.contains("DeviceSigningVerifierCallback")) {
      if (stage != null) {
        Map<String, dynamic>? response2 = jsonDecode(frNode.stage!);
        Map<String, dynamic>? submitButtonText;
        String? en;

        if (response2!.containsKey("submitButtonText")) {
          submitButtonText = response2["submitButtonText"];
        }

        if (submitButtonText!.containsKey("en")) {
          en = submitButtonText["en"];
          _choiceButtons.add(_okButton(en));
        } else {
          addNextButton = true;
        }
      }

      if (addNextButton || (stage == null)) {
        _choiceButtons.add(_okButton("Next"));
      }
    }

    debugPrint('FRNode types: $types');

    // Go through the node callbacks and present the UI fields as needed. Check for the type of each callback to determine, what UI element is needed.
    for (final FRCallback frCallback in frNode.callbacks) {
      if (frCallback.type == "DeviceSigningVerifierCallback" ||
          frCallback.type == "DeviceBindingCallback") {
        debugPrint(
          'Response contains either DeviceSigningVerifierCallback or DeviceBindingCallback, returning to next method to execute callback.',
        );
        _next();
      } else if (frCallback.type == "TextOutputCallback") {
        var message = frCallback.output[0].value;

        final message1 = customText(
          textValue: message,
          textStyle: bodyText1.copyWith(color: text),
          textAlign: TextAlign.left,
        );

        setState(() {
          _uiWidgets.add(message1);
        });

        debugPrint('TextOutputCallback value: $message');
      } else if (frCallback.type == "BooleanAttributeInputCallback") {
        //This is just for view rendering, the Checkboxes for handling BooleanAttributeInputCallback won't work when
        //the Checkbox itself is added to the Widget array using setState like below as the view doesn't get updated
        //upon being checked. They would need to be created dynamically with just the value set in the state.

        final checkBox = Row(
          children: [
            Expanded(
              child: Text(
                frCallback.output[1].value,
                style: const TextStyle(fontSize: 15.0),
              ),
            ),
            Expanded(
              child: Checkbox(
                checkColor: Colors.white,
                activeColor: primary90,
                value: checkboxValue1,
                onChanged: (bool? value) {
                  setState(() {
                    checkboxValue1 = !value!;
                  });
                },
              ),
            ),
          ],
        );

        setState(() {
          _uiWidgets.add(checkBox);
        });
      } else if (frCallback.type == "ConfirmationCallback") {
        for (int i = 0; i < frCallback.output.toList().length; i++) {
          if (frCallback.output[i].name == "options") {
            for (int j = 0; j < frCallback.output[i].value.length; j++) {
              String buttonText = frCallback.output[i].value[j];
              debugPrint('ConfirmationCallback options>> $buttonText');

              var confirmationButton = customButton(
                buttonOnTap: () {
                  _handleConfirmationCallbackChoice(j);
                },
                buttonText: buttonText,
                buttonFirstGradientColor: primary80,
                buttonSecondGradientColor: primary90,
                buttonWidth: MediaQuery.of(context).size.width * 0.65,
              );

              setState(() {
                _choiceButtons.add(confirmationButton);
              });
            }
          }
        }
      } else if (frCallback.type == "ChoiceCallback") {
        menuChoices = [];
        var index = 0;
        frCallback.output[1].value.forEach(
          (auth) => {
            menuChoices.add(DropdownChoice(code: auth, choice: index++)),
          },
        );

        final controller = TextEditingController();
        var menu = Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            DropdownMenu(
              width: 250,
              controller: controller,
              initialSelection: menuChoices[frCallback.output[2].value],
              label: Text(frCallback.output[0].value),
              onSelected: (DropdownChoice? authType) {
                _handleButtonChoice(authType!.choice);
              },
              dropdownMenuEntries: [
                for (var choice in menuChoices)
                  DropdownMenuEntry(label: choice.code, value: choice),
              ],
            ),
          ],
        );

        setState(() {
          _uiWidgets.add(menu);
        });
      } else {
        var labelTextValue = "";
        if (frCallback.type == "StringAttributeInputCallback") {
          labelTextValue = frCallback.output[1].value;
        } else {
          labelTextValue = frCallback.output[0].value;
        }

        final controller = TextEditingController();
        final field = TextField(
          controller: controller,
          obscureText:
              frCallback.type ==
              "PasswordCallback", // If the callback type is 'PasswordCallback', make this a 'secure' textField.
          enableSuggestions: false,
          autocorrect: false,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.black, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.teal, width: 1.0),
            ),
            labelText: labelTextValue,
          ),
        );
        setState(() {
          _controllers.add(controller);
          _uiWidgets.add(field);
        });
      }
    }
  }

  // Widgets
  Widget _listView() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.all(15.0),
          child: Column(children: [_messages[index++]]),
        );
      },
    );
  }

  Widget _messageListView() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.all(15.0),
          child: Column(children: [_messages[index]]),
        );
      },
    );
  }

  Widget _messageButtonListView() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _choiceButtons.length,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(14),
          child: Column(children: [_choiceButtons[index]]),
        );
      },
    );
  }

  void addButtonWidgets() {
    for (var item in _choiceButtons) {
      _uiWidgets.add(item);
    }
    _choiceButtons.clear();
  }

  Widget _uiWidgetListView() {
    //add buttons at the end
    addButtonWidgets();
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _uiWidgets.length,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(12.0),
          child: Column(children: [_uiWidgets[index]]),
        );
      },
    );
  }

  Widget _okButton(text) {
    return Container(
      color: Colors.transparent,
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.all(15.0),
      height: 60,
      child: TextButton(
        style: TextButton.styleFrom(backgroundColor: primary80),
        onPressed: () async {
          _next();
        },
        child: Text(text, style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void showAlertDialog(BuildContext context) {
    AlertDialog alert = AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          Container(margin: EdgeInsets.only(left: 5), child: Text("Loading")),
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
}
