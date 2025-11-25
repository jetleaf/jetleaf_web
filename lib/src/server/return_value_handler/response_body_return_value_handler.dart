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

/// {@template response_body_return_value_handler}
/// JetLeaf’s [ReturnValueHandler] responsible for processing
/// controller methods that return a [ResponseBody] instance.
///
/// This handler bridges the gap between the framework’s response abstraction
/// and the underlying [HttpMessageConverters], allowing arbitrary Dart objects
/// to be written to the HTTP response stream using proper content negotiation.
///
/// ### Overview
/// The `ResponseBodyReturnValueHandler` is used exclusively by
/// `@RestController` classes that return a [ResponseBody].  
/// It delegates the serialization process to the configured
/// [HttpMessageConverters], ensuring proper `Content-Type` handling,
/// encoding, and HTTP status propagation.
///
/// ### Responsibilities
/// - Detects and handles `ResponseBody` return values  
/// - Selects an appropriate [HttpMessageConverter] based on response type and
///   client `Accept` headers  
/// - Applies the status code defined in [ResponseBody.status]  
/// - Writes serialized output to the [ServerHttpResponse]
///
/// ### Example
/// ```dart
/// @RestController()
/// class UserController {
///   @Get('/users/{id}')
///   ResponseBody getUser(@PathVariable('id') String id) {
///     final user = userService.findById(id);
///     if (user == null) {
///       return ResponseBody.of('User not found', HttpStatus.NOT_FOUND);
///     }
///     return ResponseBody.of(user, HttpStatus.OK);
///   }
/// }
/// ```
///
/// **Resulting Response:**
/// ```http
/// HTTP/1.1 200 OK
/// Content-Type: application/json
///
/// { "id": "42", "name": "Alice" }
/// ```
///
/// ### Design Notes
/// - Only applies to controllers annotated with [RestController].  
/// - Delegates serialization to the first compatible [HttpMessageConverter].  
/// - Throws [HttpMediaTypeNotSupportedException] if no suitable converter
///   is available for the given object and content type.
/// - Uses client `Accept` headers to select the most appropriate response format.
///
/// ### Related Components
/// - [JsonReturnValueHandler] — serializes plain object responses to JSON  
/// - [StringReturnValueHandler] — writes plain text responses  
/// - [VoidReturnValueHandler] — handles void or null return types
/// {@endtemplate}
final class ResponseBodyReturnValueHandler implements ReturnValueHandler {
  /// The configured HTTP message converters responsible for serializing
  /// response objects into various media types.
  final HttpMessageConverters _converters;

  /// {@macro response_body_return_value_handler}
  ResponseBodyReturnValueHandler(this._converters);

  @override
  bool canHandle(Method? method, Object? returnValue, ServerHttpRequest request) {
    if (method != null && method.getDeclaringClass().hasDirectAnnotation<RestController>() && returnValue is ResponseBody) {
      return true;
    }

    return returnValue is ResponseBody;
  }

  @override
  List<Object?> equalizedProperties() => [ResponseBodyReturnValueHandler];

  @override
  List<MediaType> getSupportedMediaTypes() => [
    MediaType.APPLICATION_JSON,
    MediaType.APPLICATION_XML,
    MediaType.APPLICATION_YAML,
    MediaType.TEXT_PLAIN,
    MediaType.TEXT_HTML,
  ];

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
    final body = returnValue as ResponseBody;
    response.setStatus(body.status);
    final valueToWrite = body.getBody();

    if (valueToWrite == null) {
      return tryWith(response.getBody(), (stream) => stream.flush());
    }
    
    final valueClass = Class.forObject(valueToWrite);
    final writer = _converters.findWritable(valueClass, contentType);

    if (writer == null) {
      throw HttpMediaTypeNotSupportedException('No suitable HttpMessageConverter found for type ${valueClass.getName()} and content type $contentType');
    }

    return writer.write(valueToWrite, contentType, response);
  }
}