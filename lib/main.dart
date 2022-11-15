import 'dart:developer';
// import 'dart:ffi';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

void main() => runApp(const MaterialApp(home: MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Demo Home Page')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const QRViewExample(),
            ));
          },
          child: const Text('qrView'),
        ),
      ),
    );
  }
}

class QRViewExample extends StatefulWidget {
  const QRViewExample({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  Barcode? result;
  QRViewController? controller;
  dynamic infoStatus;
  dynamic userName;
  dynamic userId;
  dynamic eventId;
  dynamic attendStatus;
  dynamic attendMessage;

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Map<String, String> requestHeaders = {
    'x-rapidapi-host': 'love-calculator.p.rapidapi.com',
    'apiKey':
        'eyJpdiI6IllwYnEzQ0FYc2NVbUdtcHNtZHR3akE9PSIsInZhbHVlIjoiZ21YdFFVa2RUOHBqZWJGK1JqNEV1OEFiVGhEVWFDYnJWOE8za0Z6NW9PbVJtUmZmY1hCOWI5ejkreTI3WmJIanBFK1ZKTU9YUVdHc3RwdWp0VzZaRVFsa21kcEljYzl1QTdtWnoxZGF6akU5NHpDbDU5dDkxUjBhdStMWHJmTGoiLCJtYWMiOiJlYTg2MjlmMjcxMWQzOTcyZTIyMDc0NjI1MDMyNTQxMjVjZGIwZWNkMmUzOWUyZDMzZWE5ODdlNzdjMTEzZDYzIn0=',
  };
  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(flex: 1, child: _buildQrView(context)),
          Expanded(
              flex: 1,
              child: Column(
                children: [
                  Text('Status: $infoStatus, User: $userId'),
                  Text(
                      'AttendedStatus: $attendStatus, Message: $attendMessage'),
                ],
              )),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  if (result == null)
                    // Column(
                    //   children: [
                    //     Text('Status: $infoStatus, User: $userName'),
                    //     Text('Status: $infoStatus, User: $userName'),
                    //   ],
                    // )
                    // else
                    const Text('Scan a code'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                            onPressed: () async {
                              await controller?.toggleFlash();
                              setState(() {});
                            },
                            child: FutureBuilder(
                              future: controller?.getFlashStatus(),
                              builder: (context, snapshot) {
                                return Text('Flash: ${snapshot.data}');
                              },
                            )),
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                            onPressed: () async {
                              await controller?.flipCamera();
                              setState(() {});
                            },
                            child: FutureBuilder(
                              future: controller?.getCameraInfo(),
                              builder: (context, snapshot) {
                                if (snapshot.data != null) {
                                  return Text(
                                      'Camera facing ${describeEnum(snapshot.data!)}');
                                } else {
                                  return const Text('loading');
                                }
                              },
                            )),
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                          onPressed: () async {
                            await controller?.pauseCamera();
                          },
                          child: const Text('pause',
                              style: TextStyle(fontSize: 20)),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                          onPressed: () async {
                            await controller?.resumeCamera();
                          },
                          child: const Text('resume',
                              style: TextStyle(fontSize: 20)),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
      _getInfo(uuid: scanData.code);
    });
  }

  void _getInfo({required uuid}) async {
    final response = await http.get(
      Uri.parse('http://13.212.108.126/api/v1/3ptevent_payment_info/$uuid'),
      // Send authorization headers to the backend.
      headers: requestHeaders,
    );

    final responseJson = json.decode(response.body);
    setState(() {
      infoStatus = responseJson['status'];
      userName = responseJson['user']['name'];
      userId = responseJson['user']['id'];
      eventId = responseJson['event']['id'];
    });
    if (infoStatus == 200) {
      _attendEvent();
    }
  }

  void _attendEvent() async {
    final response = await http.post(
      Uri.parse('http://13.212.108.126/api/v1/3ptevent_attend'),
      // Send authorization headers to the backend.
      headers: requestHeaders,
      body: jsonEncode(<String, String>{
        'user_id': userId,
        'event_uuid': eventId,
      }),
    );

    final responseJson = json.decode(response.body);
    setState(() {
      attendStatus = responseJson['status'];
      attendMessage = responseJson['message'];
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
