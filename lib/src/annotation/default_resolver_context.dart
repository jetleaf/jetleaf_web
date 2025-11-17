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

import 'request_parameter.dart';
import '../converter/http_message_converters.dart';
import '../converter/http_message_converter.dart';
import '../http/media_type.dart';

/// {@template default_resolver_context}
/// Default implementation of [ResolverContext] backed by [HttpMessageConverters].
///
/// The [DefaultResolverContext] delegates converter lookup to a provided
/// [HttpMessageConverters] registry. It acts as the canonical lookup bridge
/// between the web layer and available HTTP message converters (JSON, text,
/// binary, etc.).
///
/// ### Responsibilities
/// - Provide a single place for locating the first compatible
///   [HttpMessageConverter] for **reading** request bodies (deserialization).
/// - Provide a single place for locating the first compatible
///   [HttpMessageConverter] for **writing** response bodies (serialization).
/// - Delegate ordering and compatibility decisions to [HttpMessageConverters].
///
/// ### Typical Uses
/// - Passed into argument resolvers that need to deserialize request bodies.
/// - Used by return-value handlers to find a suitable serializer for responses.
/// - Supplied to components that perform content negotiation.
///
/// ### Behavior & Guarantees
/// - This implementation performs **no** converter selection logic itself;
///   it forwards requests to the underlying [HttpMessageConverters].
/// - The ordering, media-type compatibility, and capability checks are the
///   responsibility of the injected registry.
///
/// ### Example
/// ```dart
/// final converters = HttpMessageConverters([JsonConverter(), StringConverter()]);
/// final context = DefaultResolverContext(converters);
///
/// final writer = context.findWritable(Product.class, MediaType.APPLICATION_JSON);
/// if (writer != null) {
///   await writer.write(product, MediaType.APPLICATION_JSON, response);
/// }
/// ```
///
/// ### See also
/// - [ResolverContext] — the interface this class implements.
/// - [HttpMessageConverters] — the registry that actually holds converters.
/// - [HttpMessageConverter] — converter interface for reading/writing messages.
/// {@endtemplate}
@Author("Evaristus Adimonyemma")
final class DefaultResolverContext implements ResolverContext {
  /// The composite registry of all available [HttpMessageConverter]s.
  ///
  /// This instance determines which converters can read or write
  /// given media types and Dart types.
  final HttpMessageConverters _converter;

  /// Creates a new [DefaultResolverContext] backed by the given [_converter].
  ///
  /// {@macro default_resolver_context}
  const DefaultResolverContext(this._converter);

  @override
  HttpMessageConverter? findReadable(Class type, MediaType? mediaType) => _converter.findReadable(type, mediaType);

  @override
  HttpMessageConverter? findWritable(Class type, MediaType mediaType) => _converter.findWritable(type, mediaType);
}