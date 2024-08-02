import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'dart:io' as io;
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart';
/*class GoogleHttpClient extends http.BaseClient {
  final Map<String, String> headers;

  final http.Client _inner = http.Client();

  GoogleHttpClient(this.headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request..headers.addAll(headers));
  }

  @override
  void close() {
    _inner.close();
  }
}
class GoogleDrive {
  final _clientId =
      "935194572765-klink9jd3ctrod71uupk64q0cf6h1d3s.apps.googleusercontent.com";
  final _scopes = ['https://www.googleapis.com/auth/drive.file'];
  final _redirectUri =
      "com.googleusercontent.apps.935194572765-vaek2qh8onveln61lcr0epar0coabrvg:/oauth2redirect";
  void authenticate(io.File file ) async {
   /* final url = 'https://accounts.google.com/o/oauth2/auth?response_type=code'
        '&client_id=$_clientId'
        '&redirect_uri=$_redirectUri'
        '&scope=${_scopes.join(' ')}';

    final result = await FlutterWebAuth.authenticate(
      url: url,
      callbackUrlScheme:
          'com.googleusercontent.apps.935194572765-vaek2qh8onveln61lcr0epar0coabrvg',
    );

    final code = Uri.parse(result).queryParameters['code'];
    // Use the code to obtain tokens
    debugPrint('Authorization code: $code');
    // Exchange authorization code for access token
    //Uri newUri = Uri(path: 'https://oauth2.googleapis.com/token');
    final response = await http.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      body: {
        'code': code,
        'client_id': _clientId,
        'client_secret': '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',
        'redirect_uri': _redirectUri,
        'grant_type': 'authorization_code',
      },
    );

    // Parse access token from response
    final accessToken = json.decode(response.body)['access_token'];
    debugPrint('Response body: ${response.body}');
    debugPrint(accessToken);
    // Initialize the client
    final client = http.Client();
    final authClient = authenticatedClient(
      client,
      AccessCredentials(
        accessToken,
        null,
        ['https://www.googleapis.com/auth/drive'],
      ),
  );*/
  debugPrint("Will sign in ");
 
    try{
       final googleAuthData = await GoogleSignIn(
     clientId: "935194572765-vaek2qh8onveln61lcr0epar0coabrvg.apps.googleusercontent.com",
      scopes: [
        'https://www.googleapis.com/auth/drive',
      ],
    ).signIn();
  


    if(googleAuthData==null){
      debugPrint("googleAuthData is null");
      return;
    }
     final client = GoogleHttpClient(
        await googleAuthData.authHeaders
    );
    //_inner.send(request..headers.addAll(googleAuthData.authHeaders));
  

    // Initialize the Drive API
    final driveApi = drive.DriveApi(client);
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
      catch (e) {
        debugPrint('Error uploading file: $e');
    }
  }
}*/
class GoogleDrive {
  // "935194572765-klink9jd3ctrod71uupk64q0cf6h1d3s.apps.googleusercontent.com";
  final _clientId =
     
      "935194572765-vaek2qh8onveln61lcr0epar0coabrvg.apps.googleusercontent.com";
  final _scopes = ['https://www.googleapis.com/auth/drive.file'];
  final _redirectUri =
      "com.googleusercontent.apps.935194572765-vaek2qh8onveln61lcr0epar0coabrvg:/oauth2redirect";
  void authenticate(io.File file ) async {
    final url = 'https://accounts.google.com/o/oauth2/auth?response_type=code'
        '&client_id=$_clientId'
        '&redirect_uri=$_redirectUri'
        '&scope=${_scopes.join(' ')}';

    final result = await FlutterWebAuth.authenticate(
      url: url,
      callbackUrlScheme:
      'com.googleusercontent.apps.935194572765-vaek2qh8onveln61lcr0epar0coabrvg',
         
    );
// 'com.googleusercontent.apps.935194572765-vaek2qh8onveln61lcr0epar0coabrvg',
    final code = Uri.parse(result).queryParameters['code'];
    // Use the code to obtain tokens
    debugPrint('Authorization code: $code');
    // Exchange authorization code for access token
    //Uri newUri = Uri(path: 'https://oauth2.googleapis.com/token');
    // 'client_secret': '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',
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
    final client = http.Client();
    final accessTokenObj = AccessToken(
  'Bearer', // The type of token, usually 'Bearer'
  accessToken, // The actual access token string
  DateTime.now().add(Duration(hours: 1)).toUtc(), // The expiry date and time
);
    final authClient = authenticatedClient(
      client,
      AccessCredentials(
        accessTokenObj,
        null,
        ['https://www.googleapis.com/auth/drive'],
      ),
  );
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
/*class GoogleHttpClient extends http.BaseClient {
  final Map<String, String> headers;

  final http.Client _inner = http.Client();

  GoogleHttpClient(this.headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request..headers.addAll(headers));
  }

  @override
  void close() {
    _inner.close();
  }
}

class GoogleDrive {
 DriveApi? driveApi;
 io.File localFile;
 GoogleDrive(this.localFile);
  Future<void> SetDrive() async {
    final googleAuthData = await GoogleSignIn(
      scopes: [
        'sandrahanyshinuda@gmail.com',
        'https://www.googleapis.com/auth/drive',
      ],
    ).signIn();
    
    if (googleAuthData == null) {
      return;
    }

    final client = GoogleHttpClient(
        await googleAuthData.authHeaders
    );
    driveApi = DriveApi(client);

      // Prepare the file metadata
    final gDriveFile = drive.File()..name = localFile.path.split('/').last;

    try{
  await driveApi!.files.create(
      gDriveFile,
      uploadMedia: Media(localFile.openRead(), localFile.lengthSync()),
    );
  } catch (err){
    debugPrint('G-Drive Error : $err');
  }
}
}
*/