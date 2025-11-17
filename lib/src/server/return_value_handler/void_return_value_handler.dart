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
import '../handler_method.dart';
import 'return_value_handler.dart';

/// {@template void_return_value_handler}
/// JetLeaf’s [ReturnValueHandler] implementation for controller
/// methods that return **void** or produce **no response body**.
///
/// This handler ensures a clean and predictable response flow for endpoints
/// that do not explicitly return data, such as:
/// - `void` controller methods
/// - `Future<void>` asynchronous handlers
/// - Methods that complete work but send no response content
///
/// ### Overview
/// When a controller method does not return a value, the framework routes
/// handling to `VoidReturnValueHandler`.  
/// It finalizes the HTTP response with a `204 No Content` status if
/// the response has not already been committed.
///
/// ### Responsibilities
/// - Detects methods returning `void` or `null` values
/// - Ensures proper HTTP semantics for empty responses
/// - Prevents duplicate response writes after a committed response
///
/// ### Example
/// ```dart
/// @RestController()
/// class TaskController {
///   @Post('/tasks/cleanup')
///   void cleanupOldTasks() {
///     taskService.removeExpired();
///     // Returns no content, handled by VoidReturnValueHandler
///   }
/// }
/// ```
///
/// Resulting HTTP response:
/// ```http
/// HTTP/1.1 204 No Content
/// ```
///
/// ### Design Notes
/// - This handler is always considered **lowest precedence**; other handlers
///   may intercept first if they can process the return value.
/// - Explicitly flushes the response body to ensure completion in streaming contexts.
/// - Does not modify headers or body when the response is already committed.
///
/// ### Related Components
/// - [JsonReturnValueHandler] — handles object-to-JSON serialization  
/// - [StringReturnValueHandler] — handles string and template returns  
/// - [ResponseBodyReturnValueHandler] — writes raw [ResponseBody] content
/// {@endtemplate}
final class VoidReturnValueHandler implements ReturnValueHandler {
  /// {@macro void_return_value_handler}
  const VoidReturnValueHandler();

  @override
  bool canHandle(Method? method, Object? returnValue, ServerHttpRequest request) {
    return (method != null && method.isFutureVoid()) || returnValue == null;
  }

  @override
  List<Object?> equalizedProperties() => [VoidReturnValueHandler];

  @override
  List<MediaType> getSupportedMediaTypes() => [];

  @override
  Future<void> handleReturnValue(Object? returnValue, Method? method, ServerHttpRequest request, ServerHttpResponse response, HandlerMethod? hm) async {
    if (!response.isCommitted()) {
      if (response.getStatus() == null) {
        response.setStatus(HttpStatus.NO_CONTENT);
      }

      return tryWith(response.getBody(), (stream) => stream.flush());
    }
  }
}
