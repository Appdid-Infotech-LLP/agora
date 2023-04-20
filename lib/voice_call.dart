import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_uikit/agora_uikit.dart';
import 'package:flutter/material.dart';

import 'main.dart';

class CallingScreen extends StatefulWidget {
  final String username;
  final bool isVideoCall;
  final RtcEngine engine;
  // define the leave method as a parameter

  const CallingScreen(
      {super.key,
      required this.username,
      required this.isVideoCall,
      required this.engine});

  @override
  _CallingScreenState createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>(); // Global key to access the scaffold
  void _endCall() async {
    // call the leave method using the widget parameter
    widget.engine.leaveChannel();
    Navigator.pop(context);
  }

  int _secondsElapsed = 0;
  late Timer _timer;
  bool _isTimerRunning = false;

  // uid of the local user

  int? _remoteUid; // uid of the remote user
  bool _isJoined = false; // Indicates if the local user has joined the channel
  late RtcEngine agoraEngine; // Agora engine instance
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

  join() async {
    // Set channel options including the client role and channel profile
    ChannelMediaOptions options = const ChannelMediaOptions(
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    );

    await widget.engine.joinChannel(
      token: token,
      channelId: channelName,
      options: options,
      uid: uid,
    );
  }

  @override
  void initState() {
    super.initState();
    // Initialize Agora client and join the channel

    join();
    widget.engine.registerEventHandler(RtcEngineEventHandler(
      onUserJoined: (RtcConnection connection, int uid, int elapsed) {
        if (!_isTimerRunning) {
          _startTimer();
        }
      },
    ));
  }

  @override
  void dispose() {
    super.dispose();
    _stopTimer();
    widget.engine.unregisterEventHandler(RtcEngineEventHandler());
  }

  void _startTimer() {
    _isTimerRunning = true;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  void _stopTimer() {
    _isTimerRunning = false;
    _timer.cancel();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue[900]!, Colors.blue[600]!],
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
                radius: 70,
                backgroundImage: NetworkImage(
                  'https://picsum.photos/200/300',
                ),
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
              Center(
                child: Text(
                  _formatDuration(Duration(seconds: _secondsElapsed)),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
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
                    onPressed: () {
                      join();
                    },
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

  showMessage(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}
