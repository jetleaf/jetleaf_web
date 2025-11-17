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

import '../io/io_request.dart';
import '../server/server_http_request.dart';
import '../server/server_http_response.dart';

/// {@template web_request}
/// Represents a unified abstraction over an HTTP request–response interaction.
///
/// The [WebRequest] class serves as a container that binds a [ServerHttpRequest]
/// and its corresponding [ServerHttpResponse], allowing filters, interceptors,
/// and controllers to operate on the same logical web exchange.
///
/// ### Purpose
/// - Simplifies access to both request and response within the same object.
/// - Provides lifecycle timing utilities (request start, completion, duration).
/// - Enables reflective access via the static [CLASS] constant for
///   runtime type inspection and dependency resolution.
///
/// ### Reflection Support
/// The static [CLASS] field exposes the runtime [Class] metadata used by the
/// JetLeaf reflection system. This allows the framework to dynamically detect,
/// resolve, or inject instances of [WebRequest] in annotated controller methods.
///
/// ### Example
/// ```dart
/// final webRequest = WebRequest(req, res);
/// log.info('Started at: ${webRequest.getRequestedAt()}');
///
/// await controller.handle(webRequest.getRequest(), webRequest.getResponse());
///
/// final duration = webRequest.getDuration();
/// if (duration != null) {
///   log.info('Request completed in ${duration.inMilliseconds} ms');
/// }
/// 
/// extension TenantAwareWebRequest on WebRequest {
///  /// Returns the tenant ID if the underlying [ServerHttpRequest]
///  /// is a [CustomHttpRequest].
///  ///
///  /// If the request type does not match, returns `null`.
///  String? getTenantId() {
///    final req = getRequest();
///    if (req is CustomHttpRequest) {
///      return req.tenantId;
///    }
///    return null;
///  }
///
///  /// Convenience method to check whether this request belongs
///  /// to a particular tenant.
///  bool isTenant(String tenantId) => getTenantId() == tenantId;
/// }
/// ```
///
/// ### Notes
/// - Subclasses of [ServerHttpRequest] (e.g., [IoRequest]) may provide their own
///   timing metadata for performance tracing.
/// - If either timestamp is unavailable, [getDuration] will return `null`.
/// - Equality checks are based on class identity rather than field values.
/// {@endtemplate}
class WebRequest with EqualsAndHashCode {
  // ---------------------------------------------------------------------------
  // Fields
  // ---------------------------------------------------------------------------

  /// Represents the [WebRequest] type for reflection purposes.
  ///
  /// This static [Class] instance allows the framework to access metadata,
  /// type information, and perform reflective operations on [WebRequest] objects.
  /// Used in argument resolution, type checks, and dynamic dispatch.
  static final Class CLASS = Class<WebRequest>(null, PackageNames.WEB);

  /// The underlying HTTP request associated with this web exchange.
  ///
  /// Provides access to request metadata such as method, URI, headers, and body.
  /// Typically an instance of [ServerHttpRequest] or its subtype (e.g., [IoRequest]).
  final ServerHttpRequest _httpRequest;

  /// The corresponding HTTP response object for this request.
  ///
  /// Provides APIs for writing headers, status codes, and response bodies.
  /// Ensures both sides of the exchange can be accessed from a single context.
  final ServerHttpResponse _httpResponse;

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------

  /// Creates a new [WebRequest] binding the given [ServerHttpRequest]
  /// and [ServerHttpResponse] instances into a single exchange context.
  ///
  /// ### Example
  /// ```dart
  /// final request = WebRequest(incomingRequest, outgoingResponse);
  /// print(request.getRequest().getUri());
  /// ```
  /// 
  /// {@macro web_request}
  WebRequest(this._httpRequest, this._httpResponse);

  // ---------------------------------------------------------------------------
  // Accessors
  // ---------------------------------------------------------------------------

  /// Returns the underlying [ServerHttpRequest] for this web exchange.
  ///
  /// Provides full access to the incoming request, including headers,
  /// parameters, method, and payload.
  ServerHttpRequest getRequest() => _httpRequest;

  /// Returns the [ServerHttpResponse] associated with this web exchange.
  ///
  /// Enables response writing, header manipulation, and status management.
  ServerHttpResponse getResponse() => _httpResponse;

  // ---------------------------------------------------------------------------
  // Timing Utilities
  // ---------------------------------------------------------------------------

  /// Returns the timestamp at which the request was originally received.
  ///
  /// - For [IoRequest] instances, this value comes from [IoRequest.getCreatedAt].
  /// - For other [ServerHttpRequest] subtypes, this may be `null` unless
  ///   the subclass explicitly provides timing metadata.
  ///
  /// ### Returns
  /// A [DateTime] marking when the request was created, or `null` if unavailable.
  DateTime? getRequestedAt() {
    if (_httpRequest is IoRequest) {
      return _httpRequest.getCreatedAt();
    }
    return null;
  }

  /// Returns the timestamp when the request–response exchange completed.
  ///
  /// - For [IoRequest] instances, this is derived from [IoRequest.getCompletedAt].
  /// - For other implementations, this may be `null` unless explicitly supported.
  ///
  /// ### Returns
  /// A [DateTime] marking completion time, or `null` if not provided.
  DateTime? getCompletedAt() {
    if (_httpRequest is IoRequest) {
      return _httpRequest.getCompletedAt();
    }
    return null;
  }

  /// Computes the total duration of the request lifecycle.
  ///
  /// The duration is calculated as:
  /// ```dart
  /// getCompletedAt().difference(getRequestedAt());
  /// ```
  ///
  /// If either timestamp is unavailable, this returns `null`.
  ///
  /// ### Example
  /// ```dart
  /// final duration = webRequest.getDuration();
  /// if (duration != null) {
  ///   print('Took ${duration.inMilliseconds} ms');
  /// }
  /// ```
  Duration? getDuration() {
    final completedAt = getCompletedAt();
    final requestedAt = getRequestedAt();

    if (completedAt == null || requestedAt == null) {
      return null;
    }
    return completedAt.difference(requestedAt);
  }

  // ---------------------------------------------------------------------------
  // Equality and Hashing
  // ---------------------------------------------------------------------------

  /// Provides the list of properties used in equality and hash code comparisons.
  ///
  /// Equality for [WebRequest] is based solely on its class identity,
  /// ensuring that requests are compared as distinct logical exchanges
  /// rather than by their underlying request or response values.
  @override
  List<Object?> equalizedProperties() => [WebRequest];
}