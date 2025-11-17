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

part of 'path_pattern_parser.dart';

/// Default framework implementation of PathPatternParser.
class _FrameworkPathPatternParser implements PathPatternParser {
  PathPatternParserConfig _config;
  
  /// Cache for compiled patterns to improve performance.
  final Map<String, PathPattern> _patternCache = {};
  
  /// Cache for match results.
  final Map<String, PathMatch> _matchCache = {};

  _FrameworkPathPatternParser([PathPatternParserConfig? config]) : _config = config ?? const PathPatternParserConfig();

  @override
  PathPattern parsePattern(String pattern) {
    // Normalize pattern
    var normalized = pattern.trim();
    if (!normalized.startsWith(PathPatternParser.PATH_SEPARATOR)) {
      throw InvalidPathPatternException('Pattern must start with ${PathPatternParser.PATH_SEPARATOR}', pattern);
    }

    // Check cache
    if (_patternCache.containsKey(normalized)) {
      return _patternCache[normalized]!;
    }

    // Validate pattern
    _validatePattern(normalized);

    // Parse segments
    final segments = _parseSegments(normalized);
    
    // Determine pattern characteristics
    bool hasWildcard = false;
    bool hasVariables = false;
    
    for (final segment in segments) {
      if (segment is WildcardSegment) {
        hasWildcard = true;
      } else if (segment is VariableSegment) {
        hasVariables = true;
      }
    }

    final isStatic = !hasWildcard && !hasVariables;
    
    // Calculate matching rank (lower rank = higher priority)
    final matchingRank = _calculateMatchingRank(segments);

    final pathPattern = PathPattern(
      pattern: normalized,
      segments: segments,
      hasWildcard: hasWildcard,
      hasVariables: hasVariables,
      optionalTrailingSlash: _config.optionalTrailingSlash,
      caseInsensitive: _config.caseInsensitive,
      isStatic: isStatic,
      matchingRank: matchingRank,
    );

    // Cache the result
    if (_patternCache.length < _config.cacheSize) {
      _patternCache[normalized] = pathPattern;
    }

    return pathPattern;
  }

  @override
  PathMatch match(String path, PathPattern pattern) {
    // Normalize path
    var normalizedPath = path.trim();
    if (!normalizedPath.startsWith(PathPatternParser.PATH_SEPARATOR)) {
      return PathMatch.noMatch(path, pattern.pattern);
    }

    // Check cache
    final cacheKey = '$normalizedPath|${pattern.pattern}';
    if (_matchCache.containsKey(cacheKey)) {
      return _matchCache[cacheKey]!;
    }

    final result = _matchPath(normalizedPath, pattern);

    // Cache the result
    if (_matchCache.length < _config.cacheSize) {
      _matchCache[cacheKey] = result;
    }

    return result;
  }

  @override
  PathMatch matchBest(String path, List<PathPattern> patterns) {
    if (patterns.isEmpty) {
      return PathMatch.noMatch(path, '');
    }

    // Sort patterns by specificity (static first, then by matching rank)
    final sorted = List<PathPattern>.from(patterns)
      ..sort((a, b) {
        // Static patterns have highest priority
        if (a.isStatic && !b.isStatic) return -1;
        if (!a.isStatic && b.isStatic) return 1;
        
        // Patterns with fewer wildcards have higher priority
        final aWildcardCount = a.segments.whereType<WildcardSegment>().length;
        final bWildcardCount = b.segments.whereType<WildcardSegment>().length;
        if (aWildcardCount != bWildcardCount) {
          return aWildcardCount.compareTo(bWildcardCount);
        }
        
        // Compare by specificity score
        return b.getSpecificityScore().compareTo(a.getSpecificityScore());
      });

    // Try to match patterns in order
    for (final pattern in sorted) {
      final result = match(path, pattern);
      if (result.matches) {
        return result;
      }
    }

    return PathMatch.noMatch(path, '');
  }

  @override
  Set<String> extractVariables(String pattern) {
    try {
      final parsed = parsePattern(pattern);
      return parsed.getVariableNames();
    } catch (e) {
      return {};
    }
  }

  @override
  bool matches(String path, String pattern) {
    try {
      final parsedPattern = parsePattern(pattern);
      final result = match(path, parsedPattern);
      return result.matches;
    } catch (e) {
      return false;
    }
  }

  @override
  PathPatternParser caseInsensitive(bool value) {
    _config = _config.copyWith(caseInsensitive: value);
    _patternCache.clear();
    _matchCache.clear();
    return this;
  }

  @override
  PathPatternParser optionalTrailingSlash(bool value) {
    _config = _config.copyWith(optionalTrailingSlash: value);
    _patternCache.clear();
    _matchCache.clear();
    return this;
  }

  @override
  PathPatternParser strict(bool value) {
    _config = _config.copyWith(strict: value);
    _patternCache.clear();
    _matchCache.clear();
    return this;
  }

  @override
  PathPatternParserConfig getConfig() => _config;

  // ==================== Private Methods ====================

  void _validatePattern(String pattern) {
    // Check for invalid characters/sequences
    if (pattern.contains('//')) {
      throw InvalidPathPatternException('Double slashes not allowed', pattern);
    }

    // Check for unmatched braces
    int braceCount = 0;
    for (int i = 0; i < pattern.length; i++) {
      if (pattern[i] == '{') {
        braceCount++;
        if (braceCount > 1) {
          throw InvalidPathPatternException('Nested variable patterns not allowed', pattern, i);
        }
      } else if (pattern[i] == '}') {
        braceCount--;
        if (braceCount < 0) {
          throw InvalidPathPatternException('Unmatched closing brace', pattern, i);
        }
      }
    }

    if (braceCount != 0) {
      throw InvalidPathPatternException('Unmatched opening brace', pattern);
    }

    // Check segment count
    final segmentCount = pattern.split(PathPatternParser.PATH_SEPARATOR).length - 1;
    if (segmentCount > _config.maxSegments) {
      throw InvalidPathPatternException('Pattern exceeds maximum segment count (${_config.maxSegments})', pattern);
    }
  }

  List<PathSegment> _parseSegments(String pattern) {
    final segments = <PathSegment>[];
    
    // Remove leading slash and split
    final parts = pattern.substring(1).split(PathPatternParser.PATH_SEPARATOR).where((p) => p.isNotEmpty).toList();

    for (final part in parts) {
      segments.add(_parseSegment(part));
    }

    return segments;
  }

  PathSegment _parseSegment(String segment) {
    // Handle wildcards
    if (segment == '**') {
      return WildcardSegment(true);
    }
    if (segment == '*') {
      return WildcardSegment(false);
    }

    // Handle variables with optional regex patterns {varName:pattern}
    if (segment.startsWith('{') && segment.endsWith('}')) {
      final content = segment.substring(1, segment.length - 1);
      
      // Check for regex pattern
      if (content.contains(':')) {
        final parts = content.split(':');
        final varName = parts[0].trim();
        final pattern = parts.sublist(1).join(':').trim();
        
        _validateVariableName(varName);
        
        try {
          final regex = RegExp('^$pattern\$');
          return VariableSegment(varName, regex: regex, pattern: pattern);
        } catch (e) {
          throw InvalidPathPatternException('Invalid regex pattern: $pattern', segment);
        }
      } else {
        _validateVariableName(content);
        return VariableSegment(content);
      }
    }

    // Handle literal segments
    return LiteralSegment(segment);
  }

  void _validateVariableName(String name) {
    if (name.isEmpty) {
      throw InvalidPathPatternException('Variable name cannot be empty', '{}');
    }
    
    // Variable names should be alphanumeric with underscores
    if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(name)) {
      throw InvalidPathPatternException('Invalid variable name: $name. Must start with letter or underscore.', '{$name}');
    }
  }

  PathMatch _matchPath(String path, PathPattern pattern) {
    var normalizedPath = path;
    var normalizedPattern = pattern.pattern;
    
    if (_config.optionalTrailingSlash) {
      if (normalizedPath.endsWith(PathPatternParser.PATH_SEPARATOR) && normalizedPath.length > 1) {
        normalizedPath = normalizedPath.substring(0, normalizedPath.length - 1);
      }
      if (normalizedPattern.endsWith(PathPatternParser.PATH_SEPARATOR) && normalizedPattern.length > 1) {
        normalizedPattern = normalizedPattern.substring(0, normalizedPattern.length - 1);
      }
    } else {
      final pathEndsWithSlash = normalizedPath.endsWith(PathPatternParser.PATH_SEPARATOR) && normalizedPath.length > 1;
      final patternEndsWithSlash = normalizedPattern.endsWith(PathPatternParser.PATH_SEPARATOR) && normalizedPattern.length > 1;
      if (pathEndsWithSlash != patternEndsWithSlash) {
        return PathMatch.noMatch(normalizedPath, normalizedPattern);
      }
    }

    // Split path into segments
    final pathSegments = normalizedPath
        .substring(1)
        .split(PathPatternParser.PATH_SEPARATOR)
        .where((s) => s.isNotEmpty)
        .toList();

    // Try to match segments
    return _matchSegments(pathSegments, pattern.segments, pattern);
  }

  PathMatch _matchSegments(List<String> pathSegments, List<PathSegment> patternSegments, PathPattern pattern) {
    final variables = <String, String>{};
    int pathIndex = 0;
    int patternIndex = 0;

    while (patternIndex < patternSegments.length) {
      final patternSeg = patternSegments[patternIndex];

      // Handle multi-segment wildcard
      if (patternSeg is WildcardSegment && patternSeg.multiSegment) {
        // If this is the last segment, match remaining path (at least 1 segment required)
        if (patternIndex == patternSegments.length - 1) {
          // ** at the end requires at least 1 segment left
          if (pathIndex >= pathSegments.length) {
            return PathMatch.noMatch(pathSegments.join(PathPatternParser.PATH_SEPARATOR), pattern.pattern);
          }
          pathIndex = pathSegments.length;
        } else {
          // Try to match the rest of the pattern after the wildcard
          final remaining = patternSegments.sublist(patternIndex + 1);
          // Start matching from pathIndex + 1 (at least 1 segment for wildcard)
          final matchResult = _findMatchPosition(pathSegments, pathIndex + 1, remaining);
          if (matchResult == null) {
            return PathMatch.noMatch(pathSegments.join(PathPatternParser.PATH_SEPARATOR), pattern.pattern);
          }
          pathIndex = matchResult['index'] as int;
          variables.addAll(matchResult['variables'] as Map<String, String>);
          // Skip all remaining pattern segments since they were already matched
          patternIndex = patternSegments.length;
          continue;
        }
        patternIndex++;
        continue;
      }

      // Handle single-segment wildcard
      if (patternSeg is WildcardSegment && !patternSeg.multiSegment) {
        if (pathIndex >= pathSegments.length) {
          return PathMatch.noMatch(pathSegments.join(PathPatternParser.PATH_SEPARATOR), pattern.pattern);
        }
        pathIndex++;
        patternIndex++;
        continue;
      }

      // Handle regular segments
      if (pathIndex >= pathSegments.length) {
        return PathMatch.noMatch(pathSegments.join(PathPatternParser.PATH_SEPARATOR), pattern.pattern);
      }

      final pathSeg = pathSegments[pathIndex];

      if (!patternSeg.matches(pathSeg, _config.caseInsensitive)) {
        return PathMatch.noMatch(pathSegments.join(PathPatternParser.PATH_SEPARATOR), pattern.pattern);
      }

      // Extract variables
      variables.addAll(patternSeg.extractVariables(pathSeg));

      pathIndex++;
      patternIndex++;
    }

    // All pattern segments matched, check if all path segments consumed
    if (pathIndex != pathSegments.length) {
      return PathMatch.noMatch(pathSegments.join(PathPatternParser.PATH_SEPARATOR), pattern.pattern);
    }

    return PathMatch(
      matches: true,
      variables: variables,
      segments: pathSegments,
      path: '/${pathSegments.join(PathPatternParser.PATH_SEPARATOR)}',
      pattern: pattern.pattern,
    );
  }

  /// Find where the remaining pattern can be matched after a wildcard.
  /// Returns a map with 'index' (next path index) and 'variables' (extracted vars), or null if no match.
  Map<String, dynamic>? _findMatchPosition(List<String> pathSegments, int startIndex, List<PathSegment> remaining) {
    if (remaining.isEmpty) {
      // If no remaining pattern, wildcard matches everything after startIndex
      return {
        'index': pathSegments.length,
        'variables': <String, String>{},
      };
    }

    // Try each possible starting position for the remaining pattern
    // We need at least the segments required by the remaining pattern
    final minSegmentsNeeded = _countMinimumSegmentsNeeded(remaining);
    
    // startIndex is already after the ** wildcard, so we try to find where
    // the remaining pattern can be matched
    for (int i = startIndex; i <= pathSegments.length - minSegmentsNeeded; i++) {
      // Try to match the remaining segments starting at position i
      final matchResult = _tryMatchSegmentsAt(pathSegments, i, remaining);
      if (matchResult != null) {
        return matchResult;
      }
    }

    return null;
  }

  /// Count the minimum number of segments needed to match the pattern segments
  int _countMinimumSegmentsNeeded(List<PathSegment> segments) {
    int count = 0;
    for (final seg in segments) {
      if (seg is WildcardSegment && seg.multiSegment) {
        // ** needs at least 1 segment, but might match more
        count += 1;
      } else {
        // Literal and single-segment wildcards need exactly 1
        count += 1;
      }
    }
    return count;
  }

  /// Try to match segments starting at a specific path index
  Map<String, dynamic>? _tryMatchSegmentsAt(List<String> pathSegments, int startPathIndex, List<PathSegment> patternSegments) {
    final variables = <String, String>{};
    int pathIndex = startPathIndex;
    int patternIndex = 0;

    while (patternIndex < patternSegments.length) {
      final patternSeg = patternSegments[patternIndex];

      // Handle multi-segment wildcard
      if (patternSeg is WildcardSegment && patternSeg.multiSegment) {
        if (patternIndex == patternSegments.length - 1) {
          // Last segment is **, match all remaining (at least 1 segment required)
          if (pathIndex >= pathSegments.length) {
            return null;
          }
          pathIndex = pathSegments.length;
        } else {
          // Find where remaining segments start
          final remaining = patternSegments.sublist(patternIndex + 1);
          final subResult = _findMatchPosition(pathSegments, pathIndex + 1, remaining);
          if (subResult == null) {
            return null;
          }
          pathIndex = subResult['index'] as int;
          variables.addAll(subResult['variables'] as Map<String, String>);
          // Skip all remaining pattern segments since they were already matched
          patternIndex = patternSegments.length;
          continue;
        }
        patternIndex++;
        continue;
      }

      // Handle single-segment wildcard
      if (patternSeg is WildcardSegment && !patternSeg.multiSegment) {
        if (pathIndex >= pathSegments.length) {
          return null;
        }
        pathIndex++;
        patternIndex++;
        continue;
      }

      // Handle literal and variable segments
      if (pathIndex >= pathSegments.length) {
        return null;
      }

      final pathSeg = pathSegments[pathIndex];
      if (!patternSeg.matches(pathSeg, _config.caseInsensitive)) {
        return null;
      }

      variables.addAll(patternSeg.extractVariables(pathSeg));
      pathIndex++;
      patternIndex++;
    }

    // Check if we consumed exactly the right number of segments
    if (pathIndex == pathSegments.length) {
      return {
        'index': pathIndex,
        'variables': variables,
      };
    }

    return null;
  }

  int _calculateMatchingRank(List<PathSegment> segments) {
    int rank = 0;
    
    for (final segment in segments) {
      if (segment is LiteralSegment) {
        rank += 1000;
      } else if (segment is VariableSegment) {
        rank += 100;
      } else if (segment is WildcardSegment) {
        if (segment.multiSegment) {
          rank += 1;
        } else {
          rank += 10;
        }
      }
    }
    
    return rank;
  }
}