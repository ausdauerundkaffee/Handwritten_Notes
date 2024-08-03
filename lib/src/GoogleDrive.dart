import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'dart:io' as io;
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'SecureStorage.dart';

class GoogleDrive {
  final storage = SecureStorage();
  final _clientId =
      "935194572765-vaek2qh8onveln61lcr0epar0coabrvg.apps.googleusercontent.com";
  final _scopes = ['https://www.googleapis.com/auth/drive.file'];
  final _redirectUri =
      "com.googleusercontent.apps.935194572765-vaek2qh8onveln61lcr0epar0coabrvg:/oauth2redirect";
  
  void authenticate(io.File file) async {
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

    debugPrint('Authenticated');
    // Initialize the Drive API
    final driveApi = drive.DriveApi(authClient);
    // Prepare the file metadata
    final fileToUpload = drive.File()..name = file.path.split('/').last;

    // Create media from the file
    final media = drive.Media(file.openRead(), file.lengthSync());

    try {
      // Upload the file
      await driveApi.files.create(fileToUpload, uploadMedia: media);
      debugPrint('File uploaded successfully!');
    } catch (e) {
      debugPrint('Error uploading file: $e');
    } finally {
      // Close the HTTP client
      client.close();
    }
  }
}
