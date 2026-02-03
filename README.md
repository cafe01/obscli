# obscli

Obsidian CLI — a thin client for Obsidian's Local REST API.

```
obs <command> [subcommand] [flags]
```

Same mental model as `gh` for GitHub, but for your Obsidian vault. Read notes, append to daily journals, run DQL queries, execute commands — all from the terminal. Requires Obsidian running with the Local REST API plugin.

**Version**: 0.1.0 | **SDK**: Dart 3.8+ | **License**: See repository

## Quick start

```bash
# Build from source
cd packages/obscli
dart compile exe bin/obs.dart -o obs

# Move to PATH
mv obs /usr/local/bin/obs

# Set up authentication
obs auth setup
# Prompts for API key and host, tests connection

# Verify connection
obs status

# Read a note
obs note read "daily/2026-02-03.md"

# Append to your daily note
echo "- Completed task" | obs note append "daily/2026-02-03.md"

# Run a DQL query
obs search dql 'TABLE status, due FROM "projects" WHERE status = "active"'
```

## Prerequisites

1. **Obsidian** installed and running
2. **Local REST API plugin** installed and enabled
   - Get it: https://github.com/coddingtonbear/obsidian-local-rest-api
   - Enable it in Obsidian: Settings → Community plugins → Browse → "Local REST API"
3. **API key** from plugin settings (Settings → Local REST API → API Key)

## Install

```bash
# From source (for now)
dart pub global activate --source path packages/obscli

# Or compile to native executable
cd packages/obscli
dart compile exe bin/obs.dart -o obs
sudo cp obs /usr/local/bin/obs
```

## Command groups

| Command | Description |
|---------|-------------|
| `obs note` | Vault file operations (read, create, append, patch, delete, open) |
| `obs active` | Operations on the currently active file in Obsidian |
| `obs periodic` | Periodic note operations (daily, weekly, monthly, etc.) |
| `obs search` | Search vault contents (text search, DQL queries, JsonLogic) |
| `obs command` | List and execute Obsidian commands (core + plugins) |
| `obs auth` | Authentication setup and status |
| `obs config` | Configuration management |
| `obs status` | Check connection to Obsidian REST API |
| `obs api` | Raw REST API escape hatch |

## Examples

```bash
# Read a note's content
obs note read "projects/bentos.md"

# Read with structured metadata (frontmatter, tags)
obs note read "projects/bentos.md" --json

# List directory contents
obs note list "projects/"

# Append to today's daily note
echo "- 14:30 standup completed" | obs periodic append daily

# Patch a specific heading in a note
obs note patch "projects/bentos.md" --heading "Status" --content "In progress"

# Run a Dataview DQL query
obs search dql 'TABLE file.name, file.mtime FROM "inbox" SORT file.mtime DESC LIMIT 10'

# Search for text across the vault
obs search text "TODO" --context-length 50

# List all available Obsidian commands
obs command list --filter dataview

# Execute a command
obs command exec "dataview:dataview-force-refresh-views"

# Open a note in Obsidian GUI
obs note open "projects/bentos.md" --new-leaf

# Pipe content between notes
obs note read "template.md" | obs note create "new-note.md"

# Agent-friendly JSON output
obs note read "projects/bentos.md" --json | jq '.frontmatter.status'

# Raw API access for anything not covered
obs api /vault/inbox/ | jq '.[].name'
```

## Configuration

### Config file

Location: `~/.config/obscli/config.yaml`

```yaml
host: "https://127.0.0.1:27124"
api-key: "your-api-key-here"
no-color: false
```

### Environment variables

| Variable | Description |
|----------|-------------|
| `OBS_HOST` | REST API host URL |
| `OBS_API_KEY` | Bearer token for authentication |
| `NO_COLOR` | Disable colored output (https://no-color.org) |

### Resolution order

For `host` and `api-key`:
1. CLI flag (`--host`, `--api-key`) — highest priority
2. Environment variable (`OBS_HOST`, `OBS_API_KEY`)
3. Config file (`~/.config/obscli/config.yaml`)
4. Default (host: `https://127.0.0.1:27124`)

## For agents

obscli is designed for both humans and AI agents. Key patterns:

**Always use JSON mode for structured output:**
```bash
obs note read "path.md" --json
obs search dql 'LIST FROM "inbox"' --json
obs auth status --json
```

**Pipe content for composition:**
```bash
# Read from stdin for write operations
echo "# New note" | obs note create "inbox/idea.md"
cat draft.md | obs periodic append daily

# Pipe between commands
obs note read "template.md" | obs note create "new-note.md"
```

**Exit codes:**
- `0` — Success
- `1` — General error (API error, connection failed)
- `2` — Connection error
- `64` — Usage error (bad arguments)
- `65` — Data error (file not found)
- `78` — Config error (missing API key)

**Common workflows:**
```bash
# Append to daily note
echo "- Log entry" | obs periodic append daily --json

# Query vault and process results
obs search dql 'TABLE FROM "projects"' --json | jq '.values[] | .[0]'

# Batch create notes
for title in "Note 1" "Note 2"; do
  echo "# $title" | obs note create "inbox/$title.md"
done
```

## Global flags

| Flag | Description |
|------|-------------|
| `--version` | Print CLI version |
| `--json` | Machine-readable JSON output |
| `--no-color` | Disable colored output |
| `--host <url>` | Obsidian REST API host |
| `--api-key <key>` | Bearer token for auth |
| `--verbose` | Enable verbose output |

The `NO_COLOR` environment variable is also respected per the [no-color.org](https://no-color.org) standard.

## Development

```bash
# Run tests
dart test packages/obscli

# Run analyzer
dart analyze packages/obscli

# Build executable
dart compile exe packages/obscli/bin/obs.dart -o obs
```

## See also

- [obscli Manual](docs/manual.md) — Comprehensive command reference
- [Local REST API Plugin](https://github.com/coddingtonbear/obsidian-local-rest-api) — Plugin documentation
- [Obsidian](https://obsidian.md) — The knowledge base app
