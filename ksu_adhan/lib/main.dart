import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:adhan/adhan.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:ksu_adhan/Settings.dart';
import 'package:path_provider/path_provider.dart';
import 'package:real_volume/real_volume.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';


//Isolate
@pragma('vm:entry-point')
void reCalculatePrayerTimesNotifications() {
  final DateTime now = DateTime.now();
  final int isolateId = Isolate.current.hashCode;
  final DateTime expected = DateTime(DateTime.now().year, DateTime.now().month,
      DateTime.now().add(Duration(days: 1)).day, 0, 0, 0);
  DateTimeRange dateRange = DateTimeRange(start: now, end: expected);

  if (dateRange.duration.inMinutes <= 5) {
    SendPort snd = IsolateNameServer.lookupPortByName("back")!;
    snd.send("do");
  } else {
    print("not yet");
  }
}

void reDo(Coordinates myCoordinates, CalculationParameters params,
    Map<String, dynamic> myJson) async {
  await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
            criticalAlerts: true,
            channelKey: 'a',
            channelName: 'Sound',
            channelDescription: "Call for Prayer",
            soundSource: "resource://raw/m",
            importance: NotificationImportance.High,
            playSound: true),
        NotificationChannel(
            criticalAlerts: true,
            channelKey: 'b',
            channelName: 'No Sound',
            channelDescription: "Call for Prayer",
            importance: NotificationImportance.High,
            playSound: true),
      ],
      debug: true);
  //await AwesomeNotifications().cancelAllSchedules();
  print("next Day");

  final date = DateComponents(DateTime.now().year, DateTime.now().month,
      DateTime.now().add(Duration(days: 1)).day);
  final prayerTimes = PrayerTimes(myCoordinates, date, params,
      utcOffset: Duration(hours: DateTime.now().timeZoneOffset.inHours));
  if (myJson['sound'] == 'm.mp3') {
    print("mp3");
//Creates Notification if user picked "Makkah" sound
    await notiInit(prayerTimes, true);
  } else {
    print("regular");
//Creates Notification if user picked "android" sound
    await notiInit(prayerTimes, false);
  }

  print(prayerTimes.fajr);
  print(prayerTimes.dhuhr);
  print(prayerTimes.asr);
  print(prayerTimes.maghrib);
  print(prayerTimes.isha);
}

Future<void> main() async {
  //needed if main is async to tell the flutter engine to await before building
  WidgetsFlutterBinding.ensureInitialized();

  final Directory directory = await getApplicationDocumentsDirectory();
  print(File('${directory.path}/data.json').existsSync());
  final File file = File('${directory.path}/data.json');
  if (!file.existsSync()) {
    Map<String, dynamic> Default = {
      "param": "uq",
      "sound": "m.mp3",
      "mad": "s",
      "fi": 20,
      "di": 20,
      "ai": 20,
      "mi": 10,
      "ii": 20
    };
    await file.writeAsString(json.encode(Default));
  }
  final DateTime now = DateTime.now();

  final DateTime expected = DateTime.now().add(Duration(hours: 1));
  DateTimeRange dateRange = DateTimeRange(start: now, end: expected);
  print("Hours Left ${dateRange.duration.inHours}");

  Map<String, dynamic> myJson = await json.decode(await file.readAsString());

  await AndroidAlarmManager.initialize();

  await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
            criticalAlerts: true,
            channelKey: 'a',
            channelName: 'Sound',
            channelDescription: "Call for Prayer",
            soundSource: "resource://raw/m",
            importance: NotificationImportance.High,
            playSound: true),
        NotificationChannel(
            criticalAlerts: true,
            channelKey: 'b',
            channelName: 'No Sound',
            channelDescription: "Call for Prayer",
            importance: NotificationImportance.High,
            playSound: true),
      ],
      debug: true);
  await AwesomeNotifications().cancelAllSchedules();
  final myCoordinates = Coordinates(
    await _determinePosition().then((value) => value.latitude),
    await _determinePosition().then((value) => value.longitude),
  );
  print(myJson);
  bool? isPermissionGranted = await RealVolume.isPermissionGranted();

  if (!isPermissionGranted!) {
    // Opens Do Not Disturb Access settings to grant the access
    await RealVolume.openDoNotDisturbSettings();
  }

  // Replace with your own location lat, lng.
  CalculationParameters params = CalculationMethod.umm_al_qura.getParameters();
  if (myJson['param'] == "mwl") {
    params = CalculationMethod.muslim_world_league.getParameters();
  } else if (myJson['param'] == "s") {
    params = CalculationMethod.singapore.getParameters();
  } else if (myJson['param'] == "a") {
    params = CalculationMethod.north_america.getParameters();
  }
  if (myJson['mad'] == "s") {
    params.madhab = Madhab.shafi;
  } else if (myJson['mad'] == "h") {
    params.madhab = Madhab.hanafi;
  }

  final date = DateComponents(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final prayerTimes = PrayerTimes(myCoordinates, date, params,
      utcOffset: Duration(hours: DateTime.now().timeZoneOffset.inHours));

  await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      // This is just a basic example. For real apps, you must show some
      // friendly dialog box before call the request method.
      // This is very important to not harm the user experience
      AwesomeNotifications().requestPermissionToSendNotifications();
    } else {
      return true;
    }
  });

  if (myJson['sound'] == 'm.mp3') {
    //Creates Notification if user picked "Makkah" sound
    await notiInit(prayerTimes, true);
  } else {
    //Creates Notification if user picked "Android default" sound
    await notiInit(prayerTimes, false);
  }

  //Testing Purposes(Lists all Scheduled Notifs)
  AwesomeNotifications().listScheduledNotifications().then(
    (value) {
      print(value);
    },
  );
  AwesomeNotifications().setListeners(
    //If Notification is displayed a callback function will take place(Timer).
    onNotificationDisplayedMethod: (ReceivedNotification receivedNotification) {
      return NotificationController.onDisnCreatedMethod(
          receivedNotification, myJson);
    },
    onActionReceivedMethod: (ReceivedAction receivedAction) {
      return NotificationController.onActionReceivedMethod(receivedAction);
    },
  );
  //Main[Thread] thread Message port
  ReceivePort rcvport = ReceivePort();
  IsolateNameServer.registerPortWithName(rcvport.sendPort, "back");
  rcvport.listen(
    (message) {
      //Listens to Background Thread and then executes it on the main thread
      reDo(myCoordinates, params, myJson);
    },
  );
  runApp(MyApp(
    set: myJson,
    file: file,
    prayerTimes: prayerTimes,
  ));
  final int helloAlarmID = 0;
  await AndroidAlarmManager.periodic(const Duration(minutes: 1), helloAlarmID,
      reCalculatePrayerTimesNotifications);
}

class MyApp extends StatelessWidget {
  final Map<String, dynamic> set;
  final File file;
  final PrayerTimes prayerTimes;
  const MyApp(
      {super.key,
      required this.set,
      required this.file,
      required this.prayerTimes});

  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KSU ADHAN',
      theme: ThemeData(
        useMaterial3: true,
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.deepPurple,
      ),
      home: MyHomePage(
          title: 'KSU ADHAN',
          settings: set,
          file: file,
          prayerTimes: prayerTimes),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final Map<String, dynamic> settings;
  final File file;
  final PrayerTimes prayerTimes;
  const MyHomePage(
      {super.key,
      required this.title,
      required this.settings,
      required this.file,
      required this.prayerTimes});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late DateTime _time = DateTime.now();
  late var count = 0;

  //final myCoordinates = Coordinates()

  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _time = DateTime.now();
        count++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    return FutureBuilder(
        future: _determinePosition(),
        builder: ((context, snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(
                // Here we take the value from the MyHomePage object that was created by
                // the App.build method, and use it to set our appbar title.
                title: Image.asset(
                  "assets/logo.png",
                  fit: BoxFit.cover,
                  scale: 3.95,
                ),
                centerTitle: true,
              ),
              body: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                    colors: [Color(0x8ce8e8e8), Color(0x0f008b9d)],
                    begin: Alignment.bottomRight,
                    end: Alignment.topLeft,
                  )),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                "${DateFormat.jms().format(_time)}",
                                style: TextStyle(
                                    fontSize: 35, color: Color(0xFF055FFA)),
                              ),
                            ),
                            Icon(
                              Icons.access_time,
                              size: 35,
                              color: Color(0xFF055FFA),
                            )
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 2.5),
                          child: Container(),
                        ),
                        Expanded(
                            child: Container(
                          child: ListView(
                            scrollDirection: Axis.vertical,
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.all(5.5),
                                width: 200,
                                height: 120,
                                decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(8)),
                                    color: Color.fromARGB(201, 1, 77, 157)
                                        .withOpacity(0.5),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: Colors.black,
                                        offset: Offset.fromDirection(10),
                                        blurRadius: 10,
                                      )
                                    ]),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 10),
                                      child: Text(
                                        "Al Fajr",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10),
                                          child: Text(
                                            "Time: ${DateFormat.jm().format(widget.prayerTimes.fajr)} | IQama: ${widget.settings['fi']} Min",
                                            style: TextStyle(
                                                fontSize: 20,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.all(5.5),
                                width: 200,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8)),
                                  color: Color.fromARGB(255, 14, 188, 245)
                                      .withOpacity(0.5),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                        color: Colors.black54,
                                        blurRadius: 15.0,
                                        offset: Offset(0.0, 0.75))
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 10),
                                      child: Text(
                                        "Al Dhuhr",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10),
                                          child: Text(
                                            "Time: ${DateFormat.jm().format(widget.prayerTimes.dhuhr)} | IQama: ${widget.settings['di']} Min",
                                            style: TextStyle(
                                                fontSize: 20,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.all(5.5),
                                width: 200,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8)),
                                  color: Color.fromARGB(235, 237, 227, 32)
                                      .withOpacity(0.5),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                        color: Colors.black54,
                                        blurRadius: 15.0,
                                        offset: Offset(0.0, 0.75))
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 10),
                                      child: Text(
                                        "Al Asr",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10),
                                          child: Text(
                                            "Time: ${DateFormat.jm().format(widget.prayerTimes.asr)} | IQama: ${widget.settings['ai']} Min",
                                            style: TextStyle(
                                                fontSize: 20,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.all(5.5),
                                width: 150,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8)),
                                  color: Color.fromARGB(204, 66, 0, 232)
                                      .withOpacity(0.5),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                        color: Colors.black54,
                                        blurRadius: 15.0,
                                        offset: Offset(0.0, 0.75))
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 10),
                                      child: Text(
                                        "Al Maghrib",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10),
                                          child: Text(
                                            "Time: ${DateFormat.jm().format(widget.prayerTimes.maghrib)} | IQama: ${widget.settings['mi']} Min",
                                            style: TextStyle(
                                                fontSize: 20,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.all(5.5),
                                width: 150,
                                height: 120,
                                decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(8)),
                                    color: Color.fromARGB(255, 29, 9, 102)
                                        .withOpacity(0.5),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: Colors.black,
                                        offset: Offset.fromDirection(10),
                                        blurRadius: 10,
                                      )
                                    ]),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 10),
                                      child: Text(
                                        "Al Isha",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10),
                                          child: Text(
                                            "Time: ${DateFormat.jm().format(widget.prayerTimes.isha)} | IQama: ${widget.settings['ii']} Min",
                                            style: TextStyle(
                                                fontSize: 20,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  )),
              floatingActionButton: FloatingActionButton(
                backgroundColor: Colors.blueAccent,
                onPressed: (() {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => Scaffold(
                          appBar: AppBar(),
                          body: Settings(
                            file: widget.file,
                            sett: widget.settings,
                          ))));
                }),
                tooltip: 'Increment',
                child: const Icon(Icons.settings),
              ), // This trailing comma makes auto-formatting nicer for build methods.
            );
          } else if (snapshot.hasError) {
            return AlertDialog(
              title: const Text('Permission Needed'),
              content:
                  const Text('Enable Location and Notification to Continue'),
            );
          } else {
            return AlertDialog(
                title: const Text(
                  'KSU ADHAN | Making things ready...',
                  style: TextStyle(fontSize: 16),
                ),
                content: Container(
                    width: 10,
                    height: 10,
                    child: const LinearProgressIndicator()));
          }
        }));
  }
}

Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines

      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    await Geolocator.openAppSettings();
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
}

Future<void> notiInit(PrayerTimes prayerTimes, bool sound) async {
  print(prayerTimes.maghrib.toUtc());
  if (sound) {
    AwesomeNotifications().createNotification(
        schedule: NotificationAndroidCrontab.daily(
            referenceDateTime:
                DateTime.now().add(Duration(seconds: 5)).toUtc()),
        content: NotificationContent(
          displayOnForeground: true,
          customSound: "resource://raw/m.mp3",
          displayOnBackground: true,
          id: 6,
          channelKey: 'a',
          title: 'Test Notification',
          body: 'Simple body',
        ));
    AwesomeNotifications().createNotification(
        schedule: NotificationCalendar(
            allowWhileIdle: true,
            hour: prayerTimes.fajr.hour,
            minute: prayerTimes.fajr.minute,
            second: 0),
        content: NotificationContent(
            displayOnForeground: true,
            displayOnBackground: true,
            id: 1,
            channelKey: 'a',
            title: 'Fajr Prayer',
            body: 'is now',
            customSound: "resource://raw/m"));
    AwesomeNotifications().createNotification(
        schedule: NotificationCalendar(
            allowWhileIdle: true,
            hour: prayerTimes.dhuhr.hour,
            minute: prayerTimes.dhuhr.minute,
            second: 0),
        content: NotificationContent(
            displayOnForeground: true,
            displayOnBackground: true,
            id: 2,
            channelKey: 'a',
            title: 'Al duhur Prayer',
            body: 'is now',
            customSound: "resource://raw/m"));
    AwesomeNotifications().createNotification(
        schedule: NotificationCalendar(
            allowWhileIdle: true,
            hour: prayerTimes.asr.hour,
            minute: prayerTimes.asr.minute,
            second: 0),
        content: NotificationContent(
            displayOnForeground: true,
            displayOnBackground: true,
            id: 3,
            channelKey: 'a',
            title: 'Al asr prayer',
            body: 'is now',
            customSound: "resource://raw/m"));
    AwesomeNotifications().createNotification(
        schedule: NotificationCalendar(
            allowWhileIdle: true,
            hour: prayerTimes.maghrib.hour,
            minute: prayerTimes.maghrib.minute,
            second: 0),
        content: NotificationContent(
            displayOnForeground: true,
            displayOnBackground: true,
            id: 4,
            channelKey: 'a',
            title: 'Al magrib prayer',
            body: 'is now ',
            customSound: "resource://raw/m"));
    AwesomeNotifications().createNotification(
        schedule: NotificationCalendar(
            allowWhileIdle: true,
            hour: prayerTimes.isha.hour,
            minute: prayerTimes.isha.minute,
            second: 0),
        content: NotificationContent(
          displayOnForeground: true,
          displayOnBackground: true,
          id: 5,
          channelKey: 'a',
          title: 'Al isha Prayer',
          customSound: "resource://raw/m.mp3",
          body: 'is now',
        ));
  } else {
    AwesomeNotifications().createNotification(
        schedule: NotificationAndroidCrontab.daily(
            referenceDateTime:
                DateTime.now().add(Duration(seconds: 5)).toUtc()),
        content: NotificationContent(
          displayOnForeground: true,
          displayOnBackground: true,
          id: 12,
          channelKey: 'b',
          title: 'Test Notification',
          body: 'Test body',
        ));
    AwesomeNotifications().createNotification(
        schedule: NotificationCalendar(
            allowWhileIdle: true,
            hour: prayerTimes.fajr.hour,
            minute: prayerTimes.fajr.minute,
            second: 0),
        content: NotificationContent(
          displayOnForeground: true,
          displayOnBackground: true,
          id: 7,
          channelKey: 'b',
          title: 'alFajr Prayer',
          body: 'is now',
        ));
    AwesomeNotifications().createNotification(
        schedule: NotificationCalendar(
            allowWhileIdle: true,
            hour: prayerTimes.dhuhr.hour,
            minute: prayerTimes.dhuhr.minute,
            second: 0),
        content: NotificationContent(
          displayOnForeground: true,
          displayOnBackground: true,
          id: 8,
          channelKey: 'b',
          title: 'Al duhur Prayer',
          body: 'is now',
        ));
    AwesomeNotifications().createNotification(
        schedule: NotificationCalendar(
            allowWhileIdle: true,
            hour: prayerTimes.asr.hour,
            minute: prayerTimes.asr.minute,
            second: 0),
        content: NotificationContent(
          displayOnForeground: true,
          displayOnBackground: true,
          id: 9,
          channelKey: 'b',
          title: 'Al asr Prayer',
          body: 'is now',
        ));
    AwesomeNotifications().createNotification(
        schedule: NotificationCalendar(
            allowWhileIdle: true,
            hour: prayerTimes.maghrib.hour,
            minute: prayerTimes.maghrib.minute,
            second: 0),
        content: NotificationContent(
          displayOnForeground: true,
          displayOnBackground: true,
          id: 10,
          channelKey: 'b',
          title: 'Al magrib prayer',
          body: 'is now ',
        ));
    AwesomeNotifications().createNotification(
        schedule: NotificationCalendar(
            allowWhileIdle: true,
            hour: prayerTimes.isha.hour,
            minute: prayerTimes.isha.minute,
            second: 0),
        content: NotificationContent(
          displayOnForeground: true,
          displayOnBackground: true,
          id: 11,
          channelKey: 'b',
          title: 'Al isha Prayer',
          body: 'is now',
        ));
  }
}

class NotificationController {
  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Your code goes here
  }

  @pragma("vm:entry-point")
  static Future<void> onDisnCreatedMethod(
      ReceivedNotification receivedNotification,
      Map<String, dynamic> file) async {
    print(receivedNotification.id);
    switch (receivedNotification.id) {
      case 1:
        Timer(Duration(minutes: int.parse(file['fi'].toString())), (() {
          RealVolume.setRingerMode(RingerMode.SILENT, redirectIfNeeded: false);

          Timer(Duration(minutes: 10), (() {
            RealVolume.setRingerMode(RingerMode.NORMAL,
                redirectIfNeeded: false);
          }));
        }));
        break;
      case 2:
        Timer(Duration(minutes: int.parse(file['di'].toString())), (() {
          RealVolume.setRingerMode(RingerMode.SILENT, redirectIfNeeded: false);

          Timer(Duration(minutes: 10), (() {
            RealVolume.setRingerMode(RingerMode.NORMAL,
                redirectIfNeeded: false);
          }));
        }));
        break;
      case 3:
        Timer(Duration(minutes: int.parse(file['ai'].toString())), (() {
          RealVolume.setRingerMode(RingerMode.SILENT, redirectIfNeeded: false);

          Timer(Duration(minutes: 10), (() {
            RealVolume.setRingerMode(RingerMode.NORMAL,
                redirectIfNeeded: false);
          }));
        }));
        break;
      case 4:
        Timer(Duration(minutes: int.parse(file['mi'].toString())), (() {
          RealVolume.setRingerMode(RingerMode.SILENT, redirectIfNeeded: false);

          Timer(Duration(minutes: 10), (() {
            RealVolume.setRingerMode(RingerMode.NORMAL,
                redirectIfNeeded: false);
          }));
        }));
        break;
      case 5:
        Timer(Duration(minutes: int.parse(file['ii'].toString())), (() {
          RealVolume.setRingerMode(RingerMode.SILENT, redirectIfNeeded: false);

          Timer(Duration(minutes: 10), (() {
            RealVolume.setRingerMode(RingerMode.NORMAL,
                redirectIfNeeded: false);
          }));
        }));
        break;
      case 6:
        Timer(Duration(seconds: int.parse(file['fi'].toString())), (() {
          RealVolume.setRingerMode(RingerMode.SILENT, redirectIfNeeded: false);

          Timer(Duration(seconds: 10), (() {
            RealVolume.setRingerMode(RingerMode.NORMAL,
                redirectIfNeeded: false);
          }));
        }));
        break;
      case 7:
        Timer(Duration(minutes: int.parse(file['fi'].toString())), (() {
          RealVolume.setRingerMode(RingerMode.SILENT, redirectIfNeeded: false);

          Timer(Duration(minutes: 10), (() {
            RealVolume.setRingerMode(RingerMode.NORMAL,
                redirectIfNeeded: false);
          }));
        }));
        break;
      case 8:
        Timer(Duration(minutes: int.parse(file['di'].toString())), (() {
          RealVolume.setRingerMode(RingerMode.SILENT, redirectIfNeeded: false);

          Timer(Duration(minutes: 10), (() {
            RealVolume.setRingerMode(RingerMode.NORMAL,
                redirectIfNeeded: false);
          }));
        }));
        break;
      case 9:
        Timer(Duration(minutes: int.parse(file['ai'].toString())), (() {
          RealVolume.setRingerMode(RingerMode.SILENT, redirectIfNeeded: false);

          Timer(Duration(minutes: 10), (() {
            RealVolume.setRingerMode(RingerMode.NORMAL,
                redirectIfNeeded: false);
          }));
        }));
        break;
      case 10:
        Timer(Duration(minutes: int.parse(file['mi'].toString())), (() {
          RealVolume.setRingerMode(RingerMode.SILENT, redirectIfNeeded: false);

          Timer(Duration(minutes: 10), (() {
            RealVolume.setRingerMode(RingerMode.NORMAL,
                redirectIfNeeded: false);
          }));
        }));
        break;
      case 11:
        Timer(Duration(minutes: int.parse(file['ii'].toString())), (() {
          RealVolume.setRingerMode(RingerMode.SILENT, redirectIfNeeded: false);

          Timer(Duration(minutes: 10), (() {
            RealVolume.setRingerMode(RingerMode.NORMAL,
                redirectIfNeeded: false);
          }));
        }));
        break;
      case 12:
        Timer(Duration(seconds: int.parse(file['fi'].toString())), (() {
          RealVolume.setRingerMode(RingerMode.SILENT, redirectIfNeeded: false);

          Timer(Duration(seconds: 10), (() {
            RealVolume.setRingerMode(RingerMode.NORMAL,
                redirectIfNeeded: false);
          }));
        }));
        break;
      default:
    }
  }
}
