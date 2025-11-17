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
import '../server_http_response.dart';
import 'content_negotiation_strategy.dart';

/// {@template content_negotiation_resolver}
/// Abstract interface for resolving content negotiation and setting
/// response headers automatically for all return value handlers.
///
/// ### Overview
/// The [ContentNegotiationResolver] acts as a centralized point for
/// applying content negotiation logic across all return value handlers.
/// Rather than each handler implementing content negotiation separately,
/// handlers delegate to this resolver, ensuring consistency and enabling
/// easy customization by users.
///
/// ### Key Responsibilities
/// - Negotiate the appropriate [MediaType] using configured strategy
/// - Set the response `Content-Type` header with the negotiated type
/// - Apply character encoding to the content type
/// - Handle fallback scenarios when no suitable type is found
/// - Provide a clean separation of concerns
///
/// ### Design Pattern
/// This implements the **Strategy Pattern** with **Dependency Injection**:
/// - Each handler receives a [ContentNegotiationResolver] instance
/// - The resolver encapsulates the negotiation algorithm
/// - Handlers invoke [resolve] without needing to know
///   the specific negotiation strategy being used
/// - Users can replace the resolver by providing a custom pod
///
/// ### Usage in Return Value Handlers
/// ```dart
/// class MyReturnValueHandler implements ReturnValueHandler {
///   final ContentNegotiationResolver _negotiationResolver;
///
///   MyReturnValueHandler(this._negotiationResolver);
///
///   @override
///   Future<void> handleReturnValue(...) async {
///     // Delegate content type resolution to the resolver
///     await _negotiationResolver.resolve(method, request, response, availableConverters);
///     
///     // Then proceed with handler-specific logic
///     // Response Content-Type header is already set
///   }
/// }
/// ```
///
/// ### Implementation Notes
/// - Implementations should be stateless and thread-safe
/// - Should handle null media types gracefully
/// - Can throw exceptions when no suitable type is found
/// - Typically maintains a reference to a [ContentNegotiationStrategy]
///
/// ### Related Components
/// - [ContentNegotiationStrategy] — Algorithm for determining media type
/// - [HttpMessageConverter] — Converters for specific media types
///
/// {@endtemplate}
abstract interface class ContentNegotiationResolver {
  /// Resolves the appropriate content type and sets the response
  /// `Content-Type` header automatically.
  ///
  /// ### Parameters
  /// - [method]: The handler method that produced the return value (nullable)
  /// - [request]: The incoming HTTP request
  /// - [response]: The HTTP response to update with Content-Type header
  /// - [supportedMediaTypes]: List of media types available for this value
  ///
  /// ### Responsibilities
  /// 1. Invoke the configured [ContentNegotiationStrategy] to negotiate media type
  /// 2. Set the response `Content-Type` header with the negotiated type
  /// 3. Handle encoding information (charset, etc.)
  /// 4. Provide appropriate error handling and fallback behavior
  ///
  /// ### Error Handling
  /// May throw exceptions if:
  /// - No suitable converter can handle the return value
  /// - Content negotiation fails completely
  /// - Response headers cannot be modified
  ///
  /// ### Example
  /// ```dart
  /// final user = User(id: 1, name: 'Alice');
  /// final supportedTypes = [
  ///   MediaType.APPLICATION_JSON,
  ///   MediaType.APPLICATION_XML,
  /// ];
  ///
  /// await resolver.resolve(user, method, request, response, supportedTypes);
  ///
  /// // Response now has Content-Type: application/json
  /// // (or application/xml depending on Accept header)
  /// ```
  Future<void> resolve(Method? method, ServerHttpRequest request, ServerHttpResponse response, List<MediaType> supportedMediaTypes);
}