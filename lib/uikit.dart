import 'package:agora_uikit/agora_uikit.dart';
import 'package:flutter/material.dart';


const appId = '402c142c9d804067a51143fd143b9ad4';
String channelName = 'agoratest';
String token = '007eJxTYNAvL8/I2/r2v3zfog+frHZPue+yuuSH5pUoj5DyHMP0w38UGEwMjJINTYySLVMsDEwMzMwTTQ0NTYzTUoBEkmViiknaB4uUhkBGhta50syMDBAI4nMyJKbnFyWWpBaXMDAAAH63IsE=';
int uid = 1; // uid of the local user


void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  final AgoraClient client = AgoraClient(
    agoraConnectionData: AgoraConnectionData(
      appId: appId,
      channelName: channelName,
      tempToken: token,
      uid: uid,
    ),
  );

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  void initAgora() async {
    await client.initialize();
  }

    @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Agora UI Kit'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              AgoraVideoViewer(
                client: client,
                layoutType: Layout.floating,
                enableHostControls: true, // Add this to enable host controls
              ),
              AgoraVideoButtons(
                client: client,
              ),
            ],
          ),
        ),
      ),
    );
  }

}