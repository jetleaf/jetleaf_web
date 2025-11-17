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

import 'dart:typed_data';

import 'package:jetleaf_lang/lang.dart';

import '../exception/exceptions.dart';
import '../server/multipart/multipart_file.dart';
import '../server/multipart/multipart_server_http_request.dart';
import '../server/multipart/part.dart';
import '../utils/matrix_variable_utils.dart';
import '../server/server_http_request.dart';
import 'request_parameter.dart';

/// {@template jetleaf_matrix_variable_resolver}
/// Resolves method parameters annotated with [MatrixVariable] by extracting
/// matrix variables from URI path segments.
///
/// This resolver handles the complex parsing of matrix variables embedded
/// within path segments using semicolon syntax. It supports both segment-specific
/// matrix variables (when [MatrixVariable.pathVar] is specified) and global
/// matrix variable resolution.
///
/// ### Resolution Process
/// 1. Extracts the target path segment based on [MatrixVariable.pathVar]
/// 2. Parses matrix variables from the segment using [MatrixVariableUtils.resolve]
/// 3. Returns the value for the specified matrix variable name
/// 4. Handles required validation and default values
///
/// ### Example
/// For a URI like `/cars;color=red;year=2022/owners` and annotation
/// `@MatrixVariable('color')`, this resolver would return `"red"`.
///
/// ### Error Handling
/// Throws [InvalidArgumentException] when:
/// - Required matrix variable is missing and no default value is provided
/// - Specified path variable segment doesn't exist for segment-specific resolution
///
/// ### Thread Safety
/// This resolver is stateless and thread-safe.
/// {@endtemplate}
final class MatrixVariableResolver implements Resolver {
  /// {@macro jetleaf_matrix_variable_resolver}
  const MatrixVariableResolver();

  @override
  Future<Object?> resolve(ServerHttpRequest request, Parameter parameter, ResolverContext context) async {
    final annotation = parameter.getDirectAnnotation<MatrixVariable>();

    // Since [supports] make the check valid, we assume that [annotation] cannot be null, but we still do this
    // for safety.
    if (annotation == null) {
      return null;
    }

    final resolvedName = annotation.value ?? parameter.getName();

    // Get matrix variable from path variable segment (if applicable)
    final pathVarName = annotation.pathVar;
    final pathValue = pathVarName != null ? request.getPathVariable(pathVarName) : request.getQueryString() ?? request.getRequestURI().path;

    if (pathValue == null) {
      if (annotation.required && annotation.defaultValue == null) {
        throw InvalidArgumentException('Missing matrix variable path segment "$pathVarName" for $resolvedName');
      }

      return annotation.defaultValue;
    }

    // Parse matrix variables like: /path;key=value;another=foo
    final matrixVars = MatrixVariableUtils.resolve(pathValue);
    final value = matrixVars.get(resolvedName);

    if (value == null) {
      if (annotation.required && annotation.defaultValue == null) {
        throw InvalidArgumentException('Missing required matrix variable "$resolvedName"');
      }

      return annotation.defaultValue;
    }

    return value;
  }

  @override
  bool supports(Parameter parameter) => parameter.hasDirectAnnotation<MatrixVariable>();
}

/// {@template jetleaf_cookie_value_resolver}
/// Resolves method parameters annotated with [CookieValue] by extracting
/// values from HTTP cookies in the request.
///
/// This resolver accesses cookies from the [HttpCookies] collection attached
/// to the request and returns the value of the specified cookie.
///
/// ### Resolution Process
/// 1. Looks up the cookie by name in the request's cookie collection
/// 2. Returns the cookie value if found
/// 3. Handles required validation and default values
///
/// ### Example
/// For a request with cookie `sessionId=abc123` and annotation
/// `@CookieValue('sessionId')`, this resolver would return `"abc123"`.
///
/// ### Security Considerations
/// - Cookie values are returned as-is without validation
/// - Consider additional security checks for sensitive cookie data
///
/// ### Error Handling
/// Throws [InvalidArgumentException] when a required cookie is missing
/// and no default value is provided.
///
/// ### Thread Safety
/// This resolver is stateless and thread-safe.
/// {@endtemplate}
final class CookieValueResolver implements Resolver {
  /// {@macro jetleaf_cookie_value_resolver}
  const CookieValueResolver();

  @override
  Future<Object?> resolve(ServerHttpRequest request, Parameter parameter, ResolverContext context) async {
    final annotation = parameter.getDirectAnnotation<CookieValue>();

    // Since [supports] make the check valid, we assume that [annotation] cannot be null, but we still do this
    // for safety.
    if (annotation == null) {
      return null;
    }

    final resolvedName = annotation.value ?? parameter.getName();
    final cookies = request.getCookies();
    final cookie = cookies.get(resolvedName);

    if (cookie == null) {
      if (annotation.required && annotation.defaultValue == null) {
        throw InvalidArgumentException('Missing required cookie "$resolvedName"');
      }

      return annotation.defaultValue;
    }

    return cookie.getValue();
  }

  @override
  bool supports(Parameter parameter) => parameter.hasDirectAnnotation<CookieValue>();
}

/// {@template jetleaf_path_variable_resolver}
/// Resolves method parameters annotated with [PathVariable] by extracting
/// values from URI template variables.
///
/// This resolver accesses path variables that were extracted from the request
/// URI during routing. Path variables are typically defined in request mapping
/// patterns like `/users/{id}`.
///
/// ### Resolution Process
/// 1. Looks up the path variable by name in the request's path variable map
/// 2. Returns the path variable value if found
/// 3. Handles required validation and default values
///
/// ### Example
/// For a URI like `/users/123` with mapping `/users/{id}` and annotation
/// `@PathVariable('id')`, this resolver would return `"123"`.
///
/// ### Error Handling
/// Throws [InvalidArgumentException] when a required path variable is missing
/// and no default value is provided.
///
/// ### Thread Safety
/// This resolver is stateless and thread-safe.
/// {@endtemplate}
final class PathVariableResolver implements Resolver {
  /// {@macro jetleaf_path_variable_resolver}
  const PathVariableResolver();

  @override
  Future<Object?> resolve(ServerHttpRequest request, Parameter parameter, ResolverContext context) async {
    final annotation = parameter.getDirectAnnotation<PathVariable>();

    // Since [supports] make the check valid, we assume that [annotation] cannot be null, but we still do this
    // for safety.
    if (annotation == null) {
      return null;
    }

    final resolvedName = annotation.value ?? parameter.getName();
    final value = request.getPathVariable(resolvedName);

    if (value == null) {
      if (annotation.required && annotation.defaultValue == null) {
        throw PathVariableException('Missing required path variable "$resolvedName"');
      }

      return annotation.defaultValue;
    }

    return value;
  }

  @override
  bool supports(Parameter parameter) => parameter.hasDirectAnnotation<PathVariable>();
}

/// {@template jetleaf_request_attribute_resolver}
/// Resolves method parameters annotated with [RequestAttribute] by extracting
/// values from request-scoped attributes.
///
/// Request attributes are typically set by filters, interceptors, or previous
/// processing steps and are available for the duration of a single request.
///
/// ### Resolution Process
/// 1. Looks up the attribute by name in the request's attribute map
/// 2. Returns the attribute value if found
/// 3. Handles required validation and default values
///
/// ### Example
/// For a request with attribute `authenticatedUser` set to a User object
/// and annotation `@RequestAttribute('authenticatedUser')`, this resolver
/// would return the User object.
///
/// ### Common Use Cases
/// - Authentication context from security filters
/// - Request processing metadata
/// - Cross-cutting concern data
///
/// ### Error Handling
/// Throws [InvalidArgumentException] when a required request attribute is missing
/// and no default value is provided.
///
/// ### Thread Safety
/// This resolver is stateless and thread-safe.
/// {@endtemplate}
final class RequestAttributeResolver implements Resolver {
  /// {@macro jetleaf_request_attribute_resolver}
  const RequestAttributeResolver();

  @override
  Future<Object?> resolve(ServerHttpRequest request, Parameter parameter, ResolverContext context) async {
    final annotation = parameter.getDirectAnnotation<RequestAttribute>();

    // Since [supports] make the check valid, we assume that [annotation] cannot be null, but we still do this
    // for safety.
    if (annotation == null) {
      return null;
    }

    final resolvedName = annotation.value ?? parameter.getName();
    final attr = request.getAttribute(resolvedName);

    if (attr == null) {
      if (annotation.required && annotation.defaultValue == null) {
        throw InvalidArgumentException('Missing required request attribute "$resolvedName"');
      }

      return annotation.defaultValue;
    }

    return attr;
  }

  @override
  bool supports(Parameter parameter) => parameter.hasDirectAnnotation<RequestAttribute>();
}

/// {@template jetleaf_session_attribute_resolver}
/// Resolves method parameters annotated with [SessionAttribute] by extracting
/// values from HTTP session attributes.
///
/// This resolver accesses attributes stored in the user's HTTP session,
/// which persist across multiple requests from the same client.
///
/// ### Resolution Process
/// 1. Retrieves the current HTTP session (optionally creating one if needed)
/// 2. Looks up the attribute by name in the session's attribute map
/// 3. Returns the attribute value if found
/// 4. Handles required validation and default values
///
/// ### Example
/// For a session with attribute `shoppingCart` containing a Cart object
/// and annotation `@SessionAttribute('shoppingCart')`, this resolver
/// would return the Cart object.
///
/// ### Session Management
/// - Uses `request.getSession(true)` to optionally create a new session
/// - Requires session support to be enabled in the application
///
/// ### Error Handling
/// Throws [InvalidArgumentException] when a required session attribute is missing
/// and no default value is provided.
///
/// ### Thread Safety
/// This resolver is stateless and thread-safe.
/// {@endtemplate}
final class SessionAttributeResolver implements Resolver {
  /// {@macro jetleaf_session_attribute_resolver}
  const SessionAttributeResolver();

  @override
  Future<Object?> resolve(ServerHttpRequest request, Parameter parameter, ResolverContext context) async {
    final annotation = parameter.getDirectAnnotation<SessionAttribute>();

    // Since [supports] make the check valid, we assume that [annotation] cannot be null, but we still do this
    // for safety.
    if (annotation == null) {
      return null;
    }

    final resolvedName = annotation.value ?? parameter.getName();
    final session = request.getSession(true);
    final attribute = session?.getAttribute(resolvedName);
    
    if (attribute == null) {
      if (annotation.required && annotation.defaultValue == null) {
        throw InvalidArgumentException('Missing required session attribute "$resolvedName"');
      }

      return annotation.defaultValue;
    }

    return attribute;
  }

  @override
  bool supports(Parameter parameter) => parameter.hasDirectAnnotation<SessionAttribute>();
}

/// {@template jetleaf_request_header_resolver}
/// Resolves method parameters annotated with [RequestHeader] by extracting
/// values from HTTP request headers.
///
/// This resolver accesses headers from the [HttpHeaders] collection attached
/// to the request and returns the value of the specified header.
///
/// ### Resolution Process
/// 1. Looks up the header by name in the request's headers
/// 2. Returns the first value of the header if it exists
/// 3. Handles required validation and default values
///
/// ### Example
/// For a request with header `Authorization: Bearer token123` and annotation
/// `@RequestHeader('Authorization')`, this resolver would return `"Bearer token123"`.
///
/// ### Header Name Resolution
/// - Uses case-insensitive header name matching
/// - Supports standard HTTP headers and custom headers
/// - Returns the first value for multi-value headers
///
/// ### Error Handling
/// Throws [InvalidArgumentException] when a required header is missing
/// and no default value is provided.
///
/// ### Thread Safety
/// This resolver is stateless and thread-safe.
/// {@endtemplate}
final class RequestHeaderResolver implements Resolver {
  /// {@macro jetleaf_request_header_resolver}
  const RequestHeaderResolver();

  @override
  Future<Object?> resolve(ServerHttpRequest request, Parameter parameter, ResolverContext context) async {
    final annotation = parameter.getDirectAnnotation<RequestHeader>();

    // Since [supports] make the check valid, we assume that [annotation] cannot be null, but we still do this
    // for safety.
    if (annotation == null) {
      return null;
    }

    final resolvedName = annotation.value ?? parameter.getName();
    final headers = request.getHeaders();
    final value = headers.getFirst(resolvedName);

    if (value == null) {
      if (annotation.required && annotation.defaultValue == null) {
        throw InvalidArgumentException('Missing required request header "$resolvedName"');
      }

      return annotation.defaultValue;
    }

    return value;
  }

  @override
  bool supports(Parameter parameter) => parameter.hasDirectAnnotation<RequestHeader>();
}

/// {@template jetleaf_request_param_resolver}
/// Resolves method parameters annotated with [RequestParam] by extracting
/// values from HTTP request parameters (query string or form data).
///
/// This resolver accesses parameters from the request, which can come from
/// the query string (`?name=value`) or form data in POST requests.
///
/// ### Resolution Process
/// 1. Looks up the parameter by name in the request's parameter map
/// 2. Returns the parameter value if found
/// 3. Handles required validation and default values
///
/// ### Example
/// For a request to `/search?q=flutter&page=2` and annotation
/// `@RequestParam('q')`, this resolver would return `"flutter"`.
///
/// ### Parameter Sources
/// - Query string parameters for GET requests
/// - Form data parameters for POST requests with `application/x-www-form-urlencoded`
/// - Both sources for other HTTP methods
///
/// ### Error Handling
/// Throws [InvalidArgumentException] when a required parameter is missing
/// and no default value is provided.
///
/// ### Thread Safety
/// This resolver is stateless and thread-safe.
/// {@endtemplate}
final class RequestParamResolver implements Resolver {
  /// {@macro jetleaf_request_param_resolver}
  const RequestParamResolver();

  @override
  Future<Object?> resolve(ServerHttpRequest request, Parameter parameter, ResolverContext context) async {
    final annotation = parameter.getDirectAnnotation<RequestParam>();

    // Since [supports] make the check valid, we assume that [annotation] cannot be null, but we still do this
    // for safety.
    if (annotation == null) {
      return null;
    }

    final resolvedName = annotation.value ?? parameter.getName();
    final param = request.getParameter(resolvedName);

    if (param == null) {
      if (annotation.required && annotation.defaultValue == null) {
        throw InvalidArgumentException('Missing required request parameter "$resolvedName"');
      }

      return annotation.defaultValue;
    }

    return param;
  }

  @override
  bool supports(Parameter parameter) => parameter.hasDirectAnnotation<RequestParam>();
}

/// {@template request_part_resolver}
/// Resolves method parameters annotated with `@RequestPart` in multipart requests.
/// 
/// The `RequestPartResolver` is responsible for extracting **parts of a multipart
/// HTTP request** (usually `multipart/form-data`) and binding them to controller
/// method parameters annotated with `@RequestPart`.
///
/// It supports multiple target types:
/// 1. **`Part`** – A generic abstraction representing a single part of the request.
/// 2. **`MultipartFile`** – Represents an uploaded file.
/// 3. **`Uint8List`** – The raw bytes of a part or file.
/// 4. **`String`** – Text content of a part or file, read as UTF-8.
///
/// The resolver determines the part to inject based on the `@RequestPart` annotation
/// name. If the annotation does not specify a name, it falls back to the method
/// parameter name.
///
/// This resolver is used internally by JetLeaf’s argument resolution pipeline to
/// provide automatic injection of multipart data into controller methods.
///
/// ### Example
/// ```dart
/// @PostMapping("/upload")
/// Future<void> uploadFile(
///   @RequestPart("avatar") MultipartFile file,
///   @RequestPart("metadata") Part metadata,
///   @RequestPart("data") Uint8List rawData,
///   @RequestPart("description") String description
/// ) async {
///   // The parameters are automatically populated from the multipart request.
/// }
/// ```
/// {@endtemplate}
final class RequestPartResolver implements Resolver {
  /// Creates a new [RequestPartResolver].
  ///
  /// {@macro request_part_resolver}
  const RequestPartResolver();

  @override
  Future<Object?> resolve(ServerHttpRequest request, Parameter parameter, ResolverContext context) async {
    print("Request is $request");
    final annotation = parameter.getDirectAnnotation<RequestPart>();

    // Safety check
    if (annotation == null || request is! MultipartServerHttpRequest) {
      return null;
    }

    final resolvedName = annotation.value ?? parameter.getName();
    final maxSize = annotation.maxSize; // max size from annotation
    final required = annotation.required;
    final allowedMaxSizePerFile = request.getMaxUploadSizePerFile();
    final paramClass = parameter.getClass();

    // Utility: validate per-file size
    void validatePerFileSize(int size, String fileName) {
      final effectiveMax = maxSize ?? allowedMaxSizePerFile;
      if (size > effectiveMax) {
        throw MaxUploadSizePerFileExceededException(effectiveMax, size, fileName);
      }
    }

    // Utility: extract bytes and validate size
    Future<Uint8List> extractBytes(dynamic partOrFile, String name) async {
      late Uint8List bytes;
      late int size;

      if (partOrFile is MultipartFile) {
        bytes = await partOrFile.getInputStream().readAll();
        size = partOrFile.getSize();
      } else if (partOrFile is Part) {
        bytes = await partOrFile.getInputStream().readAll();
        size = partOrFile.getSize();
      } else {
        throw MultipartException('Unsupported type for byte extraction');
      }

      validatePerFileSize(size, name);
      return bytes;
    }

    // --- Handle Part ---
    if (Class<Part>(null, PackageNames.WEB).isAssignableFrom(paramClass)) {
      final part = request.getPart(resolvedName);
      if (part != null) {
        validatePerFileSize(part.getSize(), resolvedName);
        return part;
      } else if (required) {
        throw MultipartException('Required part "$resolvedName" is missing');
      }
    }

    // --- Handle MultipartFile ---
    if (Class<MultipartFile>(null, PackageNames.WEB).isAssignableFrom(paramClass)) {
      final file = request.getFile(resolvedName);
      if (file != null) {
        validatePerFileSize(file.getSize(), file.getOriginalFilename());
        return file;
      } else if (required) {
        throw MultipartException('Required file "$resolvedName" is missing');
      }
    }

    // --- Handle Uint8List ---
    if (Class<Uint8List>(null, PackageNames.DART).isAssignableFrom(paramClass)) {
      final file = request.getFile(resolvedName);
      if (file != null) return await extractBytes(file, file.getOriginalFilename());

      final part = request.getPart(resolvedName);
      if (part != null) return await extractBytes(part, resolvedName);

      if (required) {
        throw MultipartException('Required part "$resolvedName" is missing');
      }
    }

    // --- Handle String ---
    if (Class<String>(null, PackageNames.DART).isAssignableFrom(paramClass)) {
      final file = request.getFile(resolvedName);
      if (file != null) {
        final bytes = await extractBytes(file, file.getOriginalFilename());
        return String.fromCharCodes(bytes);
      }

      final part = request.getPart(resolvedName);
      if (part != null) {
        final bytes = await extractBytes(part, resolvedName);
        return String.fromCharCodes(bytes);
      }

      if (required) {
        throw MultipartException('Required part "$resolvedName" is missing');
      }
    }

    // --- Fallback to converter ---
    final contentType = request.getHeaders().getContentType();
    final converter = context.findReadable(paramClass, contentType);

    if (converter == null) {
      throw HttpMediaTypeNotSupportedException(
          'No suitable HttpMessageConverter found for type ${paramClass.getName()} '
          'and content type $contentType');
    }

    return converter.read(paramClass, request);
  }

  @override
  bool supports(Parameter parameter) => parameter.hasDirectAnnotation<RequestPart>();
}

/// {@template request_body_resolver}
/// Resolves method parameters annotated with `@RequestBody`.
///
/// The [RequestBodyResolver] uses the configured [HttpMessageConverter]s to
/// deserialize the HTTP request body into the target Dart object, based on
/// the request's `Content-Type` header.
///
/// ### Example
///
/// ```dart
/// @PostMapping('/users')
/// Future<ResponseBody<User>> createUser(@RequestBody User user) async {
///   // `user` is automatically deserialized from JSON (or another supported format)
/// }
/// ```
///
/// ### Supported Types
/// - JSON (`application/json`)
/// - XML (`application/xml`)
/// - Form data, text, or binary (depending on available converters)
///
/// ### Error Handling
/// Throws:
/// - [HttpMediaTypeNotSupportedException] if no suitable converter is found
/// - [HttpMessageNotReadableException] if deserialization fails
/// {@endtemplate}
final class RequestBodyResolver implements Resolver {
  /// {@macro request_body_resolver}
  const RequestBodyResolver();

  @override
  Future<Object?> resolve(ServerHttpRequest request, Parameter parameter, ResolverContext context) async {
    final annotation = parameter.getDirectAnnotation<RequestBody>();
    if (annotation == null) {
      return null; // Shouldn’t happen because supports() already checked
    }

    final contentType = request.getHeaders().getContentType();
    final paramClass = parameter.getClass();

    // Find a converter that can read the request body into the parameter type
    final converter = context.findReadable(paramClass, contentType);

    if (converter == null) {
      throw HttpMediaTypeNotSupportedException('No suitable HttpMessageConverter found for type ${paramClass.getName()} and content type $contentType');
    }

    return await converter.read(paramClass, request);
  }

  @override
  bool supports(Parameter parameter) => parameter.hasDirectAnnotation<RequestBody>();
}