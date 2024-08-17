import 'package:googleapis/drive/v3.dart' as drive;
class Filee {
  final String id;
  final String name;

  Filee({required this.id, required this.name});

  static  Filee fromDriveFile(drive.File driveFile) {
    return Filee(
      id: driveFile.id ?? '',
      name: driveFile.name ?? 'Unknown',
    );
  }
}
