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
import 'package:jetleaf_pod/pod.dart';
import 'package:jetson/jetson.dart';

import '../http/http_message.dart';
import '../http/media_type.dart';
import 'abstract_http_message_converter.dart';

/// {@template jetson2_yaml_http_message_converter}
/// JetLeaf's YAML-based [AbstractHttpMessageConverter] backed by
/// the [ObjectMapper] from the Jetson serialization framework.
///
/// This converter provides full-featured **YAML serialization and
/// deserialization** for request and response bodies using Jetson's
/// reflective object mapping capabilities with YAML format support.
///
/// ### Overview
/// The [Jetson2YamlHttpMessageConverter] integrates Jetson's [ObjectMapper]
/// with JetLeaf's web I/O model ([HttpInputMessage], [HttpOutputMessage]),
/// enabling seamless YAML handling for annotated controllers.
///
/// ### Responsibilities
/// - Deserialize incoming YAML request bodies into Dart objects
/// - Serialize controller return values into YAML responses
/// - Support YAML-specific serialization options and features
///
/// ### Supported Media Types
/// - `application/yaml`
/// - `text/yaml`
/// - `text/x-yaml`
///
/// ### Example
/// ```dart
/// @RestController()
/// class ConfigController {
///   @GetMapping('/config', produces: ['application/yaml'])
///   Config getConfig() => Config(...);
/// }
/// ```
///
/// ### Design Notes
/// - Extends [AbstractHttpMessageConverter] with `Object` as the base type
/// - Uses Jetson's pluggable architecture for YAML support
/// - Ensures all YAML payloads are encoded properly (UTF-8 by default)
/// - Works seamlessly with content negotiation strategies
///
/// ### Related Types
/// - [ObjectMapper] — core Jetson component for serialization
/// - [AbstractHttpMessageConverter] — JetLeaf's HTTP I/O abstraction
/// - [Jetson2HttpMessageConverter] — JSON equivalent
/// - [Jetson2XmlHttpMessageConverter] — XML equivalent
/// {@endtemplate}
@Order(Ordered.HIGHEST_PRECEDENCE - 2)
class Jetson2YamlHttpMessageConverter extends AbstractHttpMessageConverter<Object> implements InitializingPod {
  /// The Jetson [ObjectMapper] responsible for YAML serialization/deserialization.
  final ObjectMapper _objectMapper;

  /// {@macro jetson2_yaml_http_message_converter}
  Jetson2YamlHttpMessageConverter(this._objectMapper) {
    super.addSupportedMediaType(MediaType.APPLICATION_YAML);
    super.addSupportedMediaType(MediaType.APPLICATION_XYAML);
    super.addSupportedMediaType(MediaType('text', 'yaml'));
    super.addSupportedMediaType(MediaType('text', 'x-yaml'));
  }
  
  @override
  List<Object?> equalizedProperties() => [Jetson2YamlHttpMessageConverter];
  
  @override
  String getPackageName() => PackageNames.WEB;
  
  @override
  Future<void> onReady() async {
    // YAML support discovered through Jetson's ObjectMapper configuration
  }

  @override
  bool canRead(Class type, [MediaType? mediaType]) => _objectMapper is YamlObjectMapper;

  @override
  bool canWrite(Class type, [MediaType? mediaType]) => _objectMapper is YamlObjectMapper;
  
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
}