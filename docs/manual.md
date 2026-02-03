# obscli Manual

Complete reference for the `obs` command-line tool for Obsidian.

Version 0.1.0 | Dart 3.8+

---

## Table of contents

1. [Installation](#installation)
2. [Getting started](#getting-started)
3. [Core concepts](#core-concepts)
4. [Command reference](#command-reference)
   - [Note commands](#note-commands)
   - [Active file commands](#active-file-commands)
   - [Periodic note commands](#periodic-note-commands)
   - [Search commands](#search-commands)
   - [Command operations](#command-operations)
   - [Auth commands](#auth-commands)
   - [Config commands](#config-commands)
   - [Status command](#status-command)
   - [API command](#api-command)
5. [Configuration](#configuration)
6. [For agents](#for-agents)
7. [Troubleshooting](#troubleshooting)

---

## Installation

### Prerequisites

1. **Obsidian** installed and running
2. **Dart SDK 3.8+** for building from source
3. **Local REST API plugin** installed in Obsidian:
   - Get it: https://github.com/coddingtonbear/obsidian-local-rest-api
   - Install: Settings → Community plugins → Browse → "Local REST API"
   - Enable: Settings → Community plugins → Enable "Local REST API"
4. **API key** from plugin settings:
   - Navigate to: Settings → Local REST API → API Key
   - Copy the displayed key

### Building from source

```bash
# Clone repository
cd /path/to/bentos

# Compile to native executable
cd packages/obscli
dart compile exe bin/obs.dart -o obs

# Verify the build
./obs --version
# obscli version 0.1.0
```

### Adding to PATH

```bash
# Option 1: Copy to a directory already in PATH
sudo cp obs /usr/local/bin/obs

# Option 2: Add the build directory to PATH
export PATH="$PATH:$(pwd)"

# Verify
obs --version
```

### Running without compiling

```bash
cd packages/obscli
dart run bin/obs.dart --version
```

---

## Getting started

### First-time setup

```bash
# Run interactive setup wizard
obs auth setup
```

This will:
1. Prompt for your API key
2. Prompt for host URL (default: `https://127.0.0.1:27124`)
3. Test the connection to Obsidian
4. Write configuration to `~/.config/obscli/config.yaml`

Example session:

```
Obsidian CLI Setup

Enter Obsidian REST API host [https://127.0.0.1:27124]:
Enter API key: abc123def456...

Testing connection...
Connection successful!
  Server status: OK

Configuration saved to ~/.config/obscli/config.yaml
```

### Verifying setup

```bash
# Check connection status
obs status
```

```
Connected to Obsidian at https://127.0.0.1:27124
Status: OK
```

```bash
# Check authentication
obs auth status
```

```
Host: https://127.0.0.1:27124
API Key: ***...456 (set)
Connected: Yes
```

### First operations

```bash
# List vault root
obs note list

# Read a note
obs note read "daily/2026-02-03.md"

# Append to today's daily note
echo "- First CLI entry" | obs periodic append daily
```

---

## Core concepts

### Architecture

obscli is a **thin REST client**. Every command maps directly to an Obsidian Local REST API endpoint. There is no local parsing, no caching, no state. Obsidian maintains the authoritative vault index. The CLI simply provides a command-line interface to the REST API.

### Human-readable vs JSON output

Most read commands support two output modes:

**Human-readable** (default): Formatted text with ANSI colors (unless `--no-color`), aligned tables for DQL results, grep-like output for searches.

**JSON** (`--json` flag): Machine-parseable JSON output, suitable for piping to `jq`, scripting, or agent consumption.

```bash
# Human-readable
obs note read "path.md"

# JSON (structured metadata)
obs note read "path.md" --json
```

### Global flags

These flags apply to all commands:

| Flag | Short | Description |
|------|-------|-------------|
| `--version` | | Print `obscli version 0.1.0` and exit |
| `--json` | | Machine-readable JSON output |
| `--no-color` | | Disable ANSI color codes in output |
| `--host <url>` | | Obsidian REST API host URL |
| `--api-key <key>` | | Bearer token for authentication |
| `--verbose` | | Enable verbose/debug output |

The `NO_COLOR` environment variable is also respected (see [no-color.org](https://no-color.org)):

```bash
NO_COLOR=1 obs note list
```

### Exit codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error (API error, unexpected failure) |
| 2 | Connection error (cannot reach Obsidian) |
| 64 | Usage error (missing argument, invalid flag) |
| 65 | Data error (file not found, invalid path) |
| 78 | Config error (missing API key, invalid config) |

### Stdin/stdout conventions

**Write commands** (create, append, patch, replace) read content from stdin when `--content` is not provided:

```bash
echo "# New note" | obs note create "inbox/idea.md"
cat draft.md | obs periodic append daily
```

**Read commands** output raw content to stdout with no decoration (for `note read`, `active read`, `periodic read`):

```bash
obs note read "path.md" | wc -l
obs note read "template.md" | obs note create "new.md"
```

---

## Command reference

### Note commands

Parent command: `obs note <subcommand>`

Operates on vault files by path.

#### obs note read

Read a note's content from the vault.

**Syntax:**
```
obs note read <path> [--json]
```

**Arguments:**
- `<path>` (required): Note path relative to vault root (e.g., `daily/2026-02-03.md`)

**Flags:**
- `--json`: Output structured JSON with frontmatter, tags, content, and metadata

**Default output:**
Raw markdown to stdout.

**JSON output:**
Structured note data with frontmatter parsed, tags extracted, and metadata included.

**Examples:**

```bash
# Read raw markdown
obs note read "projects/bentos.md"
```

```markdown
---
status: active
due: 2026-03-01
---

# Bentos Project

## Status
In progress...
```

```bash
# Read structured data
obs note read "projects/bentos.md" --json
```

```json
{
  "content": "# Bentos Project\n\n## Status\nIn progress...",
  "frontmatter": {
    "status": "active",
    "due": "2026-03-01"
  },
  "tags": [],
  "path": "projects/bentos.md"
}
```

**Error cases:**
- File not found: exits 65
- Connection error: exits 2

---

#### obs note list

List directory contents in the vault.

**Syntax:**
```
obs note list [path] [--json]
```

**Arguments:**
- `[path]` (optional): Directory path (default: vault root `/`)

**Flags:**
- `--json`: Output raw JSON array

**Default output:**
One entry per line. Directories prefixed with `[dir]`.

**Examples:**

```bash
# List vault root
obs note list
```

```
[dir] daily/
[dir] projects/
[dir] inbox/
README.md
index.md
```

```bash
# List specific directory
obs note list "projects/"
```

```
bentos.md
xcli.md
archive.md
```

```bash
# JSON output
obs note list --json
```

```json
[
  {"name": "daily", "path": "daily/", "type": "folder"},
  {"name": "projects", "path": "projects/", "type": "folder"},
  {"name": "README.md", "path": "README.md", "type": "file"}
]
```

---

#### obs note create

Create or replace a note. Content from `--content` flag or stdin.

**Syntax:**
```
obs note create <path> [--content <text>] [--json]
```

**Arguments:**
- `<path>` (required): Note path

**Flags:**
- `--content <text>`: Inline content (alternative to stdin)
- `--json`: Output JSON confirmation

**Content source:**
1. `--content` flag value if provided
2. Otherwise read from stdin

**Examples:**

```bash
# Create from stdin
echo "# New Note" | obs note create "inbox/idea.md"
```

```
Created: inbox/idea.md
```

```bash
# Create with inline content
obs note create "inbox/quick.md" --content "# Quick thought"
```

```bash
# Create from file
cat template.md | obs note create "projects/new-project.md"
```

```bash
# JSON output
echo "# Test" | obs note create "test.md" --json
```

```json
{"path": "test.md", "status": "created"}
```

**Note:** This command uses `PUT`, so it will replace existing files.

---

#### obs note append

Append content to an existing note.

**Syntax:**
```
obs note append <path> [--content <text>] [--json]
```

**Arguments:**
- `<path>` (required): Note path

**Flags:**
- `--content <text>`: Inline content
- `--json`: Output JSON confirmation

**Examples:**

```bash
# Append from stdin
echo "- New item" | obs note append "daily/2026-02-03.md"
```

```
Appended to: daily/2026-02-03.md
```

```bash
# Append with inline content
obs note append "inbox/log.md" --content "Another entry"
```

**Error cases:**
- File not found: exits 65

---

#### obs note patch

Modify a specific section of a note. Targets a heading, block reference, or frontmatter.

**Syntax:**
```
obs note patch <path> [targeting flags] [--content <text>] [--json]
```

**Arguments:**
- `<path>` (required): Note path

**Targeting flags (exactly one required):**
- `--heading <text>`: Target content under this heading
- `--block <id>`: Target a specific block reference (`^block-id`)
- `--frontmatter`: Target the YAML frontmatter

**Other flags:**
- `--insert-position <pos>`: `beginning` or `end` within the targeted section (default: `end`)
- `--content <text>`: Content to insert/replace
- `--json`: Output JSON confirmation

**Examples:**

```bash
# Patch a heading
obs note patch "projects/bentos.md" --heading "Status" --content "In progress"
```

```
Patched: projects/bentos.md (heading: Status)
```

```bash
# Update frontmatter
echo '{"status": "active", "priority": "high"}' | obs note patch "projects/bentos.md" --frontmatter
```

```bash
# Patch with position control
obs note patch "daily/2026-02-03.md" --heading "Log" --insert-position beginning --content "- 09:00 standup"
```

**Note:** When targeting `--frontmatter`, the content must be valid JSON representing frontmatter key-value pairs.

---

#### obs note delete

Delete a note from the vault.

**Syntax:**
```
obs note delete <path> [--confirm] [--json]
```

**Arguments:**
- `<path>` (required): Note path

**Flags:**
- `--confirm`: Skip confirmation prompt (required for non-interactive use)
- `--json`: Output JSON confirmation

**Examples:**

```bash
# Delete with confirmation
obs note delete "inbox/old-idea.md" --confirm
```

```
Deleted: inbox/old-idea.md
```

**Interactive mode:** Without `--confirm`, prompts for confirmation.

**Error cases:**
- File not found: exits 65

---

#### obs note open

Open a note in the Obsidian GUI.

**Syntax:**
```
obs note open <path> [--new-leaf] [--json]
```

**Arguments:**
- `<path>` (required): Note path

**Flags:**
- `--new-leaf`: Open in a new pane/tab
- `--json`: Output JSON confirmation

**Examples:**

```bash
# Open in current pane
obs note open "projects/bentos.md"
```

```
Opened: projects/bentos.md
```

```bash
# Open in new pane
obs note open "daily/2026-02-03.md" --new-leaf
```

---

### Active file commands

Parent command: `obs active <subcommand>`

Operates on whichever file is currently open/active in Obsidian. No path argument needed.

#### obs active read

Read the currently active file's content.

**Syntax:**
```
obs active read [--json]
```

**Flags:**
- `--json`: Output structured JSON

**Examples:**

```bash
# Read raw markdown
obs active read
```

```bash
# Read structured data
obs active read --json
```

---

#### obs active replace

Replace the active file's content.

**Syntax:**
```
obs active replace [--content <text>] [--json]
```

**Flags:**
- `--content <text>`: Inline content
- `--json`: Output JSON confirmation

**Examples:**

```bash
# Replace from stdin
echo "# Replaced content" | obs active replace
```

```
Replaced active file
```

---

#### obs active append

Append content to the active file.

**Syntax:**
```
obs active append [--content <text>] [--json]
```

**Examples:**

```bash
echo "- Appended line" | obs active append
```

```
Appended to active file
```

---

#### obs active patch

Modify a section of the active file.

**Syntax:**
```
obs active patch [targeting flags] [--content <text>] [--json]
```

**Targeting flags:**
- `--heading <text>`
- `--block <id>`
- `--frontmatter`
- `--insert-position <pos>`

**Examples:**

```bash
obs active patch --heading "Tasks" --content "- New task"
```

```
Patched active file (heading: Tasks)
```

---

#### obs active delete

Delete the active file.

**Syntax:**
```
obs active delete [--confirm] [--json]
```

**Flags:**
- `--confirm`: Skip confirmation prompt

**Examples:**

```bash
obs active delete --confirm
```

```
Deleted active file
```

---

### Periodic note commands

Parent command: `obs periodic <subcommand> <period>`

Operates on periodic notes (daily, weekly, monthly, quarterly, yearly).

All subcommands accept `--date YYYY-MM-DD` to target a specific date (default: current period).

#### obs periodic read

Read a periodic note's content.

**Syntax:**
```
obs periodic read <period> [--date YYYY-MM-DD] [--json]
```

**Arguments:**
- `<period>` (required): One of `daily`, `weekly`, `monthly`, `quarterly`, `yearly`

**Flags:**
- `--date <YYYY-MM-DD>`: Target specific date (default: today/current period)
- `--json`: Output structured JSON

**Examples:**

```bash
# Read today's daily note
obs periodic read daily
```

```bash
# Read specific date
obs periodic read daily --date 2026-01-15
```

```bash
# Read current week's weekly note
obs periodic read weekly
```

```bash
# Read with structured data
obs periodic read monthly --json
```

---

#### obs periodic create

Create or replace a periodic note.

**Syntax:**
```
obs periodic create <period> [--date YYYY-MM-DD] [--content <text>] [--json]
```

**Examples:**

```bash
# Create today's daily note
echo "# 2026-02-03\n\n## Log" | obs periodic create daily
```

```bash
# Create specific date
obs periodic create daily --date 2026-02-10 --content "# Future note"
```

---

#### obs periodic append

Append content to a periodic note.

**Syntax:**
```
obs periodic append <period> [--date YYYY-MM-DD] [--content <text>] [--json]
```

**Examples:**

```bash
# Append to today's daily note
echo "- 14:30 standup completed" | obs periodic append daily
```

```
Appended to periodic note: daily (2026-02-03)
```

```bash
# Append to specific date
obs periodic append daily --date 2026-01-15 --content "- Late addition"
```

---

#### obs periodic patch

Modify a section of a periodic note.

**Syntax:**
```
obs periodic patch <period> [--date YYYY-MM-DD] [targeting flags] [--content <text>] [--json]
```

**Targeting flags:**
- `--heading <text>`
- `--block <id>`
- `--frontmatter`
- `--insert-position <pos>`

**Examples:**

```bash
# Patch today's daily note
obs periodic patch daily --heading "Log" --content "- 15:00 review done"
```

```bash
# Patch specific date
obs periodic patch daily --date 2026-01-15 --heading "Tasks" --content "- New task"
```

---

#### obs periodic delete

Delete a periodic note.

**Syntax:**
```
obs periodic delete <period> [--date YYYY-MM-DD] [--confirm] [--json]
```

**Examples:**

```bash
obs periodic delete daily --date 2026-01-15 --confirm
```

```
Deleted periodic note: daily (2026-01-15)
```

---

### Search commands

Parent command: `obs search <subcommand>`

#### obs search text

Full-text search across the vault.

**Syntax:**
```
obs search text <query> [--context-length <n>] [--json]
```

**Arguments:**
- `<query>` (required): Search query text (multiple words joined with spaces)

**Flags:**
- `--context-length <n>`: Characters of context around each match
- `--json`: Output raw JSON array

**Default output:**
Grep-like format: `filename -- ...match context...`

**Examples:**

```bash
# Simple search
obs search text "TODO"
```

```
daily/2026-02-03.md -- - TODO: Review PR
projects/bentos.md -- TODO: Add tests
inbox/ideas.md -- TODO: Explore this concept
```

```bash
# With more context
obs search text "project status" --context-length 100
```

```bash
# JSON output
obs search text "TODO" --json
```

```json
[
  {
    "filename": "daily/2026-02-03.md",
    "score": 0.85,
    "matches": [
      {
        "match": {"start": 2, "end": 6},
        "context": "- TODO: Review PR"
      }
    ]
  }
]
```

**Empty state:**
```
No matches found.
```

---

#### obs search dql

Execute a Dataview DQL query. Requires the Dataview plugin in Obsidian.

**Syntax:**
```
obs search dql <query> [--json]
```

**Arguments:**
- `<query>` (required): DQL query string
- Use `-` to read multi-line query from stdin

**Flags:**
- `--json`: Output raw JSON result from Dataview

**Default output:**
- TABLE: Aligned ASCII table with column headers
- LIST: Bulleted list
- TASK: Checkbox items

**Examples:**

```bash
# TABLE query
obs search dql 'TABLE status, due FROM "projects" WHERE status = "active"'
```

```
File             | status | due
-----------------|--------|------------
projects/bentos  | active | 2026-03-01
projects/xcli    | active | 2026-02-15
```

```bash
# LIST query
obs search dql 'LIST FROM [[project-bentos]]'
```

```
- daily/2026-02-03
- journal/s234-session
- projects/bentos
```

```bash
# TASK query
obs search dql 'TASK FROM "daily/2026-02-03"'
```

```
[ ] Review PR
[x] Write journal entry
[ ] Push session artifacts
```

```bash
# Multi-line query from stdin
echo 'TABLE file.name, file.mtime
FROM "inbox"
SORT file.mtime DESC
LIMIT 10' | obs search dql -
```

```bash
# JSON output
obs search dql 'TABLE FROM "projects"' --json
```

```json
{
  "type": "table",
  "headers": ["File", "status", "due"],
  "values": [
    ["projects/bentos", "active", "2026-03-01"],
    ["projects/xcli", "active", "2026-02-15"]
  ]
}
```

**Error cases:**
- Dataview plugin not installed: API error
- Invalid DQL syntax: API error with details

---

#### obs search jsonlogic

Execute a JsonLogic structured query. Supports `glob` and `regexp` operators.

**Syntax:**
```
obs search jsonlogic [--query <json>] [--json]
```

**Flags:**
- `--query <json>`: JsonLogic query as JSON string
- Alternatively: pipe JSON from stdin

**Examples:**

```bash
# Glob pattern
obs search jsonlogic --query '{"glob": ["*.md", {"var": "path"}]}'
```

```
projects/bentos.md
projects/xcli.md
daily/2026-02-03.md
```

```bash
# Complex query from stdin
echo '{
  "and": [
    {"glob": ["projects/*.md", {"var": "path"}]},
    {"==": [{"var": "frontmatter.status"}, "active"]}
  ]
}' | obs search jsonlogic
```

```bash
# JSON output
obs search jsonlogic --query '{"glob": ["projects/*.md", {"var": "path"}]}' --json
```

---

### Command operations

Parent command: `obs command <subcommand>`

#### obs command list

List all available Obsidian commands (core + plugin).

**Syntax:**
```
obs command list [--filter <text>] [--json]
```

**Flags:**
- `--filter <text>`: Client-side text filter on command name/ID
- `--json`: Output raw JSON array

**Default output:**
Two-column table: `ID -- Name`

**Examples:**

```bash
# List all commands
obs command list
```

```
app:open-vault -- Open another vault
app:reload -- Reload app without saving
dataview:dataview-force-refresh-views -- Dataview: Force Refresh All Views
editor:toggle-bold -- Toggle bold
graph:open -- Open graph view
```

```bash
# Filter commands
obs command list --filter dataview
```

```
dataview:dataview-force-refresh-views -- Dataview: Force Refresh All Views
dataview:dataview-drop-cache -- Dataview: Drop All Caches
```

```bash
# JSON output
obs command list --json
```

```json
[
  {"id": "app:reload", "name": "Reload app without saving"},
  {"id": "dataview:dataview-force-refresh-views", "name": "Dataview: Force Refresh All Views"}
]
```

---

#### obs command exec

Execute an Obsidian command by its ID.

**Syntax:**
```
obs command exec <commandId> [--json]
```

**Arguments:**
- `<commandId>` (required): Command ID (from `obs command list`)

**Examples:**

```bash
# Refresh Dataview
obs command exec "dataview:dataview-force-refresh-views"
```

```
Executed: dataview:dataview-force-refresh-views
```

```bash
# Open graph view
obs command exec "graph:open"
```

```bash
# Reload Obsidian
obs command exec "app:reload"
```

**Use case:** Trigger plugin operations, refresh caches, open specific views.

---

### Auth commands

Parent command: `obs auth <subcommand>`

#### obs auth setup

Interactive setup wizard for API key authentication.

**Syntax:**
```
obs auth setup
```

**Flow:**
1. Prompt for host URL (default: `https://127.0.0.1:27124`)
2. Prompt for API key
3. Test connection via `GET /`
4. Write configuration to `~/.config/obscli/config.yaml`

**Example:**

```bash
obs auth setup
```

```
Obsidian CLI Setup

Enter Obsidian REST API host [https://127.0.0.1:27124]:
Enter API key: abc123...

Testing connection...
Connection successful!
  Server status: OK

Configuration saved to ~/.config/obscli/config.yaml
```

---

#### obs auth status

Show current authentication and connection status.

**Syntax:**
```
obs auth status [--json]
```

**Default output:**

```bash
obs auth status
```

```
Host: https://127.0.0.1:27124
API Key: ***...456 (set)
Connected: Yes
```

**JSON output:**

```bash
obs auth status --json
```

```json
{
  "host": "https://127.0.0.1:27124",
  "key_set": true,
  "connected": true
}
```

**Not configured:**

```
Host: https://127.0.0.1:27124
API Key: (not set)
Connected: No

Run "obs auth setup" to configure.
```

---

### Config commands

Parent command: `obs config <subcommand>`

#### obs config get

Print a single config value.

**Syntax:**
```
obs config get <key>
```

**Arguments:**
- `<key>` (required): Config key (`host`, `api-key`, `no-color`)

**Examples:**

```bash
obs config get host
# https://127.0.0.1:27124

obs config get api-key
# abc123def456...
```

---

#### obs config set

Set a config value.

**Syntax:**
```
obs config set <key> <value>
```

**Arguments:**
- `<key>` (required): Config key
- `<value>` (required): Value to set

**Examples:**

```bash
obs config set host "https://127.0.0.1:27124"
obs config set api-key "new-key-here"
obs config set no-color "true"
```

---

#### obs config list

List all config values.

**Syntax:**
```
obs config list
```

**Example:**

```bash
obs config list
```

```
host: https://127.0.0.1:27124
api-key: abc123...
no-color: false
```

**Config keys:**
- `host` — REST API base URL
- `api-key` — Bearer token
- `no-color` — Disable colored output (boolean)

---

### Status command

Top-level command (not a group).

#### obs status

Check connection to the Obsidian REST API.

**Syntax:**
```
obs status [--json]
```

**Default output:**

```bash
obs status
```

```
Connected to Obsidian at https://127.0.0.1:27124
Status: OK
```

**JSON output:**

```bash
obs status --json
```

```json
{
  "status": "OK",
  "service": "Obsidian Local REST API",
  "versions": {
    "obsidian": "1.5.3",
    "self": "3.3.0"
  }
}
```

**Error cases:**
- Cannot connect: exits 2 with error message
- API key invalid: exits 78

---

### API command

Top-level command. Raw REST API escape hatch.

#### obs api

Make an arbitrary request to the Obsidian REST API.

**Syntax:**
```
obs api <endpoint> [-X <method>] [-H <header>] [--body <text>]
```

**Arguments:**
- `<endpoint>` (required): API endpoint path (e.g., `/vault/path.md`)

**Flags:**
- `-X, --method <method>`: HTTP method (default: `GET`)
- `-H, --header <header>`: Custom header (repeatable)
- `--body <text>`: Request body (or read from stdin)

**Examples:**

```bash
# List vault contents
obs api /vault/inbox/
```

```bash
# Custom Accept header
obs api /periodic/daily/ -H "Accept: application/vnd.olrapi.note+json"
```

```bash
# POST with query params (search uses query params, not body)
obs api "/search/simple/?query=test" -X POST
```

```bash
# Pipe to jq
obs api /commands/ | jq '.[].id'
```

**Use case:** Access API features not yet wrapped by typed commands.

---

## Configuration

### Config file format

Location: `~/.config/obscli/config.yaml`

```yaml
host: "https://127.0.0.1:27124"
api-key: "your-api-key-here"
no-color: false
```

### Resolution order

For `host` and `api-key`, the resolution order is:

1. **CLI flag** (`--host`, `--api-key`) — highest priority
2. **Environment variable** (`OBS_HOST`, `OBS_API_KEY`)
3. **Config file** (`~/.config/obscli/config.yaml`)
4. **Default value** (host: `https://127.0.0.1:27124`, api-key: none)

### Environment variables

| Variable | Maps To | Description |
|----------|---------|-------------|
| `OBS_API_KEY` | `--api-key` | Bearer token for authentication |
| `OBS_HOST` | `--host` | REST API base URL |
| `NO_COLOR` | `--no-color` | Disable colored output (standard: no-color.org) |

### TLS certificate handling

The REST API uses a self-signed certificate by default (HTTPS on port 27124). The HTTP client must trust the certificate.

**Current behavior:** TLS verification is disabled for localhost connections to handle self-signed certificates.

**For production/remote use:** You would need to download and trust the certificate from `GET /{cert_name}`, or use an environment variable like `OBS_INSECURE=1` to explicitly disable verification.

---

## For agents

obscli is designed to work well as a tool for AI agents and automation scripts.

### Always use JSON mode

Agents should always pass `--json` to get structured, parseable output. Human-readable output includes ANSI escape codes and formatting that are harder to process.

```bash
# Get structured note data
obs note read "path.md" --json

# Get DQL results as JSON
obs search dql 'TABLE FROM "projects"' --json
```

### Disable color output

To avoid ANSI escape codes:

```bash
export NO_COLOR=1
# Or: obs --no-color <command>
```

### Error handling

obscli uses specific exit codes:

| Exit code | Meaning | Action |
|-----------|---------|--------|
| 0 | Success | Parse stdout |
| 1 | General error | Check stderr for message |
| 2 | Connection error | Obsidian not running or API not enabled |
| 64 | Usage error (bad args) | Fix the command syntax |
| 65 | Data error (file not found) | Check path validity |
| 78 | Config error (missing API key) | Run `obs auth setup` |

### Typical agent workflows

**Append to daily note:**
```bash
echo "- Agent log entry" | obs periodic append daily --json
```

**Query vault and process:**
```bash
# Get all active projects
obs search dql 'TABLE FROM "projects" WHERE status = "active"' --json | jq '.values[] | .[0]'
```

**Read and update note:**
```bash
# Read current status
status=$(obs note read "project.md" --json | jq -r '.frontmatter.status')

# Update frontmatter
echo '{"status": "completed"}' | obs note patch "project.md" --frontmatter
```

**Search and batch process:**
```bash
# Find all TODOs
obs search text "TODO" --json | jq -r '.[].filename' | while read file; do
  echo "Found TODO in $file"
done
```

**Create notes from templates:**
```bash
# Read template and create new note
obs note read "templates/project.md" | obs note create "projects/new-project.md"
```

---

## Troubleshooting

### Cannot connect to Obsidian

**Symptoms:** `Error: Cannot connect to Obsidian at https://127.0.0.1:27124`

**Causes:**
- Obsidian not running
- Local REST API plugin not installed or enabled
- Different port configured in plugin

**Solutions:**
1. Start Obsidian
2. Check plugin: Settings → Community plugins → "Local REST API" is enabled
3. Check port: Settings → Local REST API → Port (default: 27124)
4. Test: `obs status`

---

### 401 Unauthorized / Invalid API key

**Symptoms:** `Error: Unauthorized` or `AuthException: 401`

**Causes:**
- API key not configured
- API key incorrect
- API key changed in Obsidian but not updated in CLI config

**Solutions:**
```bash
# Check current config
obs auth status

# Re-run setup
obs auth setup

# Or manually set key
obs config set api-key "new-key-from-obsidian"
```

---

### 404 File not found

**Symptoms:** `Error: File not found: path.md`

**Causes:**
- Path does not exist in vault
- Path typo
- Wrong vault (if multiple vaults)

**Solutions:**
```bash
# List directory to verify path
obs note list "projects/"

# Check vault root
obs note list
```

---

### TLS certificate errors

**Symptoms:** `TLS handshake failed` or `Certificate verify failed`

**Cause:** Self-signed certificate not trusted.

**Current solution:** TLS verification is disabled for localhost by default in the HTTP client implementation.

**If connecting remotely:** You may need to download and trust the certificate manually, or set an insecure flag.

---

### Dataview queries fail

**Symptoms:** `Error: Invalid DQL` or no results

**Causes:**
- Dataview plugin not installed or enabled
- DQL syntax error
- Dataview cache stale

**Solutions:**
```bash
# Check if Dataview is installed
obs command list --filter dataview

# Force refresh Dataview
obs command exec "dataview:dataview-force-refresh-views"

# Test simple query
obs search dql 'LIST FROM ""'
```

---

### Command not found

**Symptoms:** `bash: obs: command not found`

**Cause:** Binary not in PATH.

**Solutions:**
```bash
# Find where obs is
which obs

# Add to PATH
export PATH="$PATH:/path/to/obscli"

# Or copy to standard location
sudo cp obs /usr/local/bin/obs
```

---

## See also

- [Local REST API Plugin Documentation](https://github.com/coddingtonbear/obsidian-local-rest-api)
- [Obsidian](https://obsidian.md)
- [Dataview Plugin](https://github.com/blacksmithgu/obsidian-dataview)
- [no-color.org](https://no-color.org)
