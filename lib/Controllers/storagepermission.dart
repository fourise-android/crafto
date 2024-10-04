import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class StoragePermissionManager {
  // Request storage permission
  Future<bool> requestStoragePermission(BuildContext context) async {
    var status = await Permission.storage.status;

    if (status.isGranted) {
      // Permission is already granted
      return true;
    } else if (status.isDenied || status.isRestricted) {
      // Request permission
      var result = await Permission.storage.request();

      if (result.isGranted) {
        // Permission granted after request
        return true;
      } else if (result.isPermanentlyDenied) {
        // If permission is permanently denied, navigate to app settings
        await _showAppSettingsDialog(context);
        return false;
      } else {
        // Permission denied, handle appropriately
        _showPermissionDeniedDialog(context);
        return false;
      }
    } else if (status.isPermanentlyDenied) {
      // If the user has permanently denied the permission, navigate to app settings
      await _showAppSettingsDialog(context);
      return false;
    }

    return false;
  }

  // Show a dialog when permission is denied
  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Storage Permission Required"),
          content: Text(
              "This app requires storage permission to access and store media files. Please grant storage access to continue."),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Grant Permission"),
              onPressed: () {
                Navigator.of(context).pop();
                requestStoragePermission(context);
              },
            ),
          ],
        );
      },
    );
  }

  // Show a dialog to navigate to app settings if permission is permanently denied
  Future<void> _showAppSettingsDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Permission Required"),
          content: Text(
              "Storage permission is permanently denied. You need to enable it in app settings."),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Open Settings"),
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }
}
