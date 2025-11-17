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
import 'http_headers.dart';

/// {@template jetleaf_http_message}
/// Represents the base abstraction for HTTP messages, containing
/// both **headers** and a potential **body**.
///
/// This interface is the common parent for both [HttpInputMessage]
/// (used for requests) and [HttpOutputMessage] (used for responses).
/// It provides the fundamental contract that all HTTP message types
/// must implement, ensuring consistent access to message headers
/// across different message contexts.
///
/// ### Responsibilities
/// - Provides access to the HTTP [HttpHeaders]
/// - Defines a common contract for input/output message structures
/// - Serves as a foundation for high-level entities like
///   [RequestHttpBody] and [ResponseBody]
/// - Enables header manipulation and inspection regardless of message direction
///
/// ### Inheritance Hierarchy
/// ```
/// HttpMessage (abstract)
/// ├── HttpInputMessage (abstract) - for incoming messages
/// └── HttpOutputMessage (abstract) - for outgoing messages
/// ```
///
/// ### Example
/// ```dart
/// void logHeaders(HttpMessage message) {
///   final headers = message.getHeaders();
///   headers.forEach((name, values) {
///     print('$name: ${values.join(", ")}');
///   });
/// }
/// ```
///
/// ### Design Notes
/// - Part of JetLeaf's unified request/response abstraction model
/// - Does not itself define a body; see [HttpInputMessage] and
///   [HttpOutputMessage] for body access
/// - Designed to be implemented by both client and server-side message types
///
/// ### Related Classes
/// - [HttpInputMessage] - For reading incoming HTTP messages
/// - [HttpOutputMessage] - For writing outgoing HTTP messages  
/// - [HttpHeaders] - Header storage and manipulation
/// - [RequestHttpBody] - High-level request representation
/// - [ResponseBody] - High-level response representation
/// {@endtemplate}
abstract interface class HttpMessage {
  /// Returns the HTTP headers associated with this message.
  ///
  /// The headers may include standard fields like `Content-Type`,
  /// `Accept`, `Authorization`, or custom application-specific metadata.
  /// The returned [HttpHeaders] instance provides case-insensitive lookups
  /// and convenient accessors for common header values.
  ///
  /// ### Returns
  /// An [HttpHeaders] instance containing all message headers
  ///
  /// ### Example
  /// ```dart
  /// final headers = message.getHeaders();
  /// final contentType = headers.getContentType();
  /// final contentLength = headers.getContentLength();
  /// 
  /// // Access custom headers
  /// final customValue = headers.getFirst('X-Custom-Header');
  /// ```
  ///
  /// ### Header Mutability
  /// The mutability of the returned headers depends on the concrete implementation:
  /// - RequestHttpBody headers are typically read-only
  /// - ResponseBody headers are typically mutable
  /// - Always check the implementation documentation for mutability guarantees
  HttpHeaders getHeaders();

  /// Replaces the entire set of HTTP headers for this message.
  ///
  /// This method assigns a new [HttpHeaders] instance to the message,
  /// completely overwriting any existing header entries. It is typically used
  /// by framework components (e.g., interceptors, filters, or response
  /// builders) when constructing or modifying outgoing requests or responses.
  ///
  /// ### Parameters
  /// - [headers]: The new [HttpHeaders] instance to associate with this message.
  ///
  /// ### Behavior
  /// - All previously set headers are discarded.
  /// - The message will subsequently return the provided headers when
  ///   [getHeaders] is called.
  ///
  /// ### Example
  /// ```dart
  /// final newHeaders = HttpHeaders()
  ///   ..setContentType('application/json')
  ///   ..set('X-App-Version', '1.0.0');
  ///
  /// message.setHeaders(newHeaders);
  /// ```
  ///
  /// ### Notes
  /// - Mutability depends on the specific message implementation:
  ///   - For response messages, this operation is usually allowed before
  ///     the body is written.
  ///   - For request messages, header replacement is typically restricted
  ///     once the request has been dispatched.
  /// - Implementations may throw an [UnsupportedOperationException] if
  ///   the headers are immutable at the current lifecycle stage.
  ///
  /// ### See Also
  /// - [getHeaders] — for reading the current headers
  /// - [HttpHeaders] — for available header manipulation APIs
  void setHeaders(HttpHeaders headers);
}

/// {@template jetleaf_http_input_message}
/// Represents an HTTP **input message**, typically corresponding to
/// an incoming HTTP **request** or a deserialized response body.
///
/// Extends [HttpMessage] by adding an input body stream,
/// which provides access to the **raw incoming bytes**. This interface
/// is used when you need to read data from an HTTP message, such as
/// processing a client request or reading a server response.
///
/// ### Primary Use Cases
/// - **Server-side**: Processing incoming HTTP requests in [ServerHttpRequest]
/// - **Client-side**: Reading HTTP responses from remote servers
/// - **Message conversion**: Deserializing request bodies in message converters
/// - **Stream processing**: Handling large payloads as streams
///
/// ### Example
/// ```dart
/// Future<void> handleRequest(HttpInputMessage message) async {
///   final headers = message.getHeaders();
///   final contentType = headers.getContentType();
///   final bodyStream = message.getBody();
///   
///   if (contentType?.includes(MediaType.APPLICATION_JSON)) {
///     final jsonString = await bodyStream.readAsString(Closeable.DEFAULT_ENCODING);
///     final data = jsonDecode(jsonString);
///     // Process JSON data
///   }
/// }
/// ```
///
/// ### Stream Consumption
/// - The [InputStream] should be consumed **once** per request
/// - Attempting to read the stream multiple times may result in errors
/// - Consider using stream transformers for complex processing pipelines
///
/// ### Error Handling
/// Implementations should handle stream errors appropriately and
/// provide meaningful error messages when the body cannot be accessed.
///
/// ### Related Classes
/// - [HttpMessage] - Base interface with header access
/// - [ServerHttpRequest] - Server-side request implementation
/// - [InputStream] - Raw byte stream access
/// - [HttpHeaders] - Header management and inspection
/// {@endtemplate}
abstract interface class HttpInputMessage extends HttpMessage {
  /// Represents the [HttpInputMessage] type for reflection purposes.
  ///
  /// This static [Class] instance is used to inspect and manipulate
  /// [HttpInputMessage] objects dynamically. It helps the framework
  /// identify input message parameters for handler methods and perform
  /// type-based operations, such as automatic deserialization of request bodies
  /// or headers handling.
  ///
  /// Example:
  /// ```dart
  /// final clazz = HttpInputMessage.CLASS;
  /// if (clazz.isAssignableFrom(someObject.getClass())) {
  ///   // Perform type-specific logic
  /// }
  /// ```
  static final CLASS = Class<HttpInputMessage>(null, PackageNames.WEB);

  /// Returns the message body as an [InputStream].
  ///
  /// This provides raw access to the request content, which can be
  /// decoded or parsed by higher-level HTTP converters. The stream
  /// contains the complete message body as raw bytes, allowing for
  /// flexible processing of various content types.
  ///
  /// ### Returns
  /// An [InputStream] providing access to the message body bytes
  ///
  /// ### Example
  /// ```dart
  /// // Reading as string
  /// final stream = message.getBody();
  /// final content = await stream.readAsString();
  ///
  /// // Processing as binary data
  /// final bytes = await stream.readAsBytes();
  /// final image = decodeImage(bytes);
  ///
  /// // Streaming processing for large files
  /// await stream.pipe(fileSink);
  /// ```
  ///
  /// ### Important Notes
  /// - The stream **must be consumed only once**
  /// - The stream may be empty for messages without a body (e.g., GET requests)
  /// - Always check [HttpHeaders.getContentLength()] for expected body size
  /// - Consider the encoding specified in `Content-Type` header when reading as text
  ///
  /// ### Performance Considerations
  /// For large messages, consider using stream processing rather than
  /// reading the entire content into memory at once.
  InputStream getBody();
}

/// {@template jetleaf_http_output_message}
/// Represents an HTTP **output message**, typically corresponding to
/// a server **response** or a serialized outgoing request body.
///
/// Extends [HttpMessage] by adding an output body stream, which allows
/// writing bytes directly to the underlying transport channel. This
/// interface is used when you need to send data in an HTTP message,
/// such as returning a response to a client or making an HTTP request.
///
/// ### Primary Use Cases
/// - **Server-side**: Sending HTTP responses in [ServerHttpResponse]
/// - **Client-side**: Making HTTP requests with request bodies
/// - **Message conversion**: Serializing response bodies in message converters
/// - **Stream writing**: Sending large payloads as streams
///
/// ### Example
/// ```dart
/// void writeJsonResponse(HttpOutputMessage message, Map<String, dynamic> data) {
///   final headers = message.getHeaders();
///   headers.setContentType(MediaType.APPLICATION_JSON);
///   
///   final body = message.getBody();
///   final jsonString = jsonEncode(data);
///   body.writeString(jsonString, Closeable.DEFAULT_ENCODING);
/// }
/// ```
///
/// ### Stream Writing
/// - The [OutputStream] should be written to **once** per response
/// - The stream should be properly closed after writing is complete
/// - Implementations may buffer writes for efficiency
///
/// ### Header Timing
/// Headers should typically be set **before** writing to the body stream,
/// as some transport implementations may send headers immediately upon
/// first body write.
///
/// ### Related Classes
/// - [HttpMessage] - Base interface with header access
/// - [ServerHttpResponse] - Server-side response implementation
/// - [OutputStream] - Raw byte stream writing
/// - [HttpHeaders] - Header management and configuration
/// - [ResponseBody] - High-level response representation
/// {@endtemplate}
abstract interface class HttpOutputMessage extends HttpMessage {
  /// Represents the [HttpOutputMessage] type for reflection purposes.
  ///
  /// This static [Class] instance is used to inspect and manipulate
  /// [HttpOutputMessage] objects dynamically. It helps the framework
  /// identify output message parameters for handler methods and perform
  /// type-based operations, such as automatic serialization of response bodies
  /// or headers handling.
  ///
  /// Example:
  /// ```dart
  /// final clazz = HttpOutputMessage.CLASS;
  /// if (clazz.isAssignableFrom(someObject.getClass())) {
  ///   // Perform type-specific logic
  /// }
  /// ```
  static final CLASS = Class<HttpOutputMessage>(null, PackageNames.WEB);

  /// Returns the message body as an [OutputStream].
  ///
  /// Allows writing directly to the HTTP response or outbound request stream.
  /// The output stream accepts raw bytes and handles the underlying transport
  /// details, including chunked encoding when appropriate.
  ///
  /// ### Returns
  /// An [OutputStream] for writing the message body content
  ///
  /// ### Example
  /// ```dart
  /// // Writing string content
  /// final body = message.getBody();
  /// body.writeString('Hello, World!');
  ///
  /// // Writing binary data
  /// final imageBytes = await readImageFile();
  /// body.writeBytes(imageBytes);
  ///
  /// // Streaming large content
  /// await fileStream.pipe(body);
  /// ```
  ///
  /// ### Important Notes
  /// - The stream should be written to **only once**
  /// - Always set appropriate headers (like `Content-Type` and `Content-Length`)
  ///   before writing to the body
  /// - The stream should be properly closed/flushed when writing is complete
  /// - Some implementations may auto-close the stream when the message is committed
  ///
  /// ### Performance Considerations
  /// For large responses, consider using streaming writes rather than
  /// buffering the entire content in memory before writing.
  OutputStream getBody();
}