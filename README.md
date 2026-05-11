# MeSameerAhmed Claude Marketplace

Personal collection of [Claude Code](https://claude.com/claude-code) plugins.

## Install

In Claude Code:

```
/plugin marketplace add MeSameerAhmed/claude-marketplace
/plugin install implement-with-review
```

After install, the `/implement-with-review` slash command and its two subagents
(`opus-architect`, `pr-reviewer`) are available.

## Plugins

### `implement-with-review`

End-to-end feature delivery loop:

```
spec → plan → implement → branch + commit + PR → pr-reviewer subagent
                                                   ↑           ↓
                                                   └── fix ────┘  (up to 3 rounds)
                                                          ↓
                                                  APPROVE + build + summary
```

Run with:

```
/implement-with-review <feature description, ticket link, or rough idea>
```

See [`plugins/implement-with-review/README.md`](plugins/implement-with-review/README.md)
for full docs, requirements, and customisation notes (the command currently assumes a
Maven/Java project for the build/PMD steps — adapt for your stack).

## Repo layout

```
.
├── .claude-plugin/
│   └── marketplace.json        # marketplace manifest
└── plugins/
    └── implement-with-review/
        ├── .claude-plugin/
        │   └── plugin.json     # plugin manifest
        ├── commands/
        │   └── implement-with-review.md
        ├── agents/
        │   ├── opus-architect.md
        │   └── pr-reviewer.md
        ├── install.sh          # manual fallback installer
        └── README.md
```
