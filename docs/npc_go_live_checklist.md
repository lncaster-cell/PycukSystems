# Ambient Life V3 Final Go-Live Checklist

Операторский checklist перед запуском pilot rollout.

## A. Mandatory gates (must be green)

- [ ] `bash scripts/test_npc_smoke.sh` — зелёный smoke/contracts baseline.
- [ ] `bash scripts/test_npc_final_pilot_readiness_contract.sh` — финальный pilot-ready gate зелёный.
- [ ] `docs/reports/npc_rollout_readiness_report.json` актуален (перегенерирован после последних изменений).
- [ ] `docs/reports/npc_migration_execution_report.json` актуален и dry-run/apply path проверен.
- [ ] `docs/reports/npc_remediation_backlog_report.json` не содержит `OPEN/P1`.
- [ ] `docs/npc_migration_exception_registry.json` актуален: все active exceptions с owner+rationale.
- [ ] Canonical contract фиксирован: `docs/npc_toolset_authoring_contract.md`.

## B. Pilot scope readiness

- [ ] Pilot subset определён явными path-patterns.
- [ ] Pilot subset в readiness находится только в `READY/BRIDGEABLE`.
- [ ] Dry-run для pilot subset выполнен и review-нут.
- [ ] Apply plan для pilot subset согласован.

## C. Rollback / containment readiness

- [ ] Понятен rollback path (git revert/cherry-pick rollback commit для pilot партии).
- [ ] Confirmed: остальной контент не затрагивается pilot-партией.
- [ ] Если выявлена проблема: кейс уходит в backlog/exception с owner и причиной.

## D. Stop/Go decision

GO разрешён, когда одновременно:
- нет `OPEN/P1`;
- smoke/contracts зелёные;
- pilot subset `READY/BRIDGEABLE`;
- audit/execution/backlog отчёты консистентны;
- exceptions только осознанные и non-blocking.

STOP обязателен, если:
- любой smoke/contract regression;
- новые `OPEN/P1` после regeneration;
- pilot scope получил unsafe tier (`MANUAL/CONFLICTED/FALLBACK-RISK`) без planned handling;
- drift между readiness/execution/backlog;
- runtime-risk regression в pilot verification.
