## Neo Bank, a device binding and WebAuthen sample app for PingOne AIC / Ping AM 

This sample Flutter banking app is to help demonstrate device binding or mobile biometrics using WebAuthn with PingOne Advanced Identity Cloud or PingAM. It is provided "as is" and is not an official product of Ping and is not officially supported.

## Description
Neo Banking is a mobile application that allows you to setup passwordless authentication with either device binding or WebuAuthn. This application is built using Flutter. In order to test device binding or WebAuthn a physical device is required. This application is still in development stage. The base code for the banking app was cloned from https://github.com/nerufuyo/newtronic_banking. 

## Requirements
- A Pingone AIC or self hosted PingAM/IDM/DS environment
- Flutter
- Xcode 
- Android SDK
- Android Emulator / Android Device (Google Pixel 5)


## Installation
- Clone This Repository
- Run `flutter pub get`
- cd ios/ && pod install
- From Xcode run the project