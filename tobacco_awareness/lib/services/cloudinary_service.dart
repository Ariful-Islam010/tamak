import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  static String get _cloudName => (dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '').trim().replaceAll('"', '').replaceAll("'", "");
  static String get _apiKey => (dotenv.env['CLOUDINARY_API_KEY'] ?? '').trim().replaceAll('"', '').replaceAll("'", "");
  static String get _apiSecret => (dotenv.env['CLOUDINARY_API_SECRET'] ?? '').trim().replaceAll('"', '').replaceAll("'", "");
  static String get _uploadPreset => (dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '').trim().replaceAll('"', '').replaceAll("'", "");
  static String get _uploadUrl => 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';


  /// Uploads an image to Cloudinary using either unsigned or signed upload flow and returns the secure URL
  static Future<String?> uploadImage(File file) async {
    try {
      final preset = _uploadPreset;
      
      // If upload preset is defined, use the foolproof UNSIGNED upload flow
      if (preset.isNotEmpty) {
        final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
        request.fields['upload_preset'] = preset;
        
        final multipartFile = await http.MultipartFile.fromPath('file', file.path);
        request.files.add(multipartFile);
        
        final response = await request.send();
        final responseData = await response.stream.bytesToString();
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          final Map<String, dynamic> jsonMap = jsonDecode(responseData);
          return jsonMap['secure_url'] as String?;
        } else {
          String errMsg = 'Cloudinary unsigned upload failed with status: ${response.statusCode}';
          try {
            final Map<String, dynamic> jsonMap = jsonDecode(responseData);
            if (jsonMap['error'] != null && jsonMap['error']['message'] != null) {
              errMsg = jsonMap['error']['message'];
            }
          } catch (_) {}
          throw Exception(errMsg);
        }
      }

      // OTHERWISE fallback to standard SIGNED upload flow
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final folder = 'tobacco_awareness_profiles';
      
      // Prepare parameters to sign (sorted alphabetically)
      final params = {
        'folder': folder,
        'timestamp': timestamp,
      };

      // Generate signature by hashing alphabetically sorted query string appended with api_secret
      final sortedKeys = params.keys.toList()..sort();
      final signString = sortedKeys.map((key) => '$key=${params[key]}').join('&');
      final finalString = '$signString$_apiSecret';
      
      final bytes = utf8.encode(finalString);
      final signature = sha1.convert(bytes).toString();

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      
      // Add text fields
      request.fields['api_key'] = _apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['folder'] = folder;
      request.fields['signature'] = signature;
      
      // Add file using helper
      final multipartFile = await http.MultipartFile.fromPath('file', file.path);
      request.files.add(multipartFile);

      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonMap = jsonDecode(responseData);
        return jsonMap['secure_url'] as String?;
      } else {
        String errMsg = 'Cloudinary upload failed with status: ${response.statusCode}';
        try {
          final Map<String, dynamic> jsonMap = jsonDecode(responseData);
          if (jsonMap['error'] != null && jsonMap['error']['message'] != null) {
            errMsg = jsonMap['error']['message'];
          }
        } catch (_) {}
        throw Exception(errMsg);
      }
    } catch (e) {
      debugPrint('Error uploading to Cloudinary: $e');
      rethrow;
    }
  }
}
