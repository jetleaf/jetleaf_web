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
import 'package:jetleaf_pod/pod.dart';
import 'package:jetleaf_utils/utils.dart';
import '../annotation/core.dart';
import '../exception/exceptions.dart';
import '../http/http_status.dart';
import '../http/media_type.dart';
import '../path/path_pattern_parser.dart';
import '../server/server_http_request.dart';
import '../server/server_http_response.dart';
import '../web_configurer.dart';

/// {@template web_utils}
/// Utility methods for web-related operations, such as retrieving
/// HTTP response status codes from annotated methods or classes.
/// {@endtemplate}
final class WebUtils {
  /// {@macro web_utils}
  WebUtils._(); // private constructor to prevent instantiation

  /// {@macro web_utils}
  ///
  /// Retrieves the [HttpStatus] associated with a controller method or its
  /// declaring class via the [ResponseStatus] annotation.
  ///
  /// ### Parameters
  /// - [value]: The return value of a handler method (optional, used to inspect annotations on its type if not `void`).
  /// - [method]: The handler method to inspect for the [ResponseStatus] annotation.
  ///
  /// ### Returns
  /// The [HttpStatus] declared by [ResponseStatus], or `null` if no annotation is present.
  ///
  /// ### Lookup order:
  /// 1. Method-level [ResponseStatus] annotation.
  /// 2. Declaring class-level [ResponseStatus] annotation.
  /// 3. Return type-level [ResponseStatus] annotation, if `value` is not `null` or `void`.
  ///
  /// ### Example:
  /// ```dart
  /// final status = WebUtils.getResponseStatus(user, userMethod);
  /// if (status != null) {
  ///   response.setStatus(status);
  /// }
  /// ```
  static HttpStatus? getResponseStatus(Object? value, Method? method, [Object? ex]) {
    final status = method?.getDirectAnnotation<ResponseStatus>()
      ?? method?.getDeclaringClass().getDirectAnnotation<ResponseStatus>()
      ?? (value == null ? null : (ClassUtils.isVoid(value) ? null : Class.forObject(value).getDirectAnnotation<ResponseStatus>()));

    if (status != null) {
      return status.status;
    }

    if (ex != null) {
      if (ex is HttpException) {
        return ex.getStatus();
      }

      final exceptionClass = ex.getClass();
      final exStatus = exceptionClass.getDirectAnnotation<ResponseStatus>();
      if (exStatus != null) {
        return exStatus.status;
      }
    }

    return null;
  }

  /// {@template handle_cors}
  /// Applies CORS (Cross-Origin Resource Sharing) headers to the given request
  /// and response based on the [CrossOrigin] annotation found on a method or class.
  ///
  /// ### Parameters
  /// - [method]: The controller method to inspect for [CrossOrigin] annotations (optional).
  /// - [targetClass]: The class declaring the method, inspected if [method] is `null`.
  /// - [request]: The [ServerHttpRequest] whose headers will be updated.
  /// - [response]: The [ServerHttpResponse] to update if necessary (currently headers are set on request).
  ///
  /// ### Behavior
  /// 1. Determines the annotation source (`method` first, then `targetClass`).
  /// 2. If a [CrossOrigin] annotation exists:
  ///    - Sets `Access-Control-Allow-Credentials`
  ///    - Sets `Access-Control-Allow-Headers`
  ///    - Sets `Access-Control-Allow-Methods`
  ///    - Sets `Access-Control-Allow-Origin`
  ///    - Sets `Access-Control-Expose-Headers`
  ///    - Sets `Access-Control-Max-Age`
  ///
  /// This allows the server to control which origins, methods, and headers
  /// are permitted for cross-origin requests.
  ///
  /// {@endtemplate}
  static void handleCors(Method? method, Class? targetClass, ServerHttpRequest request, ServerHttpResponse response) {
    final source = method ?? targetClass;
    if (source == null) {
      return;
    }

    final cors = source.getDirectAnnotation<CrossOrigin>();
    if (cors != null) {
      request.getHeaders().setAccessControlAllowCredentials(cors.allowCredentials);
      request.getHeaders().setAccessControlAllowHeaders(cors.allowedHeaders);
      request.getHeaders().setAccessControlAllowMethods(cors.methods);
      request.getHeaders().setAccessControlAllowOrigin(StringUtils.collectionToCommaDelimitedString(cors.origins));
      request.getHeaders().setAccessControlExposeHeaders(cors.exposedHeaders);
      request.getHeaders().setAccessControlMaxAge(cors.maxAge);
    }
  }

  /// Attempts to locate and return a [WebConfigurer] instance from the provided
  /// [ConfigurableListablePodFactory].
  ///
  /// This method searches the dependency injection container for a pod of type [WebConfigurer].
  /// If such an instance exists, it will be retrieved and returned. Otherwise, `null` is returned.
  ///
  /// ### Parameters
  /// - [podFactory]: The [ConfigurableListablePodFactory] used to look up
  ///   registered component types.
  ///
  /// ### Returns
  /// A [Future] that completes with the [WebConfigurer] instance if found,
  /// or `null` if no such configuration exists.
  ///
  /// ### Example
  /// ```dart
  /// final podFactory = MyAppPodFactory();
  /// final webConfigurer = await WebUtils.findWebConfigurer(podFactory);
  ///
  /// if (webConfigurer != null) {
  ///   webConfigurer.configureRoutes();
  /// }
  /// ```
  ///
  /// ### See also
  /// - [WebConfigurer] for customizing web behavior and routing.
  /// - [ConfigurableListablePodFactory] for managing injectable components.
  static Future<WebConfigurer?> findWebConfigurer(ConfigurableListablePodFactory podFactory) async {
    final type = Class<WebConfigurer>(null, PackageNames.WEB);
    if (await podFactory.containsType(type)) {
      return await podFactory.get(type);
    }

    return null;
  }

  /// {@template do_combine_paths}
  /// Protected helper method that combines two individual path segments.
  ///
  /// ### Combination Algorithm
  ///
  /// This method implements the core path joining logic:
  /// 1. **Empty Path Check**: If either path is empty, returns the other
  /// 2. **Separator Adjustment**:
  ///    - Removes trailing separator from first path if present
  ///    - Adds leading separator to second path if missing
  /// 3. **Concatenation**: Joins the adjusted paths with a single separator
  ///
  /// ### Parameters
  /// - [path1]: The first path segment (typically left side of combination)
  /// - [path2]: The second path segment (typically right side of combination)
  ///
  /// ### Returns
  /// A combined path string with proper separator handling.
  ///
  /// ### Examples
  ///
  /// ```dart
  /// doCombinePaths('/api', 'v1/users');    // Returns: '/api/v1/users'
  /// doCombinePaths('/app/', '/dashboard'); // Returns: '/app/dashboard'
  /// doCombinePaths('', '/users');          // Returns: '/users'
  /// doCombinePaths('/api', '');            // Returns: '/api'
  /// ```
  ///
  /// ### Edge Case Handling
  ///
  /// - **Both paths empty**: Returns empty string
  /// - **First path with trailing slash**: Trailing slash is removed
  /// - **Second path with leading slash**: Leading slash is preserved
  /// - **Mixed separator scenarios**: Always results in single separator between paths
  ///
  /// ### Extension Point
  ///
  /// Subclasses can override this method to provide custom path combination
  /// logic while maintaining the standard [combinePaths] interface.
  ///
  /// ### Thread Safety
  ///
  /// This method is stateless and thread-safe, operating only on its parameters.
  /// {@endtemplate}
  static String doCombinePaths(String path1, String path2) {
    if (path1.isEmpty) return path2;
    if (path2.isEmpty) return path1;

    final p1 = path1.endsWith(PathPatternParser.PATH_SEPARATOR) ? path1.substring(0, path1.length - 1) : path1;
    final p2 = path2.startsWith(PathPatternParser.PATH_SEPARATOR) ? path2 : PathPatternParser.PATH_SEPARATOR + path2;

    return p1 + p2;
  }

  /// {@template combine_paths}
  /// Combines multiple path segments into a single normalized path.
  ///
  /// ### Path Combination Rules
  ///
  /// The combination follows these rules:
  /// - Empty segments are ignored
  /// - Duplicate slashes are collapsed
  /// - Leading/trailing slashes are handled appropriately
  /// - The result is always normalized
  ///
  /// ### Parameters
  /// - [contextPath]: The base context path (often application root)
  /// - [basePath]: Middle path segment (often controller base path)
  /// - [endpointPath]: Final path segment (often method mapping path)
  ///
  /// ### Returns
  /// A single combined and normalized path string.
  ///
  /// ### Example
  /// ```dart
  /// final fullPath = matcher.combinePaths('/app', '/api/v1', '/users');
  /// // Returns: '/app/api/v1/users'
  /// ```
  /// {@endtemplate}
  static String combinePaths(String contextPath, String basePath, String endpointPath) {
    // Combine all segments, collapse duplicate slashes, and normalize
    String combined = [contextPath, basePath, endpointPath]
      .where((s) => s.isNotEmpty)
      .join('/');
    combined = combined.replaceAll(RegExp(r'/+'), '/');
    return normalizePath(combined);
  }

  /// {@template normalize_path}
  /// Normalizes a path string for consistent matching and comparison.
  ///
  /// ### Normalization Rules
  ///
  /// Normalization typically includes:
  /// - Ensuring leading slash (except for empty paths)
  /// - Removing trailing slash (except for root path)
  /// - Converting empty path to root (`/`)
  /// - Preserving case sensitivity as configured
  ///
  /// ### Parameters
  /// - [path]: The path string to normalize
  ///
  /// ### Returns
  /// A normalized path string ready for matching operations.
  ///
  /// ### Example
  /// ```dart
  /// matcher.normalizePath('users/123/'); // Returns: '/users/123'
  /// matcher.normalizePath('');           // Returns: '/'
  /// matcher.normalizePath('/');          // Returns: '/'
  /// ```
  /// {@endtemplate}
  static String normalizePath(String path) {
    // Trim whitespace
    String normalized = path.trim();
    if (normalized.isEmpty) return PathPatternParser.PATH_SEPARATOR;

    // Collapse duplicate slashes
    normalized = normalized.replaceAll(RegExp(r'/+'), '/');

    // Remove trailing slash except for root
    if (normalized.endsWith(PathPatternParser.PATH_SEPARATOR) && normalized.length > 1) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    // Ensure leading slash
    if (!normalized.startsWith(PathPatternParser.PATH_SEPARATOR)) {
      normalized = PathPatternParser.PATH_SEPARATOR + normalized;
    }

    return normalized;
  }

  /// Returns the list of media types that a handler method or its declaring class
  /// explicitly declares it can produce, based on the `@Produces` annotation.
  ///
  /// This utility checks for a [`@Produces`] annotation on the provided [method],
  /// and if none is found, falls back to checking the declaring class of that method.
  ///
  /// Example:
  /// ```dart
  /// @Produces([MediaType.APPLICATION_JSON])
  /// class UserController {
  ///   @Produces([MediaType.APPLICATION_XML])
  ///   User getUser() => User(...);
  /// }
  ///
  /// final produces = WebUtils.producing(getUserMethod);
  /// // returns [MediaType.APPLICATION_XML]
  /// ```
  ///
  /// If neither the method nor its declaring class is annotated with `@Produces`,
  /// this method returns an empty list.
  ///
  /// - [method]: the handler method to inspect (may be `null`)
  /// - Returns: a list of [MediaType]s declared via `@Produces`, or an empty list
  ///   if none are found.
  static List<MediaType> producing(Method? method) {
    final produces = method?.getDirectAnnotation<Produces>() ?? method?.getDeclaringClass().getDirectAnnotation<Produces>();

    if (produces != null) {
      return produces.mediaTypes;
    }

    return [];
  }
}