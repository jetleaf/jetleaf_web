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
import 'package:jetleaf_web/src/http/media_type.dart';

import '../http/http_message.dart';
import 'abstract_http_message_converter.dart';

/// {@template string_http_message_converter}
/// JetLeaf’s built-in [AbstractHttpMessageConverter] implementation
/// for handling plain text (`text/plain`) HTTP payloads.
///
/// This converter supports:
/// - **Inbound conversion**: Reads the body of an [HttpInputMessage] as a UTF-8 string.
/// - **Outbound conversion**: Writes a `String` directly to an [HttpOutputMessage] body.
///
/// ### Supported Media Types
/// - `text/plain`
///
/// ### Example
/// ```dart
/// final converter = StringHttpMessageConverter();
/// final message = HttpInputMessage.fromBody('Hello JetLeaf');
/// final result = await converter.read(String, message);
/// print(result); // "Hello JetLeaf"
/// ```
///
/// ### Design Notes
/// - Registered by default in JetLeaf’s message conversion chain.
/// - Delegated by `HttpMessageConverters` for plain text serialization.
/// - Uses UTF-8 encoding for both read and write operations.
/// {@endtemplate}
final class StringHttpMessageConverter extends AbstractHttpMessageConverter<String> {
  /// {@macro string_http_message_converter}
  StringHttpMessageConverter() : super() {
    super.addSupportedMediaType(MediaType.TEXT_PLAIN);
  }

  @override
  bool matchesType(Class type) => type == Class<String>() || type.getType() == String;

  @override
  Future<String> readInternal(Class<String> type, HttpInputMessage inputMessage) async {
    return inputMessage.getBody().readAsString(resolveRequestEncoding(inputMessage));
  }

  @override
  Future<void> writeInternal(String object, HttpOutputMessage outputMessage) async {
    final encoding = resolveResponseEncoding(outputMessage);
    return tryWith(outputMessage.getBody(), (output) async => await output.writeString(object, encoding));
  }

  @override
  List<Object?> equalizedProperties() => [StringHttpMessageConverter];
}

/// {@template byte_array_http_message_converter}
/// JetLeaf’s built-in [AbstractHttpMessageConverter] for handling
/// raw binary data with media type `application/octet-stream`.
///
/// This converter supports:
/// - **Inbound conversion**: Reads the full request body as a `List<int>`.
/// - **Outbound conversion**: Writes a binary `List<int>` directly to the response stream.
///
/// ### Supported Media Types
/// - `application/octet-stream`
///
/// ### Example
/// ```dart
/// final converter = ByteArrayHttpMessageConverter();
/// final bytes = await converter.read(List<int>, request);
/// await converter.write(bytes, response);
/// ```
///
/// ### Design Notes
/// - Used by JetLeaf for binary payloads such as file uploads/downloads.
/// - Optimized for direct byte stream transfer without text decoding.
/// - Registered internally by `HttpMessageConverters` for fallback binary handling.
/// {@endtemplate}
final class ByteArrayHttpMessageConverter extends AbstractHttpMessageConverter<List<int>> {
  /// {@macro byte_array_http_message_converter}
  ByteArrayHttpMessageConverter() : super() {
    super.addSupportedMediaType(MediaType.APPLICATION_OCTET_STREAM);
  }

  @override
  bool matchesType(Class type) {
    if (type == Class<List<int>>() || type.getType() == List<int>) {
      return true;
    }

    if (type.getType() == List && (type.componentType() == Class<int>() || type.componentType()?.getType() == int)) {
      return true;
    }

    return super.matchesType(type);
  }

  @override
  Future<List<int>> readInternal(Class<List<int>> type, HttpInputMessage inputMessage) async {
    return await inputMessage.getBody().readAll();
  }

  @override
  Future<void> writeInternal(List<int> object, HttpOutputMessage outputMessage) async {
    await outputMessage.getBody().write(object);
  }

  @override
  List<Object?> equalizedProperties() => [ByteArrayHttpMessageConverter];
}