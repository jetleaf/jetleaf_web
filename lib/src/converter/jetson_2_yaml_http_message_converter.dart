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

/// {@template jetson2_yaml_http_message_converter}
/// A high-priority HTTP message converter that uses Jetson’s YAML-capable
/// [ObjectMapper] to read and write YAML request and response bodies.
///
/// This converter:
///
/// * Is registered with `Ordered.HIGHEST_PRECEDENCE - 2`, running after the XML
///   converter and before other lower-precedence converters.
/// * Supports the standard and extended YAML media types:
///   - `application/yaml`  
///   - `application/x-yaml`  
///   - `text/yaml`  
///   - `text/x-yaml`
/// * Only participates in reading/writing when the configured `_objectMapper`
///   is a [YamlObjectMapper].
/// * Delegates all YAML → object and object → YAML transformations to Jetson.
/// * Honors declared request/response character encodings.
/// * Automatically assigns the `Content-Type` header (with charset) when not
///   already present.
///
/// ### Reading
///
/// The full request body is decoded using the resolved character encoding,
/// then passed into the YAML-aware Jetson mapper:
///
/// ```dart
/// mapper.readYamlValue(yamlString, type);
/// ```
///
/// If the provided object mapper is *not* a [YamlObjectMapper], the converter
/// gracefully falls back to generic Jetson deserialization:
///
/// ```dart
/// mapper.readValue(yamlString, type);
/// ```
///
/// Any parsing or mapping errors propagate naturally to the caller, where they
/// can be handled by the surrounding JetLeaf HTTP framework.
///
/// ### Writing
///
/// Objects are serialized using:
///
/// ```dart
/// mapper.writeValueAsYaml(object);
/// ```
///
/// with a fallback of:
///
/// ```dart
/// mapper.writeValueAsString(object);
/// ```
///
/// After serialization:
///
/// 1. The `Content-Type` header is set to `application/yaml` (with charset) if
///    not already specified.  
/// 2. The YAML string is written to the output stream using the resolved
///    encoding.
///
/// ### Application Context
///
/// This converter does not customize its mapper via dependency injection.
/// Instead, YAML support is enabled simply by providing a [YamlObjectMapper]
/// to the converter at construction time, or by exposing one in the
/// application context that Jetson is configured to use.
///
/// ### Example
///
/// ```dart
/// final converter = Jetson2YamlHttpMessageConverter(yamlMapper);
/// final dto = await converter.readInternal(Class<MyDto>(), inputMessage);
/// ```
///
/// Most JetLeaf applications automatically register this converter when a YAML
/// mapper is present in the environment.
///
/// {@endtemplate}
@Order(Ordered.HIGHEST_PRECEDENCE - 2)
class Jetson2YamlHttpMessageConverter extends AbstractHttpMessageConverter<Object> {
  /// The Jetson [ObjectMapper] responsible for serialization and deserialization.
  final ObjectMapper _objectMapper;

  /// {@macro jetson2_yaml_http_message_converter}
  Jetson2YamlHttpMessageConverter(this._objectMapper) {
    super.addSupportedMediaType(MediaType.APPLICATION_YAML);
    super.addSupportedMediaType(MediaType.APPLICATION_XYAML);
    super.addSupportedMediaType(MediaType('text', 'yaml'));
    super.addSupportedMediaType(MediaType('text', 'x-yaml'));
  }

  @override
  bool canRead(Class type, [MediaType? mediaType]) {
    if (mediaType != null && getSupportedMediaTypes().any((media) => media.isCompatibleWith(mediaType)) && _objectMapper is YamlObjectMapper) {
      return true;
    }

    return false;
  }

  @override
  bool canWrite(Class type, [MediaType? mediaType]) {
    if (mediaType != null && getSupportedMediaTypes().any((media) => media.isCompatibleWith(mediaType)) && _objectMapper is YamlObjectMapper) {
      return true;
    }

    return false;
  }
  
  @override
  Future<Object> readInternal(Class<Object> type, HttpInputMessage inputMessage) async {
    final encoding = resolveRequestEncoding(inputMessage);

    final stream = inputMessage.getBody();
    final yaml = await stream.readAsString(encoding);

    final mapper = _objectMapper;
    if (mapper is YamlObjectMapper) {
      return mapper.readYamlValue(yaml, type);
    } else {
      return mapper.readValue(yaml, type);
    }
  }
  
  @override
  Future<void> writeInternal(Object object, HttpOutputMessage outputMessage) async {
    final encoding = resolveResponseEncoding(outputMessage);
    final mapper = _objectMapper;
    
    String yamlString;
    if (mapper is YamlObjectMapper) {
      yamlString = mapper.writeValueAsYaml(object);
    } else {
      yamlString = mapper.writeValueAsString(object);
    }

    // Always ensure Content-Type is set correctly
    final contentType = outputMessage.getHeaders().getContentType();
    final resolved = contentType ?? MediaType.APPLICATION_YAML.withCharset(encoding.name);
    outputMessage.getHeaders().setContentType(resolved);

    return tryWith(outputMessage.getBody(), (output) async => await output.writeString(yamlString, encoding));
  }

  @override
  List<Object?> equalizedProperties() => [runtimeType];
}