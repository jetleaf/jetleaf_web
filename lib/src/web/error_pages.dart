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

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';

import '../http/http_status.dart';
import 'error_page.dart';

/// {@template error_pages}
/// Central registry and manager for error page pods in the Jetleaf framework.
///
/// ### Overview
///
/// The [ErrorPages] class serves as the unified container for all error page
/// configurations in a Jetleaf application. It manages both application-defined
/// error pages and framework-provided default error pages, providing a
/// comprehensive error handling solution with proper prioritization and
/// conflict resolution.
///
/// ### Key Responsibilities
///
/// - **Error Page Management**: Maintains separate collections for application
///   and framework error pages
/// - **Automatic Discovery**: Scans for `@Pod` annotated error page instances
/// - **Registrar Integration**: Supports modular error page configuration via [ErrorPageRegistrar]
/// - **Conflict Resolution**: Handles duplicate error pages with application pages taking precedence
/// - **Ordering**: Applies proper sorting for consistent error page selection
///
/// ### Error Page Resolution Strategy
///
/// When resolving error pages for a specific HTTP status:
/// 1. **Application Pages First**: Application-defined pages take precedence
/// 2. **Framework Fallbacks**: Framework pages fill gaps without application overrides
/// 3. **Status-Based Mapping**: Pages are mapped by HTTP status code for efficient lookup
/// 4. **Duplicate Prevention**: Only one page per status code in final resolution
///
/// ### Framework vs Application Pages
///
/// - **Framework Pages**: Identified by special path prefixes or attributes,
///   provide default error handling
/// - **Application Pages**: Custom error pages defined by application developers,
///   override framework defaults
///
/// ### Initialization Process
///
/// During [onReady]:
/// 1. **Direct Pod Discovery**: Finds all [ErrorPage] pods in the application context
/// 2. **Registrar Discovery**: Locates all [ErrorPageRegistrar] pods for modular configuration
/// 3. **Ordering Application**: Sorts pages using package and annotation-aware comparators
/// 4. **Registration**: Adds discovered pages to appropriate collections
///
/// ### Usage Example
///
/// ```dart
/// @Service()
/// class ErrorConfiguration {
///   @Pod()
///   ErrorPage getNotFoundPage() => ErrorPage('/errors/404')..setStatus(HttpStatus.NOT_FOUND);
///
///   @Pod()  
///   ErrorPage getServerErrorPage() => ErrorPage('/errors/500')..setStatus(HttpStatus.INTERNAL_SERVER_ERROR);
/// }
///
/// @Component()
/// class CustomErrorRegistrar implements ErrorPageRegistrar {
///   @override
///   void configure(ErrorPageRegistry registry) {
///     registry.addPage('/custom/400', HttpStatus.BAD_REQUEST);
///   }
/// }
/// ```
///
/// ### Integration Points
///
/// - Used by error handling components to resolve appropriate error pages
/// - Integrated with exception resolvers for unified error response generation
/// - Supports both programmatic and declarative error page configuration
/// - Works with template engines for dynamic error page rendering
///
/// ### Performance Considerations
///
/// - Pages are resolved once during initialization for runtime efficiency
/// - Unmodifiable views prevent accidental modification after initialization
/// - Status-based mapping enables O(1) lookups during error handling
///
/// ### Thread Safety
///
/// - Collections are populated during initialization and become effectively immutable
/// - Unmodifiable list views prevent external modification
/// - Safe for concurrent read access after initialization
///
/// ### Related Components
///
/// - [ErrorPage]: Individual error page configuration pod
/// - [ErrorPageRegistry]: Registration interface for error pages
/// - [ErrorPageRegistrar]: Modular configuration pattern for error pages
/// - [HttpStatus]: HTTP status codes for error page mapping
///
/// ### Summary
///
/// The [ErrorPages] class provides a robust, hierarchical error page management
/// system that balances application flexibility with framework-provided defaults,
/// ensuring comprehensive error handling across all HTTP status scenarios.
/// {@endtemplate}
class ErrorPages implements InitializingPod, ApplicationContextAware, ErrorPageRegistry {
  /// {@template application_context_field}
  /// The application context used for pod discovery and dependency access.
  ///
  /// Provides access to:
  /// - Pod definition registry for scanning error page pods
  /// - Pod instantiation for creating error page instances
  /// - Registrar discovery for modular configuration
  ///
  /// ### Lifecycle
  /// - Set during pod initialization via [setApplicationContext]
  /// - Used during [onReady] for pod discovery and instantiation
  /// - Available for dynamic lookups if needed
  /// {@endtemplate}
  late ApplicationContext _applicationContext;

  /// {@template application_error_pages_field}
  /// Set of application-defined error page pods.
  ///
  /// Contains error pages defined by the application developer, which take
  /// precedence over framework-provided error pages during resolution.
  ///
  /// ### Characteristics
  /// - **Application-Specific**: Custom error handling for the specific application
  /// - **High Priority**: Override framework pages for the same HTTP status
  /// - **Mutable During Init**: Populated during initialization phase
  /// - **Unique by Status**: Enforced by set semantics (based on equality)
  /// {@endtemplate}
  final Set<ErrorPage> _errorPages = {};

  /// {@template framework_error_pages_field}
  /// Set of framework-provided error page pods.
  ///
  /// Contains default error pages provided by the Jetleaf framework, which
  /// serve as fallbacks when no application-specific page is available.
  ///
  /// ### Identification
  /// Framework pages are identified by:
  /// - Special path prefixes (starts with framework identifier)
  /// - Specific attributes marking them as framework-provided
  ///
  /// ### Characteristics
  /// - **Framework Defaults**: Standard error handling provided by Jetleaf
  /// - **Lower Priority**: Overridden by application pages for same status
  /// - **Comprehensive Coverage**: Covers all standard HTTP error statuses
  /// {@endtemplate}
  final Set<ErrorPage> _frameworkErrorPages = {};

  /// {@macro error_pages}
  ErrorPages();

  @override
  void add(ErrorPage page) {
    if (page.getAttributes().containsKey(ErrorPage.FRAMEWORK_ERROR_PAGE_IDENTIFIER) || page.getPath().startsWith(ErrorPage.FRAMEWORK_ERROR_PAGE_IDENTIFIER)) {
      _frameworkErrorPages.add(page);
    } else if (!_errorPages.add(page)) {
      // An error page with same status already exists
    }
  }

  @override
  void addPage(String path, HttpStatus status) {
    if (path.startsWith(ErrorPage.FRAMEWORK_ERROR_PAGE_IDENTIFIER)) {
      _frameworkErrorPages.add(ErrorPage(path)..setStatus(status));
    } else if (!_errorPages.add(ErrorPage(path)..setStatus(status))) {
      // An error page with same status already exists
    }
  }

  @override
  String getPackageName() => PackageNames.WEB;

  @override
  Future<void> onReady() async {
    // Target directly declared error pages
    final pages = await _findDeclaredErrorPagePods();
    pages.sort(PackageOrderComparator().compare);
    for (final page in pages) {
      add(page);
    }

    // Find registrars to complete with
    final type = Class<ErrorPageRegistrar>(null, PackageNames.WEB);
    final pods = await _applicationContext.getPodsOf(type, allowEagerInit: true);

    if (pods.isNotEmpty) {
      final pages = List<ErrorPageRegistrar>.from(pods.values);
      AnnotationAwareOrderComparator.sort(pages);
      pages.sort(PackageOrderComparator().compare);

      for (var page in pages) {
        page.configure(this);
      }
    } else {}
  }

  /// {@template find_declared_error_page_pods}
  /// Discovers all [ErrorPage] pods declared in the application context.
  ///
  /// ### Discovery Process
  ///
  /// 1. Queries application context for all pods of type [ErrorPage]
  /// 2. Enables eager initialization to ensure pages are ready
  /// 3. Applies annotation-aware ordering to discovered pages
  /// 4. Returns sorted list of error page pods
  ///
  /// ### Returns
  /// A sorted list of all [ErrorPage] pods found in the application context,
  /// ready for registration and classification.
  /// {@endtemplate}
  Future<List<ErrorPage>> _findDeclaredErrorPagePods() async {
    final type = Class<ErrorPage>(null, PackageNames.WEB);
    final pods = await _applicationContext.getPodsOf(type, allowEagerInit: true);
    final result = <ErrorPage>[];

    if (pods.isNotEmpty) {
      final pages = List<ErrorPage>.from(pods.values);
      AnnotationAwareOrderComparator.sort(pages);

      result.addAll(pages);
    } else {}

    return result;
  }

  @override
  void setApplicationContext(ApplicationContext applicationContext) {
    _applicationContext = applicationContext;
  }

  /// {@template get_resolved_pages}
  /// Returns the final resolved list of error pages with application precedence.
  ///
  /// ### Resolution Logic
  ///
  /// 1. **Application Priority**: Application pages take precedence for each status
  /// 2. **Framework Fallback**: Framework pages fill gaps for statuses without application pages
  /// 3. **Status Mapping**: Pages are mapped by HTTP status code to ensure uniqueness
  /// 4. **Sorted Output**: Final list is sorted by HTTP status code for consistent ordering
  ///
  /// ### Returns
  /// An unmodifiable list of error pages where each HTTP status has at most one page,
  /// with application pages overriding framework pages for the same status.
  ///
  /// ### Example Output
  /// ```dart
  /// final pages = errorPages.getResolvedPages();
  /// // Returns: [404->/app/404, 500->/framework/500] 
  /// // (app page for 404, framework page for 500)
  /// ```
  /// {@endtemplate}
  List<ErrorPage> getResolvedPages() {
    // Map by status code to avoid duplicates
    final resolvedMap = <HttpStatus, ErrorPage>{};

    // First, add application-defined pages
    for (final page in _errorPages) {
      resolvedMap[page.getStatus()] = page;
    }

    // Then, fill in any framework pages that don't have an app-defined override
    for (final page in _frameworkErrorPages) {
      resolvedMap.putIfAbsent(page.getStatus(), () => page);
    }

    // Return as a list, sorted by status code
    final resolvedList = resolvedMap.values.toList()
      ..sort((a, b) => a.getStatus().getCode().compareTo(b.getStatus().getCode()));

    return UnmodifiableListView(resolvedList);
  }

  /// {@template get_framework_pages}
  /// Returns all framework-provided error page pods.
  ///
  /// ### Returns
  /// An unmodifiable list containing all error pages identified as framework pages,
  /// regardless of whether they were overridden by application pages in the final resolution.
  ///
  /// ### Use Cases
  /// - Framework internal error handling
  /// - Diagnostic information about available framework defaults
  /// - Custom resolution logic that needs access to all framework pages
  /// {@endtemplate}
  List<ErrorPage> getFrameworkPages() => UnmodifiableListView(_frameworkErrorPages);

  /// {@template get_application_pages}
  /// Returns all application-defined error page pods.
  ///
  /// ### Returns
  /// An unmodifiable list containing all error pages defined by the application,
  /// representing the custom error handling configuration.
  ///
  /// ### Use Cases
  /// - Application configuration validation
  /// - Custom error handling logic that needs application page details
  /// - Diagnostic and debugging information
  /// {@endtemplate}
  List<ErrorPage> getApplicationPages() => UnmodifiableListView(_errorPages);

  /// Finds a suitable [ErrorPage] for a given [status].
  ///
  /// Searches in order of priority:
  /// 1. Application-defined pages
  /// 2. Resolved pages
  /// 3. Framework-provided default pages
  ///
  /// Returns `null` if no matching page is found.
  ///
  /// ### Example
  /// ```dart
  /// final page = resolver.findPossibleErrorPageForStatus(HttpStatus.NOT_FOUND);
  /// if (page != null) {
  ///   print("Render page: ${page.getPath()}");
  /// }
  /// ```
  ErrorPage? findPossibleErrorPage(HttpStatus? status) {
    return getApplicationPages().find((page) => page.getStatus().equals(status))
      ?? getResolvedPages().find((page) => page.getStatus().equals(status))
      ?? getFrameworkPages().find((page) => page.getStatus().equals(status));
  }
}