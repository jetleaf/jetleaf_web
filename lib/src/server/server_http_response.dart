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

/// {@template jetleaf_http_response_provider}
/// A generic abstraction representing an **HTTP response** within the JetLeaf framework.
///
/// The [ServerHttpResponse] interface defines a unified contract for sending
/// response data in a framework-agnostic way. It decouples response handling
/// logic from any specific server or client implementation (e.g., `dart:io`,
/// `shelf`, or custom adapters).
///
/// ### Key Responsibilities
/// - Provide access to the underlying native HTTP response object.
/// - Provide an [OutputStream] for writing response content (bytes, strings, etc.).
///
/// ### Example: Writing a HttpResponse
/// ```dart
/// void handleResponse(ServerHttpResponse response) async {
///   final output = response.getBody();
///   await output.writeString('Hello, JetLeaf!');
///   await output.flush();
///   await output.close();
/// }
/// ```
///
/// ### Notes
/// - The generic type `<HttpResponse>` allows exposing the native response
///   object safely while maintaining type safety.
/// - Implementations should ensure proper flushing and closure of the output
///   stream to avoid incomplete responses.
///
/// {@endtemplate}
abstract interface class ServerHttpResponse implements HttpOutputMessage {
  /// Represents the [ServerHttpResponse] type for reflection purposes.
  /// 
  /// This static [Class] instance is used to inspect and manipulate
  /// [ServerHttpResponse] objects dynamically. It helps the framework
  /// to identify response parameters for handler methods.
  static final Class CLASS = Class<ServerHttpResponse>(null, PackageNames.WEB);

  /// Sets the HTTP status code for this response.
  ///
  /// This method updates the response's status to the specified [httpStatus],
  /// allowing the server to indicate success, client errors, server errors,
  /// or any other relevant HTTP status to the client.
  ///
  /// Example:
  /// ```dart
  /// // Respond with a success status
  /// responseProvider.setStatus(HttpStatus.OK);
  ///
  /// // Respond with a client error
  /// responseProvider.setStatus(HttpStatus.BAD_REQUEST);
  ///
  /// // Respond with a custom or unknown status code
  /// responseProvider.setStatus(HttpStatus.fromCode(499));
  /// ```
  ///
  /// [httpStatus] – An instance of [HttpStatus] representing the desired
  /// response status. This ensures type safety and readability instead of
  /// using raw integers.
  void setStatus(HttpStatus httpStatus);

    /// Encodes the given redirect URL for use in HTTP redirection.
  ///
  /// This method converts a plain URL [location] into a format suitable
  /// for HTTP redirection, ensuring that any special characters are properly
  /// encoded according to URL standards. This is necessary to prevent
  /// invalid URLs or injection issues when sending redirects.
  ///
  /// The returned string should be safe to pass to [sendRedirect].
  ///
  /// ### Parameters
  /// - [location]: The target URL to which the client should be redirected.
  ///
  /// ### Returns
  /// A [Future] that completes with the URL string properly encoded for redirection.
  ///
  /// ### Example
  /// ```dart
  /// final encoded = await response.encodeRedirectUrl('/login?next=/dashboard');
  /// await response.sendRedirect(encoded);
  /// ```
  Future<String> encodeRedirectUrl(String location);

  /// Sends an HTTP redirect to the client using the specified encoded URL.
  ///
  /// This method instructs the client to perform a redirection to the
  /// given [encodedLocation]. The URL must be properly encoded; use
  /// [encodeRedirectUrl] before calling this method.
  ///
  /// The redirect is typically performed with an HTTP status code 302 (Found),
  /// but implementations may allow overriding the status code if needed.
  ///
  /// ### Parameters
  /// - [encodedLocation]: The URL to redirect the client to, properly encoded.
  ///
  /// ### Returns
  /// A [Future] that completes when the redirect has been sent.
  ///
  /// ### Example
  /// ```dart
  /// final target = await response.encodeRedirectUrl('/home');
  /// await response.sendRedirect(target);
  /// ```
  Future<void> sendRedirect(String encodedLocation);

  /// Returns the current HTTP status code of this response.
  ///
  /// This method retrieves the [HttpStatus] that has been set on the response.
  /// It can be used to inspect the status before sending the response, for logging,
  /// conditional handling, or testing purposes.
  ///
  /// ### Returns
  /// - An instance of [HttpStatus] representing the currently set HTTP status.
  /// - Returns `null` if no status has been explicitly set.
  ///
  /// ### Example
  /// ```dart
  /// final status = response.getStatus();
  /// if (status == HttpStatus.OK) {
  ///   print('Response is successful.');
  /// }
  /// ```
  HttpStatus? getStatus();

  /// Indicates whether the response has already been committed to the client.
  ///
  /// Once a response is committed, its status, headers, and body cannot be
  /// modified. This method is useful for filters, interceptors, or handlers
  /// that need to check if the response is still mutable before making changes.
  ///
  /// ### Returns
  /// - `true` if the response has been committed and cannot be modified further.
  /// - `false` if the response is still mutable and can be updated.
  ///
  /// ### Example
  /// ```dart
  /// if (!response.isCommitted()) {
  ///   response.setStatus(HttpStatus.OK);
  ///   await response.getBody().writeString('Hello World');
  /// }
  /// ```
  bool isCommitted();

  /// Sets the HTTP detailed reason for this response.
  ///
  /// This method updates the response's message,
  /// allowing the server to indicate success, client errors, server errors,
  /// or any other relevant reason why the response is what it is, to the client.
  ///
  /// Example:
  /// ```dart
  /// // Respond with a success message
  /// responseProvider.setReason("Request is success");
  ///
  /// // Respond with a client error
  /// responseProvider.setReason("Something happened");
  /// ```
  ///
  /// [message] – A string representing the desired message to be sent.
  void setReason(String message);
}