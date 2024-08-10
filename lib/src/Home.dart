import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'as material;
import 'dart:io' as io;
import 'package:flutter/scheduler.dart';
import 'package:googleapis/calendar/v3.dart';
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
import 'package:cached_network_image/cached_network_image.dart';
class Home extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _HomeState();
  
  final storage = SecureStorage();
  final _clientId =
      "935194572765-vaek2qh8onveln61lcr0epar0coabrvg.apps.googleusercontent.com";
  final _scopes = ['https://www.googleapis.com/auth/drive.file'];
  final _redirectUri =
      "com.googleusercontent.apps.935194572765-vaek2qh8onveln61lcr0epar0coabrvg:/oauth2redirect";
  Future<void> _downloadFile(drive.File file , DriveApi driveApi) async {
    try{
    final fileId = file.id!;
    final fileName = file.name!;
    Duration duration = const Duration(hours: 1);
    final media = await driveApi.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia).timeout(duration) as drive.Media;
    final saveDir = await getApplicationDocumentsDirectory();
    final savePath = '${saveDir.path}/$fileName';
    final fileStream = io.File(savePath).openWrite();
    media.stream.pipe(fileStream).whenComplete(() {
      fileStream.close();
      debugPrint('Downloaded $fileName to $savePath');
    });
    }
    catch(e){
      debugPrint(e.toString());
      return;
    }
  }

  void authenticate() async {
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

    try {
       String folderId = "1yyszY-l7h5KsTp-poCSqMHB9vsed6cgJ";
    //final fileList = await driveApi.files.list(q: "mimeType='application/pdf'", spaces: 'drive');
      var fileList = await driveApi.files.list(
        q: "'$folderId' in parents and mimeType='application/pdf'",
      );
    for (var file in fileList.files ?? []) {
      try{
      await _downloadFile(file,driveApi );
      }
      catch(e){
        debugPrint(e.toString());
      }
      finally{
      
      }
    }
      // Upload the file
    //  await driveApi.files.get(fileToUpload, uploadMedia: media);
     // debugPrint('File uploaded successfully!');
    } catch (e) {
      debugPrint('Error uploading file: $e');
    } finally {
      // Close the HTTP client
      client.close();
    }
    debugPrint("finished downloading");
  }

}
class _HomeState extends State<Home>{

  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Handle book tap, such as opening the book
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: material.Colors.black26,
                    offset: Offset(0, 4),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: "dgD",
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            book.title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
