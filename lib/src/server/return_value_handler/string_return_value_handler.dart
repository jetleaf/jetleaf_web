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

import '../../http/http_status.dart';
import '../../http/media_type.dart';
import '../server_http_request.dart';
import '../server_http_response.dart';
import '../../web/view.dart';
import '../handler_method.dart';
import 'return_value_handler.dart';

/// {@template string_return_value_handler}
/// JetLeaf’s [ReturnValueHandler] responsible for handling
/// controller methods that return **plain string content**.
///
/// This handler interprets a string return value as direct response body
/// content, writing it to the [ServerHttpResponse] with a `text/plain`
/// media type by default.
///
/// ### Overview
/// The `StringReturnValueHandler` processes simple `String` responses from
/// controllers that are **not redirects** and **not templates**.
/// Redirects (`"redirect:/..."`) are delegated to
/// [RedirectReturnValueHandler].
///
/// ### Responsibilities
/// - Writes `String` return values directly to the response body  
/// - Sets `Content-Type` based on the client’s `Accept` header, or defaults
///   to `text/plain`  
/// - Ensures an `HTTP 200 OK` status if none is explicitly set  
/// - Flushes the response stream after writing
///
/// ### Example
/// ```dart
/// @RestController()
/// class PingController {
///   @Get('/ping')
///   String ping() => 'pong';
/// }
/// ```
///
/// **Resulting Response:**
/// ```http
/// HTTP/1.1 200 OK
/// Content-Type: text/plain
///
/// pong
/// ```
///
/// ### Design Notes
/// - Avoids processing `"redirect:/..."` strings to prevent overlap with
///   `RedirectReturnValueHandler`.  
/// - Content negotiation honors the first accepted media type from
///   the `Accept` header.  
/// - Primarily used for lightweight REST endpoints or debugging utilities.
///
/// ### Related Components
/// - [RedirectReturnValueHandler] — handles `"redirect:/..."` strings  
/// - [JsonReturnValueHandler] — serializes structured objects to JSON  
/// - [VoidReturnValueHandler] — finalizes void or null responses
/// {@endtemplate}
final class StringReturnValueHandler implements ReturnValueHandler {
  /// {@macro string_return_value_handler}
  const StringReturnValueHandler();

  @override
  bool canHandle(Method? method, Object? returnValue, ServerHttpRequest request) {
    if (returnValue == null) return false;
    return returnValue is String && !(returnValue.startsWith(View.REDIRECT_ATTRIBUTE)); // handled by Redirect handler
  }

  @override
  List<Object?> equalizedProperties() => [StringReturnValueHandler];

  @override
  List<MediaType> getSupportedMediaTypes() => [
    MediaType.TEXT_PLAIN,
    MediaType.TEXT_HTML,
    MediaType('text', 'csv'),
    MediaType.TEXT_XML,
  ];

  @override
  Future<void> handleReturnValue(Object? returnValue, Method? method, ServerHttpRequest request, ServerHttpResponse response, HandlerMethod? hm) async {
    final contentType = request.getHeaders().getAccept().firstOrNull ?? MediaType.TEXT_PLAIN;
    response.getHeaders().setContentType(contentType);

    if (response.getStatus() == null) {
      response.setStatus(HttpStatus.OK);
    }

    return tryWith(response.getBody(), (output) async => await output.writeString(returnValue.toString()));
  }
}