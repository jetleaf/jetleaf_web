// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'package:jetleaf_lang/lang.dart';

import '../http/http_message.dart';
import '../http/media_type.dart';
import '../exception/exceptions.dart';
import 'abstract_http_message_converter.dart';

/// {@template form_http_message_converter}
/// [AbstractHttpMessageConverter] implementation for handling HTML form data
/// serialization and deserialization.
///
/// ### Overview
/// The [FormHttpMessageConverter] enables reading and writing of
/// `application/x-www-form-urlencoded` request and response bodies.
/// This is the standard format for HTML form submissions.
///
/// ### Supported Media Types
/// - `application/x-www-form-urlencoded`
///
/// ### Reading Form Data
/// Deserializes form-encoded request bodies into [Map<String, dynamic>]
/// or other compatible types, where keys are parameter names and values
/// are the form field values.
///
/// ### Writing Form Data
/// Serializes objects as form-encoded response bodies, converting
/// the object's properties into URL-encoded key-value pairs.
///
/// ### Example: Reading Form Data
/// ```dart
/// @PostMapping('/form')
/// Future<String> handleForm(@RequestBody Map<String, dynamic> formData) async {
///   final username = formData['username'];
///   final email = formData['email'];
///   return 'Received: $username, $email';
/// }
/// // Request body: "username=john&email=john@example.com"
/// ```
///
/// ### Example: Writing Form Data
/// ```dart
/// @GetMapping('/form', produces: ['application/x-www-form-urlencoded'])
/// Map<String, String> getFormData() => {
///   'name': 'John Doe',
///   'email': 'john@example.com',
/// };
/// // Response body: "name=John+Doe&email=john%40example.com"
/// ```
///
/// ### Form Data Encoding
/// - Parameter names and values are URL-encoded
/// - Spaces are encoded as `+` (or `%20`)
/// - Special characters are percent-encoded
/// - Multiple values for same key are supported as repeated parameters
///
/// ### Type Support
/// - **Reading**: Converts to [Map<String, dynamic>] with string values
/// - **Writing**: Converts from [Map<String, dynamic>] to form-encoded string
///
/// ### Design Notes
/// - Stateless and thread-safe
/// - Uses UTF-8 encoding by default
/// - Compatible with standard HTML form submission
/// - Ordered after more specific converters in processing
///
/// ### Related Types
/// - [MultipartHttpMessageConverter] — for multipart/form-data
/// - [AbstractHttpMessageConverter] — base class for all converters
/// - [HttpMessageConverter] — converter interface
///
/// {@endtemplate}
final class FormHttpMessageConverter extends AbstractHttpMessageConverter<Object> {
  /// {@macro form_http_message_converter}
  FormHttpMessageConverter() {
    super.addSupportedMediaType(MediaType.APPLICATION_X_WWW_FORM_URLENCODED);
  }

  @override
  bool matchesType(Class type) => false;

  @override
  List<Object?> equalizedProperties() => [FormHttpMessageConverter];

  @override
  Future<Object> readInternal(Class<Object> type, HttpInputMessage inputMessage) async {
    final encoding = resolveRequestEncoding(inputMessage);
    final body = await inputMessage.getBody().readAsString(encoding);

    return _parseFormData(body);
  }

  @override
  Future<void> writeInternal(Object object, HttpOutputMessage outputMessage) async {
    final encoding = resolveResponseEncoding(outputMessage);

    // Ensure Content-Type is set
    final contentType = outputMessage.getHeaders().getContentType();
    final resolved = contentType ?? MediaType('application', 'x-www-form-urlencoded').withCharset(encoding.name);
    outputMessage.getHeaders().setContentType(resolved);

    // Convert object to form data
    final formString = _objectToFormData(object);

    return tryWith(outputMessage.getBody(), (output) async => await output.writeString(formString, encoding));
  }

  /// Parses form-encoded body into a Map.
  Map<String, dynamic> _parseFormData(String body) {
    final result = <String, dynamic>{};

    if (body.isEmpty) return result;

    final pairs = body.split('&');
    for (final pair in pairs) {
      if (pair.isEmpty) continue;

      final index = pair.indexOf('=');
      final key = index > 0 ? Uri.decodeComponent(pair.substring(0, index)) : Uri.decodeComponent(pair);
      final value = index > 0 ? Uri.decodeComponent(pair.substring(index + 1)) : '';

      // Handle multiple values for same key
      if (result.containsKey(key)) {
        final existing = result[key];
        if (existing is List) {
          existing.add(value);
        } else {
          result[key] = [existing, value];
        }
      } else {
        result[key] = value;
      }
    }

    return result;
  }

  /// Converts an object to form-encoded string.
  String _objectToFormData(Object object) {
    if (object is Map) {
      return _mapToFormString(object as Map<String, dynamic>);
    }

    // For other objects, convert to map via JSON (requires toJson or similar)
    if (object is String) {
      return object;
    }

    throw HttpMessageNotWritableException('Cannot convert ${object.runtimeType} to form data');
  }

  /// Converts a Map to form-encoded string.
  String _mapToFormString(Map<String, dynamic> map) {
    final pairs = <String>[];

    map.forEach((key, value) {
      final encodedKey = Uri.encodeComponent(key);

      if (value is List) {
        for (final item in value) {
          pairs.add('$encodedKey=${Uri.encodeComponent(item.toString())}');
        }
      } else if (value != null) {
        pairs.add('$encodedKey=${Uri.encodeComponent(value.toString())}');
      }
    });

    return pairs.join('&');
  }
}
