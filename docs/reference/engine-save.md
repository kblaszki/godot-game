---
title: Engine save
diataxis: reference
audience: [ai, human]
related_code:
  - engine/high_score_table.gd
  - engine/score_store.gd
  - tests/engine/high_score_table_test.gd
  - tests/engine/score_store_test.gd
related_docs:
  - ../index.md
  - ../explanation/architecture.md
  - source-layout.md
keywords: [save, high-score, HighScoreTable, ScoreStore, FileAccess]
last_reviewed: 2026-11-02
---

# Engine save

In-memory high-score table plus a small file store. Sims never call this; app code loads/saves after reading sim scores.

```mermaid
classDiagram
  class HighScoreTable {
    +qualifies(score)
    +insert(score)
    +entries()
  }
  class ScoreStore {
    +load(path, capacity)$
    +save(path, table)$
  }
  ScoreStore --> HighScoreTable : load/save
  HighScoreTable --|> RefCounted
  ScoreStore --|> RefCounted
```

## HighScoreTable

Fixed-capacity descending `int` list (`engine/high_score_table.gd`). Ties keep the older entry above a new equal score.

| API | Behavior |
|-----|----------|
| `_init(capacity)` | Capacity clamped to `>= 0` |
| `qualifies(score)` | Room remains, or `score` beats the lowest entry; rejects negatives and capacity `0` |
| `insert(score)` | Inserts descending; returns 0-based rank, or `-1` if dropped |
| `entries()` | Copy of scores, highest first |

## ScoreStore

Text persistence (`engine/score_store.gd`). **Exception:** this type may use `FileAccess` / `DirAccess`. Game `sim/` and other headless rule types must not.

Format: first line exactly `gg-highscores 1`, then one non-negative integer per line.

| API | Behavior |
|-----|----------|
| `load(path, capacity)` | Missing, corrupt, or IO failure → empty `HighScoreTable` of that capacity |
| `save(path, table)` | Ensures parent dir, writes `path.tmp`, renames into place; returns `false` on failure |

Snake uses `user://scores/snake.txt` with capacity `10`.
