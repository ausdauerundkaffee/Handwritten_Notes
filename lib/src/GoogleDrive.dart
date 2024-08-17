import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'dart:io' as io;
import 'package:flutter/scheduler.dart';
//import 'package:googleapis/driveactivity/v2.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'SecureStorage.dart';
import 'package:flutter_handwritten_notes/src/File.dart' as filee;

class GoogleDrive {
  final storage = SecureStorage();
  final _clientId =
      "935194572765-vaek2qh8onveln61lcr0epar0coabrvg.apps.googleusercontent.com";
  final _scopes = ['https://www.googleapis.com/auth/drive.file'];
  final _redirectUri =
      "com.googleusercontent.apps.935194572765-vaek2qh8onveln61lcr0epar0coabrvg:/oauth2redirect";
  
  Future<AuthClient> authenticate() async {
    var client = http.Client();
    var accessTokenObj;
    //var credentials = await storage.getCredentials();
    var authClient;
    //if (credentials == null) {
      debugPrint("not found in storage");
      final url = 'https://accounts.google.com/o/oauth2/auth?response_type=code'
          '&client_id=$_clientId'
          '&redirect_uri=$_redirectUri'
          '&scope=${_scopes.join(' ')}';

      final result = await FlutterWebAuth.authenticate(
        url: url,
        callbackUrlScheme:
            'com.googleusercontent.apps.935194572765-vaek2qh8onveln61lcr0epar0coabrvg',
      );
      final code = Uri.parse(result).queryParameters['code'];
      debugPrint('Authorization code: $code');
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        body: {
          'code': code,
          'client_id': _clientId,
          'redirect_uri': _redirectUri,
          'grant_type': 'authorization_code',
        },
      );

      // Parse access token from response
      final accessToken = json.decode(response.body)['access_token'];
      debugPrint('Response body: ${response.body}');
      debugPrint(accessToken);
      // Initialize the client

      accessTokenObj = AccessToken(
        'Bearer', // The type of token, usually 'Bearer'
        accessToken, // The actual access token string
        DateTime.now()
            .add(Duration(days: 1))
            .toUtc(), // The expiry date and time
      );
      authClient = authenticatedClient(
        client,
        AccessCredentials(
          accessTokenObj,
          null,
          ['https://www.googleapis.com/auth/drive'],
        ),
      );
      debugPrint(json.decode(response.body)['refresh_token']);
      debugPrint('Authenticated');
      return authClient;
      //  debugPrint( authClient.credentials.accessToken);
     // await storage.saveCredentials(
      //    accessTokenObj, json.decode(response.body)['refresh_token']);
    /*} else {
      authClient = authenticatedClient(
        client,
        AccessCredentials(
          AccessToken(credentials["type"], credentials["data"],
              DateTime.tryParse(credentials["expiry"])!),
          credentials["refreshToken"],
          ['https://www.googleapis.com/auth/drive'],
        ),
      );
    }*/
  }
  Future<bool> uploadFile(AuthClient authClient , io.File file ) async {
    http.Client client = http.Client();
    debugPrint('uploadFile');
    // Initialize the Drive API
    final driveApi = drive.DriveApi(authClient);
    // Prepare the file metadata
    final fileToUpload = drive.File()..name = file.path.split('/').last  ..parents = ["1yyszY-l7h5KsTp-poCSqMHB9vsed6cgJ"];

    // Create media from the file
    final media = drive.Media(file.openRead(), file.lengthSync());

    try {
      // Upload the file
      await driveApi.files.create(fileToUpload, uploadMedia: media);
      debugPrint('File uploaded successfully!');
      return true;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return false;
    } finally {
      // Close the HTTP client
      client.close();
    }
  }
  Future<String> downloadFile(drive.File file, AuthClient authClient ) async {
    try {
       final driveApi = drive.DriveApi(authClient);
      final fileId = file.id!;
      final fileName = file.name!;
      Duration duration = const Duration(hours: 1);
      final media = await driveApi.files
          .get(fileId, downloadOptions: drive.DownloadOptions.fullMedia)
          .timeout(duration) as drive.Media;
      final saveDir = await getApplicationDocumentsDirectory();
      final savePath = '${saveDir.path}/$fileName';
      final fileStream = io.File(savePath).openWrite();
      media.stream.pipe(fileStream).whenComplete(() {
        fileStream.close();
        debugPrint('Downloaded $fileName to $savePath');
      });
      return savePath;
    } catch (e) {
      debugPrint(e.toString());
      return "";
    }
  }
  Future< drive.FileList?> getFileList(AuthClient authClient) async{
      drive.FileList fileList = drive.FileList();
      try {
        String folderId = "1yyszY-l7h5KsTp-poCSqMHB9vsed6cgJ";
         final driveApi = drive.DriveApi(authClient);
        fileList = await driveApi.files.list(
          q: "'$folderId' in parents and mimeType='application/pdf'",
        );
        return fileList;
        /*if (fileList.files != null) {
          return fileList.files!.map((driveFile) => filee.fromDriveFile(driveFile)).toList();
        } else {
        return null;
        }*/
      }
      catch(e){
         debugPrint(e.toString());
      }
  }
}
