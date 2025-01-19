import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestStoragePermission(context) async {
  final photosStatus = await Permission.photos.request();
  final videosStatus = await Permission.videos.request();
  final audioStatus = await Permission.audio.request();
  final manageExternalStorageStatus =
      await Permission.manageExternalStorage.request();

  if (photosStatus.isDenied ||
      videosStatus.isDenied ||
      audioStatus.isDenied ||
      manageExternalStorageStatus.isDenied) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Storage permission is required to save PDFs')),
    );
    print("PERMISSION DENIED");
  } else if (photosStatus.isPermanentlyDenied ||
      videosStatus.isPermanentlyDenied ||
      audioStatus.isPermanentlyDenied ||
      manageExternalStorageStatus.isPermanentlyDenied) {
    print("PERMISSION PERMANENTLY DENIED");
    await openAppSettings();
  } else if (photosStatus.isGranted &&
      videosStatus.isGranted &&
      audioStatus.isGranted &&
      manageExternalStorageStatus.isGranted) {
    print("PERMISSION GRANTED");
  }
}
