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

/// {@template uri_builder}
/// Defines the contract for building [Uri] instances from templates,
/// path variables, and query parameters.
///
/// Implementations of [UriBuilder] are responsible for generating fully
/// qualified or relative URIs by interpolating template variables and
/// appending query parameters in a structured and predictable manner.
///
/// ### Core Responsibilities
/// 1. **Template Expansion** — Replace placeholders in the given URI
///    template (e.g., `"/users/{id}"`) with values supplied via the
///    [variables] map.
/// 2. **Query Parameter Composition** — Merge query parameters provided
///    through [queryParams] with any existing ones in the template.
/// 3. **Safe URI Construction** — Produce a valid [Uri] instance that can
///    be used for HTTP requests, routing, or link generation.
///
/// ### Example
/// ```dart
/// class CustomUriBuilder extends UriBuilder {
///   const CustomUriBuilder();
///
///   @override
///   Uri build(String template, Map<String, dynamic>? variables, Map<String, String>? queryParams) {
///     var url = template;
///
///     variables?.forEach((key, value) {
///       url = url.replaceAll('{$key}', value.toString());
///     });
///
///     final uri = Uri.parse(url);
///
///     if (queryParams != null && queryParams.isNotEmpty) {
///       return uri.replace(queryParameters: {
///         ...uri.queryParameters,
///         ...queryParams,
///       });
///     }
///
///     return uri;
///   }
/// }
///
/// void main() {
///   const builder = CustomUriBuilder();
///   final uri = builder.build('/api/users/{id}', {'id': 123}, {'active': 'true'});
///   print(uri); // /api/users/123?active=true
/// }
/// ```
///
/// ### Implementations
/// - [SimpleUriBuilder] — A lightweight implementation that supports
///   placeholder substitution and query parameter merging.
///
/// ### When to Use
/// Use this interface when:
/// - You need a consistent abstraction for building dynamic URLs.
/// - Your framework or SDK requires pluggable URI construction strategies.
/// - You want to separate routing or link generation logic from business code.
///
/// {@endtemplate}
abstract interface class UriBuilder {
  /// {@template uri_builder_constructor}
  /// Creates a new [UriBuilder] instance.
  ///
  /// Implementations should be immutable and stateless, allowing them to be
  /// reused safely across threads or isolates.
  ///
  /// ### Example
  /// ```dart
  /// const builder = SimpleUriBuilder();
  /// final uri = builder.build('/users/{id}', {'id': 1}, null);
  /// print(uri); // /users/1
  /// ```
  /// {@endtemplate}
  /// 
  /// {@macro uri_builder}
  const UriBuilder();
  
  /// {@macro uri_builder}
  ///
  /// Builds a [Uri] from the given [template], replacing placeholders
  /// defined as `{key}` with values from [variables], and appending
  /// additional query parameters from [queryParams].
  ///
  /// If both the template and query parameters contain overlapping keys,
  /// query parameters take precedence.
  ///
  /// ### Parameters
  /// - `template`: The base URI template (e.g., `"/api/{resource}/{id}"`).
  /// - `variables`: Optional map of placeholders and their values.
  /// - `queryParams`: Optional map of query parameters to include.
  ///
  /// ### Returns
  /// A fully constructed [Uri] instance.
  Uri build(String template, Map<String, dynamic>? variables, Map<String, String>? queryParams);
}

/// {@template simple_uri_builder}
/// A lightweight implementation of [UriBuilder] that constructs URIs from
/// string templates, variable placeholders, and optional query parameters.
///
/// `SimpleUriBuilder` provides a simple yet powerful mechanism for generating
/// URIs dynamically by substituting path variables and merging query parameters.
///
/// It supports three main operations:
///
/// 1. **Variable Substitution** — Replaces placeholders in the template
///    (e.g., `"/users/{id}"`) with values provided in the `variables` map.
/// 2. **Query Parameter Binding** — Merges query parameters from the given map
///    into the final URI.
/// 3. **Existing Query Preservation** — Retains any existing query parameters
///    already present in the URI template.
///
/// ### Example
/// ```dart
/// const builder = SimpleUriBuilder();
///
/// final uri = builder.build(
///   '/api/users/{userId}/posts',
///   {'userId': 42},
///   {'page': '2', 'limit': '10'},
/// );
///
/// print(uri.toString());
/// // Output: /api/users/42/posts?page=2&limit=10
/// ```
///
/// ### Use Cases
/// - Building REST API endpoint URIs dynamically.
/// - Generating links with variable paths and query parameters.
/// - Simplifying construction of service-to-service request URLs.
///
/// {@endtemplate}
final class SimpleUriBuilder implements UriBuilder {
  /// {@template simple_uri_builder_constructor}
  /// Creates a new [SimpleUriBuilder] instance.
  ///
  /// This implementation is **stateless** and **immutable**, meaning it can
  /// be safely reused across threads, isolates, or dependency-injected services.
  ///
  /// ### Example
  /// ```dart
  /// final builder = const SimpleUriBuilder();
  /// final uri = builder.build('/search', null, {'q': 'dart'});
  /// print(uri); // /search?q=dart
  /// ```
  /// {@endtemplate}
  /// 
  /// {@macro simple_uri_builder}
  const SimpleUriBuilder();

  @override
  Uri build(String template, Map<String, dynamic>? variables, Map<String, String>? queryParams) {
    var url = template;
    
    // Replace URI variables
    if (variables != null) {
      variables.forEach((key, value) {
        url = url.replaceAll('{$key}', value.toString());
      });
    }
    
    // Parse the URL
    final uri = Uri.parse(url);
    
    // Add query parameters
    if (queryParams != null && queryParams.isNotEmpty) {
      final existingParams = Map<String, String>.from(uri.queryParameters);
      existingParams.addAll(queryParams);
      return uri.replace(queryParameters: existingParams);
    }
    
    return uri;
  }
}