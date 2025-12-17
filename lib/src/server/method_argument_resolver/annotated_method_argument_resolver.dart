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
import 'package:meta/meta.dart';

import '../../annotation/request_parameter.dart';
import '../server_http_request.dart';
import '../server_http_response.dart';
import '../handler_method.dart';
import 'method_argument_resolver.dart';

/// {@template jetleaf_annotated_method_argument_resolver}
/// Resolves parameters of handler methods annotated with request parameter
/// annotations in JetLeaf's web request handling system.
///
/// An [AnnotatedMethodArgumentResolver] is responsible for:
/// - Inspecting method parameters at runtime.
/// - Detecting annotations that are either [RequestParameter] or annotated
///   with [RequestParameter].
/// - Locating a corresponding [Resolver] (via [ResolvedBy]) to extract
///   values from the [ServerHttpRequest].
///
/// This resolver allows developers to define custom parameter resolution
/// strategies using annotations on method parameters, enabling a clean
/// separation between controller logic and request parsing.
///
/// ### Resolution Workflow
/// 1. **Annotation Discovery:** Collects all direct annotations on a parameter.
/// 2. **Type Matching:** Checks if an annotation is a [RequestParameter] or
///    is meta-annotated with [RequestParameter].
/// 3. **Resolver Extraction:** Looks for a [ResolvedBy] annotation on the
///    annotation class to retrieve the resolver instance.
/// 4. **Value Resolution:** Uses the resolver to extract the argument value
///    from the incoming request.
/// 5. Returns `null` if no suitable resolver is found.
///
/// ### Example
/// ```dart
/// class UserController {
///   void getUser(
///     @RequestParam('id') String id,
///     @RequestParam('verbose') bool verbose
///   ) {}
/// }
///
/// final resolver = AnnotatedMethodArgumentResolver();
/// final param = HandlerMethod(UserController.getUser).getParameter('id');
/// final value = await resolver.resolveArgument(param, request, response, handler);
/// ```
///
/// ### Design Notes
/// - This class is **stateless** and can be reused across multiple requests.
/// - Supports annotation-driven parameter resolution via [RequestParameter] and [ResolvedBy].
/// - Reflection failures while inspecting annotation metadata are silently ignored,
///   ensuring robust request handling.
/// - Designed for internal use in the JetLeaf request dispatch pipeline.
/// {@endtemplate}
final class AnnotatedMethodArgumentResolver implements MethodArgumentResolver {
  /// The [ResolverContext] to use for this resolver
  final ResolverContext _context;

  /// {@macro jetleaf_annotated_method_argument_resolver}
  const AnnotatedMethodArgumentResolver(this._context);

  @override
  Future<Object?> resolveArgument(Parameter param, ServerHttpRequest req, ServerHttpResponse res, HandlerMethod handler, [Object? ex, StackTrace? st]) async {
    final resolver = getResolver(param);
    if (resolver != null) {
      return await resolver.resolve(req, param, _context);
    }

    return null;
  }

  /// Retrieves the [Resolver] associated with a given [source] (parameter).
  ///
  /// The search follows these rules:
  /// 1. Collect all direct annotations on the [source].
  /// 2. For each annotation, check if it is a [RequestParameter] or is
  ///    meta-annotated with [RequestParameter].
  /// 3. Inspect the annotation’s metadata for a [ResolvedBy] annotation.
  /// 4. If found, return the [Resolver] provided by [ResolvedBy].
  ///
  /// Returns `null` if no suitable resolver is found.
  @protected
  Resolver? getResolver(Source source) {
    final parent = Class<RequestParameter>(null, PackageNames.WEB);

    for (final ann in source.getAllDirectAnnotations()) {
      final annClass = ann.getDeclaringClass();

      if (parent.isAssignableFrom(annClass) || ann.matches<RequestParameter>()) {
        for (final meta in annClass.getAllAnnotations()) {
          try {
            final metaClass = meta.getDeclaringClass();

            // If the annotation on the annotation class is a ResolvedBy, extract it
            if (Class<ResolvedBy>(null, PackageNames.WEB).isAssignableFrom(metaClass)) {
              final instance = meta.getInstance();

              if (instance is ResolvedBy) {
                return instance.resolver;
              }
            }
          } catch (e) {
            // ignore reflection failures
          }
        }
      }
    }

    return null;
  }

  @override
  bool canResolve(Parameter param) => getResolver(param) != null;
}