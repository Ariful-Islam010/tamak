import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  static String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get _apiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  static String get _apiSecret => dotenv.env['CLOUDINARY_API_SECRET'] ?? '';
  static String get _uploadUrl => 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';


  /// Uploads an image to Cloudinary using a signed upload flow and returns the secure URL
  static Future<String?> uploadImage(File file) async {
    try {
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
        // Log details to console
        print('Cloudinary upload failed with status: ${response.statusCode}');
        print('Response body: $responseData');
        return null;
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }
}
