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
import 'package:jetleaf_pod/pod.dart';
import 'package:jetson/jetson.dart';

import '../converter/common_http_message_converters.dart';
import '../converter/http_message_converters.dart';
import '../converter/jetson_2_http_message_converter.dart';
import '../converter/jetson_2_xml_http_message_converter.dart';
import '../converter/jetson_2_yaml_http_message_converter.dart';
import '../converter/form_http_message_converter.dart';
import '../converter/http_message_converter.dart';

/// {@template http_message_converter_configuration}
/// Auto-configuration class for HTTP message converters in Jetleaf.
///
/// This configuration provides the default infrastructure pods
/// required for reading and writing HTTP request and response bodies:
/// - Collection of `HttpMessageConverters`
/// - String, byte array, and JSON (Jetson2) converters
///
/// pods are marked with `@Role(DesignRole.INFRASTRUCTURE)` indicating
/// that they are framework infrastructure. Conditional registration
/// allows developers to override with custom pods if needed.
/// {@endtemplate}
@Named(HttpMessageAutoConfiguration.NAME)
@AutoConfiguration()
@Role(DesignRole.INFRASTRUCTURE)
final class HttpMessageAutoConfiguration {
  /// Class name pod for this configuration.
  static const String NAME = "jetleaf.web.HttpMessageAutoConfiguration";

  /// {@template jetleaf_web_http.http_message_converters_pod_name}
  /// Pod name for the collection of HTTP message converters.
  ///
  /// Provides a registry of converters to read from and write to HTTP
  /// request and response bodies, supporting multiple media types.
  /// {@endtemplate}
  static const String HTTP_MESSAGE_CONVERTERS_POD_NAME = "jetleaf.web.http.httpMessageConverters";

  /// {@template jetleaf_web_http.jetson2_http_message_converter_pod_name}
  /// Pod name for the JSON (Jetson2) HTTP message converter.
  ///
  /// Converts Dart objects to JSON and vice versa using the Jetson2
  /// serialization library.
  /// {@endtemplate}
  static const String JETSON_2_HTTP_MESSAGE_CONVERTER_POD_NAME = "jetleaf.web.http.jetson2HttpMessageConverter";

  /// {@template jetleaf_web_http.string_http_message_converter_pod_name}
  /// Pod name for the String HTTP message converter.
  ///
  /// Handles conversion between plain text strings and HTTP request
  /// or response bodies.
  /// {@endtemplate}
  static const String STRING_HTTP_MESSAGE_CONVERTER_POD_NAME = "jetleaf.web.http.stringHttpMessageConverter";

  /// {@template jetleaf_web_http.byte_array_http_message_converter_pod_name}
  /// Pod name for the byte array HTTP message converter.
  ///
  /// Handles conversion between raw byte arrays and HTTP request or
  /// response bodies.
  /// {@endtemplate}
  static const String BYTE_ARRAY_HTTP_MESSAGE_CONVERTER_POD_NAME = "jetleaf.web.http.byteArrayHttpMessageConverter";

  /// {@template jetleaf_web_http.jetson2_xml_http_message_converter_pod_name}
  /// Pod name for the XML HTTP message converter using Jetson2.
  ///
  /// Converts Dart objects to and from XML representations, allowing
  /// XML-based request and response handling in controllers.
  /// {@endtemplate}
  static const String JETSON_2_XML_HTTP_MESSAGE_CONVERTER_POD_NAME = "jetleaf.web.http.jetson2XmlHttpMessageConverter";

  /// {@template jetleaf_web_http.jetson2_yaml_http_message_converter_pod_name}
  /// Pod name for the YAML HTTP message converter using Jetson2.
  ///
  /// Converts Dart objects to and from YAML representations, providing
  /// YAML serialization support for request and response bodies.
  /// {@endtemplate}
  static const String JETSON_2_YAML_HTTP_MESSAGE_CONVERTER_POD_NAME = "jetleaf.web.http.jetson2YamlHttpMessageConverter";

  /// {@template jetleaf_web_http.form_http_message_converter_pod_name}
  /// Pod name for the form HTTP message converter.
  ///
  /// Handles conversion between `application/x-www-form-urlencoded`
  /// form data and HTTP request or response bodies, supporting traditional
  /// HTML form submissions.
  /// {@endtemplate}
  static const String FORM_HTTP_MESSAGE_CONVERTER_POD_NAME = "jetleaf.web.http.formHttpMessageConverter";

  /// {@template http_message_converters_pod}
  /// Provides the registry of HTTP message converters.
  ///
  /// This pod aggregates all registered `HttpMessageConverter` instances,
  /// allowing the framework to select the appropriate converter for
  /// reading request bodies and writing response bodies.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: HTTP_MESSAGE_CONVERTERS_POD_NAME)
  HttpMessageConverters httpMessageConverters() => HttpMessageConverters();

  /// {@template string_http_message_converter_pod}
  /// Provides a `String` HTTP message converter.
  ///
  /// Handles conversion between plain text strings and HTTP request
  /// or response bodies.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: STRING_HTTP_MESSAGE_CONVERTER_POD_NAME)
  HttpMessageConverter stringHttpMessageConverter() => StringHttpMessageConverter();

  /// {@template byte_array_http_message_converter_pod}
  /// Provides a byte array HTTP message converter.
  ///
  /// Handles conversion between raw byte arrays and HTTP request or
  /// response bodies.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: BYTE_ARRAY_HTTP_MESSAGE_CONVERTER_POD_NAME)
  HttpMessageConverter byteArrayHttpMessageConverter() => ByteArrayHttpMessageConverter();

  /// {@template jetson2_http_message_converter_pod}
  /// Provides a JSON HTTP message converter using Jetson2.
  ///
  /// Converts Dart objects to JSON and vice versa, delegating
  /// serialization and deserialization to the provided `ObjectMapper`.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: JETSON_2_HTTP_MESSAGE_CONVERTER_POD_NAME)
  HttpMessageConverter jetson2HttpMessageConverter(ObjectMapper mapper) => Jetson2HttpMessageConverter(mapper);

  /// {@template jetson2_xml_http_message_converter_pod}
  /// Provides an XML HTTP message converter using Jetson2.
  ///
  /// Converts Dart objects to XML and vice versa for XML request/response bodies.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: JETSON_2_XML_HTTP_MESSAGE_CONVERTER_POD_NAME)
  HttpMessageConverter jetson2XmlHttpMessageConverter(ObjectMapper mapper) => Jetson2XmlHttpMessageConverter(mapper);

  /// {@template jetson2_yaml_http_message_converter_pod}
  /// Provides a YAML HTTP message converter using Jetson2.
  ///
  /// Converts Dart objects to YAML and vice versa for YAML request/response bodies.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: JETSON_2_YAML_HTTP_MESSAGE_CONVERTER_POD_NAME)
  HttpMessageConverter jetson2YamlHttpMessageConverter(ObjectMapper mapper) => Jetson2YamlHttpMessageConverter(mapper);

  /// {@template form_http_message_converter_pod}
  /// Provides a form data HTTP message converter.
  ///
  /// Handles conversion between application/x-www-form-urlencoded form data
  /// and HTTP request or response bodies.
  /// {@endtemplate}
  @Role(DesignRole.INFRASTRUCTURE)
  @Pod(value: FORM_HTTP_MESSAGE_CONVERTER_POD_NAME)
  HttpMessageConverter formHttpMessageConverter() => FormHttpMessageConverter();
}