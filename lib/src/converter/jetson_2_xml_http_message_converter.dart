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
import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';
import 'package:jetson/jetson.dart';

import '../http/http_message.dart';
import '../http/media_type.dart';
import 'abstract_http_message_converter.dart';

/// {@template jetson2_xml_http_message_converter}
/// JetLeaf's XML-based [AbstractHttpMessageConverter] backed by
/// the [ObjectMapper] from the Jetson serialization framework.
///
/// This converter provides full-featured **XML serialization and
/// deserialization** for request and response bodies using Jetson's
/// reflective object mapping capabilities with XML format support.
///
/// ### Overview
/// The [Jetson2XmlHttpMessageConverter] integrates Jetson's [ObjectMapper]
/// with JetLeaf's web I/O model ([HttpInputMessage], [HttpOutputMessage]),
/// enabling seamless XML handling for annotated controllers.
///
/// ### Responsibilities
/// - Deserialize incoming XML request bodies into Dart objects
/// - Serialize controller return values into XML responses
/// - Discover and register custom [XmlSerializer], [XmlDeserializer],
///   and [XmlConverterAdapter] implementations from the application context
///
/// ### Supported Media Types
/// - `application/xml`
/// - `text/xml`
///
/// ### Example
/// ```dart
/// @RestController()
/// class UserController {
///   @PostMapping('/user', consumes: ['application/xml'], produces: ['application/xml'])
///   User saveUser(User user) => user;
/// }
/// ```
///
/// ### Design Notes
/// - Extends [AbstractHttpMessageConverter] with `Object` as the base type
/// - Uses Jetson's pluggable architecture for XML support
/// - Ensures all XML payloads are encoded properly (UTF-8 by default)
/// - Works seamlessly with content negotiation strategies
///
/// ### Related Types
/// - [ObjectMapper] — core Jetson component for serialization
/// - [AbstractHttpMessageConverter] — JetLeaf's HTTP I/O abstraction
/// - [Jetson2HttpMessageConverter] — JSON equivalent
/// - [Jetson2YamlHttpMessageConverter] — YAML equivalent
/// {@endtemplate}
@Order(Ordered.HIGHEST_PRECEDENCE - 1)
class Jetson2XmlHttpMessageConverter extends AbstractHttpMessageConverter<Object> implements InitializingPod, ApplicationContextAware {
  /// The Jetson [ObjectMapper] responsible for XML serialization/deserialization.
  final ObjectMapper _objectMapper;

  /// {@macro jetson2_xml_http_message_converter}
  Jetson2XmlHttpMessageConverter(this._objectMapper) {
    super.addSupportedMediaType(MediaType.APPLICATION_XML);
    super.addSupportedMediaType(MediaType.TEXT_XML);
  }
  
  @override
  List<Object?> equalizedProperties() => [Jetson2XmlHttpMessageConverter];
  
  @override
  String getPackageName() => PackageNames.WEB;
  
  @override
  Future<void> onReady() async {
    // XML support discovered through Jetson's ObjectMapper configuration
    // No additional registrar discovery needed unless custom XML handlers exist
  }

  @override
  bool canRead(Class type, [MediaType? mediaType]) => _objectMapper is XmlObjectMapper;

  @override
  bool canWrite(Class type, [MediaType? mediaType]) => _objectMapper is XmlObjectMapper;
  
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
  void setApplicationContext(ApplicationContext podFactory) {
    // XML converter uses default Jetson XML configuration
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
}