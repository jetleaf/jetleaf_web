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

/// {@template xml_return_value_handler}
/// [ReturnValueHandler] implementation that handles **XML-serializable**
/// controller return values.
///
/// This handler activates for controller methods intended to return XML
/// responses and automatically serializes the return value as XML using
/// an appropriate [HttpMessageConverter].
///
/// ### Overview
/// When a handler returns an object with XML media type negotiation,
/// this handler locates an appropriate converter and delegates serialization.
///
/// Content-Type header negotiation is applied globally by the
/// [DefaultReturnValueHandlerManager] before handler invocation, ensuring
/// consistent header management across all handlers.
///
/// ### Responsibilities
/// - Determine eligibility for XML serialization
/// - Select suitable [HttpMessageConverter] for the object type
/// - Write response using converter with already-negotiated Content-Type
/// - Default to `200 OK` status when applicable
///
/// ### Error Handling
/// Throws [HttpMediaTypeNotSupportedException] if no converter
/// can serialize to the requested type.
///
/// ### Related Components
/// - [HttpMessageConverters] — registry of available converters
/// - [ResponseBodyReturnValueHandler] — handles raw responses
/// - [DefaultReturnValueHandlerManager] — applies content negotiation globally
///
/// {@endtemplate}
final class XmlReturnValueHandler implements ReturnValueHandler {
  /// Central registry of [HttpMessageConverter] instances.
  final HttpMessageConverters _converters;

  /// {@macro xml_return_value_handler}
  XmlReturnValueHandler(this._converters);

  @override
  bool canHandle(Method? method, Object? returnValue, ServerHttpRequest request) {
    if (returnValue == null) return false;

    // Exclude special types
    if (returnValue is String || returnValue is ResponseBody) return false;

    // Check if method explicitly produces XML
    if (method != null) {
      final produces = WebUtils.producing(method);

      // If *any* of the declared media types match the supported XML ones
      return produces.any((type) => getSupportedMediaTypes().any((supported) => supported.includes(type)));
    }

    return false; // Only handle if explicitly marked
  }

  @override
  List<Object?> equalizedProperties() => [XmlReturnValueHandler];

  @override
  List<MediaType> getSupportedMediaTypes() => [
    MediaType.TEXT_XML,
    MediaType.APPLICATION_XML,
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

    final valueClass = Class.forObject(returnValue);
    final xmlConverters = _converters.getMessageConverters()
        .where((c) => c.getSupportedMediaTypes().any((mt) => mt.getType() == 'application' && mt.getSubtype() == 'xml'))
        .toList();

    if (xmlConverters.isEmpty) {
      throw HttpMediaTypeNotSupportedException('No suitable XML HttpMessageConverter found for ${valueClass.getName()}');
    }

    final status = WebUtils.getResponseStatus(returnValue, method) ?? HttpStatus.OK;
    if (response.getStatus() == null) {
      response.setStatus(status);
    }

    // Content-Type header already set globally by DefaultReturnValueHandlerManager
    final mediaType = response.getHeaders().getContentType() ?? MediaType.APPLICATION_XML;
    final converter = _converters.findWritable(valueClass, mediaType);
    if (converter == null) {
      throw HttpMediaTypeNotSupportedException('No suitable converter for $mediaType');
    }

    await converter.write(returnValue, mediaType, response);
  }
}
