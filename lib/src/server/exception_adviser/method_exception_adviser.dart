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

/// {@template jetleaf_method_exception_adviser}
/// Internal resolver that maps exception types to their corresponding handler methods
/// within a `@ControllerAdvice`, `@RestControllerAdvice`, or annotated controller.
///
/// A [MethodExceptionAdviser] is responsible for analyzing a reflective class
/// (usually annotated with [ControllerAdvice] or [RestControllerAdvice]) and
/// determining which methods are designated as **exception handlers** via:
///
/// - `@ExceptionHandler(ExceptionType)` — standard JetLeaf annotation  
/// - `@Catch(ExceptionType)` — alternative alias for handler declaration
///
/// It builds a **mapping** of `ExceptionType → Method` and can efficiently resolve
/// the appropriate handler for a given exception type at runtime.
///
/// ### Example
/// ```dart
/// @ControllerAdvice()
/// class GlobalErrorAdvice {
///   @ExceptionHandler(UserNotFoundException)
///   ResponseBody<String> handleUserNotFound(UserNotFoundException e) =>
///       ResponseBody.of('User not found', HttpStatus.NOT_FOUND);
///
///   @Catch(DatabaseException)
///   ResponseBody<String> handleDatabaseError(DatabaseException e) =>
///       ResponseBody.of('Database error', HttpStatus.INTERNAL_SERVER_ERROR);
/// }
///
/// // During runtime:
/// final adviser = MethodExceptionAdviser(ClassUtils.loadClass(GlobalErrorAdvice));
/// final handler = adviser.advises(ClassUtils.loadClass(UserNotFoundException));
/// print(handler?.getName()); // -> "handleUserNotFound"
/// ```
///
/// ### Matching Rules
/// When resolving a handler for a thrown exception:
/// 1. **Exact match** — if an exception type is explicitly registered, it takes precedence.
/// 2. **Assignable match** — if not found, searches for the *most specific* superclass
///    or interface handler capable of handling that exception.
/// 3. **Parameter fallback** — if no annotation value is declared, parameter types
///    of handler methods are inspected for exception subclasses.
///
/// ### Design Notes
/// - This class is used internally by JetLeaf’s exception resolution system.
/// - Supports both `@ExceptionHandler` and `@Catch` for flexibility.
/// - Uses reflection to resolve the closest applicable handler for polymorphic exceptions.
/// {@endtemplate}
final class MethodExceptionAdviser {
  /// Cached mapping of `ExceptionType → handler Method`.
  final Map<Class, Method> _handledMethods = {};

  /// {@macro jetleaf_method_exception_adviser}
  ///
  /// Creates a new adviser by scanning all methods of the given
  /// [controllerAdviceClass] for `@ExceptionHandler` or `@Catch` annotations.
  MethodExceptionAdviser(Class controllerAdviceClass) {
    final methods = controllerAdviceClass.getAllMethodsInHierarchy();

    for (final method in methods) {
      final exceptionHandler = method.getDirectAnnotation<ExceptionHandler>();
      if (exceptionHandler == null) {
        final catcher = method.getDirectAnnotation<Catch>();
        if (catcher == null) {
          continue;
        }

        _getExceptionHandlerMethods(method, catcher.value);
      } else {
        _getExceptionHandlerMethods(method, exceptionHandler.value);
      }
    }
  }

  /// Registers exception handler methods based on the annotation value
  /// or inferred from parameter types when no explicit value is provided.
  void _getExceptionHandlerMethods(Method method, Object? annotationValue) {
    if (annotationValue != null) {
      if (annotationValue is! Iterable) {
        final valueClass = ClassUtils.loadClass(annotationValue);
        if (valueClass != null) {
          _handledMethods[valueClass] = method;
        }
      } else {
        final classes = annotationValue.map((value) => ClassUtils.loadClass(value)).whereType<Class>();
        for (final type in classes) {
          _handledMethods[type] = method;
        }
      }
    } else {
      for (final param in method.getParameterTypes()) {
        if (ClassUtils.isAssignableToError(param)) {
          _handledMethods[param] = method;
        }
      }
    }
  }

  /// Returns the most appropriate handler method for the given [exceptionClass].
  ///
  /// The lookup strategy is:
  /// - First, return an **exact match** if available.
  /// - Otherwise, return the **most specific** assignable handler for the type.
  ///
  /// If no matching handler is found, returns `null`.
  Method? advises(Class exceptionClass) {
    // exact match
    if (_handledMethods.containsKey(exceptionClass)) {
      return _handledMethods[exceptionClass];
    }

    // search for closest assignable type
    Method? candidate;
    Class? bestMatch;
    
    for (final entry in _handledMethods.entries) {
      final declared = entry.key;
      if (declared.isAssignableFrom(exceptionClass)) {
        if (bestMatch == null) {
          bestMatch = declared;
          candidate = entry.value;
        } else {
          // choose the more specific (i.e., declared is subclass of current bestMatch)
          if (bestMatch.isAssignableFrom(declared)) {
            bestMatch = declared;
            candidate = entry.value;
          }
        }
      }
    }

    return candidate;
  }

  /// Returns an immutable view of all registered exception-handler mappings.
  Map<Class, Method> getHandledMethods() => Map.unmodifiable(_handledMethods);
}