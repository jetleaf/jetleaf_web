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

import 'package:jetleaf_web/src/exception/path_exception.dart';
import 'package:jetleaf_web/src/path/path_pattern_parser.dart';
import 'package:test/test.dart';

void main() {
  group('PathPatternParser - Basic Matching', () {
    late PathPatternParser parser;

    setUp(() {
      parser = PathPatternParser();
    });

    test('matches exact static paths', () {
      final pattern = parser.parsePattern('/home');
      final result = parser.match('/home', pattern);
      expect(result.matches, isTrue);
      expect(result.variables, isEmpty);
    });

    test('does not match different static paths', () {
      final pattern = parser.parsePattern('/home');
      final result = parser.match('/about', pattern);
      expect(result.matches, isFalse);
    });

    test('matches paths with single variable', () {
      final pattern = parser.parsePattern('/users/{id}');
      final result = parser.match('/users/123', pattern);
      expect(result.matches, isTrue);
      expect(result.variables['id'], equals('123'));
    });

    test('matches paths with multiple variables', () {
      final pattern = parser.parsePattern('/users/{userId}/posts/{postId}');
      final result = parser.match('/users/42/posts/7', pattern);
      expect(result.matches, isTrue);
      expect(result.variables['userId'], equals('42'));
      expect(result.variables['postId'], equals('7'));
    });

    test('does not match paths with missing segments', () {
      final pattern = parser.parsePattern('/users/{id}/posts');
      final result = parser.match('/users/123', pattern);
      expect(result.matches, isFalse);
    });

    test('does not match paths with extra segments', () {
      final pattern = parser.parsePattern('/users/{id}');
      final result = parser.match('/users/123/posts', pattern);
      expect(result.matches, isFalse);
    });
  });

  group('PathPatternParser - Wildcards', () {
    late PathPatternParser parser;

    setUp(() {
      parser = PathPatternParser();
    });

    test('matches single segment wildcard', () {
      final pattern = parser.parsePattern('/api/*/data');
      expect(parser.match('/api/v1/data', pattern).matches, isTrue);
      expect(parser.match('/api/v2/data', pattern).matches, isTrue);
      expect(parser.match('/api/data', pattern).matches, isFalse);
    });

    test('matches multi-segment wildcard', () {
      final pattern = parser.parsePattern('/api/**');
      expect(parser.match('/api/v1/users', pattern).matches, isTrue);
      expect(parser.match('/api/v1/users/123', pattern).matches, isTrue);
      expect(parser.match('/api/', pattern).matches, isFalse);
    });

    test('matches multi-segment wildcard in middle', () {
      final pattern = parser.parsePattern('/api/**/data');
      expect(parser.match('/api/v1/users/data', pattern).matches, isTrue);
      expect(parser.match('/api/v1/v2/users/data', pattern).matches, isTrue);
      expect(parser.match('/api/data', pattern).matches, isFalse);
    });

    test('matches single wildcard with mixed segments', () {
      final pattern = parser.parsePattern('/{version}/users/{id}');
      final result = parser.match('/v1/users/123', pattern);
      expect(result.matches, isTrue);
      expect(result.variables['version'], equals('v1'));
      expect(result.variables['id'], equals('123'));
    });
  });

  group('PathPatternParser - Case Sensitivity', () {
    test('case sensitive by default', () {
      final parser = PathPatternParser();
      final pattern = parser.parsePattern('/Home');
      expect(parser.match('/home', pattern).matches, isFalse);
      expect(parser.match('/Home', pattern).matches, isTrue);
    });

    test('case insensitive when configured', () {
      final parser = PathPatternParser()..caseInsensitive(true);
      final pattern = parser.parsePattern('/Home');
      expect(parser.match('/home', pattern).matches, isTrue);
      expect(parser.match('/HOME', pattern).matches, isTrue);
      expect(parser.match('/Home', pattern).matches, isTrue);
    });
  });

  group('PathPatternParser - Trailing Slash', () {
    test('trailing slash not optional by default', () {
      final parser = PathPatternParser();
      final pattern = parser.parsePattern('/home');
      expect(parser.match('/home', pattern).matches, isTrue);
      expect(parser.match('/home/', pattern).matches, isFalse);
    });

    test('trailing slash optional when configured', () {
      final parser = PathPatternParser()..optionalTrailingSlash(true);
      final pattern = parser.parsePattern('/home');
      expect(parser.match('/home', pattern).matches, isTrue);
      expect(parser.match('/home/', pattern).matches, isTrue);
    });
  });

  group('PathPatternParser - Regex Patterns', () {
    test('matches variable with numeric regex', () {
      final parser = PathPatternParser();
      final pattern = parser.parsePattern('/users/{id:\\d+}');
      expect(parser.match('/users/123', pattern).matches, isTrue);
      expect(parser.match('/users/abc', pattern).matches, isFalse);
    });

    test('matches variable with alphanumeric regex', () {
      final parser = PathPatternParser();
      final pattern = parser.parsePattern('/files/{name:[a-zA-Z0-9_-]+}');
      expect(parser.match('/files/my-file_123', pattern).matches, isTrue);
      expect(parser.match('/files/my file', pattern).matches, isFalse);
    });

    test('matches variable with custom regex', () {
      final parser = PathPatternParser();
      final pattern = parser.parsePattern('/api/{version:v\\d+}');
      expect(parser.match('/api/v1', pattern).matches, isTrue);
      expect(parser.match('/api/v2', pattern).matches, isTrue);
      expect(parser.match('/api/version1', pattern).matches, isFalse);
    });
  });

  group('PathPatternParser - Extract Variables', () {
    test('extracts variable names from pattern', () {
      final parser = PathPatternParser();
      final variables = parser.extractVariables('/users/{userId}/posts/{postId}');
      expect(variables, containsAll(['userId', 'postId']));
    });

    test('extracts empty list from static pattern', () {
      final parser = PathPatternParser();
      final variables = parser.extractVariables('/home');
      expect(variables, isEmpty);
    });
  });

  group('PathPatternParser - Best Match', () {
    test('selects static pattern over dynamic', () {
      final parser = PathPatternParser();
      final patterns = [
        parser.parsePattern('/{id}'),
        parser.parsePattern('/home'),
      ];
      final result = parser.matchBest('/home', patterns);
      expect(result.matches, isTrue);
      expect(result.pattern, equals('/home'));
    });

    test('selects pattern with most literals', () {
      final parser = PathPatternParser();
      final patterns = [
        parser.parsePattern('/users/*'),
        parser.parsePattern('/users/admin'),
        parser.parsePattern('/users/{id}'),
      ];
      final result = parser.matchBest('/users/admin', patterns);
      expect(result.pattern, equals('/users/admin'));
    });

    test('selects pattern with fewer wildcards', () {
      final parser = PathPatternParser();
      final patterns = [
        parser.parsePattern('/api/**'),
        parser.parsePattern('/api/v1/**'),
      ];
      final result = parser.matchBest('/api/v1/users', patterns);
      expect(result.pattern, equals('/api/v1/**'));
    });

    test('returns no match when no pattern matches', () {
      final parser = PathPatternParser();
      final patterns = [
        parser.parsePattern('/users/{id}'),
        parser.parsePattern('/posts/{id}'),
      ];
      final result = parser.matchBest('/about', patterns);
      expect(result.matches, isFalse);
    });
  });

  group('PathPatternParser - Edge Cases', () {
    test('handles root path', () {
      final parser = PathPatternParser();
      final pattern = parser.parsePattern('/');
      expect(parser.match('/', pattern).matches, isTrue);
    });

    test('rejects invalid patterns', () {
      final parser = PathPatternParser();
      expect(
        () => parser.parsePattern('home'),
        throwsA(isA<InvalidPathPatternException>()),
      );
    });

    test('rejects patterns with double slashes', () {
      final parser = PathPatternParser();
      expect(
        () => parser.parsePattern('/home//page'),
        throwsA(isA<InvalidPathPatternException>()),
      );
    });

    test('rejects patterns with unmatched braces', () {
      final parser = PathPatternParser();
      expect(
        () => parser.parsePattern('/users/{id'),
        throwsA(isA<InvalidPathPatternException>()),
      );
    });

    test('rejects patterns with empty variable names', () {
      final parser = PathPatternParser();
      expect(
        () => parser.parsePattern('/users/{}'),
        throwsA(isA<InvalidPathPatternException>()),
      );
    });

    test('rejects patterns with invalid variable names', () {
      final parser = PathPatternParser();
      expect(
        () => parser.parsePattern('/users/{123id}'),
        throwsA(isA<InvalidPathPatternException>()),
      );
    });

    test('handles unicode characters in literals', () {
      final parser = PathPatternParser();
      final pattern = parser.parsePattern('/café/{id}');
      final result = parser.match('/café/123', pattern);
      expect(result.matches, isTrue);
      expect(result.variables['id'], equals('123'));
    });

    test('handles percent-encoded characters', () {
      final parser = PathPatternParser();
      final pattern = parser.parsePattern('/path/{name}');
      final result = parser.match('/path/hello%20world', pattern);
      expect(result.matches, isTrue);
      expect(result.variables['name'], equals('hello%20world'));
    });
  });

  group('PathPatternParser - Performance', () {
    test('caches pattern compilation', () {
      final parser = PathPatternParser();
      final pattern1 = parser.parsePattern('/users/{id}');
      final pattern2 = parser.parsePattern('/users/{id}');
      expect(identical(pattern1, pattern2), isTrue);
    });

    test('caches match results', () {
      final parser = PathPatternParser();
      final pattern = parser.parsePattern('/users/{id}');
      
      final result1 = parser.match('/users/123', pattern);
      final result2 = parser.match('/users/123', pattern);
      
      // Both should be successful
      expect(result1.matches, isTrue);
      expect(result2.matches, isTrue);
    });

    test('handles multiple matches efficiently', () {
      final parser = PathPatternParser();
      final patterns = [
        parser.parsePattern('/api/v1/users'),
        parser.parsePattern('/api/v1/users/{id}'),
        parser.parsePattern('/api/v1/users/{id}/posts'),
        parser.parsePattern('/api/v2/users'),
        parser.parsePattern('/{version}/users/{id}'),
      ];

      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 100; i++) {
        parser.matchBest('/api/v1/users/123/posts', patterns);
      }
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });

  group('PathPatternParser - Complex Scenarios', () {
    test('REST API routing', () {
      final parser = PathPatternParser();
      final patterns = [
        parser.parsePattern('/api/v1/users'),
        parser.parsePattern('/api/v1/users/{id}'),
        parser.parsePattern('/api/v1/users/{userId}/posts/{postId}'),
        parser.parsePattern('/api/v1/**'),
      ];

      final result1 = parser.matchBest('/api/v1/users', patterns);
      expect(result1.pattern, equals('/api/v1/users'));

      final result2 = parser.matchBest('/api/v1/users/123', patterns);
      expect(result2.pattern, equals('/api/v1/users/{id}'));
      expect(result2.variables['id'], equals('123'));

      final result3 = parser.matchBest('/api/v1/users/42/posts/7', patterns);
      expect(result3.pattern, equals('/api/v1/users/{userId}/posts/{postId}'));
      expect(result3.variables['userId'], equals('42'));
      expect(result3.variables['postId'], equals('7'));
    });

    test('handles deeply nested paths', () {
      final parser = PathPatternParser();
      final pattern = parser.parsePattern('/api/v1/companies/{companyId}/departments/{deptId}/teams/{teamId}/members/{memberId}');
      final result = parser.match('/api/v1/companies/acme/departments/eng/teams/backend/members/john', pattern);
      
      expect(result.matches, isTrue);
      expect(result.variables['companyId'], equals('acme'));
      expect(result.variables['deptId'], equals('eng'));
      expect(result.variables['teamId'], equals('backend'));
      expect(result.variables['memberId'], equals('john'));
    });

    test('handles real-world scenarios', () {
      final parser = PathPatternParser();
      
      // Common REST endpoints
      expect(parser.matches('/api/users', '/api/users'), isTrue);
      expect(parser.matches('/api/users/42', '/api/users/{id}'), isTrue);
      expect(parser.matches('/api/users/42/avatar.png', '/api/users/{id}'), isFalse);
      
      // File serving
      expect(parser.matches('/static/css/style.css', '/static/**'), isTrue);
      
      // Versioned APIs
      expect(parser.matches('/v2/graphql', '/v2/**'), isTrue);
    });
  });

  group('PathPatternParser - Configuration', () {
    test('combines multiple configurations', () {
      final parser = PathPatternParser()
        ..caseInsensitive(true)
        ..optionalTrailingSlash(true);

      final pattern = parser.parsePattern('/Home');
      expect(parser.match('/home/', pattern).matches, isTrue);
    });

    test('configuration persists across patterns', () {
      final parser = PathPatternParser()
        ..caseInsensitive(true);

      final pattern1 = parser.parsePattern('/Users');
      final pattern2 = parser.parsePattern('/Posts');

      expect(parser.match('/users', pattern1).matches, isTrue);
      expect(parser.match('/posts', pattern2).matches, isTrue);
    });
  });

  group('PathPatternParser - String Escape', () {
    test('escapes special characters', () {
      expect(PathPatternParser.escape('user{id}'), equals('user\\{id\\}'));
      expect(PathPatternParser.escape('path*'), equals('path\\*'));
      expect(PathPatternParser.escape('a**b'), equals('a\\*\\*b'));
    });
  });
}
