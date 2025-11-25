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
/// A reflection-based adviser that discovers and resolves exception-handling
/// methods declared inside a JetLeaf `@ControllerAdvice` class.
///
/// `MethodExceptionAdviser` scans the annotated controller-advice class for all
/// methods marked with:
///
/// * `@ExceptionHandler` — explicit exception mapping
/// * `@Catch` — lightweight exception-catch shorthand
///
/// and builds an internal lookup table of:
///
/// ```
/// ExceptionType → Method
/// ```
///
/// This adviser is used by JetLeaf’s exception resolution pipeline to find the
/// most appropriate handler for any thrown error.
///
///
/// ### 🔍 How Handlers Are Discovered
///
/// During construction, the adviser inspects **all methods in the class
/// hierarchy** of the provided `@ControllerAdvice` class:
///
/// 1. If a method has `@ExceptionHandler(value: [...])`:
///    * Each declared type is resolved via `ClassUtils.loadClass(...)`.
///    * Each resolved exception type is mapped directly to the method.
///
/// 2. If a method has `@Catch(value: [...])`, the same logic applies.
///
/// 3. If the annotation’s `value` is *null*:
///    * All method parameters that represent errors (i.e.,
///      `ClassUtils.isAssignableToError`) are treated as inferred exception
///      types.
///
/// This allows handlers to be declared in multiple styles:
///
/// ```dart
/// @ExceptionHandler([NotFoundException])
/// Response handleNotFound(...) { ... }
///
/// @ExceptionHandler
/// Response handleAll(RuntimeException e) { ... }
///
/// @Catch(MyCustomError)
/// Response catchCustom(...) { ... }
/// ```
///
/// ### 🎯 Handler Selection Algorithm
///
/// When resolving an error, the adviser uses a two-phase matching strategy:
///
/// 1. **Exact match** — If the thrown exception’s class is directly mapped,
///    return that handler immediately.
///
/// 2. **Assignable match** — Otherwise, find the *most specific* declared type
///    that is assignable from the actual exception:
///
///    * If multiple handlers match via inheritance,
///      the one with the closest (most specific) type is selected.
///    * If none apply, the adviser returns `null`.
/// 
/// ### 🧱 Example
///
/// ```dart
/// final adviser = MethodExceptionAdviser(Class.fromType(MyControllerAdvice));
///
/// final method = adviser.getAdviceMethod(Class.fromType(MyCustomException));
/// if (method != null) {
///   // Invoke the method during exception handling
/// }
/// ```
///
/// ### 📦 Integration
///
/// `MethodExceptionAdviser` is part of JetLeaf’s exception-resolution
/// subsystem and is used by:
///
/// * `ExceptionResolver`
/// * `RestErrorHandler`
/// * JetLeaf Web MVC pipeline
///
/// It allows `@ControllerAdvice` classes to serve as global, type-aware
/// exception mappers.
/// 
/// {@endtemplate}
final class MethodExceptionAdviser with EqualsAndHashCode {
  /// Cached mapping of `ExceptionType → handler Method`.
  final Map<Class, Method> _handledMethods = {};

  /// The reflected `@ControllerAdvice` class that this adviser analyzes.
  ///
  /// This field stores the *root class* whose methods will be inspected for
  /// `@ExceptionHandler` and `@Catch` annotations. All handler discovery,
  /// mapping, and resolution originates from this class.
  ///
  /// ### Why it's important
  /// - Determines where exception-handling methods are sourced.
  /// - Allows the adviser to walk the **full class hierarchy**, enabling
  ///   inherited handler methods.
  /// - Acts as the identity value for equality and hashing so that two
  ///   advisers wrapping the same controller-advice class compare equal.
  ///
  /// The class is resolved via JetLeaf's reflection system (`Class<T>`),
  /// ensuring consistent metadata access regardless of platform or runtime.
  final Class _controllerAdviceClass;

  /// {@macro jetleaf_method_exception_adviser}
  ///
  /// Creates a new adviser by scanning all methods of the given
  /// [_controllerAdviceClass] for `@ExceptionHandler` or `@Catch` annotations.
  MethodExceptionAdviser(this._controllerAdviceClass) {
    final methods = _controllerAdviceClass.getAllMethodsInHierarchy();

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

  /// Registers all exception-handler mappings defined on a specific method.
  ///
  /// This method processes either:
  ///
  /// - Explicit annotation values (`@ExceptionHandler(value: [...])`,
  ///   `@Catch(value: [...])`)
  /// - Or *inferred* exception types based on the method’s parameters
  ///   when `value` is `null`
  ///
  /// ### Behavior
  ///
  /// **1. Explicit value provided**
  /// - If the annotation contains a single class or symbol, it is resolved
  ///   through `ClassUtils.loadClass`.
  /// - If the annotation contains an iterable of values, *each* is resolved.
  /// - All successfully resolved classes are mapped to the given [method].
  ///
  /// **2. No explicit value**
  /// - All parameter types of the method are scanned.
  /// - Each parameter that represents an error/exception type (according to
  ///   `ClassUtils.isAssignableToError`) is treated as a catchable type.
  ///
  /// This dual-mode discovery supports both concise handler signatures and
  /// explicit mappings for multiple exception types.
  ///
  /// ### Parameters
  /// - [method] — The reflective method being registered as a handler.
  /// - [annotationValue] — The `value` field of the annotation, which may be:
  ///   - a class symbol,
  ///   - an iterable of class symbols,
  ///   - or `null` to indicate inference.
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

  /// Attempts to locate the most appropriate exception-handling method for the
  /// given [exceptionClass].
  ///
  /// ### Resolution Strategy
  ///
  /// 1. **Exact Match**
  ///    If the exception class is registered directly in `_handledMethods`,
  ///    the associated method is returned immediately.
  ///
  /// 2. **Assignable (Inheritance) Match**
  ///    If no direct match exists, the adviser scans all declared
  ///    handler types and selects the *most specific* handler whose
  ///    declared type is assignable from the actual exception type.
  ///
  ///    Example:
  ///    - `IOException` is preferred over `Exception`
  ///      if both are declared handlers.
  ///
  /// 3. **No Match**
  ///    If no appropriate handler exists, returns `null`.
  ///
  /// ### Use Cases
  /// This is the core method used by JetLeaf’s exception pipeline to determine
  /// which `@ExceptionHandler` method should be invoked for a thrown exception.
  ///
  /// ### Returns
  /// - The matched [Method], or `null` if no handler applies.
  Method? getAdviceMethod(Class exceptionClass) {
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

  @override
  List<Object?> equalizedProperties() => [_controllerAdviceClass];
}