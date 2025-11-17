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

/// {@template jetson2_http_message_converter}
/// JetLeaf’s default JSON-based [AbstractHttpMessageConverter] backed by
/// the [ObjectMapper] from the Jetson serialization framework.
///
/// This converter provides full-featured **JSON serialization and
/// deserialization** for request and response bodies using Jetson’s
/// reflective object mapping capabilities.
///
/// ### Overview
/// The [Jetson2HttpMessageConverter] integrates Jetson’s [ObjectMapper]
/// with JetLeaf’s web I/O model ([HttpInputMessage], [HttpOutputMessage]),
/// enabling seamless JSON handling for annotated controllers.
///
/// It is automatically registered by JetLeaf’s web subsystem with the
/// lowest precedence, ensuring that custom converters or more specialized
/// ones can override it if needed.
///
/// ### Responsibilities
/// - Deserialize incoming JSON request bodies into Dart objects
/// - Serialize controller return values into JSON responses
/// - Discover and register custom [JsonSerializer], [JsonDeserializer],
///   and [JsonConverterAdapter] implementations from the application context
///
/// ### Supported Media Types
/// - `application/json`
/// - `application/vnd.api+json`
///
/// ### Initialization Lifecycle
/// As an [InitializingPod] and [ApplicationContextAware] component, this
/// converter:
/// 1. Receives the [ApplicationContext] via [setApplicationContext].
/// 2. Resolves all registered Jetson components (`JsonSerializer`,
///    `JsonDeserializer`, `JsonConverterAdapter`, etc.).
/// 3. Registers them with the [ObjectMapper] during [onReady].
///
/// ### Example
/// ```dart
/// final objectMapper = ObjectMapper();
/// final converter = Jetson2HttpMessageConverter(objectMapper);
///
/// // Reading JSON into a Dart object
/// final user = await converter.readInternal(User.CLASS, request);
///
/// // Writing an object as JSON
/// await converter.writeInternal(user, response);
/// ```
///
/// ### Design Notes
/// - Extends [AbstractHttpMessageConverter] with `Object` as the base type,
///   supporting any serializable model.
/// - Uses Jetson’s pluggable architecture to register serializers,
///   deserializers, and adapters automatically.
/// - Ordered with [Ordered.HIGHEST_PRECEDENCE] to act as a fallback converter.
/// - Ensures all JSON payloads are encoded with the resolved charset
///   (`UTF-8` by default).
///
/// ### Related Types
/// - [ObjectMapper] — core Jetson component for serialization/deserialization.
/// - [AbstractHttpMessageConverter] — JetLeaf’s HTTP I/O abstraction base.
/// - [HttpMessageConverters] — registry managing available converters.
/// {@endtemplate}
@Order(Ordered.HIGHEST_PRECEDENCE)
class Jetson2HttpMessageConverter extends AbstractHttpMessageConverter<Object> implements InitializingPod, ApplicationContextAware {
  /// The Jetson [ObjectMapper] responsible for serialization and deserialization.
  final ObjectMapper _objectMapper;

  /// The current JetLeaf [ApplicationContext] for dependency resolution.
  late ApplicationContext _applicationContext;

  /// {@macro jetson2_http_message_converter}
  Jetson2HttpMessageConverter(this._objectMapper) {
    super.addSupportedMediaType(MediaType.APPLICATION_JSON);
    super.addSupportedMediaType(MediaType('application', 'vnd.api+json'));
  }
  
  @override
  List<Object?> equalizedProperties() => [Jetson2HttpMessageConverter];
  
  @override
  String getPackageName() => PackageNames.WEB;
  
  @override
  Future<void> onReady() async {
    final serializers = await _applicationContext.getPodsOf(JsonSerializer.CLASS, allowEagerInit: true);
    if (serializers.isNotEmpty) {
      final ordered = AnnotationAwareOrderComparator.getOrderedItems(serializers.values);
      for (final value in ordered) {
        _objectMapper.registerSerializer(value.toClass(), value);
      }
    } else {
      // No registrars found - this is normal for many applications
    }

    final deserializers = await _applicationContext.getPodsOf(JsonDeserializer.CLASS, allowEagerInit: true);
    if (deserializers.isNotEmpty) {
      final ordered = AnnotationAwareOrderComparator.getOrderedItems(deserializers.values);
      for (final value in ordered) {
        _objectMapper.registerDeserializer(value.toClass(), value);
      }
    } else {
      // No registrars found - this is normal for many applications
    }

    final adapters = await _applicationContext.getPodsOf(JsonConverterAdapter.CLASS, allowEagerInit: true);
    if (adapters.isNotEmpty) {
      final ordered = AnnotationAwareOrderComparator.getOrderedItems(adapters.values);
      for (final value in ordered) {
        _objectMapper.registerAdapter(value.toClass(), value);
      }
    } else {
      // No registrars found - this is normal for many applications
    }

    if (await _applicationContext.containsType(JsonGenerator.CLASS)) {
      final value = await _applicationContext.get(JsonGenerator.CLASS);
      _objectMapper.setJsonGenerator(value);
    }

    if (await _applicationContext.containsType(DeserializationContext.CLASS)) {
      final value = await _applicationContext.get(DeserializationContext.CLASS);
      _objectMapper.setDeserializationContext(value);
    }

    if (await _applicationContext.containsType(NamingStrategy.CLASS)) {
      final value = await _applicationContext.get(NamingStrategy.CLASS);
      _objectMapper.setNamingStrategy(value);
    }

    if (await _applicationContext.containsType(SerializerProvider.CLASS)) {
      final value = await _applicationContext.get(SerializerProvider.CLASS);
      _objectMapper.setSerializerProvider(value);
    }
  }
  
  @override
  Future<Object> readInternal(Class<Object> type, HttpInputMessage inputMessage) async {
    final encoding = resolveRequestEncoding(inputMessage);

    final stream = inputMessage.getBody();
    final json = await stream.readAsString(encoding);
    return _objectMapper.readValue(json, type);
  }
  
  @override
  void setApplicationContext(ApplicationContext podFactory) {
    _applicationContext = podFactory;
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
}