import 'dart:io';
import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_biometric/ui/second_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  Map<String, dynamic> _deviceData = <String, dynamic>{};
  AndroidDeviceInfo? androidInfo;
  final LocalAuthentication auth = LocalAuthentication();
  _SupportState _supportState = _SupportState.unknown;
  bool? _canCheckBiometrics;
  List<BiometricType>? _availableBiometrics;
  String _authorized = 'Not Authorized';
  bool _isAuthenticating = false;
  bool _isAuthFailed = false;

  @override
  void initState() {
    super.initState();
    // Device support checker
    auth.isDeviceSupported().then(
          (bool isSupported) => setState(() => _supportState = isSupported
              ? _SupportState.supported
              : _SupportState.unsupported),
        );
  }

  Future<void> initPlatformState() async {
    var deviceData = <String, dynamic>{};

    try {
      if (Platform.isAndroid) {
        deviceData = _readAndroidBuildData(await deviceInfoPlugin.androidInfo);
      } else if (Platform.isIOS) {
        deviceData = _readIosDeviceInfo(await deviceInfoPlugin.iosInfo);
      }
    } on PlatformException {
      deviceData = <String, dynamic>{
        'Error:': 'Failed to get platform version.'
      };
    }

    if (!mounted) return;

    setState(() {
      _deviceData = deviceData;
    });
  }

  Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    return <String, dynamic>{
      'version.securityPatch': build.version.securityPatch,
      'version.sdkInt': build.version.sdkInt,
      'version.release': build.version.release,
      'version.previewSdkInt': build.version.previewSdkInt,
      'version.incremental': build.version.incremental,
      'version.codename': build.version.codename,
      'version.baseOS': build.version.baseOS,
      'board': build.board,
      'bootloader': build.bootloader,
      'brand': build.brand,
      'device': build.device,
      'display': build.display,
      'fingerprint': build.fingerprint,
      'hardware': build.hardware,
      'host': build.host,
      'id': build.id,
      'manufacturer': build.manufacturer,
      'model': build.model,
      'product': build.product,
      'supported32BitAbis': build.supported32BitAbis,
      'supported64BitAbis': build.supported64BitAbis,
      'supportedAbis': build.supportedAbis,
      'tags': build.tags,
      'type': build.type,
      'isPhysicalDevice': build.isPhysicalDevice,
      'systemFeatures': build.systemFeatures,
    };
  }

  Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {
    return <String, dynamic>{
      'name': data.name,
      'systemName': data.systemName,
      'systemVersion': data.systemVersion,
      'model': data.model,
      'localizedModel': data.localizedModel,
      'identifierForVendor': data.identifierForVendor,
      'isPhysicalDevice': data.isPhysicalDevice,
      'utsname.sysname:': data.utsname.sysname,
      'utsname.nodename:': data.utsname.nodename,
      'utsname.release:': data.utsname.release,
      'utsname.version:': data.utsname.version,
      'utsname.machine:': data.utsname.machine,
    };
  }

  Future<void> _checkBiometrics() async {
    late bool canCheckBiometrics;
    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      canCheckBiometrics = false;
      log(e.message.toString());
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _canCheckBiometrics = canCheckBiometrics;
    });
  }

  Future<void> _getBiometrics() async {
    late List<BiometricType> availableBiometrics;
    try {
      availableBiometrics = await auth.getAvailableBiometrics();
      // Use Platform specific Biometric Auth, Rules & Requirements if desired
      if (Platform.isIOS) {
        if (availableBiometrics.contains(BiometricType.face)) {
          log("iOS - Face ID");
          _authenticateWithBiometrics('Use Face ID to authenticate.');
        } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
          log("iOS - Fingerprint/Touch ID");
          _authenticateWithBiometrics('Use Touch ID to authenticate.');
        }
      } else if (Platform.isAndroid) {
        if (availableBiometrics.contains(BiometricType.fingerprint) &&
            availableBiometrics.contains(BiometricType.face)) {
          log("Android");
          _authenticateWithBiometrics('Use Fingerprint to authenticate.');
        }
      }
      log("Others - credentials auth");
      _authenticateWithBiometrics('Use anything to authenticate.');
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Warning!"),
          content: const Text(
            "Please Login with your\nPhone Number & Password to Authenticate.",
            style: TextStyle(
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text("OK"),
              ),
            ),
          ],
        ),
      );
    } on PlatformException catch (e) {
      availableBiometrics = <BiometricType>[];
      log(e.message.toString());
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _availableBiometrics = availableBiometrics;
    });
  }

  Future<void> _getAvailableBiometrics() async {
    late List<BiometricType> availableBiometrics;
    try {
      availableBiometrics = await auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      availableBiometrics = <BiometricType>[];
      log(e.message.toString());
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _availableBiometrics = availableBiometrics;
    });
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
        _authorized = 'Authenticating';
      });
      authenticated = await auth.authenticate(
        localizedReason: 'Let OS determine authentication method',
      );
      setState(() {
        _isAuthenticating = false;
      });
    } on PlatformException catch (e) {
      log(e.message.toString());
      setState(() {
        _isAuthenticating = false;
        _authorized = 'Error - ${e.message}';
      });
      return;
    }
    if (!mounted) {
      return;
    }

    setState(
        () => _authorized = authenticated ? 'Authorized' : 'Not Authorized');
  }

  Future<void> _authenticateWithBiometrics(String message) async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
        _authorized = 'Authenticating';
      });
      // NOTE: This method opens a dialog for fingerprint authentication.
      // no need to create a dialog, since it will shown natively
      if (Platform.isAndroid) {
        authenticated = await auth.authenticate(
          biometricOnly: true,
          useErrorDialogs: true,
          localizedReason:
              'Scan with Fingerprint or Face Recognition to authenticate.',
        );
      } else if (Platform.isIOS) {
        authenticated = await auth.authenticate(
          useErrorDialogs: true,
          biometricOnly: true,
          localizedReason: 'Scan with Face ID or Touch ID to authenticate.',
        );
      }
      setState(() {
        _isAuthenticating = false;
        _authorized = 'Authenticating';
      });

      if (authenticated) {
        initPlatformState();
        // If Biometric Authentication is Successful,
        // Navigate User to desired routes or screens (e.g: Main Screen/Dashboard)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SecondScreen(
              deviceId: _deviceData['id'],
              osVersion: _deviceData['version.release'],
              deviceData: _deviceData,
            ),
          ),
        );
      }
    } on PlatformException catch (e) {
      log(e.message.toString());
      setState(() {
        _isAuthenticating = false;
        _authorized = 'Error - ${e.message}';
      });
      return;
    }
    // if (!mounted) {
    //   return;
    // }
    final String message = authenticated ? 'Authorized' : 'Not Authorized';
    setState(() {
      _authorized = message;
    });
  }

  Future<void> _cancelAuthentication() async {
    await auth.stopAuthentication();
    setState(() => _isAuthenticating = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.indigo,
          centerTitle: true,
          title: const Text('Biometric Authentication'),
        ),
        body: ListView(
          padding: const EdgeInsets.only(top: 30),
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // This code stated whether User's device support Biometric or not
                if (_supportState == _SupportState.unknown)
                  const CircularProgressIndicator()
                else if (_supportState == _SupportState.supported)
                  const Text(
                    'This device is supported',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.green,
                    ),
                  )
                else
                  const Text(
                    'This device is not supported',
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                const Divider(height: 80),
                // NOTE: To check any available Biometric options from User's device
                Text('Check Biometric Options: $_canCheckBiometrics\n'),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Colors.red,
                  ),
                  onPressed: _checkBiometrics,
                  child: const Text('Check Biometrics'),
                ),
                const Divider(height: 100),
                Text('Available Biometrics: $_availableBiometrics\n'),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Colors.green,
                  ),
                  onPressed: _getAvailableBiometrics,
                  child: const Text('Get available Biometrics'),
                ),
                const Divider(height: 100),
                Text('Current State: $_authorized\n'),
                if (_isAuthenticating)
                  ElevatedButton(
                    onPressed: _cancelAuthentication,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const <Widget>[
                        Text('Cancel Authentication'),
                        Icon(Icons.cancel),
                      ],
                    ),
                  )
                else
                  Column(
                    children: const <Widget>[
                      // Authenticate with available options selected by the OS
                      // ElevatedButton(
                      //   onPressed: _authenticate,
                      //   child: Row(
                      //     mainAxisSize: MainAxisSize.min,
                      //     children: const <Widget>[
                      //       Text('Authenticate'),
                      //       Icon(Icons.perm_device_information),
                      //     ],
                      //   ),
                      // ),
                      // Authenticate with Biometrics Only
                      // ElevatedButton(
                      //   onPressed: _authenticateWithBiometrics,
                      //   child: Row(
                      //     mainAxisSize: MainAxisSize.min,
                      //     children: <Widget>[
                      //       Text(_isAuthenticating
                      //           ? 'Cancel'
                      //           : 'Authenticate: Biometrics only'),
                      //       const Icon(Icons.fingerprint),
                      //     ],
                      //   ),
                      // ),
                    ],
                  ),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _getBiometrics,
          tooltip: 'Authentication',
          child: const Icon(Icons.fingerprint),
        ),
      ),
    );
  }
}

enum _SupportState {
  unknown,
  supported,
  unsupported,
}
