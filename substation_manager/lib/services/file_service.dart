// lib/services/file_service.dart

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:substation_manager/models/daily_reading.dart';
import 'package:image/image.dart' as img;
import 'package:substation_manager/models/substation.dart';
import 'dart:convert'; // Import for jsonEncode/jsonDecode

class FileService {
  Future<String> getTemporaryImagePath(String filename) async {
    final tempDir = await getTemporaryDirectory();
    return p.join(tempDir.path, filename);
  }

  Future<String> saveImageToAppDirectory(
    String tempImagePath,
    String subfolder,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final String appDir = p.join(directory.path, subfolder);

    if (!await Directory(appDir).exists()) {
      await Directory(appDir).create(recursive: true);
    }

    final String filename = p.basename(tempImagePath);
    final String permanentPath = p.join(appDir, filename);

    final File tempFile = File(tempImagePath);
    await tempFile.copy(permanentPath);
    return permanentPath;
  }

  // This method will need substantial modification to map DailyReading.readings dynamically.
  Future<File?> generateCsvFile(
    List<DailyReading> readings, {
    List<Substation>? allSubstations,
  }) async {
    if (readings.isEmpty) {
      return null;
    }

    List<List<dynamic>> csvData = [];

    List<String> headers = [
      'Reading ID',
      'Substation Name',
      'Equipment Type',
      'Equipment Name',
      'Reading For Date',
      'Reading Time',
      'Recorded By User ID',
      'Status',
      'Notes',
      'Photo Path',
    ];

    Set<String> allReadingKeys = {};
    for (var reading in readings) {
      allReadingKeys.addAll(reading.readings.keys);
    }
    headers.addAll(allReadingKeys.toList()..sort());

    csvData.add(headers);

    for (var reading in readings) {
      List<dynamic> row = [
        reading.id,
        reading.substationId, // This should be substation Name
        reading.equipmentId, // This should be equipment name/type
        reading.readingForDate.toIso8601String().split('T')[0],
        reading.readingTimeOfDay,
        reading.recordedByUserId,
        reading.status,
        reading.notes ?? '',
        reading.photoPath ?? '',
      ];

      for (var key in allReadingKeys.toList()..sort()) {
        row.add(reading.readings[key] ?? '');
      }

      csvData.add(row);
    }

    String csvString = const ListToCsvConverter().convert(csvData);

    final String directory = (await getTemporaryDirectory()).path;
    final String path = p.join(
      directory,
      'substation_daily_readings_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv',
    );
    final File file = File(path);
    await file.writeAsString(csvString);
    return file;
  }

  // This method will need modification to map DailyReading details.
  Future<File?> addTextOverlayToImage(DailyReading reading) async {
    try {
      final originalFile = File(reading.photoPath!);
      if (!await originalFile.exists()) {
        print('Original image file not found: ${reading.photoPath}');
        return null;
      }

      List<int> imageBytes = await originalFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(
        Uint8List.fromList(imageBytes),
      );

      if (originalImage == null) {
        print('Failed to decode image: ${reading.photoPath}');
        return null;
      }

      final int fontSize = (originalImage.width / 30).round().clamp(12, 40);
      final int padding = (originalImage.width / 60).round().clamp(5, 15);

      final String substationText = 'Substation: ${reading.substationId}';
      final String equipmentText = 'Equipment: ${reading.equipmentId}';
      final String dateText =
          'Date: ${reading.readingForDate.toLocal().toString().split(' ')[0]}';
      final String timeText = 'Time: ${reading.readingTimeOfDay}';
      final String statusText = 'Status: ${reading.status.toUpperCase()}';

      final List<String> textLines = [
        substationText,
        equipmentText,
        dateText,
        timeText,
        statusText,
      ];

      double textHeightPerLine = fontSize * 1.3;
      double totalTextHeight = textLines.length * textHeightPerLine;
      double backgroundHeight = totalTextHeight + (padding * 2);

      if (backgroundHeight > originalImage.height) {
        backgroundHeight = originalImage.height.toDouble();
      }

      img.Image outputImage = img.copyResize(
        originalImage,
        width: originalImage.width,
        height: originalImage.height,
      );

      img.drawRect(
        outputImage,
        x1: 0,
        y1: (outputImage.height - backgroundHeight).toInt(),
        x2: outputImage.width,
        y2: outputImage.height,
        color: img.ColorUint16.rgba(0, 0, 0, 255),
        thickness: 1,
      );

      int currentY =
          (originalImage.height - backgroundHeight).toInt() + padding;

      img.BitmapFont? font;
      if (fontSize >= 24) {
        font = img.arial24;
      } else if (fontSize >= 14) {
        font = img.arial14;
      } else {
        font = img.arial14;
      }

      for (String line in textLines) {
        img.drawString(
          outputImage,
          line,
          font: font,
          x: padding,
          y: currentY,
          color: img.ColorRgb8(255, 255, 255),
        );
        currentY += textHeightPerLine.toInt();
      }

      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = tempDir.path;
      final String outputFileName =
          'reading_photo_overlay_${p.basenameWithoutExtension(reading.photoPath!)}.jpg';
      final File outputFile = File('$tempPath/$outputFileName');

      await outputFile.writeAsBytes(img.encodeJpg(outputImage, quality: 90));

      return outputFile;
    } catch (e) {
      print('Error adding text overlay to image: $e');
      return null;
    }
  }

  Future<void> shareFiles(List<String> filePaths, {String? text}) async {
    final List<XFile> files = filePaths.map((path) => XFile(path)).toList();
    await Share.shareXFiles(files, text: text);
  }
}
