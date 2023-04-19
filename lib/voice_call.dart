import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_uikit/agora_uikit.dart';
import 'package:flutter/material.dart';

import 'main.dart';

class CallingScreen extends StatefulWidget {
  final String username;
  final bool isVideoCall;
  final void Function() leave; // define the leave method as a parameter

  CallingScreen(
      {required this.username, required this.isVideoCall, required this.leave});

  @override
  _CallingScreenState createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>(); // Global key to access the scaffold
  void _endCall() {
    widget.leave(); // call the leave method using the widget parameter
    Navigator.pop(context);
  }

  String channelName = "agoratest";
  String token =
      "007eJxTYJi4SyW54Zl40YxjMRfL2FljJvVeb5T/sHhOaX3hsp6j5u4KDCYGRsmGJkbJlikWBiYGZuaJpoaGJsZpKUAiyTIxxcS+xT6lIZCR4cy3yyyMDBAI4nMyJKbnFyWWpBaXMDAAAOTEIaI=";

  int uid = 1; // uid of the local user

  int? _remoteUid; // uid of the remote user
  bool _isJoined = false; // Indicates if the local user has joined the channel
  late RtcEngine agoraEngine; // Agora engine instance

  void join() async {
    // Set channel options including the client role and channel profile
    ChannelMediaOptions options = const ChannelMediaOptions(
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    );

    await agoraEngine.joinChannel(
      token: token,
      channelId: channelName,
      options: options,
      uid: uid,
    );
  }

  Future<void> setupVoiceSDKEngine() async {
    // retrieve or request microphone permission
    await [Permission.microphone].request();

    //create an instance of the Agora engine
    agoraEngine = createAgoraRtcEngine();
    await agoraEngine.initialize(const RtcEngineContext(appId: appId));

    // Register the event handler
    agoraEngine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          showMessage(
              "Local user uid:${connection.localUid} joined the channel");
          setState(() {
            _isJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          showMessage("Remote user uid:$remoteUid joined the channel");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          showMessage("Remote user uid:$remoteUid left the channel");
          setState(() {
            _remoteUid = null;
          });
        },
      ),
    );
  }

  showMessage(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  @override
  void initState() {
    super.initState();
    // Initialize Agora client and join the channel
    join();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF5170EB),
                Color(0xFFBD5AF2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 80),
              Text(
                '${widget.isVideoCall ? "Video" : "Voice"} Call',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),
              CircleAvatar(
                radius: 80,
                backgroundImage: AssetImage('assets/avatar.png'),
              ),
              SizedBox(height: 16),
              Text(
                widget.username,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    onPressed: () {
                      _endCall();
                    },
                    backgroundColor: Colors.white,
                    child: Icon(Icons.call_end, color: Colors.red),
                  ),
                  FloatingActionButton(
                    onPressed: () {},
                    backgroundColor: Colors.white,
                    child: Icon(Icons.mic_off, color: Colors.red),
                  ),
                  FloatingActionButton(
                    onPressed: () {},
                    backgroundColor: Colors.white,
                    child: Icon(
                        widget.isVideoCall
                            ? Icons.videocam_off
                            : Icons.volume_off,
                        color: Colors.red),
                  ),
                  FloatingActionButton(
                    onPressed: () {},
                    backgroundColor: Colors.white,
                    child: Icon(
                        widget.isVideoCall ? Icons.videocam : Icons.call,
                        color: Color(0xFF5170EB)),
                  ),
                  FloatingActionButton(
                    onPressed: () {},
                    backgroundColor: Colors.white,
                    child: Icon(Icons.volume_up, color: Color(0xFF5170EB)),
                  ),
                ],
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
