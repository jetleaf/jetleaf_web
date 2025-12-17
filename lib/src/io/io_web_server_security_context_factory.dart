import 'dart:io';

/// {@template io_web_server_security_context_factory}
/// A factory interface responsible for creating and configuring a
/// [SecurityContext] for an HTTPS-enabled JetLeaf IO web server.
///
/// Implementations provide all certificate, key, trust store, and TLS-related
/// configuration needed to bootstrap a secure server socket.  
/// This abstraction allows the framework to remain independent of how TLS
/// assets are loaded—whether from files, memory, environment variables,
/// secret managers, or dynamically generated at runtime.
///
/// ---
/// ## 🔐 Responsibilities
///
/// - Create and return a fully configured instances of [`SecurityContext`]  
/// - Optionally declare whether the server should request (or require)
///   client certificates for mutual TLS (mTLS)
///
/// This interface is intentionally minimal so that applications may define
/// custom security models without coupling them to JetLeaf internals.
///
/// ---
/// ## 🧩 Example
/// ```dart
/// class FileBasedSecurityContextFactory
///     implements IoWebServerSecurityContextFactory {
///
///   @override
///   SecurityContext createContext() {
///     final context = SecurityContext();
///     context.useCertificateChain('cert.pem');
///     context.usePrivateKey('key.pem');
///     return context;
///   }
///
///   @override
///   bool shouldRequestClientCertificate() => false;
/// }
/// ```
///
/// ---
/// ## 🔎 Related
/// - [SecurityContext](https://api.dart.dev/stable/dart-io/SecurityContext-class.html)  
/// - JetLeaf IO Web Server configuration and bootstrapping  
///
/// {@endtemplate}
abstract interface class IoWebServerSecurityContextFactory {
  /// Creates and returns a configured HTTPS [`SecurityContext`] instance.
  ///
  /// Implementations may:
  /// - Load certificates and keys from disk
  /// - Load certificates from memory or environment variables
  /// - Configure trusted root CAs
  /// - Add ALPN protocols
  ///
  /// This method **must** return a valid context suitable for binding a secure
  /// server socket. If configuration fails, implementations should throw an
  /// informative exception.
  SecurityContext createContext();

  /// Indicates whether the web server should request or require a
  /// client-side certificate.
  ///
  /// Returning:
  /// - `true` → The server will request a certificate from the client during
  ///   the TLS handshake (used in mutual TLS / mTLS configurations).
  /// - `false` → Standard TLS behavior; the client is *not* expected to present
  ///   a certificate.
  ///
  /// Implementations may derive this from configuration, environment variables,
  /// or static policy.
  bool shouldRequestClientCertificate();
}