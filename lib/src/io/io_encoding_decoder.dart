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

import 'dart:convert';
import 'dart:typed_data';

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';

import '../utils/encoding.dart';

/// {@template pluggable_encoding_decoder}
/// A **pluggable, multi-encoding decoder** that supports dynamic registration
/// of custom [EncodingDecoder] implementations while providing a fallback
/// [EncodingDecoder] for unsupported encodings.
///
/// The [IoEncodingDecoder] acts as a central registry and coordinator
/// for encoding/decoding operations across multiple character encodings.
/// It delegates requests to user-defined [EncodingDecoder] instances, if
/// available, or defers to the configured fallback decoder for all other
/// cases.
///
/// ### Overview
/// - Enables **runtime extensibility** — new encodings can be added or replaced
///   dynamically using [registerHandler].
/// - Ensures **compatibility and robustness** by always delegating to a fallback
///   decoder (defaults to [BasicEncodingDecoder]) when no handler is available.
/// - Provides unified APIs for text encoding, decoding, and supported encoding
///   enumeration.
/// - Internally normalizes encoding names to lowercase for consistent lookup.
///
/// ### Typical Use Cases
/// - Supporting **custom or legacy encodings** (e.g., Shift-JIS, GB2312).
/// - Extending base decoding behavior for **application-specific formats**.
/// - Centralizing all encoding logic in I/O, HTTP, and serialization layers.
///
/// ### Design Notes
/// - Thread-safe for concurrent encoding operations, assuming all handlers are.
/// - Encodings are matched case-insensitively (`utf-8`, `UTF-8`, `Utf8` → same).
/// - Unregistered encodings automatically fall back to the default decoder.
/// - Handlers can be dynamically added, removed, or replaced at runtime.
///
/// ### Example
/// ```dart
/// final decoder = IoEncodingDecoder();
/// decoder.registerHandler('shift-jis', ShiftJisEncodingHandler());
///
/// final bytes = Uint8List.fromList([0x82, 0xA0]);
/// print(decoder.decode(bytes, 'shift-jis')); // "あ"
/// ```
///
/// ### See Also
/// - [EncodingDecoder] — Low-level encoding/decoding abstraction.
/// - [EncodingDecoder] — Base interface for all multi-encoding decoders.
/// - [BasicEncodingDecoder] — Default implementation using Dart’s `dart:convert`.
/// {@endtemplate}
class IoEncodingDecoder implements EncodingDecoder, ApplicationContextAware, InitializingPod {
  /// The application context used to discover and register encoding decoder pods.
  ///
  /// This field is set via [setApplicationContext] and is required for
  /// automatic discovery of `EncodingDecoder` implementations when
  /// [onReady] is called.
  late ApplicationContext _applicationContext;

  /// A registry of user-defined [EncodingDecoder]s mapped by normalized
  /// (lowercase) encoding names.
  ///
  /// Each entry associates an encoding identifier (e.g., `"utf-8"`,
  /// `"shift-jis"`, `"iso-8859-1"`) with its corresponding handler instance.
  ///
  /// This collection allows runtime extensibility — new encodings can be added,
  /// updated, or removed without recompilation.
  ///
  /// ### Example
  /// ```dart
  /// decoder.registerHandler('gbk', GbkEncodingHandler());
  /// ```
  final List<EncodingDecoder> _customHandlers = [];

  /// The fallback [EncodingDecoder] used when no registered handler exists
  /// for a given encoding.
  ///
  /// By default, this is an instance of [BasicEncodingDecoder], which relies on
  /// standard Dart codecs (`utf-8`, `latin1`, `ascii`, etc.). You can override
  /// it via the constructor to chain decoders or integrate specialized logic.
  ///
  /// ### Example
  /// ```dart
  /// final decoder = IoEncodingDecoder(MyCustomFallbackDecoder());
  /// ```
  final EncodingDecoder _fallbackDecoder;

  /// Creates a new [IoEncodingDecoder] instance with an optional
  /// [fallbackDecoder].
  ///
  /// - **Parameters:**
  ///   - `fallbackDecoder`: The [EncodingDecoder] to delegate to when no custom
  ///     [EncodingDecoder] is found. Defaults to [BasicEncodingDecoder].
  ///
  /// ### Example
  /// ```dart
  /// final decoder = IoEncodingDecoder();
  /// // or
  /// final decoder = IoEncodingDecoder(CustomDecoder());
  /// ```
  /// 
  /// {@macro pluggable_encoding_decoder}
  IoEncodingDecoder([EncodingDecoder? fallbackDecoder])
      : _fallbackDecoder = fallbackDecoder ?? BasicEncodingDecoder();

  /// Registers a custom encoding for the specified [decoder].
  ///
  /// The encoding name is stored in lowercase.
  void registerHandler(EncodingDecoder decoder) {
    return synchronized(_customHandlers, () {
      _customHandlers.remove(decoder);
      _customHandlers.add(decoder);
    });
  }

  /// Removes a previously registered handler for the specified [decoder].
  ///
  /// If no handler was registered for this encoding, nothing happens.
  void removeHandler(EncodingDecoder decoder) {
    return synchronized(_customHandlers, () {
      _customHandlers.remove(decoder);
    });
  }

  @override
  String getPackageName() => PackageNames.WEB;

  @override
  Future<void> onReady() async {
    final type = Class<EncodingDecoder>(null, PackageNames.WEB);
    final pods = await _applicationContext.getPodsOf(type);
    final ordered = AnnotationAwareOrderComparator.getOrderedItems(pods.values);

    for (final order in ordered) {
      if (order is IoEncodingDecoder) continue;

      registerHandler(order);
    }
  }

  @override
  void setApplicationContext(ApplicationContext applicationContext) {
    _applicationContext = applicationContext;
  }

  @override
  String decode(Uint8List bytes, {String encodingString = 'utf-8', Encoding? encoding}) {
    if (encoding != null) {
      return encoding.decode(bytes);
    }

    final normalizedEncoding = encodingString.toLowerCase();
    final handler = _customHandlers.find((hand) => hand.supportsEncoding(normalizedEncoding));

    if (handler != null) {
      return handler.decode(bytes);
    }

    return _fallbackDecoder.decode(bytes, encodingString: encodingString, encoding: encoding);
  }

  @override
  Uint8List encode(String text, {String encodingString = 'utf-8', Encoding? encoding}) {
    if (encoding != null) {
      return Uint8List.fromList(encoding.encode(text));
    }

    final normalizedEncoding = encodingString.toLowerCase();
    final handler = _customHandlers.find((hand) => hand.supportsEncoding(normalizedEncoding));

    if (handler != null) {
      return handler.encode(text);
    }

    return _fallbackDecoder.encode(text, encodingString: encodingString, encoding: encoding);
  }

  @override
  bool supportsEncoding(String encoding) {
    final normalizedEncoding = encoding.toLowerCase();
    final handler = _customHandlers.find((hand) => hand.supportsEncoding(normalizedEncoding));

    return handler != null || _fallbackDecoder.supportsEncoding(encoding);
  }

  @override
  List<String> getSupportedEncodings() {
    final supported = <String>{};
    supported.addAll(_customHandlers.flatMap((t) => t.getSupportedEncodings()));
    supported.addAll(_fallbackDecoder.getSupportedEncodings());
    return supported.toList();
  }
}