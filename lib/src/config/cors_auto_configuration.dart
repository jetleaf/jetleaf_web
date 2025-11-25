import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_pod/pod.dart';

import '../cors/cors_configuration.dart';
import '../cors/cors_filter.dart';
import '../cors/default_cors_configuration_manager.dart';
import '../path/path_pattern_parser_manager.dart';

/// {@template cors_auto_configuration}
/// Auto-configures CORS support within the JetLeaf runtime.
///
/// `CorsAutoConfiguration` is an infrastructure-level configuration component
/// responsible for providing default CORS behavior when no user-defined
/// configuration is supplied.
///
/// This auto-configuration registers:
///
/// - A [CorsConfigurationManager] responsible for resolving allowed origins,
///   headers, credentials, and methods.
/// - A [CorsFilter] that applies those rules to incoming HTTP requests.
///
/// ### Activation Rules
///
/// This configuration becomes active only when:
/// - JetLeaf auto-configuration is enabled, and
/// - No existing [CorsConfiguration] pod is already defined.
///
/// Developers may override behavior simply by declaring their own pod.
///
/// ### Typical Use
///
/// ```dart
/// // Automatically provided at runtime:
/// final filter = context.getPod<CorsFilter>();
/// ```
///
/// ### Design Notes
/// - Marked as [DesignRole.INFRASTRUCTURE] because it participates in the
///   framework boot process rather than user application logic.
/// - Declared as `final` to prevent extension or mutation.
/// {@endtemplate}
@AutoConfiguration()
@Role(DesignRole.INFRASTRUCTURE)
@Named(CorsAutoConfiguration.NAME)
final class CorsAutoConfiguration {
  /// The logical component name for this auto-configuration.
  ///
  /// Used for identification inside the dependency container.
  static const String NAME = "jetleaf.cors.corsAutoConfiguration";

  /// The pod registration name for the [CorsConfigurationManager] bean.
  ///
  /// Consumers may reference this value to override or retrieve the instance.
  static const String CORS_MANAGER = "jetleaf.cors.corsConfigurationManager";

  /// The pod registration name for the [CorsFilter] bean.
  ///
  /// The filter is inserted into the HTTP processing chain to enforce CORS.
  static const String CORS_FILTER = "jetleaf.cors.corsFilter";

  /// Creates the default [CorsConfigurationManager] instance.
  ///
  /// - Registered under [CORS_MANAGER]
  /// - Only created if no existing [CorsConfiguration] is present
  ///
  /// The manager uses the [PathPatternParserManager] to resolve request path
  /// rules against configured CORS mappings.
  ///
  /// ### Example Override
  /// ```dart
  /// @Pod(value: CorsAutoConfiguration.CORS_MANAGER)
  /// CorsConfigurationManager customManager() =>
  ///   MyCustomCorsManager();
  /// ```
  @Pod(value: CORS_MANAGER)
  @Role(DesignRole.INFRASTRUCTURE)
  @ConditionalOnMissingPod(values: [CorsConfiguration])
  CorsConfigurationManager manager(PathPatternParserManager parser) => DefaultCorsConfigurationManager(parser);

  /// Creates the HTTP filter that applies CORS policies at request time.
  ///
  /// - Registered under [CORS_FILTER]
  /// - Depends on the active [CorsConfigurationManager]
  ///
  /// The filter inspects incoming requests and sets:
  /// - `Access-Control-Allow-Origin`
  /// - `Access-Control-Allow-Headers`
  /// - `Access-Control-Allow-Methods`
  /// - Preflight (`OPTIONS`) handling
  @Pod(value: CORS_FILTER)
  @Role(DesignRole.INFRASTRUCTURE)
  CorsFilter corsFilter(CorsConfigurationManager manager) => CorsFilter(manager);
}