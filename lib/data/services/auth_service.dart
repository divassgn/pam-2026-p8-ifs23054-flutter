// lib/data/services/auth_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/api_response_model.dart';
import '../models/user_model.dart';
import '../../core/constants/api_constants.dart';

class AuthService {
  AuthService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  // ─────────────────────────────────────────────
  // POST /auth/register
  // ─────────────────────────────────────────────
  Future<ApiResponse<String>> register({
    required String name,
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.authRegister}');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'username': username, 'password': password}),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) {
      final userId = (body['data'] as Map<String, dynamic>)['userId'] as String;
      return ApiResponse(success: true, message: body['message'] as String, data: userId);
    }
    return ApiResponse(success: false, message: body['message'] as String? ?? 'Gagal mendaftar.');
  }

  // ─────────────────────────────────────────────
  // POST /auth/login
  // ─────────────────────────────────────────────
  Future<ApiResponse<Map<String, String>>> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.authLogin}');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      final data = body['data'] as Map<String, dynamic>;
      return ApiResponse(
        success: true,
        message: body['message'] as String,
        data: {
          'authToken':    data['authToken']    as String,
          'refreshToken': data['refreshToken'] as String,
        },
      );
    }
    return ApiResponse(success: false, message: body['message'] as String? ?? 'Gagal login.');
  }

  // ─────────────────────────────────────────────
  // POST /auth/logout
  // ─────────────────────────────────────────────
  Future<ApiResponse<void>> logout({required String authToken}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.authLogout}');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'authToken': authToken}),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return ApiResponse(success: true, message: body['message'] as String);
    }
    return ApiResponse(success: false, message: body['message'] as String? ?? 'Gagal logout.');
  }

  // ─────────────────────────────────────────────
  // POST /auth/refresh-token
  // ─────────────────────────────────────────────
  Future<ApiResponse<Map<String, String>>> refreshToken({
    required String authToken,
    required String refreshToken,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.authRefresh}');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'authToken': authToken, 'refreshToken': refreshToken}),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      final data = body['data'] as Map<String, dynamic>;
      return ApiResponse(
        success: true,
        message: body['message'] as String,
        data: {
          'authToken':    data['authToken']    as String,
          'refreshToken': data['refreshToken'] as String,
        },
      );
    }
    return ApiResponse(success: false, message: body['message'] as String? ?? 'Token tidak valid.');
  }

  // ─────────────────────────────────────────────
  // GET /users/me
  // ─────────────────────────────────────────────
  Future<ApiResponse<UserModel>> getMe({required String authToken}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.usersMe}');
    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $authToken'},
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      final user = UserModel.fromJson(
        (body['data'] as Map<String, dynamic>)['user'] as Map<String, dynamic>,
      );
      return ApiResponse(success: true, message: body['message'] as String, data: user);
    }
    return ApiResponse(success: false, message: body['message'] as String? ?? 'Gagal memuat profil.');
  }

  // ─────────────────────────────────────────────
  // PUT /users/me
  // ─────────────────────────────────────────────
  Future<ApiResponse<void>> updateMe({
    required String authToken,
    required String name,
    required String username,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.usersMe}');
    final response = await _client.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({'name': name, 'username': username}),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return ApiResponse(success: true, message: body['message'] as String);
    }
    return ApiResponse(success: false, message: body['message'] as String? ?? 'Gagal memperbarui profil.');
  }

  // ─────────────────────────────────────────────
  // PUT /users/me/password
  // ─────────────────────────────────────────────
  Future<ApiResponse<void>> updatePassword({
    required String authToken,
    required String currentPassword,
    required String newPassword,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.usersMePassword}');
    final response = await _client.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({'password': currentPassword, 'newPassword': newPassword}),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return ApiResponse(success: true, message: body['message'] as String);
    }
    return ApiResponse(success: false, message: body['message'] as String? ?? 'Gagal memperbarui kata sandi.');
  }

  // ─────────────────────────────────────────────
  // PUT /users/me/photo  (multipart/form-data)
  //
  // ROOT CAUSE FIX:
  // Versi lama: if (kIsWeb && imageBytes != null) → fromBytes
  //             else if (imageFile != null)        → fromPath
  //
  // Masalah fromPath: tidak menyertakan Content-Type secara otomatis
  // sehingga server menolak (400/415). Di Web, File tidak ada sama sekali.
  //
  // FIX: Selalu pakai fromBytes + contentType eksplisit di SEMUA platform.
  //      Jika imageBytes null tapi imageFile ada, baca dulu dari file.
  // ─────────────────────────────────────────────
  Future<ApiResponse<void>> updatePhoto({
    required String authToken,
    File? imageFile,
    Uint8List? imageBytes,
    String imageFilename = 'photo.jpg',
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.usersMePhoto}');

    // Pastikan bytes tersedia — prioritas imageBytes, fallback baca dari File
    Uint8List? bytes = imageBytes;
    if (bytes == null && imageFile != null && !kIsWeb) {
      bytes = await imageFile.readAsBytes();
    }

    if (bytes == null || bytes.isEmpty) {
      return ApiResponse(success: false, message: 'Tidak ada gambar yang dipilih.');
    }

    // Deteksi MIME type dari ekstensi — wajib agar server tidak reject
    final ext = imageFilename.split('.').last.toLowerCase();
    final mimeType = switch (ext) {
      'png'            => MediaType('image', 'png'),
      'gif'            => MediaType('image', 'gif'),
      'webp'           => MediaType('image', 'webp'),
      'jpg' || 'jpeg'  => MediaType('image', 'jpeg'),
      _                => MediaType('image', 'jpeg'),
    };

    final request = http.MultipartRequest('PUT', uri)
      ..headers['Authorization'] = 'Bearer $authToken'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',           // nama field yang diharapkan server
          bytes,
          filename:    imageFilename,
          contentType: mimeType,
        ),
      );

    try {
      final streamed  = await request.send();
      final response  = await http.Response.fromStream(streamed);
      final body      = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: body['message'] as String);
      }
      return ApiResponse(
        success: false,
        message: body['message'] as String?
            ?? 'Gagal memperbarui foto. (HTTP ${response.statusCode})',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Error upload foto: $e');
    }
  }

  void dispose() => _client.close();
}
