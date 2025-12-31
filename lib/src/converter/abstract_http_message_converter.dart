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

import 'dart:convert';

import 'package:jetleaf_lang/lang.dart';
import 'package:jetson/jetson.dart';
import 'package:meta/meta.dart';

import '../exception/exceptions.dart';
import '../http/http_headers.dart';
import '../http/http_message.dart';
import 'http_message_converter.dart';
import '../http/media_type.dart';

/// {@template abstract_http_message_converter}
/// Abstract base class implementing common [HttpMessageConverter] functionality.
///
/// ### Overview
///
/// The [AbstractHttpMessageConverter] provides a robust foundation for creating
/// concrete HTTP message converter implementations. It handles common concerns
/// like media type support management, default encoding, header processing,
/// and exception handling, allowing subclasses to focus on type-specific conversion logic.
///
/// ### Key Features
///
/// - **Media Type Management**: Configurable list of supported media types
/// - **Encoding Support**: Default character encoding configuration (UTF-8 by default)
/// - **Header Handling**: Automatic Content-Type header management
/// - **Exception Wrapping**: Consistent exception handling and transformation
/// - **Template Methods**: Clean separation between common and type-specific logic
///
/// ### Implementation Pattern
///
/// Subclasses typically:
/// 1. Call super constructor and set supported media types
/// 2. Implement [readInternal] for deserialization logic
/// 3. Implement [writeInternal] for serialization logic
/// 4. Optionally override [canRead]/[canWrite] for custom media type logic
///
/// ### Example: JSON Converter Implementation
///
/// ```dart
/// class JsonHttpMessageConverter extends AbstractHttpMessageConverter<Object> {
///   final JsonCodec _codec;
///
///   JsonHttpMessageConverter(this._codec) {
///     setSupportedMediaTypes([MediaType.APPLICATION_JSON]);
///     setDefaultEncoding(Closeable.DEFAULT_ENCODING);
///   }
///
///   @override
///   Future<Object> readInternal(Class<Object> type, HttpInputMessage inputMessage) async {
///     final body = await inputMessage.getBody().readAsString(encoding: getDefaultEncoding());
///     return _codec.decode(body);
///   }
///
///   @override
///   Future<void> writeInternal(Object object, HttpOutputMessage outputMessage) async {
///     final jsonString = _codec.encode(object);
///     await outputMessage.getBody().writeString(jsonString, encoding: getDefaultEncoding());
///   }
/// }
/// ```
///
/// ### Media Type Compatibility
///
/// The default [canRead] and [canWrite] implementations use media type compatibility
/// checking, supporting scenarios like:
/// - `application/json` ↔ `application/json; charset=utf-8`
/// - `text/plain` ↔ `text/plain; charset=iso-8859-1`
/// - Exact media type matches and compatible parameter variations
///
/// ### Exception Handling Strategy
///
/// The converter automatically wraps implementation exceptions:
/// - **Read Errors**: Wrapped in [HttpMessageNotReadableException] with status 400
/// - **Write Errors**: Wrapped in [HttpMessageNotWritableException] with status 500
/// - **Original Context**: Preserves original exception and stack trace for debugging
///
/// ### Header Management
///
/// The [addDefaultHeaders] method ensures proper Content-Type headers are set:
/// - Only sets headers if not already present
/// - Uses provided contentType or falls back to first supported media type
/// - Maintains consistency between declared and actual content types
///
/// ### Best Practices for Subclasses
///
/// - **Set Supported Media Types**: Call [setSupportedMediaTypes] in constructor
/// - **Handle Encoding**: Respect [getDefaultEncoding()] in read/write operations
/// - **Validate Input**: Perform type-specific validation in template methods
/// - **Resource Cleanup**: Ensure streams are properly closed in error scenarios
/// - **Performance**: Consider buffering strategies for large payloads
///
/// ### Extension Points
///
/// Subclasses can override:
/// - [canRead]/[canWrite]: Custom media type matching logic
/// - [addDefaultHeaders]: Custom header management
/// - [getSupportedMediaTypes]: Dynamic media type support
///
/// ### Framework Integration
///
/// Used as the base for all built-in Jetleaf converters:
/// - `StringHttpMessageConverter`: Handles text/plain content
/// - `ByteArrayHttpMessageConverter`: Handles application/octet-stream
/// - `FormHttpMessageConverter`: Handles application/x-www-form-urlencoded
/// - `JsonHttpMessageConverter`: Handles application/json
/// - `XmlHttpMessageConverter`: Handles application/xml
///
/// ### Summary
///
/// The [AbstractHttpMessageConverter] dramatically reduces boilerplate code
/// for converter implementations while ensuring consistent behavior, proper
/// error handling, and framework integration across all HTTP message converters.
/// {@endtemplate}
@Generic(AbstractHttpMessageConverter)
abstract class AbstractHttpMessageConverter<T> extends HttpMessageConverter<T> {
  /// The list of **supported media types** that this converter, renderer,
  /// or HTTP component can handle.
  ///
  /// Each entry in this list represents a [MediaType] (e.g. `application/json`,
  /// `text/html`, or `application/xml`) that the current implementation is
  /// capable of reading or writing.
  ///
  /// ### Usage
  /// - Used by content negotiation mechanisms to determine if a converter
  ///   can process a given request or response.
  /// - May be extended at runtime to add framework- or user-defined media types.
  ///
  /// ### Example
  /// ```dart
  /// _supportedMediaTypes = [
  ///   MediaType.APPLICATION_JSON,
  ///   MediaType.TEXT_HTML,
  /// ];
  /// ```
  ///
  /// ### Notes
  /// - The order of media types may determine priority during content negotiation.
  /// - Implementations should ensure this list is **not empty** for proper matching.
  List<MediaType> _supportedMediaTypes = [];

  /// The **default character encoding** used when reading or writing textual
  /// HTTP bodies (e.g., JSON, HTML, or plain text).
  ///
  /// This encoding is applied when no explicit charset is specified in the
  /// `Content-Type` or `Accept` headers.
  ///
  /// ### Default
  /// The default is [Closeable.DEFAULT_ENCODING], ensuring interoperability and compatibility
  /// with most web clients and servers.
  ///
  /// ### Example
  /// ```dart
  /// _defaultEncoding = Closeable.DEFAULT_ENCODING;
  /// ```
  ///
  /// ### Notes
  /// - Implementations should respect the charset provided in the request or
  ///   response headers when available.
  /// - Custom encodings (e.g., Latin1) can be assigned if the media type
  ///   or protocol demands it.
  Encoding _defaultEncoding = Closeable.DEFAULT_ENCODING;

  /// {@macro abstract_http_message_converter}
  AbstractHttpMessageConverter();

  @override
  List<MediaType> getSupportedMediaTypes() => List.unmodifiable(_supportedMediaTypes);

  /// {@template default_encoding}
  /// Returns the default character encoding used by this converter.
  ///
  /// ### Usage in Subclasses
  ///
  /// Subclasses should use this encoding when reading/writing text-based content:
  ///
  /// ```dart
  /// @override
  /// Future<String> readInternal(Class<String> type, HttpInputMessage inputMessage) async {
  ///   // Use the configured default encoding
  ///   return await inputMessage.getBody().readAsString(encoding: getDefaultEncoding());
  /// }
  /// ```
  ///
  /// ### Default Value
  ///
  /// Returns [Closeable.DEFAULT_ENCODING] by default. Override using [setDefaultEncoding].
  ///
  /// ### Encoding Considerations
  ///
  /// - For binary formats (images, PDFs), encoding may be irrelevant
  /// - For text formats, the encoding should match the Content-Type charset
  /// - The framework may override this based on request/response headers
  /// {@endtemplate}
  Encoding getDefaultEncoding() => _defaultEncoding;

  /// {@template set_default_encoding}
  /// Sets the default character encoding for this converter.
  ///
  /// ### Parameters
  /// - [encoding]: The character encoding to use for text-based operations
  ///
  /// ### Common Encodings
  ///
  /// ```dart
  /// setDefaultEncoding(Closeable.DEFAULT_ENCODING);      // UTF-8 (most common)
  /// setDefaultEncoding(latin1);    // ISO-8859-1
  /// setDefaultEncoding(ascii);     // US-ASCII
  /// setDefaultEncoding(utf16);     // UTF-16
  /// ```
  ///
  /// ### Example
  /// ```dart
  /// class CustomConverter extends AbstractHttpMessageConverter<String> {
  ///   CustomConverter() {
  ///     setDefaultEncoding(latin1);
  ///     setSupportedMediaTypes([MediaType.TEXT_PLAIN]);
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  void setDefaultEncoding(Encoding encoding) => _defaultEncoding = encoding;

  /// Resolves the appropriate **character encoding** for reading the request body.
  ///
  /// This method determines the encoding to use when reading data from an
  /// [HttpInputMessage] (typically a `ServerHttpRequest`).
  ///
  /// ### Resolution Logic
  /// 1. Checks the `Content-Type` header for a `charset` parameter.  
  ///    Example: `Content-Type: application/json; charset=utf-16`
  /// 2. If a charset is found, attempts to resolve it via [Encoding.getByName].
  /// 3. If no valid charset is specified or resolution fails, falls back to
  ///    [getDefaultEncoding] (UTF-8 by default).
  ///
  /// ### Parameters
  /// - [inputMessage] – The request message whose encoding should be determined.
  ///
  /// ### Returns
  /// The resolved [Encoding] to be used for reading the request body.
  ///
  /// ### Example
  /// ```dart
  /// final encoding = resolveRequestEncoding(request);
  /// final body = await request.getBody().decode(encoding);
  /// ```
  @protected
  Encoding resolveRequestEncoding(HttpInputMessage inputMessage) {
    final contentType = inputMessage.getHeaders().getContentType();
    final charset = contentType?.getCharset();
    return charset != null ? Encoding.getByName(charset) ?? getDefaultEncoding() : getDefaultEncoding();
  }

  /// Resolves the appropriate **character encoding** for writing the response body.
  ///
  /// This method determines the encoding to use when sending data via an
  /// [HttpOutputMessage] (typically a `ServerHttpResponse`).
  ///
  /// ### Resolution Logic
  /// 1. Checks the `Content-Type` header for a `charset` parameter.  
  ///    Example: `Content-Type: text/html; charset=iso-8859-1`
  /// 2. If no charset is defined, checks the `Accept-Charset` header for
  ///    preferred encodings from the client and uses the first supported one.
  /// 3. If no encoding can be resolved, falls back to [getDefaultEncoding]
  ///    (UTF-8 by default).
  ///
  /// ### Parameters
  /// - [outputMessage] – The response message whose encoding should be determined.
  ///
  /// ### Returns
  /// The resolved [Encoding] to be used for writing the response body.
  ///
  /// ### Example
  /// ```dart
  /// final encoding = resolveResponseEncoding(response);
  /// final writer = response.getBody();
  /// await writer.writeString('OK', encoding: encoding);
  /// await writer.close();
  /// ```
  @protected
  Encoding resolveResponseEncoding(HttpOutputMessage outputMessage) {
    final contentType = outputMessage.getHeaders().getContentType();
    final charset = contentType?.getCharset();

    if (charset != null) {
      return Encoding.getByName(charset) ?? getDefaultEncoding();
    }

    // Optionally consider Accept-Charset preference
    final acceptCharset = outputMessage.getHeaders().getAcceptCharset();
    if (acceptCharset.isNotEmpty) {
      return acceptCharset.first;
    }

    return getDefaultEncoding();
  }

  /// {@template set_supported_media_types}
  /// Replaces the current supported media types with the provided list.
  ///
  /// ### Parameters
  /// - [types]: Complete list of media types this converter should support
  ///
  /// ### Order Significance
  ///
  /// The order of media types may be significant for:
  /// - Content negotiation when multiple converters match
  /// - Default content type selection when none specified
  /// - Quality factor calculations in Accept headers
  ///
  /// ### Example
  /// ```dart
  /// converter.setSupportedMediaTypes([
  ///   MediaType.APPLICATION_JSON,
  ///   MediaType('application', 'vnd.company.api+json'), // More specific first
  ///   MediaType('application', '*+json') // Wildcard subtype last
  /// ]);
  /// ```
  /// {@endtemplate}
  void setSupportedMediaTypes(List<MediaType> types) => _supportedMediaTypes = types;

  /// {@template add_supported_media_type}
  /// Adds a media type to the list of supported types.
  ///
  /// ### Parameters
  /// - [type]: The media type to add to supported types
  ///
  /// ### Example: Progressive Media Type Registration
  /// ```dart
  /// final converter = JsonHttpMessageConverter();
  /// converter.addSupportedMediaType(MediaType.APPLICATION_JSON);
  /// converter.addSupportedMediaType(MediaType('application', 'vnd.api+json'));
  /// converter.addSupportedMediaType(MediaType('application', 'hal+json'));
  /// ```
  /// {@endtemplate}
  void addSupportedMediaType(MediaType type) {
    _supportedMediaTypes.add(type);
  }

  /// {@template remove_supported_media_type}
  /// Removes a media type from the list of supported types.
  ///
  /// ### Parameters
  /// - [type]: The media type to remove from supported types
  ///
  /// ### Use Cases
  /// - Dynamic media type management at runtime
  /// - Feature toggling for specific formats
  /// - Conditional support based on configuration
  ///
  /// ### Example
  /// ```dart
  /// // Remove XML support if feature is disabled
  /// if (!features.xmlEnabled) {
  ///   converter.removeSupportedMediaType(MediaType.APPLICATION_XML);
  /// }
  /// ```
  /// {@endtemplate}
  void removeSupportedMediaType(MediaType type) {
    _supportedMediaTypes.remove(type);
  }

  /// {@template add_default_headers}
  /// Adds default headers to the HTTP message if not already present.
  ///
  /// ### Parameters
  /// - [headers]: The HTTP headers to modify
  /// - [contentType]: The content type to set if no Content-Type is present
  ///
  /// ### Header Strategy
  ///
  /// This method follows a conservative approach:
  /// - Only sets Content-Type if not already specified
  /// - Respects existing headers to avoid overriding user-set values
  /// - Uses the provided contentType or falls back to first supported media type
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// Future<void> write(Object object, MediaType? contentType, HttpOutputMessage outputMessage) async {
  ///   final headers = outputMessage.getHeaders();
  ///   
  ///   // Set default headers if needed
  ///   addDefaultHeaders(headers, contentType);
  ///   
  ///   // Now proceed with writing the body
  ///   await writeInternal(object, outputMessage);
  /// }
  /// ```
  /// {@endtemplate}
  void addDefaultHeaders(HttpHeaders headers, MediaType? contentType) {
    if (headers.getContentType() == null && contentType != null) {
      headers.setContentType(contentType);
    }
  }

  /// {@template read_internal}
  /// Template method for reading and deserializing HTTP input.
  ///
  /// ### Responsibilities
  ///
  /// Subclasses must implement this method to:
  /// - Read the input message body using appropriate encoding
  /// - Parse/deserialize the content into the target type [T]
  /// - Perform type-specific validation and transformation
  /// - Handle format-specific parsing rules and edge cases
  ///
  /// ### Parameters
  /// - [type]: The target Dart type to convert to
  /// - [inputMessage]: The HTTP input message containing the content to read
  ///
  /// ### Returns
  /// A [Future] that completes with the deserialized Dart object of type [T]
  ///
  /// ### Example Implementation
  /// ```dart
  /// @override
  /// Future<User> readInternal(Class<User> type, HttpInputMessage inputMessage) async {
  ///   // Read the input stream with proper encoding
  ///   final content = await inputMessage.getBody().readAsString(encoding: getDefaultEncoding());
  ///   
  ///   // Parse the content (JSON example)
  ///   final jsonMap = jsonDecode(content) as Map<String, dynamic>;
  ///   
  ///   // Convert to target type
  ///   return User.fromJson(jsonMap);
  /// }
  /// ```
  ///
  /// ### Error Handling
  ///
  /// Exceptions thrown by this method are automatically wrapped in
  /// [HttpMessageNotReadableException] by the [read] method.
  ///
  /// ### Performance Considerations
  ///
  /// - Consider streaming for large payloads to avoid memory issues
  /// - Use efficient parsing libraries for complex formats
  /// - Cache expensive resources like parsers or validators
  /// {@endtemplate}
  Future<T> readInternal(Class<T> type, HttpInputMessage inputMessage);

  /// {@template write_internal}
  /// Template method for serializing an object to an HTTP output message.
  ///
  /// ### Responsibilities
  ///
  /// Subclasses must implement this method to:
  /// - Serialize the Dart object to the appropriate format
  /// - Write the serialized content to the output message
  /// - Use the proper encoding for text-based formats
  /// - Handle type-specific serialization rules
  ///
  /// ### Parameters
  /// - [object]: The Dart object to serialize
  /// - [outputMessage]: The HTTP output message to write the content to
  ///
  /// ### Example Implementation
  /// ```dart
  /// @override
  /// Future<void> writeInternal(User user, HttpOutputMessage outputMessage) async {
  ///   // Serialize the object
  ///   final jsonMap = user.toJson();
  ///   final jsonString = jsonEncode(jsonMap);
  ///   
  ///   // Write to output stream with proper encoding
  ///   await outputMessage.getBody().writeString(jsonString, encoding: getDefaultEncoding());
  /// }
  /// ```
  ///
  /// ### Header Consideration
  ///
  /// Content-Type headers are already handled by [addDefaultHeaders] before
  /// this method is called. Focus on writing the body content only.
  ///
  /// ### Error Handling
  ///
  /// Exceptions thrown by this method are automatically wrapped in
  /// [HttpMessageNotWritableException] by the [write] method.
  ///
  /// ### Performance Considerations
  ///
  /// - Use streaming for large objects to avoid memory pressure
  /// - Consider compression for text-based formats
  /// - Reuse serializers and formatters when possible
  /// {@endtemplate}
  Future<void> writeInternal(T object, HttpOutputMessage outputMessage);

  /// Returns whether the given [type] matches this filter's criteria.
  ///
  /// Always returns `false` by default; subclasses should override this
  /// to implement specific matching logic.
  bool matchesType(Class type) => false;

  @override
  bool canRead(Class type, [MediaType? mediaType]) {
    if (matchesType(type)) {
      return true;
    }

    if (mediaType == null) return false;
    return _supportedMediaTypes.any((m) => m.isCompatibleWith(mediaType));
  }

  @override
  bool canWrite(Class type, [MediaType? mediaType]) {
    if (matchesType(type)) {
      return true;
    }

    if (mediaType == null) return true;
    return _supportedMediaTypes.any((m) => mediaType.isCompatibleWith(m));
  }

  @override
  Future<T> read(Class<T> type, HttpInputMessage inputMessage) async {
    try {
      return await readInternal(type, inputMessage);
    } catch (e, st) {
      Object exception = e;
      StackTrace trace = st;

      if (e is FailedDeserializationException) {
        exception = e.cause ?? e;
        trace = e.stackTrace;
      }

      throw HttpMessageNotReadableException(
        'Failed to read message. $exception',
        originalException: exception is Throwable 
          ? exception
          : exception is Exception
            ? exception
            : RuntimeException(exception.toString()),
        originalStackTrace: trace
      );
    }
  }

  @override
  Future<void> write(T object, MediaType? contentType, HttpOutputMessage outputMessage) async {
    try {
      addDefaultHeaders(outputMessage.getHeaders(), contentType ?? _supportedMediaTypes.first);
      await writeInternal(object, outputMessage);
    } catch (e, st) {
      throw HttpMessageNotWritableException(
        'Failed to write message $e',
        originalException: e is Throwable ? e : e is Exception ? e : RuntimeException(e.toString()),
        originalStackTrace: st
      );
    }
  }
}