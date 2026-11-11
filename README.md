# Manta plugins for Claude Code

A [Claude Code](https://code.claude.com/docs/en/overview) plugin marketplace. Each plugin connects Claude Code to
[Manta](https://hiremanta.com) as an MCP server, and binds a Claude Code
[channel](https://code.claude.com/docs/en/channels) to it so Manta events — a manual action assigned to you, a file
landing in your datastore — arrive in a running session as `<channel>` messages.

| Plugin          | MCP server                              | For              |
| --------------- | --------------------------------------- | ---------------- |
| `manta`         | `https://app.hiremanta.com/mcp`         | everyone         |
| `manta-staging` | `https://staging-app.hiremanta.com/mcp` | Manta's own devs |

Installing a plugin replaces the hand-written `.mcp.json` entry: Claude Code starts the server for you, and `/mcp`
lists it as `plugin:manta:manta`.

## Install

```shell
/plugin marketplace add manta-eu/claude-plugins
/plugin install manta@manta
```

Then `/mcp`, select the server, and `Authenticate` to log in to Manta.

## Turn the channel on

A channel registers only for a session that names it at startup, and only where the plugin is on the approved list:

```shell
claude --channels plugin:manta@manta
```

Anthropic's list holds its own plugins alone, so ours passes only in an organization whose administrator deployed a
`managed-settings.json` naming it:

```json
{
  "channelsEnabled": true,
  "allowedChannelPlugins": [{ "marketplace": "manta", "plugin": "manta" }]
}
```

`allowedChannelPlugins` is read from the managed settings alone — a user's own `~/.claude/settings.json` is ignored —
and it _replaces_ Anthropic's list, so name every other channel plugin the organization still wants. A value Claude
Code cannot read admits nothing at all. Without those settings, start the channel the development way, which asks for
a confirmation on each launch:

```shell
claude --dangerously-load-development-channels plugin:manta@manta
```

Channels need Claude Code 2.1.80 or later. On Team and Enterprise plans an Owner also has to enable them under
Organization settings, unless the managed `channelsEnabled` above already does.

## What the events are

- `manual_action_assigned` — a manual action of an action plan was assigned to you. Only an assignee's sessions
  receive it.
- `data_landed` — a file was uploaded to the datastore the session currently uses.

A session receives only the events of the datastore it currently uses, and loses them when it switches datastore.
Events reach running sessions alone: a closed session misses them, and none is sent twice or retried. A session left
idle stops receiving events about an hour after its login token expires; calling any Manta tool refreshes it. To stop
the events, start Claude Code without `--channels`.

## Change a plugin

`.claude-plugin/plugin.json` is the whole plugin. After editing one, validate it and bump its `version`, which is what
tells an installed copy to update:

```shell
claude plugin validate ./plugins/manta
```

To try a change without publishing it, load the directory directly: `claude --plugin-dir ./plugins/manta`.

The server these plugins point at lives in [`manta-eu/manta`](https://github.com/manta-eu/manta), under
`packages/agent-server/src/agents/mcp/`.
