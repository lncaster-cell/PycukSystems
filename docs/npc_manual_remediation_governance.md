# Ambient Life V3 Manual Remediation Governance

Операторский документ для ручной фазы rollout после audit + execution.

## 1) Запуск backlog generator

```bash
python3 scripts/generate_npc_remediation_backlog.py \
  --repo-root . \
  --readiness-json docs/reports/npc_rollout_readiness_report.json \
  --execution-json docs/reports/npc_migration_execution_report.json \
  --exception-registry docs/npc_migration_exception_registry.json \
  --backlog-json docs/reports/npc_remediation_backlog_report.json \
  --backlog-md docs/reports/npc_remediation_backlog_report.md
```

## 2) Remediation categories

- `HOOK-WIRING`: noncanonical hook scripts/wiring.
- `LEGACY-UNSUPPORTED`: `al_*` вне bridge subset.
- `AMBIGUOUS-ROUTE`: route/anchor ambiguity, требующая ручного решения.
- `RUNTIME-PROTECTED`: helper намеренно не трогает path.
- `CONFLICTED-CONFIG`: смешанные несовместимые старые/новые паттерны.
- `DOC/CONTRACT-DRIFT`: дрейф относительно canonical contract.

## 3) Priority rules

- **P1**: блокеры rollout/canonical runtime (`HOOK-WIRING`, `CONFLICTED-CONFIG`, contract drift, unsupported legacy в MANUAL/CONFLICTED).
- **P2**: workaround/fallback cases (`AMBIGUOUS-ROUTE`, большинство `RUNTIME-PROTECTED`, unsupported legacy вне критических tier).
- **P3**: отложимые noncritical protected cases.

## 4) Exception registry

Файл: `docs/npc_migration_exception_registry.json`

Правила:
- каждое исключение должно иметь `id`, `path_pattern`, `category`, `status`, `rationale`;
- `status=active` только для временно разрешённых кейсов;
- закрытые исключения переводить в `status=closed`, не удалять историю без причины;
- exception registry не заменяет remediation: это governance-маркер, а не silent ignore.

## 5) Как закрывать backlog партиями

1. Сортируем backlog по `P1 -> P2 -> P3`.
2. Внутри приоритета группируем по category.
3. Исправляем batch-ами по owner/path-domain.
4. После каждой партии:
   - rerun readiness audit,
   - rerun batch migration helper,
   - rerun backlog generator,
   - сверяем уменьшение `open_cases`.

## 6) Decision policy (rewrite / bridge extension / exception)

- **Rewrite в canonical**: default для `HOOK-WIRING`, `CONFLICTED-CONFIG`, `LEGACY-UNSUPPORTED`.
- **Bridge extension**: только при повторяющемся реальном кейсе + отдельный контрактный тест.
- **Temporary exception**: только если сейчас менять рискованно/дорого, с owner и явной rationale.


## 7) P1 HOOK-WIRING closure rule

- `P1` кейсы категории `HOOK-WIRING` не должны оставаться в `OPEN`.
- Для каждого такого кейса допустимо только: 
  1) canonical fix, либо
  2) явный `EXCEPTION` в `docs/npc_migration_exception_registry.json` с rationale и owner.


## 8) Handover в launch phase

После стабилизации remediation/backlog переходите к final launch-gate: `docs/npc_go_live_checklist.md` и `docs/npc_pilot_rollout_runbook.md`.
