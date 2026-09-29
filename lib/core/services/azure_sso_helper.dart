import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

/// Decodes the payload claims of a JWT without external libraries.
Map<String, dynamic> decodeJwtClaims(String? jwtToken) {
  if (jwtToken == null || jwtToken.isEmpty) return {};
  try {
    final parts = jwtToken.split('.');
    if (parts.length != 3) return {};

    // Normalize Base64 URL padding
    String payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    while (payload.length % 4 != 0) {
      payload += '=';
    }

    final decodedBytes = base64Decode(payload);
    final decodedString = utf8.decode(decodedBytes);
    final Map<String, dynamic> claims = jsonDecode(decodedString);
    return claims;
  } catch (e) {
    debugPrint('[AzureSsoHelper] Failed to decode JWT claims: $e');
    return {};
  }
}

/// Safely prints the full token without truncation by Android Logcat, IDE buffers, or terminal limits.
void printFullToken(String? token, {String label = 'ACCESS_TOKEN'}) {
  if (token == null || token.isEmpty) {
    debugPrint('==================== [$label is NULL / EMPTY] ====================');
    return;
  }

  debugPrint('');
  debugPrint('==================== [FULL $label START] ====================');
  debugPrint('[$label] Length: ${token.length} characters');

  // 1. dart:developer log for IDE debug console & DevTools (unlimited line length)
  dev.log(token, name: label);

  // 2. Chunked logcat/terminal printing to prevent 1024-byte truncation
  const chunkSize = 500;
  int chunkIndex = 1;
  final totalChunks = (token.length / chunkSize).ceil();
  for (int i = 0; i < token.length; i += chunkSize) {
    final end = (i + chunkSize < token.length) ? i + chunkSize : token.length;
    debugPrint('[$label Part $chunkIndex/$totalChunks] ${token.substring(i, end)}');
    chunkIndex++;
  }

  debugPrint('==================== [FULL $label END] ====================');
  debugPrint('');
}
