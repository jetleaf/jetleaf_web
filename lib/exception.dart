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

/// Jetleaf Exception sub-library
///
/// This sub-library provides the **core exception types** used in the
/// `jetleaf_web` package.
///
/// Importing `package:jetleaf_web/exception.dart` gives access to
/// general exceptions, server-specific exceptions, and path-related
/// exceptions used across the web, server, and routing modules.
///
/// This library centralizes the exception hierarchy for consistent
/// error handling throughout the framework.
library;

export 'src/exception/exceptions.dart';
export 'src/exception/server_exceptions.dart';
export 'src/exception/path_exception.dart';