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

import 'dart:collection';

import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_logging/logging.dart';

import 'server_context.dart';

/// {@template io_server_context}
/// ## IoServerContext
///
/// Implementation of [ServerContext] for JetLeaf servers, providing:
/// - Thread-safe storage for runtime attributes.
/// - Configurable context path via environment properties.
/// - Logging support specific to the server context.
///
/// This class acts as the central context for a running JetLeaf server,
/// allowing server components to store and retrieve data, access logging.
///
/// Example usage:
/// ```dart
/// final context = IoServerContext();
/// context.setAttribute("appName", "MyServer");
/// print(context.getAttribute("appName")); // "MyServer"
/// ```
/// {@endtemplate}
final class IoServerContext implements ServerContext, EnvironmentAware {
  /// The context path under which the server operates.
  ///
  /// Defaults to [ServerContext.SERVER_CONTEXT_PATH]. Can be overridden
  /// via environment property [ServerContext.SERVER_CONTEXT_PATH_PROPERTY_NAME].
  String _contextPath = ServerContext.SERVER_CONTEXT_PATH;

  /// Internal thread-safe storage for runtime attributes.
  ///
  /// Use [setAttribute], [getAttribute], and [removeAttribute] to interact
  /// with this map in a synchronized manner.
  final Map<String, Object> _attributes = {};

  /// Creates a new [IoServerContext] instance.
  ///
  /// {@macro io_server_context}
  IoServerContext();

  @override
  void setEnvironment(Environment environment) {
    final contextPath = environment.getProperty(ServerContext.SERVER_CONTEXT_PATH_PROPERTY_NAME);
    if (contextPath != null) {
      _contextPath = contextPath;
    }
  }

  @override
  Object? getAttribute(String name) => synchronized(_attributes, () => _attributes.get(name));

  @override
  Iterable<String> getAttributeNames() => UnmodifiableListView(_attributes.keys);

  @override
  String getContextPath() => _contextPath;

  @override
  Log get log => LogFactory.getLog("server");

  @override
  void removeAttribute(String name) => synchronized(_attributes, () => _attributes.remove(name));

  @override
  void setAttribute(String name, Object value) => synchronized(_attributes, () => _attributes.put(name, value));
}