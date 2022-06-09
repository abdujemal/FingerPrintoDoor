import 'dart:io';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:finger_print_door/main.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../contstants.dart';

class AudioCall extends StatefulWidget {
  const AudioCall({ Key? key }) : super(key: key);

  @override
  State<AudioCall> createState() => _AudioCallState();
}

class _AudioCallState extends State<AudioCall> {

  bool _joined = false;
  int _remoteUid = 0;
  bool _switch = false;
  RtcEngine? engine;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    
    // starting audio call
    FirebaseDatabase.instance.ref().child("openAudio").onValue.listen((event) {
      if(event.snapshot.value == false){
        Navigator.push(context, MaterialPageRoute(builder: (_)=>MyHomePage()));
      }
    });
  }

  Future<void> initPlatformState() async {
    int playbackSignalVolume = 400;
    
    try{
      // Get microphone permission
      await [Permission.microphone].request();

      // Create RTC client instance
      RtcEngineContext context = RtcEngineContext(APP_ID);
      engine = await RtcEngine.createWithContext(context);
      // Define event handling logic
      engine!.setEventHandler(RtcEngineEventHandler(
          joinChannelSuccess: (String channel, int uid, int elapsed) async {
            print('joinChannelSuccess ${channel} ${uid}');
            await FirebaseDatabase.instance.ref().child("audioStarted").set(true);
            setState(() {
              _joined = true;
            });
          }, userJoined: (int uid, int elapsed) {
        print('userJoined ${uid}');
        setState(() {
          _remoteUid = uid;
        });
      }, userOffline: (int uid, UserOfflineReason reason) {
        print('userOffline ${uid}');
        setState(() {
          _remoteUid = 0;
        });
      }));
      // await getToken("123");
      // Join channel with channel name as 123
      
      // await engine!.adjustPlaybackSignalVolume(playbackSignalVolume);

      await engine!.joinChannel(await getToken("123"), '123', null, 0);

      await engine!.setEnableSpeakerphone(true);

    }catch(e){
      print(e.toString());
    }
  }

   @override
  void dispose() {
    // TODO: implement dispose
    if(engine != null){
      engine!.leaveChannel();
      engine!.destroy();
      FirebaseDatabase.instance.ref().child("audioStarted").set(false);
    }
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
              appBar: AppBar(
                  title: Text('Agora Audio quickstart'),
              ),
              body: Center(
                  child: Text('Please chat!'),
              ),
          );
  }
}