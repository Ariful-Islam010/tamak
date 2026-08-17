import 'dart:io';
import 'package:flutter/material.dart';
import '../services/backend_service.dart';

class ProfileImageHelper {
  /// Returns an [ImageProvider] for a given profile photo URL or local file path.
  /// Handles relative server paths, full URLs, and local device files.
  /// Returns `null` if photoUrl and localFilePath are null or invalid.
  static ImageProvider? getProfileImageProvider(String? photoUrl, {String? localFilePath}) {
    if (localFilePath != null && localFilePath.trim().isNotEmpty) {
      try {
        final file = File(localFilePath.trim());
        if (file.existsSync()) {
          return FileImage(file);
        }
      } catch (_) {}
    }

    if (photoUrl == null || photoUrl.trim().isEmpty) {
      return null;
    }

    final trimmed = photoUrl.trim();

    // Check if photoUrl is a local file path
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://') && !trimmed.startsWith('/')) {
      try {
        final file = File(trimmed);
        if (file.existsSync()) {
          return FileImage(file);
        }
      } catch (_) {}
    }

    // Relative path from backend
    if (trimmed.startsWith('/')) {
      final fullUrl = '${BackendService.baseUrl}$trimmed';
      return NetworkImage(fullUrl);
    }

    // Full HTTP/HTTPS URL
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return NetworkImage(trimmed);
    }

    return null;
  }
}
