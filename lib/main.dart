import 'dart:async';
import 'dart:math';

import 'package:finger_print_door/audio_call.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
//1. imported local authentication plugin
import 'package:local_auth/local_auth.dart';

void main()async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  return runApp(MyApp());
  }

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);
  
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // 2. created object of localauthentication class
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  // 3. variable for track whether your device support local authentication means
  //    have fingerprint or face recognization sensor or not
  bool _hasFingerPrintSupport = false;

  bool isAutheticating = false;
  // 4. we will set state whether user authorized or not
  String _authorizedOrNot = "Door is closed";
  // 5. list of avalable biometric authentication supports of your device will be saved in this array
  List<BiometricType> _availableBuimetricType = [];

  Future<void> _getBiometricsSupport() async {
    // 6. this method checks whether your device has biometric support or not
    bool hasFingerPrintSupport = false;
    try {
      hasFingerPrintSupport = await _localAuthentication.canCheckBiometrics;
    } catch (e) {
      print(e);
    }
    if (!mounted) return;
    setState(() {
      _hasFingerPrintSupport = hasFingerPrintSupport;
    });
  }

  Future<void> _getAvailableSupport() async {
    // 7. this method fetches all the available biometric supports of the device
    List<BiometricType> availableBuimetricType = [];
    try {
      availableBuimetricType =
          await _localAuthentication.getAvailableBiometrics();
    } catch (e) {
      print(e);
    }
    if (!mounted) return;
    setState(() {
      _availableBuimetricType = availableBuimetricType;
    });
  }

  Future<void> _authenticateMe() async {
    // 8. this method opens a dialog for fingerprint authentication.
    //    we do not need to create a dialog nut it popsup from device natively.
    bool authenticated = false;

    isAutheticating = true;
    try {
      authenticated = await _localAuthentication.authenticate(
          localizedReason: "Authenticate for opening the door...", // message for dialog
          options: const AuthenticationOptions(useErrorDialogs: false)
          // useErrorDialogs: true,// show error in dialog
          // stickyAuth: true,// native process
        );
      if(authenticated){
        Random rndm = Random();
        await FirebaseDatabase.instance.ref().child("ring").set(rndm.nextInt(100000));
      }
      isAutheticating = false;
      
    } catch (e) {
      isAutheticating = false;
      print(e);
    }
    if (!mounted) return;
    setState(() {
      
        _authorizedOrNot = authenticated ? "Door is open" : "Door is closed";
    
    });
  }

  @override
  void initState() {
    _getBiometricsSupport();
    _getAvailableSupport();
    super.initState();
    Timer.periodic(Duration(seconds: 5), (t){
      if(!isAutheticating){
       _authenticateMe();
      }
    });

    // starting audio call
    FirebaseDatabase.instance.ref().child("openAudio").onValue.listen((event) {
      if(event.snapshot.value == true){
        Navigator.push(context, MaterialPageRoute(builder: (_)=>const AudioCall()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fingerprint Authentication Door'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("Has FingerPrint Support : $_hasFingerPrintSupport"),
            Text(
                "List of Biometrics Support: ${_availableBuimetricType.toString()}"),
            Text("Authorized : $_authorizedOrNot"),
            RaisedButton(
              child: Text("Authorize Now"),
              color: Colors.green,
              onPressed: _authenticateMe,
            ),
          ],
        ),
      ),
    );
  }
}
