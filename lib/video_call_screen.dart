import 'package:agora_uikit/agora_uikit.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

const appId = '402c142c9d804067a51143fd143b9ad4';
String channelName = 'agoratest';
String token =
    '007eJxTYJi4SyW54Zl40YxjMRfL2FljJvVeb5T/sHhOaX3hsp6j5u4KDCYGRsmGJkbJlikWBiYGZuaJpoaGJsZpKUAiyTIxxcS+xT6lIZCR4cy3yyyMDBAI4nMyJKbnFyWWpBaXMDAAAOTEIaI=';
int uid = 1;

class VideoCallPage extends StatefulWidget {
  const VideoCallPage({Key? key}) : super(key: key);

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  bool mic = true;
  bool video = true;
  RtcEngine _engine = createAgoraRtcEngine();
  final AgoraClient client = AgoraClient(
    agoraConnectionData: AgoraConnectionData(
      appId: appId,
      channelName: channelName,
      tempToken: token,
      uid: uid,
    ),
  );

  void initAgora() async {
    await client.initialize();
  }

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            // Remote video view
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: Center(
                  child: AgoraVideoViewer(
                    client: client,
                    layoutType: Layout.oneToOne,
                    enableHostControls:
                        true, // Add this to enable host controls
                  ),
                ),
              ),
            ),
            // Local video view

            // Call controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(10),
                color: Colors.white,
                child: AgoraVideoButtons(
                  client: client,
                  muteButtonChild: IconButton(
                    color: mic ? Colors.black : Colors.red,
                    onPressed: () {
                      if (mic == true) {
                        setState(() {
                          mic = false;
                        });
                      } else {
                        setState(() {
                          mic = true;
                        });
                      }
                      _engine.muteLocalAudioStream(mic);
                    },
                    icon: Icon(Icons.mic_off),
                  ),
                  disconnectButtonChild: IconButton(
                    onPressed: () {
                      _engine.leaveChannel();
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.call_end),
                    color: Colors.red,
                  ),
                  switchCameraButtonChild: IconButton(
                    onPressed: () {
                      _engine.switchCamera();
                    },
                    icon: Icon(Icons.flip_camera_android),
                  ),
                  disableVideoButtonChild: IconButton(
                    color: video ? Colors.black : Colors.red,
                    onPressed: () {
                      if (video == true) {
                        setState(() {
                          video = false;
                        });
                      } else {
                        setState(() {
                          video = true;
                        });
                      }

                      _engine.enableLocalVideo(video);
                    },
                    icon: Icon(Icons.videocam_off),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
