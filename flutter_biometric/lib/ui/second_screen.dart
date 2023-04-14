import 'package:flutter/material.dart';

class SecondScreen extends StatefulWidget {
  final String? deviceId;
  final String? osVersion;
  final Map<String, dynamic>? deviceData;

  // ignore: prefer_const_constructors_in_immutables
  SecondScreen({Key? key, this.deviceId, this.osVersion, this.deviceData})
      : super(key: key);

  @override
  State<SecondScreen> createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Home Screen'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Container(
                  height: 50,
                  width: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                  ),
                  child: const Text(
                    'Congrats, you are Authenticated!',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  height: 50,
                  width: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                  ),
                  child: const Text(
                    'Device Info',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  height: 150,
                  width: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.deviceId.toString(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        widget.osVersion.toString(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: widget.deviceData != null
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(widget.deviceData.toString()),
                      )
                    : const Center(
                        child: Text('Just A Button'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
