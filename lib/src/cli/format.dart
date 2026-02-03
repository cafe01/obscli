/// Shared output formatting utilities for human-readable CLI output.
///
/// Color output respects [colorEnabled], which is set by the `--no-color`
/// flag and the `NO_COLOR` environment variable (https://no-color.org).
library;

/// Whether ANSI color output is enabled.
///
/// Defaults to `true`. Set to `false` via the `--no-color` flag or the
/// `NO_COLOR` environment variable.
bool colorEnabled = true;

// ---------------------------------------------------------------------------
// ANSI color helpers
// ---------------------------------------------------------------------------

const _reset = '\x1b[0m';

/// Wrap [s] in ANSI bold. No-op when [colorEnabled] is false.
String bold(String s) => colorEnabled ? '\x1b[1m$s$_reset' : s;

/// Wrap [s] in ANSI dim. No-op when [colorEnabled] is false.
String dim(String s) => colorEnabled ? '\x1b[2m$s$_reset' : s;

/// Wrap [s] in ANSI cyan. No-op when [colorEnabled] is false.
String cyan(String s) => colorEnabled ? '\x1b[36m$s$_reset' : s;

/// Wrap [s] in ANSI green. No-op when [colorEnabled] is false.
String green(String s) => colorEnabled ? '\x1b[32m$s$_reset' : s;

/// Wrap [s] in ANSI yellow. No-op when [colorEnabled] is false.
String yellow(String s) => colorEnabled ? '\x1b[33m$s$_reset' : s;

/// Wrap [s] in ANSI red. No-op when [colorEnabled] is false.
String red(String s) => colorEnabled ? '\x1b[31m$s$_reset' : s;
