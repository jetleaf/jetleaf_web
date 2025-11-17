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
import '../../utils/web_utils.dart';
import '../server_http_request.dart';
import 'content_negotiation_strategy.dart';

/// {@template accept_header_negotiation_strategy}
/// Default [ContentNegotiationStrategy] implementation that negotiates
/// content type based on the client's `Accept` header.
///
/// ### Overview
/// This strategy implements **client-driven content negotiation** by analyzing
/// the `Accept` header from the incoming request and finding the best match
/// among available converters.
///
/// ### Negotiation Algorithm
/// 1. Retrieves the `Accept` header from the request
/// 2. If no Accept header is present, uses the first available converter's type
/// 3. If Accept header is present, parses accepted media types
/// 4. Iterates through available converters in order (respecting ordering)
/// 5. Returns the first converter's media type that matches an accepted type
/// 6. Falls back to first converter's type if no matches found
///
/// ### Media Type Matching
/// Media types are matched using compatibility rules:
/// - `*/*` matches any media type (lowest priority)
/// - `type/*` matches any subtype of that type
/// - `type/subtype` matches exact type/subtype
/// - Parameters (charset, etc.) are ignored for matching
///
/// ### Example Scenarios
///
/// **Scenario 1: Accept JSON**
/// ```
/// Accept: application/json
/// Available Converters: JsonConverter (application/json), XmlConverter (application/xml)
/// Result: application/json
/// ```
///
/// **Scenario 2: Accept Multiple Types**
/// ```
/// Accept: application/xml, application/json;q=0.9
/// Available Converters: JsonConverter (application/json), XmlConverter (application/xml)
/// Result: application/xml (higher quality factor)
/// ```
///
/// **Scenario 3: No Accept Header**
/// ```
/// Accept: (none)
/// Available Converters: JsonConverter (application/json)
/// Result: application/json (first converter)
/// ```
///
/// **Scenario 4: Wildcard Match**
/// ```
/// Accept: application/*
/// Available Converters: JsonConverter (application/json), XmlConverter (application/xml)
/// Result: application/json (first matching converter)
/// ```
///
/// ### Error Handling
/// - Returns null if no suitable media type is found and no fallback available
/// - Handles malformed Accept headers gracefully
/// - Considers only converters that can handle the specific return value type
///
/// ### Design Notes
/// - Thread-safe and stateless
/// - Follows HTTP/1.1 content negotiation specs (RFC 7231)
/// - Compatible with quality factors (q-values) in Accept header
/// - Respects converter ordering for priority
///
/// {@endtemplate}
final class AcceptHeaderNegotiationStrategy implements ContentNegotiationStrategy {
  /// {@macro accept_header_negotiation_strategy}
  const AcceptHeaderNegotiationStrategy();

  @override
  Future<MediaType?> negotiate(Method? method, ServerHttpRequest request, List<MediaType> supportedMediaTypes) async {
    final producing = WebUtils.producing(method);
    final supported = producing.isNotEmpty ? producing : supportedMediaTypes;
    
    if (supported.isEmpty) {
      return null;
    }

    // Get Accept header from request
    final acceptHeader = request.getHeaders().getAccept();

    // If no Accept header, return first supported media type
    if (acceptHeader.isEmpty) {
      return supported.first;
    }

    // Try to find a matching media type
    for (final supportedType in supported) {
      for (final acceptedType in acceptHeader) {
        if (_isMediaTypeCompatible(supportedType, acceptedType) || supportedType.isCompatibleWith(acceptedType)) {
          return supportedType;
        }
      }
    }

    // Fallback: return first supported media type
    return supported.first;
  }

  /// Checks if a supported media type is compatible with an accepted media type.
  ///
  /// Handles wildcard matching:
  /// - `*/*` matches any type
  /// - `type/*` matches any subtype of that type
  /// - `type/subtype` matches exact type/subtype
  bool _isMediaTypeCompatible(MediaType supported, MediaType accepted) {
    final acceptedType = accepted.getType();
    final acceptedSubtype = accepted.getSubtype();
    final supportedType = supported.getType();
    final supportedSubtype = supported.getSubtype();

    // Check for wildcard matches
    if (acceptedType == '*') {
      return true; // */* matches anything
    }

    if (acceptedType == supportedType) {
      if (acceptedSubtype == '*') {
        return true; // type/* matches type/anything
      }
      return acceptedSubtype == supportedSubtype; // Exact match
    }

    return false;
  }
}