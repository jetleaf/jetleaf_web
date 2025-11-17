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
import '../http/http_status.dart';
import 'request_spec.dart';

/// {@template response_extractor}
/// A functional interface for **asynchronously extracting and transforming**
/// data from a [RestHttpResponse].
///
/// Implementations of this callback are used to decode, deserialize,
/// or map the raw HTTP response into a desired Dart type.
///
/// ### Typical Use Cases
/// - Decoding JSON bodies into typed objects
/// - Transforming binary data into domain entities
/// - Handling response status codes or headers
///
/// ### Example
/// ```dart
/// final extractor = (RestHttpResponse response) async {
///   final json = jsonDecode(await response.bodyAsString());
///   return User.fromJson(json);
/// };
/// ```
///
/// ### Lifecycle
/// The extractor is typically passed to methods like:
/// - `execute<T>(T type, [ResponseExtractor<T>? extractor])`
/// - `retrieve<T>(Class<T> type, [ResponseExtractor<T>? extractor])`
///
/// allowing custom transformation logic for specific request executions.
///
/// {@endtemplate}
typedef ResponseExtractor<T> = Future<T> Function(RestHttpResponse response);

/// {@template rest_client_response}
/// Represents the **HTTP response** returned from executing a [RestHttpRequest].
///
/// A [RestHttpResponse] provides access to the HTTP status, response headers,
/// and body content, and implements [InputStreamSource] for low-level stream
/// access to the response payload.
///
/// ### Core Responsibilities
/// - Expose response **status**, **headers**, and **body stream**.
/// - Allow consumers to read or decode the response data.
/// - Support both **binary** and **textual** processing via [InputStreamSource].
///
/// ### Example
/// ```dart
/// final response = await request.execute();
/// print('Status: ${response.getStatus().code}');
///
/// final inputStream = response.getInputStream();
/// final body = await inputStream.readAsString();
/// print('Response Body: $body');
/// ```
///
/// ### Integration
/// Used throughout JetLeaf’s HTTP client system, particularly with:
/// - [RequestSpec.retrieve]
/// - [ResponseExtractor]
/// - [RestHttpRequest.execute]
///
/// {@endtemplate}
abstract interface class RestHttpResponse implements HttpInputMessage {
  /// {@macro rest_client_response}
  ///
  /// Returns the **HTTP status** of the response as a [HttpStatus] object.
  ///
  /// This allows detailed inspection of status codes (e.g., `200 OK`, `404 Not Found`),
  /// which can be used for custom error handling, retries, or response classification.
  ///
  /// ### Example
  /// ```dart
  /// if (response.getStatus() == HttpStatus.OK) {
  ///   print('Request succeeded.');
  /// } else {
  ///   print('Request failed with: ${response.getStatus()}');
  /// }
  /// ```
  HttpStatus getStatus();
}
