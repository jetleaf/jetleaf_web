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

import '../../annotation/core.dart';
import '../../converter/http_message_converters.dart';
import '../../exception/exceptions.dart';
import '../../http/http_body.dart';
import '../../http/http_status.dart';
import '../../http/media_type.dart';
import '../../utils/web_utils.dart';
import '../server_http_request.dart';
import '../server_http_response.dart';
import '../handler_method.dart';
import 'return_value_handler.dart';

/// {@template json_return_value_handler}
/// JetLeaf’s [ReturnValueHandler] implementation that handles
/// **JSON-serializable controller return values**.
///
/// This handler activates for controller methods declared in
/// `@RestController`-annotated classes, or for methods that directly
/// return objects intended for JSON serialization.
///
/// ### Overview
/// When a JetLeaf controller returns a Dart object (not a `String` or `ResponseBody`),
/// this handler locates an appropriate [HttpMessageConverter] capable of
/// writing the object as JSON and delegates serialization to it.
///
/// The JSON response is automatically written to the [ServerHttpResponse]
/// with an appropriate `Content-Type` (usually `application/json`).
///
/// ### Responsibilities
/// - Determine eligibility for JSON serialization
/// - Select an appropriate [HttpMessageConverter] for the object type
/// - Apply response encoding and media type negotiation
/// - Default to `200 OK` or `204 No Content` status codes when applicable
///
/// ### Example
/// ```dart
/// @RestController()
/// class UserController {
///   @Get('/user')
///   User getUser() => User('Alice', 30);
/// }
/// ```
///
/// The `JsonReturnValueHandler` automatically:
/// - Detects the `@RestController` annotation
/// - Serializes the `User` instance to JSON
/// - Writes it to the response body
///
/// ### Error Handling
/// Throws [HttpMediaTypeNotSupportedException] if no converter
/// can serialize the return value to the requested `Accept` type.
///
/// ### Design Notes
/// - Skips `String` and `ResponseBody` return types (delegated elsewhere)
/// - Uses [HttpMessageConverters] registry for dynamic converter lookup
/// - Respects client `Accept` headers for content negotiation
///
/// ### Related Components
/// - [HttpMessageConverters] — registry of available message converters  
/// - [Jetson2HttpMessageConverter] — JSON converter based on Jetson serialization  
/// - [ResponseBodyReturnValueHandler] — handles raw HTTP response bodies  
/// - [ReturnValueHandler] — base strategy interface
/// {@endtemplate}
final class JsonReturnValueHandler implements ReturnValueHandler {
  /// Central registry of [HttpMessageConverter] instances used for
  /// reading and writing request/response bodies.
  final HttpMessageConverters _converters;

  /// {@macro json_return_value_handler}
  JsonReturnValueHandler(this._converters);

  @override
  bool canHandle(Method? method, Object? returnValue, ServerHttpRequest request) {
    if (returnValue == null) return false;

    // Exclude special types handled by other resolvers
    if (returnValue is String || returnValue is ResponseBody) return false;

    // If method or declaring class has @ResponseBody or @RestController
    if (method != null && method.getDeclaringClass().hasDirectAnnotation<RestController>()) {
      return true;
    }

    if (returnValue is Map || returnValue is List || returnValue is Iterable) {
      return true;
    }

    return false;
  }

  @override
  List<Object?> equalizedProperties() => [JsonReturnValueHandler];

  @override
  List<MediaType> getSupportedMediaTypes() => [MediaType.APPLICATION_JSON];

  @override
  Future<void> handleReturnValue(Object? returnValue, Method? method, ServerHttpRequest request, ServerHttpResponse response, HandlerMethod? hm) async {
    if (returnValue == null) {
      if (response.getStatus() != null) {
        return;
      }
      
      response.setStatus(HttpStatus.NO_CONTENT);
      return;
    }

    final contentType = WebUtils.resolveMediaTypeAsJson(response);
    final valueClass = Class.forObject(returnValue);

    final converter = _converters.findWritable(valueClass, contentType);
    if (converter == null) {
      throw HttpMediaTypeNotSupportedException('No suitable HttpMessageConverter found for ${valueClass.getName()} and type $contentType');
    }

    final status = WebUtils.getResponseStatus(returnValue, method) ?? HttpStatus.OK;

    // Default 200 OK if not set yet
    if (response.getStatus() == null) {
      response.setStatus(status);
    }

    await converter.write(returnValue, contentType, response);
  }
}