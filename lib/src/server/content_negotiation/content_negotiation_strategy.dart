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

import '../../http/media_type.dart';
import '../server_http_request.dart';

/// {@template content_negotiation_strategy}
/// Abstract strategy for determining the appropriate [MediaType] to use
/// when writing HTTP response bodies.
///
/// ### Overview
/// The [ContentNegotiationStrategy] defines the contract for content negotiation
/// algorithms in JetLeaf. Different implementations can employ various strategies:
/// - **Client-driven**: Based on `Accept` headers
/// - **Server-driven**: Based on server configuration
/// - **Dynamic**: Based on request parameters or resource state
/// - **Hybrid**: Combining multiple factors
///
/// ### Responsibilities
/// - Analyze request headers and context to determine response media type
/// - Consider request parameters, resource properties, and server configuration
/// - Return the most appropriate [MediaType] for the response
/// - Provide fallback behavior when no suitable type is found
///
/// ### Usage Pattern
/// ```dart
/// final strategy = ClientAcceptHeaderNegotiationStrategy();
/// final mediaType = strategy.negotiate(returnValue, method, request);
/// // mediaType is now the negotiated content type
/// ```
///
/// ### Implementation Examples
/// - **ClientAcceptHeaderNegotiationStrategy**: Uses `Accept` header from request
/// - **FixedMediaTypeStrategy**: Always returns a specific media type
/// - **ConfigBasedStrategy**: Uses application configuration
/// - **HybridStrategy**: Combines multiple strategies with fallback
///
/// ### Design Notes
/// - Implementations should be stateless and thread-safe
/// - Should handle missing/malformed headers gracefully
/// - Must return a valid [MediaType] or null to indicate no match
/// - Can throw exceptions for invalid states
/// 
/// {@endtemplate}
abstract interface class ContentNegotiationStrategy {
  /// Negotiates the appropriate [MediaType] for the response.
  ///
  /// ### Parameters
  /// - [method]: The handler method that produced the return value (nullable)
  /// - [request]: The incoming HTTP request with headers and context
  /// - [supportedMediaTypes]: List of media types available for this return value
  ///
  /// ### Returns
  /// The negotiated [MediaType] for the response, or null if no suitable
  /// media type could be determined.
  ///
  /// ### Responsibilities
  /// - Analyze request Accept headers
  /// - Check handler method annotations if available
  /// - Consider return value type and availability of media types
  /// - Apply fallback strategies if necessary
  ///
  /// ### Error Handling
  /// May throw exceptions for:
  /// - Invalid media types in Accept header
  /// - Incompatible return value and accept types
  /// - Configuration errors
  Future<MediaType?> negotiate( Method? method, ServerHttpRequest request, List<MediaType> supportedMediaTypes);
}