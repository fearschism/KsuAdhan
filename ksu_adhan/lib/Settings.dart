import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  final File file;
  final Map<String, dynamic> sett;
  const Settings({Key? key, required this.file, required this.sett})
      : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late String param;
  late String sound;
  late String mad;
  late String dmad;
  late String dparam;
  late String dsound;
  late String fi;
  late String di;
  late String ai;
  late String mi;
  late String ii;

  @override
  void initState() {
    print(widget.sett['fi'].toString());
    print(widget.sett['di'].toString());
    print(widget.sett['ai'].toString());
    print(widget.sett['mi'].toString());
    print(widget.sett['ii'].toString());

    param = widget.sett['param'];
    mad = widget.sett['mad'];
    if (param == "uq")
      dparam = "Um Alqura(Default)";
    else if (param == "mwl")
      dparam = "Muslim World League";
    else if (param == "s")
      dparam = "Singapore";
    else if (param == "a") dparam = "North America";
    sound = widget.sett['sound'];
    if (sound == "m.mp3")
      dsound = "Makkah(Default)";
    else
      dsound = "Android Default";

    if (mad == "h")
      dmad = "Hanafi";
    else if (mad == "s") dmad = "Shafai(Default)";
    fi = widget.sett['fi'].toString();
    di = widget.sett['di'].toString();
    ai = widget.sett['ai'].toString();
    mi = widget.sett['mi'].toString();
    ii = widget.sett['ii'].toString();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
        colors: [Color(0x8ce8e8e8), Color(0x0f008b9d)],
        begin: Alignment.bottomRight,
        end: Alignment.topLeft,
      )),
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DropdownButton<String>(
            // Step 3.
            value: dparam,
            // Step 4.
            items: <String>[
              'Muslim World League',
              'Um Alqura(Default)',
              'Singapore',
              'North America'
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(fontSize: 16),
                ),
              );
            }).toList(),
            // Step 5.
            onChanged: (String? newValue) {
              setState(() {
                dparam = newValue!;
                if (newValue == "Um Alqura(Default)")
                  param = "uq";
                else if (newValue == "Muslim World League")
                  param = "mwl";
                else if (newValue == "Singapore")
                  param = "s";
                else if (newValue == "North America") param = "a";
              });
            },
          ),
          DropdownButton<String>(
            // Step 3.
            value: dmad,
            // Step 4.
            items: <String>['Shafai(Default)', 'Hanafi']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(fontSize: 16),
                ),
              );
            }).toList(),
            // Step 5.
            onChanged: (String? newValue) {
              setState(() {
                dmad = newValue!;
                if (newValue == "Hanafi")
                  mad = "h";
                else
                  mad = "s";
              });
            },
          ),
          DropdownButton<String>(
            // Step 3.
            value: dsound,
            // Step 4.
            items: <String>['Makkah(Default)', 'Android Default']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(fontSize: 16),
                ),
              );
            }).toList(),
            // Step 5.
            onChanged: (String? newValue) {
              setState(() {
                dsound = newValue!;
                if (newValue == "Makkah(Default)")
                  sound = "m.mp3";
                else
                  sound = "android";
              });
            },
          ),
          Wrap(
            direction: Axis.horizontal,
            children: [
              Text("fajr Iqama"),
              SizedBox(
                width: 16,
              ),
              DropdownButton<String>(
                // Step 3.
                value: fi,
                // Step 4.
                items: <String>["5", '10', '15', '20', "25"]
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
                // Step 5.
                onChanged: (String? newValue) {
                  setState(() {
                    fi = newValue!;
                  });
                },
              ),
            ],
          ),
          Wrap(
            direction: Axis.horizontal,
            children: [
              Text("Duhur Iqama"),
              SizedBox(
                width: 16,
              ),
              DropdownButton<String>(
                // Step 3.
                value: di,
                // Step 4.
                items: <String>["5", '10', '15', '20', "25"]
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
                // Step 5.
                onChanged: (String? newValue) {
                  setState(() {
                    di = newValue!;
                  });
                },
              ),
            ],
          ),
          Wrap(
            direction: Axis.horizontal,
            children: [
              Text("Asr Iqama"),
              SizedBox(
                width: 16,
              ),
              DropdownButton<String>(
                // Step 3.
                value: ai,
                // Step 4.
                items: <String>["5", '10', '15', '20', "25"]
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
                // Step 5.
                onChanged: (String? newValue) {
                  setState(() {
                    ai = newValue!;
                  });
                },
              ),
            ],
          ),
          Wrap(
            direction: Axis.horizontal,
            children: [
              Text("Maghrib Iqama"),
              SizedBox(
                width: 16,
              ),
              DropdownButton<String>(
                // Step 3.
                value: mi,
                // Step 4.
                items: <String>["5", '10', '15', '20', "25"]
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
                // Step 5.
                onChanged: (String? newValue) {
                  setState(() {
                    mi = newValue!;
                  });
                },
              ),
            ],
          ),
          Wrap(
            direction: Axis.horizontal,
            children: [
              Text("Isha Iqama"),
              SizedBox(
                width: 16,
              ),
              DropdownButton<String>(
                // Step 3.
                value: ii,
                // Step 4.
                items: <String>["5", '10', '15', '20', "25"]
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
                // Step 5.
                onChanged: (String? newValue) {
                  setState(() {
                    ii = newValue!;
                  });
                },
              ),
            ],
          ),
          ElevatedButton(
              onPressed: () async {
                Map<String, dynamic> input = {
                  "param": param,
                  "sound": sound,
                  "mad": mad,
                  "fi": int.parse(fi),
                  "di": int.parse(di),
                  "ai": int.parse(ai),
                  "mi": int.parse(mi),
                  "ii": int.parse(ii)
                };
                await widget.file.writeAsString(json.encode(input));

                await showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: ((context) {
                      return AlertDialog(
                        actions: [
                          TextButton(
                            onPressed: () {
                              exit(0);
                            },
                            child: Text("OK"),
                          )
                        ],
                        title: const Text('App Restart Required'),
                        content: const Text(
                          'To Adjust changes to your adhan and Notifications, you must restart the app',
                          style: TextStyle(fontSize: 14),
                        ),
                      );
                    }));
              },
              child: Text("Save"))
        ],
      ),
    );
  }
}
