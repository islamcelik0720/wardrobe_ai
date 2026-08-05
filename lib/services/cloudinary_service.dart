import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  String get _cloudName {
    final value = dotenv.env['CLOUDINARY_CLOUD_NAME']?.trim();

    if (value == null || value.isEmpty) {
      throw Exception(
        'CLOUDINARY_CLOUD_NAME bulunamadı. .env dosyasını kontrol et.',
      );
    }

    return value;
  }

  String get _uploadPreset {
    final value = dotenv.env['CLOUDINARY_UPLOAD_PRESET']?.trim();

    if (value == null || value.isEmpty) {
      throw Exception(
        'CLOUDINARY_UPLOAD_PRESET bulunamadı. .env dosyasını kontrol et.',
      );
    }

    return value;
  }

  Future<String> uploadImage(File imageFile) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 60),
    );

    final response = await http.Response.fromStream(streamedResponse);

    final dynamic decodedBody;

    try {
      decodedBody = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        'Cloudinary geçersiz bir yanıt döndürdü. '
        'HTTP ${response.statusCode}',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Fotoğraf Cloudinary’ye yüklenemedi.';

      if (decodedBody is Map<String, dynamic>) {
        final error = decodedBody['error'];

        if (error is Map<String, dynamic>) {
          message = error['message']?.toString() ?? message;
        }
      }

      throw Exception('$message HTTP ${response.statusCode}');
    }

    if (decodedBody is! Map<String, dynamic>) {
      throw Exception('Cloudinary yanıt biçimi geçersiz.');
    }

    final secureUrl = decodedBody['secure_url']?.toString().trim();

    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary fotoğraf adresi döndürmedi.');
    }

    return secureUrl;
  }
}
