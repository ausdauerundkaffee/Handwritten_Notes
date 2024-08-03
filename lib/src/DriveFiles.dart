import 'package:googleapis/drive/v3.dart';

class DriveFiles {
static const folderName = "Flutter_GDrive_Practice_Folder";
static const folderMime = "application/vnd.google-apps.folder";

DriveApi? driveApi;

Future<File> _createNewFolder() async{
  final File folder = File();
  folder.name = folderName;
  folder.mimeType = folderMime;
  return await driveApi!.files.create(folder);
}

Future<String?> _folderId() async {
  final found = await driveApi!.files.list(
    q: "mimeType = '$folderMime' and name = '$folderName'",
    $fields: "files(id, name)",
  );
  final files = found.files;

  if (files == null) {
    return null;
  }
  if (files.isEmpty){
    final newFolder = await _createNewFolder();
    return newFolder.id;
  }

  return files.first.id;
}

Future<File?> _isFileExist(String fileName) async {
  final folderId =  await _folderId();
  if (folderId == null){
    return null;
  }

  final query = "name = '$fileName' and '$folderId' in parents and trashed = false";
  final driveFileList = await driveApi!.files.list(
    q: query,
    spaces: 'drive',
    $fields: 'files(id, name, mimeType, parents)',
  );

  if (driveFileList.files == null || driveFileList.files!.isEmpty) {
    return null;
  }

  return driveFileList.files!.first;
}
}