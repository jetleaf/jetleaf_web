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

/// {@template jetson2_xml_http_message_converter}
/// A high-priority HTTP message converter that uses Jetson’s XML-capable
/// [ObjectMapper] to read and write XML request and response bodies.
///
/// This converter:
///
/// * Is registered with `Ordered.HIGHEST_PRECEDENCE - 1`, running immediately
///   after the JSON converter.
/// * Supports `application/xml` and `text/xml` media types.
/// * Only activates for reading or writing when the configured `_objectMapper`
///   is an [XmlObjectMapper].
/// * Delegates all XML → object and object → XML processing to Jetson.
/// * Respects declared request/response character encodings.
/// * Automatically sets the `Content-Type` response header (with charset)
///   when missing.
///
/// ### Reading
///
/// The full request body is read using the resolved encoding and passed into
/// the Jetson XML mapper:
///
/// ```dart
/// mapper.readXmlValue(xmlString, type);
/// ```
///
/// If the provided object mapper is not an [XmlObjectMapper], this converter
/// falls back to:
///
/// ```dart
/// mapper.readValue(xmlString, type);
/// ```
///
/// (This fallback is primarily useful for advanced integration scenarios.)
///
/// Any XML parsing or mapping errors bubble up naturally and are handled by the
/// surrounding web framework.
///
/// ### Writing
///
/// Serialization uses the XML mapping function when available:
///
/// ```dart
/// mapper.writeValueAsXml(object);
/// ```
///
/// and otherwise falls back to:
///
/// ```dart
/// mapper.writeValueAsString(object);
/// ```
///
/// After serialization:
///
/// 1. The `Content-Type` header is set to an XML media type if missing.  
/// 2. The XML string is written to the output stream in the resolved encoding.
///
/// ### Application Context
///
/// Unlike the JSON converter, this class does **not** customize its mapper via
/// dependency injection, because XML usage is typically explicit and mapper
/// configuration is expected to be provided externally.
///
/// ### Example
///
/// ```dart
/// final converter = Jetson2XmlHttpMessageConverter(xmlMapper);
/// final dto = await converter.readInternal(Class<MyDto>(), inputMessage);
/// ```
///
/// Most JetLeaf applications pick up this converter automatically when an
/// [XmlObjectMapper] is present in the application context.
///
/// {@endtemplate}
@Order(Ordered.HIGHEST_PRECEDENCE - 1)
class Jetson2XmlHttpMessageConverter extends AbstractHttpMessageConverter<Object> {
  /// The Jetson [ObjectMapper] responsible for serialization and deserialization.
  final ObjectMapper _objectMapper;

  /// {@macro jetson2_xml_http_message_converter}
  Jetson2XmlHttpMessageConverter(this._objectMapper) {
    super.addSupportedMediaType(MediaType.APPLICATION_XML);
    super.addSupportedMediaType(MediaType.TEXT_XML);
  }

  @override
  bool canRead(Class type, [MediaType? mediaType]) {
    if (mediaType != null && getSupportedMediaTypes().any((media) => media.isCompatibleWith(mediaType)) && _objectMapper is XmlObjectMapper) {
      return true;
    }

    return false;
  }

  @override
  bool canWrite(Class type, [MediaType? mediaType]) {
    if (mediaType != null && getSupportedMediaTypes().any((media) => media.isCompatibleWith(mediaType)) && _objectMapper is XmlObjectMapper) {
      return true;
    }

    return false;
  }
  
  @override
  Future<Object> readInternal(Class<Object> type, HttpInputMessage inputMessage) async {
    final encoding = resolveRequestEncoding(inputMessage);

    final stream = inputMessage.getBody();
    final xml = await stream.readAsString(encoding);
    
    final mapper = _objectMapper;
    if (mapper is XmlObjectMapper) {
      return mapper.readXmlValue(xml, type);
    } else {
      return mapper.readValue(xml, type);
    }
  }
  
  @override
  Future<void> writeInternal(Object object, HttpOutputMessage outputMessage) async {
    final encoding = resolveResponseEncoding(outputMessage);
    final mapper = _objectMapper;
    
    String xmlString;
    if (mapper is XmlObjectMapper) {
      xmlString = mapper.writeValueAsXml(object);
    } else {
      xmlString = mapper.writeValueAsString(object);
    }

    // Always ensure Content-Type is set correctly
    final contentType = outputMessage.getHeaders().getContentType();
    final resolved = contentType ?? MediaType.APPLICATION_XML.withCharset(encoding.name);
    outputMessage.getHeaders().setContentType(resolved);

    return tryWith(outputMessage.getBody(), (output) async => await output.writeString(xmlString, encoding));
  }

  @override
  List<Object?> equalizedProperties() => [runtimeType];
}