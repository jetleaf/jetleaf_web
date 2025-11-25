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

import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetson/jetson.dart';

import '../http/http_message.dart';
import '../http/media_type.dart';
import 'abstract_http_message_converter.dart';

/// {@template jetson2_http_message_converter}
/// A high-priority HTTP message converter that uses Jetson’s [ObjectMapper]
/// to read and write JSON request and response bodies.
///
/// This converter:
///
/// * Is registered with [Ordered.HIGHEST_PRECEDENCE], ensuring it runs before
///   other JSON converters.
/// * Supports both standard JSON (`application/json`) and
///   `application/vnd.api+json` media types.
/// * Delegates all serialization and deserialization to the configured
///   Jetson [ObjectMapper].
/// * Respects character encodings declared in request and response headers.
/// * Ensures the `Content-Type` response header is always correctly set,
///   including charset handling.
/// * Validates generated JSON via [JsonValidator] before writing the response
///   body.
///
/// ### Reading
///
/// Incoming HTTP bodies are fully read into a string using the resolved
/// request encoding, then converted into the target Dart type via:
///
/// ```dart
/// _objectMapper.readValue(jsonString, type);
/// ```
///
/// If decoding or mapping fails, the thrown Jetson or parsing exception
/// propagates up to the HTTP layer.
///
/// ### Writing
///
/// Serialization uses:
///
/// ```dart
/// _objectMapper.writeValueAsString(object);
/// ```
///
/// After serialization:
/// 1. The output JSON is validated.
/// 2. The response’s `Content-Type` is set if missing.
/// 3. The encoded JSON is written to the response body.
///
/// ### Example
///
/// ```dart
/// final converter = Jetson2HttpMessageConverter(jsonMapper);
/// final result = await converter.readInternal(Class<MyDto>(), inputMessage);
/// ```
///
/// In most JetLeaf applications, this converter is discovered and registered
/// automatically by the application context.
///
/// {@endtemplate}
@Order(Ordered.HIGHEST_PRECEDENCE)
class Jetson2HttpMessageConverter extends AbstractHttpMessageConverter<Object> {
  /// The Jetson [ObjectMapper] responsible for serialization and deserialization.
  final ObjectMapper _objectMapper;

  /// {@macro jetson2_http_message_converter}
  Jetson2HttpMessageConverter(this._objectMapper) {
    super.addSupportedMediaType(MediaType.APPLICATION_JSON);
    super.addSupportedMediaType(MediaType('application', 'vnd.api+json'));
  }
  
  @override
  Future<Object> readInternal(Class<Object> type, HttpInputMessage inputMessage) async {
    final encoding = resolveRequestEncoding(inputMessage);

    final stream = inputMessage.getBody();
    final json = await stream.readAsString(encoding);
    return _objectMapper.readValue(json, type);
  }
  
  @override
  Future<void> writeInternal(Object object, HttpOutputMessage outputMessage) async {
    final encoding = resolveResponseEncoding(outputMessage);
    final jsonString = _objectMapper.writeValueAsString(object);

    // Always ensure Content-Type is set correctly
    final contentType = outputMessage.getHeaders().getContentType();
    final resolved = contentType ?? MediaType.APPLICATION_JSON.withCharset(encoding.name);
    outputMessage.getHeaders().setContentType(resolved);

    JsonValidator.validateJsonString(jsonString);

    return tryWith(outputMessage.getBody(), (output) async => await output.writeString(jsonString, encoding));
  }

  @override
  List<Object?> equalizedProperties() => [runtimeType];
}