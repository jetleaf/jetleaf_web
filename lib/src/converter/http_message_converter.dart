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

import '../http/http_message.dart';
import '../http/media_type.dart';

/// {@template jetleaf_http_message_converter}
/// Strategy interface for converting between HTTP messages and Dart objects.
///
/// [HttpMessageConverter] implementations are responsible for the two-way
/// conversion between HTTP request/response bodies and Dart objects. This
/// abstraction enables content negotiation, serialization, and deserialization
/// in a type-safe manner throughout the Jetleaf framework.
///
/// ### Generic Type Parameter
/// - `T`: The Dart type that this converter can read and write
///
/// ### Primary Responsibilities
/// - **Deserialization**: Convert HTTP request bodies to Dart objects ([read])
/// - **Serialization**: Convert Dart objects to HTTP response bodies ([write])
/// - **Content Negotiation**: Determine supported media types for specific types
/// - **Type Safety**: Ensure proper type handling during conversion
///
/// ### Framework Integration
/// Converters are used by:
/// - **Request Body Processing**: Converting JSON/XML request bodies to method parameters
/// - **Response Body Processing**: Converting return values to JSON/XML responses
/// - **Content Negotiation**: Selecting appropriate converters based on Accept headers
/// - **Error Handling**: Providing meaningful conversion error messages
///
/// ### Built-in Implementations
/// Jetleaf typically provides these standard converters:
/// - **`JsonHttpMessageConverter`**: Handles JSON ↔ Dart object conversion
/// - **`StringHttpMessageConverter`**: Handles text/plain content
/// - **`FormHttpMessageConverter`**: Handles application/x-www-form-urlencoded
/// - **`ByteArrayHttpMessageConverter`**: Handles binary data (application/octet-stream)
/// - **`XmlHttpMessageConverter`**: Handles XML content (application/xml)
///
/// ### Example: JSON Converter Implementation
/// ```dart
/// @Generic(HttpMessageConverter)
/// class JsonHttpMessageConverter implements HttpMessageConverter<Object> {
///   final JsonCodec _codec;
///   
///   JsonHttpMessageConverter(this._codec);
/// 
///   @override
///   bool canRead(Class<Object> type, [MediaType? mediaType]) {
///     return mediaType?.includes(MediaType.APPLICATION_JSON) ?? true;
///   }
/// 
///   @override
///   bool canWrite(Class<Object> type, [MediaType? mediaType]) {
///     return mediaType?.includes(MediaType.APPLICATION_JSON) ?? true;
///   }
/// 
///   @override
///   List<MediaType> getSupportedMediaTypes() {
///     return [MediaType.APPLICATION_JSON];
///   }
/// 
///   @override
///   Future<Object> read(Class<Object> type, HttpInputMessage inputMessage) async {
///     try {
///       final body = await inputMessage.getBody().readAsString();
///       return _codec.decode(body);
///     } catch (e) {
///       throw HttpMessageNotReadableException('Failed to read JSON: $e', e);
///     }
///   }
/// 
///   @override
///   Future<void> write(Object object, MediaType? contentType, HttpOutputMessage outputMessage) async {
///     try {
///       final json = _codec.encode(object);
///       outputMessage.getHeaders().setContentType(contentType ?? MediaType.APPLICATION_JSON);
///       await outputMessage.getBody().writeString(json);
///     } catch (e) {
///       throw HttpMessageNotWritableException('Failed to write JSON: $e', e);
///     }
///   }
/// }
/// ```
///
/// ### Content Negotiation Process
/// When processing requests/responses, the framework:
/// 1. **Collects Media Types**: From Accept header or Content-Type header
/// 2. **Finds Compatible Converters**: Using [canRead]/[canWrite] methods
/// 3. **Selects Best Match**: Based on media type specificity and quality factors
/// 4. **Executes Conversion**: Using the selected converter
///
/// ### Error Handling
/// Converters should throw framework-specific exceptions:
/// - [HttpMessageNotReadableException]: When deserialization fails
/// - [HttpMessageNotWritableException]: When serialization fails
/// - [IOException]: For I/O-related errors during stream processing
///
/// ### Best Practices
/// - Make [canRead] and [canWrite] checks efficient and fast
/// - Support common media type variations (e.g., application/json vs application/vnd.api+json)
/// - Handle character encoding properly for text-based formats
/// - Consider performance implications for large payloads
/// - Provide clear error messages for debugging conversion issues
/// {@endtemplate}
@Generic(HttpMessageConverter)
abstract class HttpMessageConverter<T> with EqualsAndHashCode {
  /// {@macro jetleaf_http_message_converter}
  const HttpMessageConverter();

  /// Determines whether this converter can deserialize the given type from the specified media type.
  ///
  /// This method is called during request processing to determine if this converter
  /// can read the incoming HTTP message body and convert it to the specified Dart type.
  ///
  /// ### Parameters
  /// - [type]: The target Dart type to convert to
  /// - [mediaType]: The media type of the incoming content (optional, for content negotiation)
  ///
  /// ### Returns
  /// `true` if this converter can perform the deserialization, `false` otherwise
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// bool canRead(Class<User> type, [MediaType? mediaType]) {
  ///   // Support JSON media types for User class
  ///   return mediaType?.includes(MediaType.APPLICATION_JSON) ?? true;
  /// }
  /// 
  /// @override
  /// bool canRead(Class<Map> type, [MediaType? mediaType]) {
  ///   // Support both JSON and XML for Map types
  ///   return mediaType?.includesAny([MediaType.APPLICATION_JSON, MediaType.APPLICATION_XML]) ?? true;
  /// }
  /// ```
  ///
  /// ### Performance Considerations
  /// This method is called frequently during content negotiation, so it should
  /// be optimized for performance and avoid expensive operations.
  bool canRead(Class type, [MediaType? mediaType]);

  /// Determines whether this converter can serialize the given type to the specified media type.
  ///
  /// This method is called during response processing to determine if this converter
  /// can convert the Dart object to the requested media type for the HTTP response.
  ///
  /// ### Parameters
  /// - [type]: The source Dart type to convert from
  /// - [mediaType]: The target media type for serialization (optional, for content negotiation)
  ///
  /// ### Returns
  /// `true` if this converter can perform the serialization, `false` otherwise
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// bool canWrite(Class<Product> type, [MediaType? mediaType]) {
  ///   // Support JSON and XML for Product responses
  ///   final supportedTypes = [MediaType.APPLICATION_JSON, MediaType.APPLICATION_XML];
  ///   return mediaType?.includesAny(supportedTypes) ?? true;
  /// }
  /// ```
  bool canWrite(Class type, [MediaType? mediaType]);

  /// Returns the list of media types this converter supports by default.
  ///
  /// This method provides the global set of media types that this converter
  /// can handle, regardless of the specific type being converted.
  ///
  /// ### Returns
  /// A list of supported [MediaType] instances
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// List<MediaType> getSupportedMediaTypes() {
  ///   return [
  ///     MediaType.APPLICATION_JSON,
  ///     MediaType('application', 'vnd.api+json'), // JSON API format
  ///   ];
  /// }
  /// ```
  ///
  /// ### Media Type Specificity
  /// More specific media types (with parameters) should be listed before
  /// more general ones to ensure proper content negotiation.
  List<MediaType> getSupportedMediaTypes();

  /// Returns the media types specifically supported for a given class type.
  ///
  /// This method allows converters to provide type-specific media type support,
  /// enabling more granular content negotiation based on the actual object type.
  ///
  /// ### Parameters
  /// - [type]: The specific class type to check supported media types for
  ///
  /// ### Returns
  /// A list of [MediaType] instances supported for the given type
  ///
  /// ### Default Implementation
  /// By default, returns the same as [getSupportedMediaTypes()]
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// List<MediaType> getClassSupportedMediaTypes(Class<T> type) {
  ///   // Special media type only for Report objects
  ///   if (type == Report.class) {
  ///     return [MediaType('application', 'vnd.company.report+json')];
  ///   }
  ///   
  ///   // Default media types for other types
  ///   return getSupportedMediaTypes();
  /// }
  /// ```
  List<MediaType> getClassSupportedMediaTypes(Class<T> type) => getSupportedMediaTypes();

  /// Deserializes an HTTP input message to a Dart object of type [T].
  ///
  /// This method reads the content from the [HttpInputMessage] and converts
  /// it to an instance of the specified Dart type.
  ///
  /// ### Parameters
  /// - [type]: The target Dart type to convert to
  /// - [inputMessage]: The HTTP input message containing the content to read
  ///
  /// ### Returns
  /// A [Future] that completes with the deserialized Dart object
  ///
  /// ### Throws
  /// - [HttpMessageNotReadableException]: If the content cannot be read or parsed
  /// - [IOException]: If an I/O error occurs during reading
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// Future<User> read(Class<User> type, HttpInputMessage inputMessage) async {
  ///   try {
  ///     final jsonString = await inputMessage.getBody().readAsString(Closeable.DEFAULT_ENCODING);
  ///     final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
  ///     return User.fromJson(jsonMap);
  ///   } on FormatException catch (e) {
  ///     throw HttpMessageNotReadableException('Invalid JSON format: $e', e);
  ///   }
  /// }
  /// ```
  ///
  /// ### Character Encoding
  /// Consider the character encoding specified in the Content-Type header
  /// when reading text-based content.
  Future<T> read(Class<T> type, HttpInputMessage inputMessage);

  /// Serializes a Dart object to an HTTP output message.
  ///
  /// This method converts the Dart object to the appropriate format and writes
  /// it to the [HttpOutputMessage], setting the appropriate Content-Type header.
  ///
  /// ### Parameters
  /// - [object]: The Dart object to serialize
  /// - [contentType]: The desired content type for the output (may be null)
  /// - [outputMessage]: The HTTP output message to write the content to
  ///
  /// ### Throws
  /// - [HttpMessageNotWritableException]: If the object cannot be serialized
  /// - [IOException]: If an I/O error occurs during writing
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// Future<void> write(User user, MediaType? contentType, HttpOutputMessage outputMessage) async {
  ///   try {
  ///     final jsonMap = user.toJson();
  ///     final jsonString = jsonEncode(jsonMap);
  ///     
  ///     // Set content type header
  ///     final actualContentType = contentType ?? MediaType.APPLICATION_JSON;
  ///     outputMessage.getHeaders().setContentType(actualContentType);
  ///     
  ///     // Write response body
  ///     await outputMessage.getBody().writeString(jsonString, Closeable.DEFAULT_ENCODING);
  ///   } on JsonUnsupportedObjectError catch (e) {
  ///     throw HttpMessageNotWritableException('Object not serializable to JSON: $e', e);
  ///   }
  /// }
  /// ```
  ///
  /// ### Content Type Handling
  /// If [contentType] is provided, it should be respected. If null, use
  /// a sensible default based on the converter's supported media types.
  Future<void> write(T object, MediaType? contentType, HttpOutputMessage outputMessage);
}