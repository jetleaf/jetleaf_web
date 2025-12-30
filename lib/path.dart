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

/// Jetleaf Path sub-library
///
/// This sub-library defines the **path matching and pattern parsing**
/// facilities of the `jetleaf_web` package.
///
/// Importing `package:jetleaf_web/path.dart` provides APIs for
/// representing, parsing, and matching URI path patterns, including
/// path segments, parsed patterns, and match results.
///
/// These utilities are primarily used by the routing and handler
/// mapping infrastructure but may also be used directly by framework
/// extensions and advanced applications.
library;

export 'src/path/path_match.dart';
export 'src/path/path_pattern.dart';
export 'src/path/path_pattern_parser.dart';
export 'src/path/path_pattern_parser_registry.dart';
export 'src/path/path_segment.dart';