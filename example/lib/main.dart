import 'dart:async';
import 'dart:ffi';
import 'dart:math';

import 'package:data_usage/data_usage.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<DataUsageModel> _dataUsage = [];
  int _totalUsage = 0;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    List<DataUsageModel> dataUsage;
    int totalUsage;
    try {
      await DataUsage.init();
      DateTime now = DateTime.now();
      dataUsage = await DataUsage.dataUsageAndroid(
          withAppIcon: true,
          dataUsageType: DataUsageType.wifi,
        startTime: DateTime(now.year, now.month, 2),
        endTime: now
      );
      totalUsage =
          dataUsage.fold(0, (total, appUsage) => total + appUsage.sent + appUsage.received);
      dataUsage = dataUsage.where((use) => use.received + use.sent > 0).toList();
      dataUsage.sort((use1,use2) => (use2.received + use2.sent) - (use1.received + use1.sent));
      // dataUsage.
    } catch (e) {
      print(e.toString());
    }

    if (!mounted) return;

    setState(() {
      _dataUsage = dataUsage;
      _totalUsage = totalUsage;
    });
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Usage Plugin Example'),
      ),
      body: Center(
          child: Android(dataUsage: _dataUsage, size: size, totalUsage: _totalUsage,)
      ),
    );
  }
}

class Android extends StatelessWidget {

  const Android({
    Key key,
    @required List<DataUsageModel> dataUsage,
    @required this.size,
    @required int totalUsage,
  })
      : _dataUsage = dataUsage,
        _totalUsage = totalUsage,
        super(key: key);

  final List<DataUsageModel> _dataUsage;
  final int _totalUsage;
  final Size size;

  static String formatBytes(int bytes, [int decimals = 2]) {
    if (bytes == 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) + ' ' + suffixes[i];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Total: ${formatBytes(_totalUsage ?? 0)}"),
        Expanded(
          child: ListView(
            children: [
              if (_dataUsage != null)
                for (var item in _dataUsage) ...[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 10),
                        if (item.appIconBytes != null)
                          Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: MemoryImage(item.appIconBytes),
                              ),
                            ),
                          ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: size.width * 0.7,
                              child: Text(
                                '${item.appName}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(height: 10),
                            Container(
                              width: size.width * 0.7,
                              child: Text(
                                '${item.packageName}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ),
                            SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  'Used: ${formatBytes(item.received + item.sent)}  ',
                                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider()
                ]
            ],
          ),
        ),
      ],
    );
  }
}
