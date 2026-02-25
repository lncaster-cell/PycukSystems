# Ambient Life V3 Batch Migration Execution (Phased Rollout)

Рабочий документ для поэтапного migration execution поверх readiness-аудита.

## 1) Базовый принцип

- Автоматизируем только безопасный scope: `READY` и `BRIDGEABLE`.
- `MANUAL` / `CONFLICTED` не автоправятся.
- При сомнении — **safe skip** + диагностика в execution report.

## 2) Команды запуска

### 2.1 Dry-run (только READY)

```bash
python3 scripts/run_npc_batch_migration.py \
  --repo-root . \
  --tier READY
```

### 2.2 Dry-run (READY + BRIDGEABLE)

```bash
python3 scripts/run_npc_batch_migration.py \
  --repo-root . \
  --tier READY \
  --tier BRIDGEABLE
```

### 2.3 Apply (READY + BRIDGEABLE)

```bash
python3 scripts/run_npc_batch_migration.py \
  --repo-root . \
  --tier READY \
  --tier BRIDGEABLE \
  --apply
```

### 2.4 Частичная партия по path-фильтру

```bash
python3 scripts/run_npc_batch_migration.py \
  --repo-root . \
  --tier BRIDGEABLE \
  --include-path 'src/content/*' \
  --limit 20 \
  --apply
```

## 3) Что делает helper

- Читает readiness report (`docs/reports/npc_rollout_readiness_report.json`).
- Берёт кандидатов по выбранным tiers.
- Для safe-кейсов нормализует поддержанные `al_*` ключи в canonical `npc_*`.
- Генерирует execution report:
  - `docs/reports/npc_migration_execution_report.json`
  - `docs/reports/npc_migration_execution_report.md`

## 4) Safeguards

- Нет `--apply` → изменений на диске нет (dry-run).
- `MANUAL/CONFLICTED` автоправкой не обрабатываются.
- Unsupported/ambiguous legacy patterns → safe skip.
- Защищённые runtime пути (`src/modules/npc/*`, `src/modules/module_skeleton/*`, `src/controllers/*`) не переписываются helper-ом.
- Повторный запуск идемпотентен: уже нормализованные файлы не меняются повторно.

## 5) Как читать execution report

Ключевые поля summary:
- `candidates_total`
- `changed_files`
- `already_canonical`
- `manual_conflicted_skips`
- `safe_skips`
- `bridge_conversions`

Рекомендуемый порядок rollout:
1. dry-run на нужной партии;
2. review отчёта;
3. apply на той же партии;
4. повторный dry-run (должен показывать 0 новых применимых изменений для уже обработанного батча).

## 6) Когда auto-migrate достаточно, а когда нужен manual rewrite

Auto-migrate достаточно, когда:
- tier в `READY` или `BRIDGEABLE`;
- нет unsupported/ambiguous legacy сигналов;
- report не показывает risky/manual/conflicted причины.

Нужен manual rewrite, когда:
- `MANUAL` или `CONFLICTED`;
- есть unsupported `al_*` patterns;
- есть смешанный noncanonical wiring, который helper помечает skip-ом.
