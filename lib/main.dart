import 'dart:async';
import 'dart:convert';
import 'package:agora/video_call_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:connectycube_flutter_call_kit/connectycube_flutter_call_kit.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

const String appId = "402c142c9d804067a51143fd143b9ad4"; //User A
var playerid = '68e72697-c342-4142-a32d-f4131bb9a9dd'; //User B

Future<void> showCallNotification(String title, String body) async {
  const channelId = 'com.yourcompany.yourapp.call';
  const channelName = 'Call Notification';
  const channelDescription = 'Notification for incoming calls';

  // Create Android notification channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    channelId,
    channelName,
    importance: Importance.max,
  );
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Create Android notification details
  final AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    channelId,
    channelName,
    importance: Importance.max,
    priority: Priority.high,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.call,
    icon: 'ic_launcher',
    sound: RawResourceAndroidNotificationSound('incoming_call'),
  );
  const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(channelId, channelName));

  // Show notification
  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    platformChannelSpecifics,
    payload: 'call',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  //Remove this method to stop OneSignal Debugging

  OneSignal.shared.setAppId("6e0b107d-26de-436e-be91-e572521d2308");

// The promptForPushNotificationsWithUserResponse function will show the iOS or Android push notification prompt. We recommend removing the following code and instead using an In-App Message to prompt for notification permission
  OneSignal.shared.promptUserForPushNotificationPermission().then((accepted) {
    print("Accepted permission: $accepted");
  });

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: true,
    provisional: false,
    sound: true,
  );
  var deviceState = await OneSignal.shared.getDeviceState();
  var playerId = deviceState!.userId!;

  // Handle any messages received while the app is in the foreground
  // FirebaseMessaging.onMessage.listen((message) {
  //   // TODO: Handle the message in your app
  //   // the call received somewhere

  //   // Handle any messages received while the app is in the background or terminated
  //   FirebaseMessaging.onMessageOpenedApp.listen((message) {
  //     // TODO: Handle the message in your app
  //   });
  // });

  // String? fcmToken = await FirebaseMessaging.instance.getToken();
  // print("FCM token: $fcmToken");

  // await FirebaseMessaging.instance.setAutoInitEnabled(true);
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: MyApp()));
}

void accept(BuildContext context) {
  // Use the context here
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (context) => VideoCallPage()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String channelName = "agoratest";
  String token =
      "007eJxTYNAvL8/I2/r2v3zfog+frHZPue+yuuSH5pUoj5DyHMP0w38UGEwMjJINTYySLVMsDEwMzMwTTQ0NTYzTUoBEkmViiknaB4uUhkBGhta50syMDBAI4nMyJKbnFyWWpBaXMDAAAH63IsE=";

  int uid = 1; // uid of the local user

  int? _remoteUid; // uid of the remote user
  bool _isJoined = false; // Indicates if the local user has joined the channel
  late RtcEngine agoraEngine; // Agora engine instance
  var call = 'deny';

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>(); // Global key to access the scaffold

  // Build UI
  @override
  void initState() {
    super.initState();
    OneSignal.shared.setNotificationOpenedHandler(
        (OSNotificationOpenedResult result) async {
      // Handle notification opened here
      print('Notification opened: ${result.notification.body}');
      if (result.action!.actionId == 'deny') {
        OneSignal.shared
            .removeNotification(result.notification.androidNotificationId!);
        call = 'deny';
      }
      if (result.action!.actionId == 'accept') {
        accept(context);
        call = 'accept';
      }

      // await showCallNotification(
      //     result.notification.title!, result.notification.body!);
    });
    OneSignal.shared.setNotificationWillShowInForegroundHandler((event) {
      OSNotification notification = event.notification;
      List<OSActionButton>? buttons =
          notification.additionalData?['buttons']?.cast<OSActionButton>();

      // Find the 'accept' action button
      OSActionButton acceptButton = buttons!.firstWhere(
          (button) => button.id == 'accept',
          orElse: () => OSActionButton(id: "deny", text: "Deny"));

      // Call the accept function if the 'accept' button is tapped
      if (acceptButton.id == 'accept') {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => VideoCallPage()));
      }

      // showCallNotification(event.notification.title!, event.notification.body!);
    });

    // Set up an instance of Agora engine
    setupVoiceSDKEngine();
  }

// Clean up the resources when you leave
  @override
  void dispose() async {
    await agoraEngine.leaveChannel();
    super.dispose();
  }

  void sendNotification() async {
    var deviceState = await OneSignal.shared.getDeviceState();
    var playerId = deviceState?.userId;
    print(playerId! + 'playerid');
    var notification = OSCreateNotification(
      playerIds: [playerId, playerid],
      content: 'User is calling you',
      heading: 'Incoming Call',
      buttons: [
        OSActionButton(
          text: 'Deny',
          id: 'deny',
        ),
        OSActionButton(text: 'Accept', id: 'accept'),
      ],
    );

    var response = await OneSignal.shared.postNotification(notification);
    if (response['errors'] == null) {
      print('Notification sent successfully');
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => VideoCallPage()));
    } else {
      print('Notification failed to send: ${response['errors']}');
    }
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

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

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

  void leave() {
    setState(() {
      _isJoined = false;
      _remoteUid = null;
    });
    agoraEngine.leaveChannel();
  }

  @override
  Widget build(BuildContext context) {
    if (call == 'deny') {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: scaffoldMessengerKey,
        home: Scaffold(
            appBar: AppBar(
              title: const Text('Get started with Voice Calling'),
            ),
            body: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: [
                // Status text
                Container(height: 40, child: Center(child: _status())),
                // Button Row
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton(
                        child: const Text("Join"),
                        onPressed: () => join(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        child: const Text("Leave"),
                        onPressed: () => {leave()},
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  child: Text('Call'),
                  onPressed: () async {
                    sendNotification();
                  },
                )
              ],
            )),
      );
    } else {
      return Center(child: CircularProgressIndicator());
    }
  }

  Widget _status() {
    String statusText;

    if (!_isJoined)
      statusText = 'Join a channel';
    else if (_remoteUid == null)
      statusText = 'Waiting for a remote user to join...';
    else
      statusText = 'Connected to remote user, uid:$_remoteUid';

    return Text(
      statusText,
    );
  }

  showMessage(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}
