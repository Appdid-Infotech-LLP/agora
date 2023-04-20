import 'package:agora/main.dart';
import 'package:agora/video_call_screen.dart';
import 'package:agora/voice_call.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callerName;
  final bool hasVideo;
  final RtcEngine engine;

  const IncomingCallScreen(
      {Key? key,
      required this.callerName,
      required this.hasVideo,
      required this.engine})
      : super(key: key);

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  int? _remoteUid; // uid of the remote user
  final bool _isJoined =
      false; // Indicates if the local user has joined the channel
  late RtcEngine agoraEngine;

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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 70,
                backgroundImage: NetworkImage(
                  'https://picsum.photos/200/300',
                ),
              ),
              SizedBox(height: 20),
              Text(
                widget.callerName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 200),
              widget.hasVideo
                  ? Icon(Icons.videocam, color: Colors.white, size: 30)
                  : Icon(Icons.call, color: Colors.white, size: 30),
              SizedBox(height: 100),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    heroTag: 'b2',
                    backgroundColor: Colors.red,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Icon(Icons.call_end),
                  ),
                  FloatingActionButton(
                    heroTag: 'b1',
                    backgroundColor: Colors.green,
                    onPressed: () async {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => CallingScreen(
                          isVideoCall: false,
                          username: 'oste',
                          engine: widget.engine,
                        ),
                      ));
                    },
                    child: Icon(Icons.call),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
