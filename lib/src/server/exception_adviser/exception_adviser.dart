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

/// {@template jetleaf_exception_adviser}
/// Internal representation of a `@ControllerAdvice` or `@RestControllerAdvice` declaration in JetLeaf.
///
/// A [ExceptionAdviser] encapsulates:
/// - The **annotated target instance** (the object containing the advice methods)
/// - The **advice annotation metadata** ([ControllerAdvice], [WebView] or [RestControllerAdvice])
/// - The **declaring class type** for reflective access
///
/// This class determines whether the advice applies to a given controller type
/// based on the scoping attributes of [ControllerAdvice]:
/// - `assignableTypes` → applies only to the specified or derived controller types
/// - `basePackages` → applies only to controllers within those packages
/// - `annotations` → applies only to controllers annotated with the listed annotations
///
/// ### Matching Rules
/// Advice applicability is determined in the following order:
/// 1. **Advice–Controller type compatibility**
///    - A `@ControllerAdvice` only applies to `@Controller` or `WebView`-annotated controllers.
///    - A `@RestControllerAdvice` only applies to `@RestController`-annotated controllers.
/// 2. **Assignable types** (if defined)
/// 3. **Base packages** (if defined)
/// 4. **Annotations** (if defined)
/// 5. Defaults to `true` (applies globally)
///
/// ### Example
/// ```dart
/// @ControllerAdvice(assignableTypes: [UserController])
/// class UserErrorAdvice {
///   @ExceptionHandler(UserNotFoundException)
///   PageView handleUserError() => PageView.of('error.html', HttpStatus.NOT_FOUND);
/// }
///
/// @RestControllerAdvice(assignableTypes: [ApiController])
/// class ApiErrorAdvice {
///   @ExceptionHandler(ApiException)
///   ResponseBody<String> handleApiError() => ResponseBody.of('API error', HttpStatus.INTERNAL_SERVER_ERROR);
/// }
///
/// // During runtime:
/// final adviser = ControllerAdviser(controllerAdvice, instance, ClassUtils.loadClass(UserErrorAdvice));
/// final applies = adviser.advises(ClassUtils.loadClass(UserController)); // true
/// ```
///
/// ### Design Notes
/// - This class is **not part of the public API**; it is used internally by JetLeaf’s
///   controller advice resolution system.
/// - The advice type–controller type pairing ensures that a REST advice cannot
///   accidentally apply to a traditional MVC controller, and vice versa.
/// {@endtemplate}
///
/// See also:
/// - [ControllerAdvice]
/// - [RestControllerAdvice]
/// - [ExceptionHandler]
final class ExceptionAdviser {
  /// The runtime instance containing the advice methods.
  final Object target;

  /// The [ControllerAdvice] or [RestControllerAdvice] annotation attached to the target class.
  final ControllerAdvice controllerAdvice;

  /// The reflective [Class] object representing the advice type.
  final Class type;

  /// {@macro jetleaf_exception_adviser}
  ExceptionAdviser(this.controllerAdvice, this.target, this.type);

  /// Determines whether this advice applies to the given [controllerClass].
  ///
  /// The applicability check follows these rules:
  ///
  /// 1. **Advice–Controller annotation match:**
  ///    - A `@RestControllerAdvice` applies only to `@RestController` controllers.
  ///    - A `@ControllerAdvice` applies only to `@Controller` controllers.
  ///
  /// 2. **Assignable types:**  
  ///    If defined, advice applies only when the given controller type is assignable
  ///    from one of the types listed in `assignableTypes`.
  ///
  /// 3. **Base packages:**  
  ///    If defined, advice applies only when the controller’s package name starts
  ///    with one of the listed packages.
  ///
  /// 4. **Annotations:**  
  ///    If defined, advice applies only when the controller class has one of the listed annotations.
  ///
  /// 5. **Default behavior:**  
  ///    If no scoping restrictions are set, the advice applies globally.
  bool advises(Class controllerClass) {
    // Step 1: Ensure advice–controller type compatibility
    final controllerAnnotation = controllerClass.getDirectAnnotation<RestController>()
      ?? controllerClass.getDirectAnnotation<WebView>()
      ?? controllerClass.getDirectAnnotation<Controller>();

    // REST advice applies only to REST controllers
    if (controllerAnnotation is RestController && controllerAdvice is! RestControllerAdvice) {
      return false;
    }

    // MVC or WebView advice applies only to MVC/WebView controllers
    if ((controllerAnnotation is Controller || controllerAnnotation is WebView) && controllerAdvice is RestControllerAdvice) {
      return false;
    }

    // Step 2: explicit assignable types
    final assignable = controllerAdvice.assignableTypes;
    final supportedTypes = assignable.map(ClassUtils.loadClass).whereType<Class>();

    if (supportedTypes.isNotEmpty) {
      return supportedTypes.any((type) => type.isAssignableFrom(controllerClass));
    }

    // Step 3: base packages
    final basePkgs = controllerAdvice.basePackages;
    if (basePkgs.isNotEmpty) {
      final controllerPkg = controllerClass.getPackage()?.getName();
      if (controllerPkg != null && basePkgs.any((pkg) => pkg.equals(controllerPkg))) {
        return true;
      }
      return false;
    }

    // Step 4: annotations
    final annotations = controllerAdvice.annotations;
    if (annotations.isNotEmpty) {
      for (final ann in annotations) {
        final annClass = ClassUtils.loadClass(ann);
        if (annClass != null && controllerClass.getAllDirectAnnotations().any((ann) => ann.getDeclaringClass() == annClass)) {
          return true;
        }
      }

      return false;
    }

    // Step 5: no scope restrictions => applies globally
    return true;
  }

  @override
  String toString() => 'ControllerAdviser(${type.getQualifiedName()})';
}