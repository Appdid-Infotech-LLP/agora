import 'dart:async';

import 'package:agora/incoming_call.dart';
import 'package:agora/video_call_screen.dart';
import 'package:agora/voice_call.dart';
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
var playerid = '13f2816e-773c-41a5-9f43-fb047fc0291f'; //User B
int uid = 2;
String channelName = "agoratest";
String token =
    "007eJxTYOjMezrTROPUziOblW9fdj0iUHbASW/xETm9De+6Ytj9ZyxVYDAxMEo2NDFKtkyxMDAxMDNPNDU0NDFOSwESSZaJKSbTrzikNAQyMmzdpsPCyACBID4nQ2J6flFiSWpxCQMDAA7nIak=";
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  //Remove this method to stop OneSignal Debugging
  initializeNotifications();

  OneSignal.shared.setAppId("6e0b107d-26de-436e-be91-e572521d2308");
  OneSignal.shared
      .promptUserForPushNotificationPermission()
      .then((accepted) {});

// The promptForPushNotificationsWithUserResponse function will show the iOS or Android push notification prompt. We recommend removing the following code and instead using an In-App Message to prompt for notification permission
  // OneSignal.shared.promptUserForPushNotificationPermission();

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: true,
    badge: true,
    carPlay: true,
    criticalAlert: true,
    provisional: true,
    sound: true,
  );

  var deviceState = await OneSignal.shared.getDeviceState();
  var playerId = deviceState!.userId;
  print(playerId! + 'playerid');

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

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

const _androidNotificationChannelId = 'default_notification_channel_id';
const _androidNotificationChannelName = 'Default';
const _androidNotificationChannelDescription =
    'The default notification channel for the app';

Future<void> showNotification(
  String title,
  String body, {
  required int notificationId,
}) async {
  const androidPlatformChannelSpecifics = AndroidNotificationDetails(
    _androidNotificationChannelId,
    _androidNotificationChannelName,
    importance: Importance.high,
    priority: Priority.high,
  );

  const platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    notificationId,
    title,
    body,
    platformChannelSpecifics,
    payload: 'item x',
  );
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
  // uid of the local user

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
    setupVoiceSDKEngine();

    OneSignal.shared.setNotificationOpenedHandler(
        (OSNotificationOpenedResult result) async {
      // result.notification.contentAvailable = true;
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
      if (result.action!.actionId == 'calldeny') {
        OneSignal.shared
            .removeNotification(result.notification.androidNotificationId!);
        call = 'calldeny';
      }
      if (result.action!.actionId == 'callaccept') {
        setState(() {
          call = 'callaccept';
        });
        try {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => CallingScreen(
              isVideoCall: false,
              username: 'oste',
              engine: agoraEngine,
            ),
          ));
        } catch (error) {
          print('Failed to join channel: $error');
        }
      }
    });

    OneSignal.shared.setNotificationWillShowInForegroundHandler((event) async {
      if (event.notification.additionalData!['remove'] == 'yes') {
        OneSignal.shared.clearOneSignalNotifications();
      }
      event.complete(null);
      if (event.notification.additionalData!['method'] == 'sendNotification') {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoCallPage(),
            ));
      } else {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IncomingCallScreen(
                callerName: 'Pushkar',
                hasVideo: true,
                engine: agoraEngine,
              ),
            ));
      }
    });

    // Set up an instance of Agora engine
  }

// Clean up the resources when you leave
  @override
  void dispose() async {
    super.dispose();
  }

  void sendNotification() async {
    var deviceState = await OneSignal.shared.getDeviceState();
    var playerId = deviceState?.userId;
    print(playerId! + 'playerid');
    var notification = OSCreateNotification(
      additionalData: {'method': 'sendNotification'},
      contentAvailable: true,
      playerIds: [playerid],
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

  void sendCall() async {
    var deviceState = await OneSignal.shared.getDeviceState();
    var playerId = deviceState?.userId;

    print(playerId! + 'playerid');
    var notification2 = OSCreateNotification(
      additionalData: {'method': 'sendCall'},
      contentAvailable: true,
      playerIds: [playerid],
      content: 'User is calling you',
      heading: 'Incoming Call',
      buttons: [
        OSActionButton(
          text: 'Hang up',
          id: 'calldeny',
        ),
        OSActionButton(text: 'Accept', id: 'callaccept'),
      ],
    );

    var response = await OneSignal.shared.postNotification(notification2);

    if (response['errors'] == null) {
      print('Notification sent successfully');
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
    // agoraEngine.registerEventHandler(
    //   RtcEngineEventHandler(
    //     onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
    //       showMessage(
    //           "Local user uid:${connection.localUid} joined the channel");
    //       setState(() {
    //         _isJoined = true;
    //       });
    //     },
    //     onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
    //       showMessage("Remote user uid:$remoteUid joined the channel");
    //       setState(() {
    //         _remoteUid = remoteUid;
    //       });
    //     },
    //     onUserOffline: (RtcConnection connection, int remoteUid,
    //         UserOfflineReasonType reason) {
    //       showMessage("Remote user uid:$remoteUid left the channel");
    //       setState(() {
    //         _remoteUid = null;
    //       });
    //     },
    //   ),
    // );
  }

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  join() async {
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
      call = 'deny';
    });
    agoraEngine.leaveChannel();
  }

  @override
  Widget build(BuildContext context) {
    // if (call == 'deny' || call == 'callaccept') {
    //   if (call == 'callaccept') {
    //     join();
    //   }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Get started with Voice Calling'),
          ),
          body: Center(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: [
                // Status text
                // Container(height: 40, child: Center(child: _status())),
                // Button Row
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton(
                        child: const Text("Join"),
                        onPressed: () {
                          sendCall();

                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CallingScreen(
                                  username: 'username',
                                  isVideoCall: false,
                                  engine: agoraEngine,
                                ),
                              ));
                          // sendCallNotification();
                        },
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
            ),
          )),
    );
  }
}

  // Widget _status() {
  //   String statusText;

  //   if (!_isJoined)
  //     statusText = 'Join a channel';
  //   else if (_remoteUid == null)
  //     statusText = 'Waiting for a remote user to join...';
  //   else
  //     statusText = 'Connected to remote user, uid:$_remoteUid';

  //   return Text(
  //     statusText,
  //   );
  // }

  // showMessage(String message) {
  //   scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
  //     content: Text(message),
  //   ));
  // }

