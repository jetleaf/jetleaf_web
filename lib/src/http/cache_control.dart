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

/// {@template cache_control}
/// Represents the HTTP `Cache-Control` header and allows fluent
/// construction of cache directives.
///
/// This class provides a **builder-style API** for setting common
/// cache control directives and generating a properly formatted
/// `Cache-Control` header string.
///
/// ### Features
/// - Supports standard HTTP cache directives such as `max-age`, `no-cache`,
///   `no-store`, `must-revalidate`, `public`, `private`, `immutable`, etc.
/// - Allows shared cache overrides via `s-maxage`.
/// - Provides fluent API for composing multiple directives in a single instance.
///
/// ### Example
/// ```dart
/// final cc = CacheControl.maxAge(Duration(minutes: 10))
///     .cachePublic()
///     .mustRevalidate()
///     .staleWhileRevalidate(Duration(seconds: 30));
///
/// print(cc.headerValue);
/// // Output: "max-age=600, public, must-revalidate, stale-while-revalidate=30"
/// ```
/// {@endtemplate}
final class CacheControl {
  /// Maximum age the response is considered fresh.
  Duration? _maxAge;

  /// Forces caches to revalidate the response before using a cached copy.
  bool _noCache = false;

  /// Prohibits caching of the response by any cache.
  bool _noStore = false;

  /// Forces caches to obey freshness information strictly.
  bool _mustRevalidate = false;

  /// Prevents intermediaries from modifying the response body.
  bool _noTransform = false;

  /// Marks the response as cacheable by any cache (including shared caches).
  bool _cachePublic = false;

  /// Marks the response as cacheable only by private caches.
  bool _cachePrivate = false;

  /// Requires shared caches to revalidate the response before reuse.
  bool _proxyRevalidate = false;

  /// Specifies how long a stale response may be served while revalidation occurs.
  Duration? _staleWhileRevalidate;

  /// Specifies how long a stale response may be served if an error occurs.
  Duration? _staleIfError;

  /// Overrides `max-age` for shared caches.
  Duration? _sMaxAge;

  /// Marks the response as immutable, preventing clients from revalidating.
  bool _immutable = false;

  // ---------------------------------------------------------------------------
  // Constructors
  // ---------------------------------------------------------------------------

  /// Private internal constructor.
  CacheControl._();

  /// {@macro cache_control}
  factory CacheControl.empty() => CacheControl._();

  /// Creates a `CacheControl` with a `max-age` directive.
  ///
  /// [maxAge] – The maximum age duration that the response is considered fresh.
  ///
  /// Example:
  /// ```dart
  /// final cc = CacheControl.maxAge(Duration(minutes: 5));
  /// print(cc.headerValue); // "max-age=300"
  /// ```
  factory CacheControl.maxAge(Duration maxAge) {
    final cc = CacheControl._();
    cc._maxAge = maxAge;
    return cc;
  }

  /// Creates a `CacheControl` with the `no-cache` directive.
  ///
  /// Indicates that caches **must revalidate** before serving a cached copy.
  factory CacheControl.noCache() {
    final cc = CacheControl._();
    cc._noCache = true;
    return cc;
  }

  /// Creates a `CacheControl` with the `no-store` directive.
  ///
  /// Indicates that the response **must not be cached** anywhere.
  factory CacheControl.noStore() {
    final cc = CacheControl._();
    cc._noStore = true;
    return cc;
  }

  // ---------------------------------------------------------------------------
  // Fluent Methods
  // ---------------------------------------------------------------------------

  /// Adds the `must-revalidate` directive.
  ///
  /// Ensures that caches strictly respect freshness information.
  CacheControl mustRevalidate() {
    _mustRevalidate = true;
    return this;
  }

  /// Adds the `no-transform` directive.
  ///
  /// Prevents intermediaries from modifying the response body.
  CacheControl noTransform() {
    _noTransform = true;
    return this;
  }

  /// Adds the `public` directive.
  ///
  /// Marks the response as cacheable by **any cache**, including shared caches.
  CacheControl cachePublic() {
    _cachePublic = true;
    return this;
  }

  /// Adds the `private` directive.
  ///
  /// Marks the response as cacheable only by **private caches** (e.g., user-agent).
  CacheControl cachePrivate() {
    _cachePrivate = true;
    return this;
  }

  /// Adds the `proxy-revalidate` directive.
  ///
  /// Requires that shared caches must revalidate the response before reuse.
  CacheControl proxyRevalidate() {
    _proxyRevalidate = true;
    return this;
  }

  /// Adds the `s-maxage` directive for shared caches.
  ///
  /// [sMaxAge] – Duration for which the response is considered fresh in **shared caches**.
  CacheControl sMaxAge(Duration sMaxAge) {
    _sMaxAge = sMaxAge;
    return this;
  }

  /// Adds the `stale-while-revalidate` directive.
  ///
  /// [duration] – Maximum duration (in seconds) that a stale response may be served
  /// while a new response is revalidated.
  CacheControl staleWhileRevalidate(Duration duration) {
    _staleWhileRevalidate = duration;
    return this;
  }

  /// Adds the `stale-if-error` directive.
  ///
  /// [duration] – Maximum duration (in seconds) that a stale response may be served
  /// in case of a backend error.
  CacheControl staleIfError(Duration duration) {
    _staleIfError = duration;
    return this;
  }

  /// Adds the `immutable` directive.
  ///
  /// Indicates that the response **will not change**, allowing clients to avoid revalidation.
  CacheControl immutable() {
    _immutable = true;
    return this;
  }

  // ---------------------------------------------------------------------------
  // Header Generation
  // ---------------------------------------------------------------------------

  /// Returns the formatted `Cache-Control` header string, or `null` if no directives are set.
  ///
  /// Example:
  /// ```dart
  /// final cc = CacheControl.maxAge(Duration(minutes: 5)).cachePublic();
  /// print(cc.headerValue); // "max-age=300, public"
  /// ```
  String? getHeaderValue() {
    final value = _toHeaderValue();
    return value.isNotEmpty ? value : null;
  }

  /// Builds the Cache-Control header string from the set directives.
  String _toHeaderValue() {
    final parts = <String>[];
    if (_maxAge != null) parts.add('max-age=${_maxAge!.inSeconds}');
    if (_noCache) parts.add('no-cache');
    if (_noStore) parts.add('no-store');
    if (_mustRevalidate) parts.add('must-revalidate');
    if (_noTransform) parts.add('no-transform');
    if (_cachePublic) parts.add('public');
    if (_cachePrivate) parts.add('private');
    if (_proxyRevalidate) parts.add('proxy-revalidate');
    if (_sMaxAge != null) parts.add('s-maxage=${_sMaxAge!.inSeconds}');
    if (_staleIfError != null) parts.add('stale-if-error=${_staleIfError!.inSeconds}');
    if (_staleWhileRevalidate != null) {
      parts.add('stale-while-revalidate=${_staleWhileRevalidate!.inSeconds}');
    }
    if (_immutable) parts.add('immutable');
    return parts.join(', ');
  }

  @override
  String toString() => 'CacheControl [${_toHeaderValue()}]';
}