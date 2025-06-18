// lib/services/permission_service.dart

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:substation_manager/utils/snackbar_utils.dart';

class PermissionService {
  Future<bool> requestCameraPermission(BuildContext context) async {
    var status = await Permission.camera.status;
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      status = await Permission.camera.request();
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        if (context.mounted) {
          SnackBarUtils.showSnackBar(
            context,
            'Camera permission permanently denied. Please enable it from app settings.',
            isError: true,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          );
        }
        return false;
      }
    }
    return false;
  }

  Future<bool> requestLocationPermission(BuildContext context) async {
    var status = await Permission.locationWhenInUse.status;
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        if (context.mounted) {
          SnackBarUtils.showSnackBar(
            context,
            'Location permission permanently denied. Please enable it from app settings.',
            isError: true,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          );
        }
        return false;
      }
    }
    return false;
  }

  Future<bool> requestStoragePermission(BuildContext context) async {
    var status = await Permission.storage.status;
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      status = await Permission.storage.request();
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        if (context.mounted) {
          SnackBarUtils.showSnackBar(
            context,
            'Storage permission permanently denied. Please enable it from app settings.',
            isError: true,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          );
        }
        return false;
      }
    }
    return false;
  }
}
