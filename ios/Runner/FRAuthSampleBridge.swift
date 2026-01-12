/*
 * Copyright (c) 2022 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import FRAuth
import FRCore
import FRDeviceBinding
import Flutter
import Foundation
import JGProgressHUD
import UIKit

/// A struct that holds the configuration constants for the authentication journey.
struct Configuration {
    /// The main authentication journey name.
    static let mainAuthenticationJourney = "LoginWithDeviceBindingOrWebAuthn"
    /// The main registration journey name.
    static let mainRegistrationJourney = "RegistrationBankingDemo"
    /// The URL of the authentication server.
    static let amURL = "https://openam-rcook.forgeblocks.com/am"
    /// The name of the cookie used for authentication.
    static let cookieName = "df42bd6d9053578"
    /// The realm used for authentication.
    static let realm = "alpha"
    /// The OAuth client ID.
    static let oauthClientId = "SDKTest"
    /// The OAuth redirect URI.
    static let oauthRedirectURI = "org.forgerock.demo://oauth2redirect"
    /// The OAuth scopes.
    static let oauthScopes = "openid profile email address"
    /// The discovery endpoint for OAuth configuration.
    static let discoveryEndpoint = "https://openam-rcook.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration"
}

/// A class that bridges the FRAuth functionality to Flutter.
public class FRAuthSampleBridge {

    @IBOutlet weak var faceIDSwitch: UISwitch!
    //private var currentNode: Node?
    private let hud = JGProgressHUD()

    /// The current authentication node.
    var currentNode: Node?
    /// The URL session used for network requests.
    private let session = URLSession(configuration: .default)

    /**
     Starts the FRAuth authentication process.
    
     - Parameter result: The result callback to be called upon completion.
     */
    @objc func frAuthStart(result: @escaping FlutterResult) {
        // Set log level according to your needs
        FRLog.setLogLevel([.all])

        do {

            let options = FROptions(
                url: Configuration.amURL,
                realm: Configuration.realm,
                cookieName: Configuration.cookieName,
                authServiceName: Configuration.mainAuthenticationJourney,
                registrationServiceName: Configuration.mainRegistrationJourney,
                oauthClientId: Configuration.oauthClientId,
                oauthRedirectUri: Configuration.oauthRedirectURI,
                oauthScope: Configuration.oauthScopes
            )
            try FRAuth.start(options: options)
            result("SDK Initialised")
            FRUser.currentUser?.logout()
        } catch {
            FRLog.e(error.localizedDescription)
            result(
                FlutterError(
                    code: "SDK Init Failed",
                    message: error.localizedDescription,
                    details: nil
                )
            )
        }
    }

    /**
     Logs in the user.
    
     - Parameter result: The result callback to be called upon completion.
     */
    @objc func login(result: @escaping FlutterResult) {
        FRUser.login { (user, node, error) in
            self.handleNode(user, node, error, completion: result)
        }
    }

    /**
     Registers a new user.
    
     - Parameter result: The result callback to be called upon completion.
     */
    @objc func register(result: @escaping FlutterResult) {
        FRUser.register { (user, node, error) in
            self.handleNode(user, node, error, completion: result)
        }
    }

    /**
     Logs out the current user from FRAuth.
    
     - Parameter result: The result callback to be called upon completion.
     */
    @objc func frLogout(result: @escaping FlutterResult) {
        FRUser.currentUser?.logout()
        result("User logged out")
    }

    /**
     Retrieves the current user's information.
    
     - Parameter result: The result callback to be called upon completion.
     */
    @objc func getUserInfo(result: @escaping FlutterResult) {
        FRUser.currentUser?.getUserInfo(completion: { userInfo, error in
            if error != nil {
                result(
                    FlutterError(
                        code: "Error",
                        message: error?.localizedDescription,
                        details: nil
                    )
                )
            } else {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                if let userInfo = userInfo?.userInfo, let userInfoJson = try? userInfo.toJson() {
                    result(userInfoJson)
                } else {
                    result(
                        FlutterError(
                            code: "Error",
                            message: "User info encoding failed",
                            details: nil
                        )
                    )
                }

            }
        })
    }

    /**
     Proceeds to the next step in the authentication journey.
    
     - Parameter result: The result callback to be called upon completion.
     */
    @objc func next(_ response: String, completion: @escaping FlutterResult) {
        let decoder = JSONDecoder()
        let jsonData = Data(response.utf8)
        if let node = self.currentNode {
            var responseObject: Response?
            do {
                responseObject = try decoder.decode(Response.self, from: jsonData)
            } catch {
                print(String(describing: error))
                completion(
                    FlutterError(
                        code: "Error",
                        message: error.localizedDescription,
                        details: nil
                    )
                )
                return
            }

            let callbacksArray = responseObject?.callbacks ?? []

            // If the array is empty there are no user inputs. This can happen in callbacks like the DeviceProfileCallback, that do not require user interaction.
            // Other callbacks like SingleValueCallback, will return the user inputs in an array of dictionaries [[String:String]] with the keys: identifier and text
            if callbacksArray.count == 0 {
                for nodeCallback in node.callbacks {

                    if let thisCallback = nodeCallback as? DeviceProfileCallback {
                        let semaphore = DispatchSemaphore(value: 1)
                        semaphore.wait()
                        thisCallback.execute { _ in
                            semaphore.signal()
                        }
                    }
                }

            } else if node.callbacks[0].type == "WebAuthnAuthenticationCallback" ||  node.callbacks[0].type == "WebAuthnRegistrationCallback" {
                
                //WebAuthn has two callbacks which need to be handled together
                    for callback: Callback in node.callbacks {
                        if let thisCallback = callback as? WebAuthnAuthenticationCallback {

                            FRLog.i("Attempting WebAuthnAuthenticationCallback ")
                            //No effect in bridging code
                            //thisCallback.delegate = self
                            DispatchQueue.main.async {
                                // Note that the `Node` parameter in `.authenticate()` is an optional parameter.
                                // If the node is provided, the SDK automatically sets the assertion to the designated HiddenValueCallback
                                thisCallback.authenticate(
                                    node: node,
                                    preferImmediatelyAvailableCredentials: false,
                                    usePasskeysIfAvailable: true
                                ) { (assertion) in

                                    // Authentication is successful
                                    // Submit the Node using Node.next()
                                    DispatchQueue.main.async {
                                     
                                        node.next(completion: { (user: FRUser?, node, error) in
                                            if let node = node {
                                                //Handle node and return
                                                self.handleNode(user, node, error, completion: completion)
                                            }
                                        })
                                        next(node)
                                    }

                                } onError: { (error) in
                                    // An error occurred during the authentication process
                                    // Submit the Node using Node.next()
                                    let message: String
                                    if let webAuthnError = error as? WebAuthnError,
                                        let platformError =
                                            webAuthnError.platformError()
                                    {
                                        message = platformError.localizedDescription
                                    } else if let webAuthnError = error as? WebAuthnError, let errorMessage = webAuthnError.message() {
                                        message = errorMessage
                                    } else {
                                        message = "Something went wrong authenticating the device"
                                    }
                                    let alert = UIAlertController(title: "WebAuthnError", message: message, preferredStyle: .alert)
                                    let okAction = UIAlertAction(
                                        title: "OK",
                                        style: .default,
                                        handler: {
                                            (action) in
                                            node.next { (user: FRUser?, node, error) in
                                                self.handleNode(user, node, error, completion: completion)
                                            }
                                            next(node)
                                        }
                                    )
                                    alert.addAction(okAction)
                                     DispatchQueue.main.async {
                                       //  self.present(alert, animated: true, completion: completion)
                                    }
                                }
                            }
                        }
                        
                        if let thisCallback = callback as? WebAuthnRegistrationCallback {
                            FRLog.i("Attempting WebAuthnRegistrationCallback ")
                            //ineffective in a bridging app
                            //thisCallback.delegate
                            DispatchQueue.main.async {
                                func localKeyExistsAndPasskeysAreAvailable() {}
                                // Note that the `Node` parameter in `.register()` is an optional parameter.
                                // If the node is provided, the SDK automatically sets the error outcome or attestation to the designated HiddenValueCallback
                                thisCallback.register(node: node, deviceName: UIDevice.current.name, usePasskeysIfAvailable: true) { (attestation) in
                                    // Registration is successful
                                    // Submit the Node using Node.next()
                                    self.hud.textLabel.text = "Registering"
                                    //self.hud.show(in: self.view)

                                    DispatchQueue.main.async {
                                     
                                        node.next(completion: { (user: FRUser?, node, error) in
                                            if let node = node {
                                                //Handle node and return
                                                self.handleNode(user, node, error, completion: completion)
                                            }
                                        })
                                        next(node)
                                    }
                                } onError: { _ in
                                    // An error occurred during the registration process
                                    // Submit the Node using Node.next()
                                    next(node)
                                    //    self.present(alert, animated: true, completion: nil)
                                    // }
                                }
                            }
                        }
                    }
                
            } else {

                for (outerIndex, nodeCallback) in node.callbacks.enumerated() {

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {

                        print("nodeCallback type: ", nodeCallback.type)

                        if let thisCallback = nodeCallback as? KbaCreateCallback {
                            for (innerIndex, rawCallback) in callbacksArray.enumerated() {
                                if let inputsArray = rawCallback.input, outerIndex == innerIndex {
                                    for input in inputsArray {
                                        if let value = input.value?.value as? String {
                                            if input.name.contains("question") {
                                                thisCallback.setQuestion(value)
                                            } else {
                                                thisCallback.setAnswer(value)
                                            }
                                        }
                                    }
                                }
                            }
                            next(node)
                        }

                        if let thisCallback = nodeCallback as? SingleValueCallback {
                            for (innerIndex, rawCallback) in callbacksArray.enumerated() {
                                if let inputsArray = rawCallback.input, outerIndex == innerIndex, let value = inputsArray.first?.value {
                                    switch value.originalType {
                                    case .string:
                                        thisCallback.setValue(value.value as? String)
                                    case .int:
                                        thisCallback.setValue(value.value as? Int)
                                    case .double:
                                        thisCallback.setValue(value.value as? Double)
                                    case .bool:
                                        thisCallback.setValue(value.value as? Bool)
                                    default:
                                        break
                                    }
                                }
                            }
                            next(node)
                        }

                        if let thisCallback = nodeCallback as? ConfirmationCallback {
                            for (innerIndex, rawCallback) in callbacksArray.enumerated() {
                                if let inputsArray = rawCallback.input, outerIndex == innerIndex, let value = inputsArray.first?.value {
                                    print("ConfirmationCallback content:")
                                    ///print(rawCallback.input)
                                    print(value.value)
                                    print(innerIndex)
                                    //thisCallback.inputName
                                    thisCallback.value = value.value
                                }
                            }
                            next(node)
                        }

                        if let thisCallback = nodeCallback as? ChoiceCallback {
                            for (innerIndex, rawCallback) in callbacksArray.enumerated() {
                                if let inputsArray = rawCallback.input, outerIndex == innerIndex, let value = inputsArray.first?.value {
                                    print("ChoiceCallback node content:")
                                    print(value.value)
                                    thisCallback.setValue(value.value)
                                }
                            }
                            next(node)
                        }

                        //let customPrompt: Prompt = Prompt(
                        //    title: thisCallback.title,
                        //    subtitle: thisCallback.subtitle,
                        //    description: thisCallback.description
                        //)

                        if let thisCallback = nodeCallback as? DeviceBindingCallback {
                            thisCallback.setDeviceName("Rick's iOS bound device")
                            thisCallback.bind { result in
                                DispatchQueue.main.async {
                                    var bindingResult = ""
                                    switch result {
                                    case .success:
                                        bindingResult = "Success"
                                        next(node)
                                    case .failure(let error):
                                        if error == .invalidCustomClaims {
                                            //Send the error back in the rejecter - nextStep.type === 'LoginFailure'
                                            bindingResult = error.errorMessage
                                            completion(
                                                FlutterError(
                                                    code:
                                                        "Device Binding Error",
                                                    message: error.errorMessage,
                                                    details: nil
                                                )
                                            )
                                            return
                                        }
                                    //break
                                    }
                                    FRLog.i("Device Binding Result: \n\(bindingResult)")

                                }
                            }
                            return print("thisNode next Signing value: ", thisCallback.response.values)
                        }

                        if let thisCallback = nodeCallback as? DeviceSigningVerifierCallback {

                            //This will only display if using pin prompt
                            let customPrompt: Prompt = Prompt(
                                title: !thisCallback.title.isEmpty ? thisCallback.title : "Neo Bank",
                                subtitle: !thisCallback.subtitle.isEmpty ? thisCallback.subtitle : "Sign in",
                                description: !thisCallback.description.isEmpty ? thisCallback.description : "Please authenticate yourself to continue"
                            )

                            thisCallback.sign(
                                customClaims: [
                                    "platform": "iOS",
                                    "isCompanyPhone": true,
                                    "lastUpdated": Int(Date().timeIntervalSince1970),
                                    "transactionAmmount": 2000,
                                    "transactionCurrency": "GBP",
                                ],
                                prompt: customPrompt
                            ) { result in
                                DispatchQueue.main.async {
                                    var signingResult = ""
                                    switch result {
                                    case .success:
                                        signingResult = "Success"

                                        //Call node.next
                                        next(node)
                                    case .failure(let error):
                                        //semaphore.signal()
                                        if error == .invalidCustomClaims {
                                            //Send the error back in the rejecter - nextStep.type === 'LoginFailure'
                                            //bindingResult = error.errorMessage
                                            completion(FlutterError(code: "Device Signing Error", message: error.errorMessage, details: nil))
                                            return
                                        }
                                        signingResult = error.errorMessage
                                    }
                                }
                                //return

                            }
                            return print("thisNode next Signing value: ", thisCallback.response.values)
                        }

                    }
                }
            }

            func next(_ node: Node) {
                //Call node.next
                node.next(completion: { (user: FRUser?, node, error) in
                    if let node = node {

                      
                            //Handle node and return
                            self.handleNode(user, node, error, completion: completion)
                

                    } else {
                        if let error = error {
                            //Send the error back in the rejecter - nextStep.type === 'LoginFailure'
                            completion(
                                FlutterError(
                                    code: "LoginFailure",
                                    message: error.localizedDescription,
                                    details: nil
                                )
                            )
                            return
                        }
                        //Transform the response for the nextStep.type === 'LoginSuccess'
                        let encoder = JSONEncoder()
                        encoder.outputFormatting = .prettyPrinted
                        do {
                            if let user = user, let token = user.token, let data = try? encoder.encode(token),
                                let jsonAccessToken = String(data: data, encoding: .utf8)
                            {
                                FRLog.i("LoginSuccess - sessionToken: \(jsonAccessToken)")
                                completion(try ["type": "LoginSuccess", "sessionToken": jsonAccessToken].toJson())
                            } else {
                                FRLog.i("LoginSuccess")
                                completion(try ["type": "LoginSuccess", "sessionToken": ""].toJson())
                            }
                        } catch {
                            completion(
                                FlutterError(
                                    code: "Serializing Response failed",
                                    message: error.localizedDescription,
                                    details: nil
                                )
                            )
                        }
                    }
                })
            }

        } else {
            completion(
                FlutterError(
                    code: "Error",
                    message: "UnkownError",
                    details: nil
                )
            )
        }
    }

    /**
     Returns the number of bound devices
     - Parameter result: The result callback to be called upon completion.
     */
    @objc func isDeviceBound(result: @escaping FlutterResult) {

        let userKeys = FRUserKeys().loadAll()

        FRLog.i("number of FRUserKeys: " + userKeys.count.formatted())

        if userKeys.count > 0 {
            result(true)
        } else {
            result(false)
        }

    }

    /**
     Calls the Device unbind method in the SDK to remove a key
     - Parameter result: The result callback to be called upon completion.
     */
    @objc func unbindDevice(result: @escaping FlutterResult) {

        let userKeys = FRUserKeys().loadAll()

        FRLog.i("number of FRUserKeys: " + userKeys.count.formatted())

        for key in userKeys {
            print("deleting key with id: ", key.kid)
            do {
                try FRUserKeys().delete(
                    userKey: key,
                    forceDelete: true
                )
                result(
                    try [
                        "type": "KeyDeletionSuccess"
                    ].toJson()
                )
            } catch {
                print("Failed to delete public key from server")
                result(
                    FlutterError(
                        code: "Error",
                        message: "Failed to delete key",
                        details: nil
                    )
                )
            }
        }

    }

    /**
     Calls a specified endpoint.
    
     - Parameters:
     - endpoint: The endpoint to call.
     - completion: The completion callback to be called upon completion.
     */
    @objc func callEndpoint(_ endpoint: String, method: String, payload: String, completion: @escaping FlutterResult) {
        // Invoke API
        FRUser.currentUser?.getAccessToken { (user, error) in

            //  AM 6.5.2 - 7.0.0
            //
            //  Endpoint: /oauth2/realms/userinfo
            //  API Version: resource=2.1,protocol=1.0

            var header: [String: String] = [:]

            if error == nil, let user = user {
                header["Authorization"] = user.buildAuthHeader()
            }

            let request = Request(
                url: endpoint,
                method: Request.HTTPMethod(rawValue: method) ?? .GET,
                headers: header,
                bodyParams: payload.convertToDictionary() ?? [:],
                urlParams: [:],
                requestType: .json,
                responseType: .json
            )
            self.session.dataTask(with: request.build()!) { (data, response, error) in
                guard let responseData = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                    completion(
                        FlutterError(
                            code: "API Error",
                            message: error?.localizedDescription,
                            details: nil
                        )
                    )
                    return
                }

                if (200..<303) ~= httpResponse.statusCode {
                    completion(String(data: responseData, encoding: .utf8))
                } else {
                    completion(
                        FlutterError(
                            code: "Error: statusCode",
                            message: httpResponse.statusCode.description,
                            details: nil
                        )
                    )
                }
            }.resume()
        }
    }

    /**
     Handles the current authentication node.
    
     - Parameters:
     - result: The result of the previous step.
     - node: The current authentication node.
     - error: Any error that occurred during the previous step.
     - completion: The completion callback to be called upon completion.
     */
    private func handleNode(_ result: Any?, _ node: Node?, _ error: Error?, completion: @escaping FlutterResult) {
        if let node = node {
            self.currentNode = node
            let frNode = FRNode(node: node)
            do {
                completion(try frNode.resolve())
            } catch {
                completion(
                    FlutterError(
                        code: "Serializing Node failed",
                        message: error.localizedDescription,
                        details: nil
                    )
                )
            }
        } else {
            completion(
                FlutterError(
                    code: "Error",
                    message: "No node present",
                    details: nil
                )
            )
        }
    }

}

extension FRAuthSampleBridge {
    func setUpChannels(_ window: UIWindow?) {
        guard let controller = window?.rootViewController as? FlutterViewController else {
            print("Could not resolve FlutterViewController from window?.rootViewController")
            return
        }
        let bridgeChannel = FlutterMethodChannel(
            name: "forgerock.com/SampleBridge",
            binaryMessenger: controller.binaryMessenger
        )

        bridgeChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch call.method {
            case "frAuthStart":
                self.frAuthStart(result: result)
            case "login":
                self.login(result: result)
            case "register":
                self.register(result: result)
            case "logout":
                self.frLogout(result: result)
            case "next":
                if let response = call.arguments as? String {
                    self.next(response, completion: result)
                } else {
                    result(FlutterError(code: "500", message: "Arguments not parsed correctly", details: nil))
                }
            case "isDeviceBound":
                self.isDeviceBound(result: result)
            case "unbindDevice":
                self.unbindDevice(result: result)
            case "callEndpoint":
                if let arguments = call.arguments as? [String] {
                    self.callEndpoint(arguments[0], method: arguments[1], payload: arguments[2], completion: result)
                } else {
                    result(FlutterError(code: "500", message: "Arguments not parsed correctly", details: nil))
                }
            case "getUserInfo":
                self.getUserInfo(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        })
    }
}
