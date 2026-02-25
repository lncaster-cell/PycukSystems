# Ambient Life V3 Rollout Readiness Checklist

Практический чеклист по поэтапному rollout на реальный контент.

## 1) Запуск readiness audit

```bash
python3 scripts/audit_npc_rollout_readiness.py \
  --repo-root . \
  --scan src \
  --json-out docs/reports/npc_rollout_readiness_report.json \
  --md-out docs/reports/npc_rollout_readiness_report.md
```

> Источник истины по wiring/hook setup: `docs/npc_toolset_authoring_contract.md`.

## 2) Как читать tiers

- **READY** — контент уже использует canonical `npc_*` и не содержит legacy риска.
- **BRIDGEABLE** — найден только поддержанный bridge subset `al_*`; возможна контролируемая миграция через bridge.
- **FALLBACK-RISK** — обнаружены ambiguous legacy patterns (например, нестандартные `al_route_*`), возможен controlled fallback.
- **MANUAL** — есть unsupported `al_*`/неканонический hook-wiring, нужен ручной фикс.
- **CONFLICTED** — смешаны несовместимые паттерны (новые/старые) без явной migration policy.

## 3) Phased adoption path

1. **READY**
   - Переводить первыми (минимальный риск).
2. **BRIDGEABLE**
   - Включать следующей волной.
   - Контролировать метрики bridge/fallback.
3. **FALLBACK-RISK**
   - Разбирать пачками, убирать ambiguous legacy ключи.
   - Перед включением в прод — снижать до BRIDGEABLE/READY.
4. **MANUAL / CONFLICTED**
   - Обязательная ручная переработка wiring/legacy ключей.
   - Не включать в массовый rollout без исправлений.

## 4) Когда достаточно bridge, а когда нужен rewrite

Bridge достаточно, когда:
- используются только поддержанные `al_*` ключи из canonical subset;
- отсутствуют unsupported/ambiguous legacy ключи;
- hook wiring соответствует `npc_*` contract.

Нужен rewrite/ручная миграция, когда:
- есть unsupported `al_*` ключи;
- присутствуют конфликтные комбинации old/new без policy;
- hook wiring частично legacy/vanilla и не соответствует canonical контракту.

## 5) Ошибки, требующие ручного вмешательства

- `MANUAL` и `CONFLICTED` tiers.
- Любые unsupported `al_*` ключи в отчёте.
- Неканонические hook-like скрипты в runtime (`module_load/spawn/heartbeat/...` вне canonical набора).
