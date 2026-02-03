/// Obsidian CLI -- a thin client for Obsidian's Local REST API.
///
/// Provides a command-line interface for interacting with Obsidian vaults
/// via the Local REST API plugin.
library;

// API
export 'src/api/http_obsidian_api.dart';
export 'src/api/obsidian_api.dart';
export 'src/api/obsidian_api_exception.dart';

// CLI
export 'src/cli/obs_runner.dart';
