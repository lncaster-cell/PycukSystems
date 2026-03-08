# Roadmap Area Modes (Ambient Life)

Обновлено: 2026-03-07

## Статус реализации

| Этап | Статус | Комментарий |
|---|---|---|
| Базовый enum и area-mode контракт | ✅ Done | Реализовано в `al_area_constants_inc` и `al_area_mode_contract_inc` |
| HOT wake / COLD freeze lifecycle | ✅ Done | Реализовано в `al_area_onenter`, `al_area_onexit`, `al_mod_onleave`, `al_npc_reg_inc` |
| WARM как соседний soft-heat | ✅ Done | One-hop прогрев с clamp до `WARM` |
| Interior whitelist | ✅ Done | `al_adj_interior_whitelist` проверяется в контракте |
| Reason-tracking и transition history | ⏳ Planned | Пока нет отдельных locals для reason/prev/changed_ts |
| Нагрузочная телеметрия fallback-веток | ⏳ Planned | Нужны counters по area |

## Приоритеты на следующий цикл

### P1 — наблюдаемость

1. Добавить area counters:
   - `al_metric_route_resync_count`
   - `al_metric_activity_fallback_count`
   - `al_metric_route_truncated_count`
2. Добавить debug summary по counters раз в N тиков.

### P2 — content validation

1. Пререлизный валидатор:
   - наличие `alwp*` на AL-NPC;
   - валидность `al_activity` на route-points;
   - целостность transition metadata.
2. Репорт с приоритезацией ошибок (critical/warning/info).

### P3 — perf и масштабирование

1. Профилировать шум `AL_EVT_ROUTE_REPEAT` на массовых сценах.
2. Для тяжёлых area вводить profile-контроль частоты repeat.
3. Подготовить рекомендации по route-длине и плотности AL-NPC.

## Non-goals (чего не делаем сейчас)

- Глобальный world-scheduler.
- Автоматическое каскадирование heat на несколько hops.
- Сложная ownership-модель кварталов в рантайме.

## Definition of Done для будущих задач

Задача по area modes считается завершённой, если:

1. есть код + документация;
2. есть smoke-checklist в QA документе;
3. в debug-режиме можно наблюдать ключевые переходы;
4. поведение совместимо с текущим slot-driven циклом AL.
