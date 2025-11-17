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
import 'package:meta/meta_meta.dart';

import '../converter/http_message_converter.dart';
import '../http/media_type.dart';
import '../server/server_http_request.dart';
import 'resolvers.dart';

/// {@template jetleaf_param_resolver}
/// A metadata annotation that associates parameter resolver implementations 
/// with annotation classes for web request parameter resolution.
///
/// This annotation provides a streamlined approach to linking custom annotations
/// with their corresponding [Resolver] implementations. It serves as the foundation
/// for the Jetleaf framework's parameter resolution system, enabling automatic
/// population of controller method parameters based on request context and annotations.
///
/// ### Design Philosophy
/// [ResolvedBy] follows the principle of convention over configuration by
/// explicitly connecting annotations to their resolution logic. This creates
/// a clear, type-safe relationship between parameter annotations and the code
/// that handles their resolution.
///
/// ### Usage Pattern
/// ```dart
/// // 1. Define a resolver implementation
/// class MatrixVariableResolver implements Resolver {
///   const MatrixVariableResolver();
///
///   @override
///   bool supports(Parameter parameter) {
///     return parameter.hasAnnotation(MatrixVariable);
///   }
///
///   @override
///   Object? resolve(ServerHttpRequest request, Parameter parameter) {
///     final annotation = parameter.getAnnotation(MatrixVariable);
///     final varName = annotation.name ?? parameter.name;
///     return request.getMatrixVariables().get(varName);
///   }
/// }
///
/// // 2. Annotate the annotation with its resolver
/// @ResolvedBy(MatrixVariableResolver())
/// @Target({TargetKind.parameter})
/// class MatrixVariable extends ReflectableAnnotation {
///   final String? name;
///   const MatrixVariable([this.name]);
/// }
///
/// // 3. Use in controller methods
/// class ProductController {
///   @Get('/categories/{id}/products')
///   List<Product> getProducts(
///     @MatrixVariable('id') String categoryId,
///     @MatrixVariable('sort') String? sortBy
///   ) {
///     // Parameters are automatically resolved from matrix variables
///     return productService.findByCategory(categoryId, sortBy: sortBy);
///   }
/// }
/// ```
///
/// ### Framework Integration
/// - Jetleaf scans for [ResolvedBy] annotations during application startup
/// - The framework builds a registry mapping annotations to their resolvers
/// - During request processing, resolvers are invoked for matching parameters
/// - Resolution occurs before controller method invocation
///
/// ### Common Built-in Resolvers
/// The Jetleaf framework typically provides these standard resolvers:
/// - **@PathVariable**: Resolves URI template variables
/// - **@RequestParam**: Resolves query string parameters  
/// - **@RequestHeader**: Resolves HTTP header values
/// - **@RequestBody**: Resolves and deserializes request body
/// - **@MatrixVariable**: Resolves matrix variables from path segments
/// - **@CookieValue**: Resolves cookie values
/// - **@SessionAttribute**: Resolves session attributes
///
/// ### Target Restrictions
/// This annotation can only be applied to class types (annotations) using `@Target({TargetKind.classType})`.
///
/// ### Related Components
/// - [Resolver] - The core interface for parameter resolution logic
/// - [ServerHttpRequest] - The request context available during resolution
/// - [Parameter] - Reflection information about method parameters
/// {@endtemplate}
@Target({TargetKind.classType})
final class ResolvedBy extends ReflectableAnnotation {
  /// The key used to store or retrieve resolver annotation in metadata.
  ///
  /// This constant typically serves as the field name for reflection-based
  /// lookups where `ResolvedBy` validators are registered.
  ///
  /// Example usage:
  /// ```dart
  /// final validators = Class<Annotation>().getField(ResolvedBy.FIELD_KEY);
  /// ```
  static const String FIELD_KEY = "resolver";

  /// The resolver implementation that handles parameter resolution for the target annotation.
  ///
  /// This resolver is responsible for:
  /// - Determining if it can resolve a specific parameter ([Resolver.supports])
  /// - Providing the actual parameter value from the request context ([Resolver.resolve])
  ///
  /// ### Example
  /// ```dart
  /// @ResolvedBy(RequestParamResolver())  // Associated resolver
  /// class RequestParam extends ReflectableAnnotation {
  ///   final String name;
  ///   final bool required;
  ///   
  ///   const RequestParam(this.name, {this.required = true});
  /// }
  /// ```
  final Resolver resolver;

  /// Creates a [ResolvedBy] annotation with the specified resolver.
  ///
  /// ### Parameters
  /// - [resolver]: The [Resolver] implementation that will handle parameter
  ///   resolution for the target annotation class.
  /// 
  /// {@macro jetleaf_param_resolver}
  const ResolvedBy(this.resolver);

  @override
  Type get annotationType => ResolvedBy;

  @override
  String toString() => "ResolvedBy($resolver)";
}

/// {@template jetleaf_resolver}
/// The core interface for resolving method parameter values from HTTP request context.
///
/// Implement this interface to create custom parameter resolvers that automatically
/// populate controller method parameters based on request data. Resolvers are
/// associated with specific annotations via the [ResolvedBy] annotation and
/// are invoked by the Jetleaf framework during request processing.
///
/// ### Resolution Process
/// 1. **Parameter Discovery**: Framework identifies all controller method parameters
/// 2. **Support Check**: For each parameter, checks if any resolver [supports] it
/// 3. **Value Resolution**: Invokes [resolve] on supporting resolvers to get parameter values
/// 4. **Method Invocation**: Passes resolved values to the controller method
///
/// ### Example Implementation
/// ```dart
/// class RequestHeaderResolver implements Resolver {
///   const RequestHeaderResolver();
///
///   @override
///   bool supports(Parameter parameter) {
///     return parameter.hasAnnotation(RequestHeader);
///   }
///
///   @override
///   Object? resolve(ServerHttpRequest request, Parameter parameter) {
///     final annotation = parameter.getAnnotation(RequestHeader);
///     final headerName = annotation.name ?? parameter.name;
///     return request.getHeaders().getFirst(headerName);
///   }
/// }
/// ```
///
/// ### Best Practices
/// - **Stateless Design**: Resolvers should be stateless and thread-safe
/// - **Fast Support Checks**: [supports] method should be efficient and fast
/// - **Clear Error Messages**: Provide meaningful errors when resolution fails
/// - **Null Safety**: Return `null` for optional parameters that aren't present
/// - **Type Safety**: Ensure resolved values match the parameter type when possible
///
/// ### Thread Safety
/// Resolver implementations must be thread-safe, as the same resolver instance
/// may be used concurrently by multiple HTTP requests.
/// {@endtemplate}
abstract interface class Resolver {
  /// Creates a const constructor for resolver implementations.
  ///
  /// Resolvers should be const-constructible to enable their use in
  /// [ResolvedBy] annotations, which require const expressions.
  /// 
  /// {@macro jetleaf_resolver}
  const Resolver();

  /// Determines whether this resolver can handle the specified method parameter.
  ///
  /// This method is called by the framework to identify which resolver should
  /// be used for a given parameter. It should perform a quick check based on
  /// the parameter's annotations, type, or other metadata.
  ///
  /// ### Parameters
  /// - [parameter]: Reflection information about the method parameter, including:
  ///   - `type`: The parameter's runtime type
  ///   - `name`: The parameter's declared name
  ///   - `annotations`: All annotations applied to the parameter
  ///   - `metadata`: Additional parameter metadata
  ///
  /// ### Returns
  /// `true` if this resolver can resolve values for the specified parameter,
  /// `false` otherwise.
  ///
  /// ### Performance Considerations
  /// This method is called frequently during request processing, so it should
  /// be optimized for speed and avoid expensive operations.
  bool supports(Parameter parameter);

  /// Resolves the actual value for the method parameter from the current HTTP request.
  ///
  /// This method is invoked when the framework needs to obtain a value for a
  /// parameter that this resolver supports. It has access to the complete
  /// request context and should return an appropriate value for the parameter.
  ///
  /// ### Parameters
  /// - [request]: The current [ServerHttpRequest] being processed, providing
  ///   access to:
  ///   - Headers, parameters, and cookies
  ///   - Request body and attributes
  ///   - Session information
  ///   - URI and method details
  /// - [parameter]: Reflection information about the method parameter being resolved
  ///
  /// ### Returns
  /// The resolved value for the parameter, or `null` if no value can be resolved.
  ///
  /// ### Error Handling
  /// - Return `null` for optional parameters that aren't present
  /// - Throw meaningful exceptions for required parameters that cannot be resolved
  /// - Use framework-specific exception types when appropriate
  /// - Consider providing fallback values when applicable
  Future<Object?> resolve(ServerHttpRequest request, Parameter parameter, ResolverContext context);
}

/// {@template resolver_context}
/// Defines a strategy interface for locating appropriate [HttpMessageConverter]s
/// capable of reading or writing specific Dart types within a given media type context.
///
/// The [ResolverContext] serves as a lightweight service abstraction for frameworks
/// that need to dynamically select serialization strategies (e.g., JSON, XML, or binary)
/// when processing HTTP requests and responses.
///
/// Implementations are typically provided by composite resolver chains within
/// the Jetleaf web layer (e.g., [`CompositeReturnValueHandler`]).
///
/// {@endtemplate}
abstract interface class ResolverContext {
  /// {@template find_writable}
  /// Finds the first [HttpMessageConverter] capable of **writing** the given type.
  ///
  /// ### Parameters
  /// - [type]: The Dart class type to serialize
  /// - [mediaType]: Optional media type specifying desired output format
  ///
  /// ### Returns
  /// The first compatible converter, or `null` if none can handle the output.
  ///
  /// ### Example
  /// ```dart
  /// final converter = composite.findWritable(Product.class, MediaType.APPLICATION_JSON);
  /// if (converter != null) {
  ///   await converter.write(product, MediaType.APPLICATION_JSON, response);
  /// }
  /// ```
  /// {@endtemplate}
  HttpMessageConverter? findWritable(Class type, MediaType mediaType);

  /// {@template find_readable}
  /// Finds the first [HttpMessageConverter] capable of **reading** the given type.
  ///
  /// ### Parameters
  /// - [type]: The target Dart class to deserialize into
  /// - [mediaType]: Optional content type to filter converters by
  ///
  /// ### Returns
  /// The first compatible converter, or `null` if none can handle the input.
  ///
  /// ### Example
  /// ```dart
  /// final converter = composite.findReadable(User.class, MediaType.APPLICATION_JSON);
  /// if (converter != null) {
  ///   final user = await converter.read(User.class, request);
  /// }
  /// ```
  /// {@endtemplate}
  HttpMessageConverter? findReadable(Class type, MediaType? mediaType);
}

/// {@template jetleaf_request_parameter}
/// Base annotation for binding HTTP request elements to method parameters.
///
/// This abstract class serves as the foundation for all parameter binding
/// annotations in the Jetleaf framework. It provides common configuration
/// options and behavior that are shared across different types of parameter
/// bindings, such as required flags and default values.
///
/// ### Common Attributes
/// All parameter binding annotations inherit these core attributes:
/// - [value]: The name of the request element to bind
/// - [required]: Whether the element is mandatory
/// - [defaultValue]: Fallback value when the element is missing
///
/// ### Framework Integration
/// - Extended by specific binding annotations like [MatrixVariable], [PathVariable], etc.
/// - Processed by Jetleaf's parameter resolution system during request handling
/// - Supports automatic type conversion and validation
///
/// ### Design Notes
/// This class implements [EqualsAndHashCode] to ensure proper equality
/// semantics for annotation instances, which is important for framework
/// internal processing and caching.
/// {@endtemplate}
abstract class RequestParameter extends ReflectableAnnotation with EqualsAndHashCode {
  /// Name of the request element to bind.
  ///
  /// If `null`, the framework will use the method parameter's declared name
  /// as the default. This allows for more concise annotation usage when
  /// the parameter name matches the request element name.
  final String? value;

  /// Whether the request element is mandatory.
  ///
  /// When `true` (default), the framework will throw an exception if the
  /// requested element is not present in the request. When `false`, the
  /// parameter will be set to `null` or the [defaultValue] if provided.
  final bool required;

  /// Default value to use if the request element is not present.
  ///
  /// This value is used when [required] is `false` and the request element
  /// is missing. The framework will attempt to convert this string value
  /// to the parameter's target type using the same conversion rules as
  /// for regular request values.
  final String? defaultValue;

  /// {@macro jetleaf_request_parameter}
  const RequestParameter({this.defaultValue, this.required = true, this.value});

  @override
  List<Object?> equalizedProperties() => [value, required, defaultValue];
  
  @override
  String toString() => '$runtimeType(value: $value, required: $required, defaultValue: $defaultValue)';

  @override
  Type get annotationType => runtimeType;
}

/// {@template jetleaf_matrix_variable}
/// Binds a **matrix variable** from a specific path segment of the URI
/// to a method parameter.
///
/// Matrix variables are key-value pairs embedded in URI path segments
/// using semicolon syntax. They provide a way to attach metadata to
/// individual path segments in a RESTful URL structure.
///
/// ### Matrix Variable Syntax
/// ```
/// /resources/{id};key=value/other;param=42
/// ```
///
/// ### Parameters
/// - [value]: Name of the matrix variable to bind
/// - [pathVar]: The name of the path variable segment containing the matrix variable
/// - [required]: Whether this variable is mandatory (default: `true`)
/// - [defaultValue]: Fallback value if the matrix variable is missing
///
/// ### Example
/// ```dart
/// @RestController()
/// class ProductController {
///   @GetMapping('/products/{category}/items/{id}')
///   Product getProduct(
///     @MatrixVariable(value: 'sort', pathVar: 'category') String sortBy,
///     @MatrixVariable(value: 'version', pathVar: 'id', required: false) String? version
///   ) {
///     // URL: /products/electronics;sort=price/items/123;version=2
///     // sortBy = "price", version = "2"
///     return productService.findProduct(sortBy: sortBy, version: version);
///   }
/// }
/// ```
///
/// ### Framework Integration
/// This annotation is processed by the [MatrixVariableResolver] which
/// extracts matrix variables from the appropriate path segments.
///
/// ### Related Components
/// - [MatrixVariableResolver] - The resolver implementation for this annotation
/// - [MatrixVariables] - Data structure holding resolved matrix variables
/// - [MatrixVariableUtils] - Parser for extracting matrix variables from URIs
/// {@endtemplate}
@Target({TargetKind.parameter})
@ResolvedBy(MatrixVariableResolver())
class MatrixVariable extends RequestParameter {
  /// The name of the path variable segment that contains this matrix variable.
  ///
  /// This specifies which path segment in the URI should be examined for
  /// the matrix variable. For example, in `/cars;color=red/owners;name=alice`,
  /// specifying `pathVar: 'cars'` would look for matrix variables in the
  /// first segment, while `pathVar: 'owners'` would look in the second.
  final String? pathVar;

  /// {@macro jetleaf_matrix_variable}
  const MatrixVariable({super.value, this.pathVar, super.required = true, super.defaultValue});

  @override
  List<Object?> equalizedProperties() => [pathVar, ...super.equalizedProperties()];
  
  @override
  String toString() => 'MatrixVariable('
      'value: $value, '
      'pathVar: $pathVar, '
      'required: $required, '
      'defaultValue: $defaultValue)';
}

/// {@template jetleaf_cookie_value}
/// Binds the value of a **cookie** from the HTTP request to a method parameter.
///
/// This annotation extracts cookie values from the `Cookie` request header
/// and converts them to the appropriate parameter type.
///
/// ### Parameters
/// - [value]: Name of the cookie to bind
/// - [required]: Whether the cookie is mandatory (default: `true`)
/// - [defaultValue]: Fallback value if the cookie is missing
///
/// ### Example
/// ```dart
/// @RestController()
/// class SessionController {
///   @GetMapping('/profile')
///   UserProfile getProfile(@CookieValue('sessionId') String sessionId) {
///     // Extracts the 'sessionId' cookie value from the request
///     return userService.getProfileBySession(sessionId);
///   }
/// }
/// ```
///
/// ### Security Considerations
/// - Cookie values should be validated and sanitized when used
/// - Consider using HTTP-only cookies for sensitive data
/// - Be aware of cookie size limitations in browsers
///
/// ### Framework Integration
/// Processed by [CookieValueResolver] which extracts values from [HttpCookies].
/// {@endtemplate}
@Target({TargetKind.parameter})
@ResolvedBy(CookieValueResolver())
class CookieValue extends RequestParameter {
  /// {@macro jetleaf_cookie_value}
  const CookieValue({super.value, super.required, super.defaultValue});
}

/// {@template jetleaf_path_variable}
/// Binds a **path variable** from the URI template to a method parameter.
///
/// Path variables are placeholders in URL patterns that are extracted from
/// the actual request URI. They are commonly used in RESTful APIs to
/// identify specific resources.
///
/// ### Parameters
/// - [value]: Name of the path variable (defaults to parameter name)
/// - [required]: Whether the path variable is mandatory (default: `true`)
/// - [defaultValue]: Fallback value (rarely used for path variables)
///
/// ### Example
/// ```dart
/// @RestController()
/// class UserController {
///   @GetMapping('/users/{userId}/orders/{orderId}')
///   Order getOrder(
///     @PathVariable('userId') String userId,
///     @PathVariable() String orderId  // Uses parameter name 'orderId'
///   ) {
///     // URL: /users/123/orders/456
///     // userId = "123", orderId = "456"
///     return orderService.findUserOrder(userId, orderId);
///   }
/// }
/// ```
///
/// ### Framework Integration
/// Processed by [PathVariableResolver] which extracts values from URI template variables.
/// {@endtemplate}
@Target({TargetKind.parameter})
@ResolvedBy(PathVariableResolver())
class PathVariable extends RequestParameter {
  /// {@macro jetleaf_path_variable}
  const PathVariable({super.value, super.required, super.defaultValue});
}

/// {@template jetleaf_request_body}
/// Marks a method parameter to be bound to the HTTP request body.
///
/// This annotation indicates that the parameter should be deserialized
/// from the request body content. The framework will automatically
/// convert the body to the parameter type based on the request's
/// `Content-Type` header.
///
/// ### Supported Content Types
/// - `application/json`: JSON deserialization using built-in or custom converters
/// - `application/x-www-form-urlencoded`: Form data parsing
/// - `multipart/form-data`: Multipart form handling
/// - Custom types via configured [HttpMessageConverter] instances
///
/// ### Example
/// ```dart
/// @RestController()
/// class UserController {
///   @PostMapping('/users')
///   ResponseBody<User> createUser(@RequestBody() UserCreateDto userDto) {
///     // The request body is automatically deserialized to UserCreateDto
///     final createdUser = userService.create(userDto);
///     return ResponseBody.created(createdUser);
///   }
/// }
/// ```
///
/// ### Error Handling
/// Throws [HttpMessageNotReadableException] if:
/// - The body cannot be read or parsed
/// - Required fields are missing during deserialization
/// - Type conversion fails
///
/// ### Framework Integration
/// Processed by [RequestBodyResolver] using configured [HttpMessageConverter] instances.
/// {@endtemplate}
@Target({TargetKind.parameter})
@ResolvedBy(RequestBodyResolver())
class RequestBody extends RequestParameter {
  /// {@macro jetleaf_request_body}
  const RequestBody();
}

/// {@template jetleaf_request_attribute}
/// Binds a **request-scoped attribute** to a method parameter.
///
/// Request attributes are server-side objects stored in the request
/// for the duration of a single request. They are typically set by
/// filters, interceptors, or previous processing steps.
///
/// ### Parameters
/// - [value]: Name of the request attribute (defaults to parameter name)
/// - [required]: Whether the attribute is mandatory (default: `true`)
/// - [defaultValue]: Fallback value if the attribute is not set
///
/// ### Example
/// ```dart
/// @RestController()
/// class AuthController {
///   @GetMapping('/profile')
///   UserProfile getProfile(@RequestAttribute('authenticatedUser') User user) {
///     // The 'authenticatedUser' attribute was set by an authentication filter
///     return userProfileService.getProfile(user.id);
///   }
/// }
/// ```
///
/// ### Common Use Cases
/// - Authentication context from security filters
/// - Request processing metadata from interceptors
/// - Cross-cutting concern data (logging, metrics, etc.)
///
/// ### Framework Integration
/// Processed by [RequestAttributeResolver] which extracts values from [ServerHttpRequest] attributes.
/// {@endtemplate}
@Target({TargetKind.parameter})
@ResolvedBy(RequestAttributeResolver())
class RequestAttribute extends RequestParameter {
  /// {@macro jetleaf_request_attribute}
  const RequestAttribute({super.value, super.required, super.defaultValue});
}

/// {@template jetleaf_session_attribute}
/// Binds a **session-scoped attribute** to a controller method parameter.
///
/// Session attributes persist across multiple requests within the same
/// user session. This annotation provides convenient access to session
/// data without manual session handling.
///
/// ### Parameters
/// - [value]: Name of the session attribute (defaults to parameter name)
/// - [required]: Whether the attribute is mandatory (default: `true`)
/// - [defaultValue]: Fallback value if the session attribute is missing
///
/// ### Example
/// ```dart
/// @RestController()
/// class ShoppingController {
///   @GetMapping('/cart')
///   ShoppingCart getCart(@SessionAttribute('currentCart') ShoppingCart cart) {
///     // The shopping cart is maintained across requests in the session
///     return cart;
///   }
/// }
/// ```
///
/// ### Session Management
/// - Requires an active HTTP session
/// - Attributes are stored in [HttpSession]
/// - Session creation can be configured per application
///
/// ### Framework Integration
/// Processed by [SessionAttributeResolver] which extracts values from [HttpSession] attributes.
/// {@endtemplate}
@Target({TargetKind.method})
@ResolvedBy(SessionAttributeResolver())
class SessionAttribute extends RequestAttribute {
  /// {@macro jetleaf_session_attribute}
  const SessionAttribute({super.value, super.required, super.defaultValue});
}

/// {@template jetleaf_request_header}
/// Binds the value of a specific HTTP request header to a method parameter.
///
/// This annotation extracts header values from the incoming HTTP request
/// and converts them to the appropriate parameter type.
///
/// ### Parameters
/// - [value]: Name of the HTTP header to bind (defaults to parameter name)
/// - [required]: Whether the header is mandatory (default: `true`)
/// - [defaultValue]: Fallback value if the header is missing
///
/// ### Example
/// ```dart
/// @RestController()
/// class ApiController {
///   @GetMapping('/data')
///   ResponseBody<Data> getData(
///     @RequestHeader('User-Agent') String userAgent,
///     @RequestHeader(value: 'Accept-Language', required: false) String? language
///   ) {
///     // userAgent contains the client's User-Agent string
///     // language contains Accept-Language header if present
///     return dataService.getData(userAgent, preferredLanguage: language);
///   }
/// }
/// ```
///
/// ### Common Headers
/// - `Authorization`: Authentication tokens
/// - `User-Agent`: Client identification
/// - `Accept`: Content negotiation
/// - `Content-Type`: Request body format
/// - Custom application-specific headers
///
/// ### Framework Integration
/// Processed by [RequestHeaderResolver] which extracts values from [HttpHeaders].
/// {@endtemplate}
@Target({TargetKind.parameter})
@ResolvedBy(RequestHeaderResolver())
class RequestHeader extends RequestParameter {
  /// {@macro jetleaf_request_header}
  const RequestHeader({super.value, super.required, super.defaultValue});
}

/// {@template jetleaf_request_param}
/// Binds a **query parameter** from the HTTP request URI to a method parameter.
///
/// Query parameters are key-value pairs appearing after the `?` in the URL.
/// They are commonly used for filtering, pagination, and optional parameters.
///
/// ### Parameters
/// - [value]: Name of the query parameter to bind (defaults to parameter name)
/// - [required]: Whether the parameter is mandatory (default: `true`)
/// - [defaultValue]: Fallback value if the query parameter is missing
///
/// ### Example
/// ```dart
/// @RestController()
/// class SearchController {
///   @GetMapping('/search')
///   SearchResults search(
///     @RequestParam('q') String query,
///     @RequestParam(value: 'page', required: false, defaultValue: '1') int page,
///     @RequestParam(value: 'size', required: false, defaultValue: '20') int pageSize
///   ) {
///     // URL: /search?q=flutter&page=2&size=50
///     // query = "flutter", page = 2, pageSize = 50
///     return searchService.search(query, page: page, size: pageSize);
///   }
/// }
/// ```
///
/// ### Type Conversion
/// The framework automatically converts query parameter strings to the
/// target parameter type (int, bool, DateTime, etc.) using registered
/// [Converter] instances.
///
/// ### Framework Integration
/// Processed by [RequestParamResolver] which extracts values from request parameters.
/// {@endtemplate}
@Target({TargetKind.parameter})
@ResolvedBy(RequestParamResolver())
class RequestParam extends RequestParameter {
  /// {@macro jetleaf_request_param}
  const RequestParam({super.value, super.required, super.defaultValue});
}

/// {@template jetleaf_request_part}
/// Binds a **multipart/form-data request part** to a method parameter.
///
/// Used for handling file uploads and complex form data in `multipart/form-data`
/// requests. Each part can contain binary data, form fields, or mixed content.
///
/// ### Parameters
/// - [value]: Name of the request part to bind (defaults to parameter name)
/// - [required]: Whether the part is mandatory (default: `true`)
/// - [contentType]: Expected content type for validation
/// - [maxSize]: Maximum allowed size in bytes
///
/// ### Example
/// ```dart
/// @RestController()
/// class UploadController {
///   @PostMapping('/upload')
///   UploadResult uploadFile(
///     @RequestPart('document') Uint8List fileData,
///     @RequestPart('metadata', contentType: 'application/json') FileMetadata metadata
///   ) {
///     // Handles multipart form with 'document' and 'metadata' parts
///     return storageService.storeFile(fileData, metadata);
///   }
/// }
/// ```
///
/// ### Validation Features
/// - Content type validation when [contentType] is specified
/// - Size validation with [maxSize] limit
/// - Required part validation
///
/// ### Framework Integration
/// Processed by [RequestPartResolver] which handles multipart request parsing.
/// {@endtemplate}
@Target({TargetKind.parameter})
@ResolvedBy(RequestPartResolver())
class RequestPart extends RequestParameter {
  /// Expected content type of the multipart part.
  ///
  /// If specified, the framework will validate that the part's content type
  /// matches this value. This is useful for ensuring that uploaded files
  /// or data parts are in the expected format.
  final String? contentType;

  /// Maximum allowed size of the part in bytes.
  ///
  /// If the part exceeds this size, a [FileSizeException] will be thrown
  /// during request processing. This helps prevent denial-of-service attacks
  /// through large file uploads.
  final int? maxSize;

  /// {@macro jetleaf_request_part}
  const RequestPart({super.value, super.required, this.contentType, this.maxSize});

  @override
  List<Object?> equalizedProperties() => [...super.equalizedProperties(), contentType, maxSize];

  @override
  String toString() => 'RequestPart(value: $value, required: $required, contentType: $contentType, maxSize: $maxSize)';
}