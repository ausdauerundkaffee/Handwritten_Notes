import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_handwritten_notes/src/File.dart';
import 'package:flutter_handwritten_notes/src/GoogleDrive.dart';
import 'package:flutter_handwritten_notes/src/whiteboard.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'SecureStorage.dart';
import 'dart:io' as io;
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  drive.FileList? driveFiles;
  GoogleDrive _googleDrive = GoogleDrive();
  late AuthClient authClient;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text('Library'),
      ),
      body: Column(children: [
        Expanded(
          child: Container(
              height: size.height,
              width: size.width,
              child: driveFiles != null
                  ?  IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async{
             var downloadedFilePath = await _googleDrive.downloadFile(driveFiles!.files![0],authClient);
             // io.File currentDownlodedFile = io.File(downloadedFilePath);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WhiteBoard( authClient, _googleDrive , currentfile: downloadedFilePath),
                ),
              );
            }
              )
                  : Text(
                      "nothing",
                      style: TextStyle(fontSize: 24, color: Colors.black),
                    )),
        ),
      ]),
      drawer: Drawer(
          // Add a ListView to the drawer. This ensures the user can scroll
          // through the options in the drawer if there isn't enough vertical
          // space to fit everything.
          child: ListView(
              // Important: Remove any padding from the ListView.
              padding: EdgeInsets.zero,
              children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Drawer Header'),
            ),
            ListTile(
                title: const Text('Sign In'),
                onTap:
                    // Update the state of the app
                    //_onItemTapped(0);
                    // Then close the drawer
                    () async {
                  AuthClient _authClient = await _googleDrive.authenticate();
                  drive.FileList? _driveFiles =
                      await _googleDrive.getFileList(_authClient);
                  setState(() {
                    authClient = _authClient;
                    driveFiles = _driveFiles;
                  });
                  Navigator.of(context).pop();
                })
          ])),
    );
  }
}
