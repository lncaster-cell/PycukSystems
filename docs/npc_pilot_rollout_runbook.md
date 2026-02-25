# Ambient Life V3 Pilot Rollout Runbook

Пошаговый runbook для первой боевой pilot-партии.

## 1) Выбор pilot subset

Рекомендуемый стартовый scope:
- `src/integrations/nwnx_sqlite/*`

Вы можете выбрать другой subset, но он должен быть явно задан паттернами пути.

## 2) Baseline validation

```bash
bash scripts/test_npc_smoke.sh
```

## 3) Readiness audit (pilot visibility)

```bash
python3 scripts/audit_npc_rollout_readiness.py \
  --repo-root . \
  --scan src \
  --json-out docs/reports/npc_rollout_readiness_report.json \
  --md-out docs/reports/npc_rollout_readiness_report.md
```

Проверить, что pilot paths находятся в `READY/BRIDGEABLE`.

## 4) Execution helper dry-run on pilot scope

```bash
python3 scripts/run_npc_batch_migration.py \
  --repo-root . \
  --tier READY \
  --tier BRIDGEABLE \
  --include-path 'src/integrations/nwnx_sqlite/*' \
  --execution-json docs/reports/npc_migration_execution_report.json \
  --execution-md docs/reports/npc_migration_execution_report.md
```

## 5) Apply for pilot scope

```bash
python3 scripts/run_npc_batch_migration.py \
  --repo-root . \
  --tier READY \
  --tier BRIDGEABLE \
  --include-path 'src/integrations/nwnx_sqlite/*' \
  --apply \
  --execution-json docs/reports/npc_migration_execution_report.json \
  --execution-md docs/reports/npc_migration_execution_report.md
```

## 6) Regenerate governance reports after pilot

```bash
python3 scripts/generate_npc_remediation_backlog.py \
  --repo-root . \
  --readiness-json docs/reports/npc_rollout_readiness_report.json \
  --execution-json docs/reports/npc_migration_execution_report.json \
  --exception-registry docs/npc_migration_exception_registry.json \
  --backlog-json docs/reports/npc_remediation_backlog_report.json \
  --backlog-md docs/reports/npc_remediation_backlog_report.md
```

## 7) Final pilot-ready decision artifact

```bash
bash scripts/test_npc_final_pilot_readiness_contract.sh
```

или объединённым pipeline:

```bash
bash scripts/test_npc_final_readiness_pipeline.sh
```

## 8) Expand to next batch only if

- pilot не создал новых `OPEN/P1`;
- нет smoke regression;
- launch-readiness report даёт `GO`;
- новые exceptions не блокирующие и обоснованы.

## 9) Rollback / containment guidance

Если pilot выявил проблему:

1. Остановить расширение rollout (STOP).
2. Откатить pilot commit(s):
   - `git revert <pilot_commit_sha>` (или серию pilot-коммитов).
3. Перегенерировать readiness/execution/backlog/launch reports.
4. Зафиксировать кейс:
   - в backlog как remediation item, и/или
   - в exception registry как временное исключение с owner+rationale.
5. Повторный pilot запуск только после возврата в состояние:
   - smoke green,
   - no OPEN/P1,
   - обновлённый launch-readiness verdict `GO`.
