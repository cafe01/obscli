/// Abstract interface for Obsidian Local REST API operations.
///
/// Defines the contract for all Obsidian API interactions. Commands
/// depend on this interface, never on a concrete implementation.
///
/// Concrete implementations:
/// - `HttpObsidianApi` -- direct HTTP via `package:http`
/// - Test mocks via `package:mocktail`
abstract class ObsidianApi {
  // ---- Server status ----

  /// Check API status and vault info.
  /// GET /
  Future<Map<String, dynamic>> getStatus();

  // ---- Vault note operations ----

  /// Read a note's raw markdown content.
  /// GET /vault/{path}  Accept: text/markdown
  Future<String> readNote(String path);

  /// Read a note with structured metadata (frontmatter, tags, etc.).
  /// GET /vault/{path}  Accept: application/vnd.olrapi.note+json
  Future<Map<String, dynamic>> readNoteStructured(String path);

  /// List contents of a vault directory.
  /// GET /vault/{path}  Accept: application/json
  /// Returns list of {name, path, type} entries.
  Future<List<Map<String, dynamic>>> listDirectory([String path = '/']);

  /// Create or replace a note.
  /// PUT /vault/{path}
  Future<void> createNote(String path, String content);

  /// Append content to a note.
  /// POST /vault/{path}
  Future<void> appendToNote(String path, String content);

  /// Modify a section of a note (heading, block, or frontmatter).
  /// PATCH /vault/{path}
  ///
  /// Exactly one targeting parameter should be set.
  /// [insertPosition] controls placement within the section:
  /// 'beginning' or 'end'.
  Future<void> patchNote(
    String path,
    String content, {
    String? heading,
    String? blockId,
    bool frontmatter = false,
    String? insertPosition,
  });

  /// Delete a note.
  /// DELETE /vault/{path}
  Future<void> deleteNote(String path);

  // ---- UI operations ----

  /// Open a note in the Obsidian GUI.
  /// POST /open/{path}
  Future<void> openNote(String path, {bool newLeaf = false});

  // ---- Active file operations ----

  /// Read the currently active file's raw content.
  /// GET /active/  Accept: text/markdown
  Future<String> readActiveFile();

  /// Read the currently active file with structured metadata.
  /// GET /active/  Accept: application/vnd.olrapi.note+json
  Future<Map<String, dynamic>> readActiveFileStructured();

  /// Replace the active file's content.
  /// PUT /active/
  Future<void> replaceActiveFile(String content);

  /// Append content to the active file.
  /// POST /active/
  Future<void> appendToActiveFile(String content);

  /// Modify a section of the active file.
  /// PATCH /active/
  Future<void> patchActiveFile(
    String content, {
    String? heading,
    String? blockId,
    bool frontmatter = false,
    String? insertPosition,
  });

  /// Delete the active file.
  /// DELETE /active/
  Future<void> deleteActiveFile();

  // ---- Periodic notes ----

  /// Read a periodic note's raw content.
  /// GET /periodic/{period}/ or GET /periodic/{period}/{year}/{month}/{day}/
  ///
  /// [period]: 'daily', 'weekly', 'monthly', 'quarterly', 'yearly'.
  /// [date]: ISO 8601 date string (e.g., '2026-02-03'). Null = current period.
  Future<String> readPeriodicNote(String period, {String? date});

  /// Read a periodic note with structured metadata.
  /// GET /periodic/{period}/[date]  Accept: application/vnd.olrapi.note+json
  Future<Map<String, dynamic>> readPeriodicNoteStructured(
    String period, {
    String? date,
  });

  /// Create or replace a periodic note.
  /// PUT /periodic/{period}/[date]
  Future<void> createPeriodicNote(
    String period,
    String content, {
    String? date,
  });

  /// Append content to a periodic note.
  /// POST /periodic/{period}/[date]
  Future<void> appendToPeriodicNote(
    String period,
    String content, {
    String? date,
  });

  /// Modify a section of a periodic note.
  /// PATCH /periodic/{period}/[date]
  Future<void> patchPeriodicNote(
    String period,
    String content, {
    String? date,
    String? heading,
    String? blockId,
    bool frontmatter = false,
    String? insertPosition,
  });

  /// Delete a periodic note.
  /// DELETE /periodic/{period}/[date]
  Future<void> deletePeriodicNote(String period, {String? date});

  // ---- Search operations ----

  /// Full-text search across the vault.
  /// POST /search/simple/  Content-Type: application/json
  ///
  /// Returns list of matches with filename, line, and context.
  Future<List<Map<String, dynamic>>> searchSimple(
    String query, {
    int? contextLength,
  });

  /// Execute a Dataview DQL query.
  /// POST /search/  Content-Type: application/vnd.olrapi.dataview-dql+txt
  ///
  /// [dqlQuery]: raw DQL string (TABLE, LIST, TASK, or CALENDAR).
  /// Returns structured results from the Dataview plugin.
  Future<Map<String, dynamic>> searchDql(String dqlQuery);

  /// Execute a JsonLogic structured query.
  /// POST /search/  Content-Type: application/vnd.olrapi.jsonlogic+json
  ///
  /// Supports standard JsonLogic operators plus custom `glob` and `regexp`.
  Future<Map<String, dynamic>> searchJsonLogic(Map<String, dynamic> query);

  // ---- Command operations ----

  /// List all available Obsidian commands (core + plugin).
  /// GET /commands/
  Future<List<Map<String, dynamic>>> listCommands();

  /// Execute an Obsidian command by ID.
  /// POST /commands/{commandId}/
  Future<void> executeCommand(String commandId);

  // ---- Raw escape hatch ----

  /// Make an arbitrary request to the Obsidian REST API.
  ///
  /// For operations not covered by typed methods above.
  Future<dynamic> rawRequest(
    String method,
    String endpoint, {
    String? body,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  });
}
