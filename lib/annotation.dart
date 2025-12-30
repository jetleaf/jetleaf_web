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

/// Jetleaf Annotation sub-library
///
/// This sub-library provides **core annotations and resolver helpers**
/// for the `jetleaf_web` package.
///
/// Importing `package:jetleaf_web/annotation.dart` exposes annotations
/// for request mapping, request parameters, and resolver contexts,
/// along with default resolver support.
///
/// These annotations enable declarative configuration of request
/// handling, parameter binding, and component resolution.
library;

export 'src/annotation/core.dart';
export 'src/annotation/default_resolver_context.dart';
export 'src/annotation/request_mapping.dart';
export 'src/annotation/request_parameter.dart';
export 'src/annotation/resolvers.dart';