# NPC Behavior Module: пошаговая настройка и FAQ

Документ описывает **практическую настройку** `src/modules/npc` в модуле NWN2 и частые операционные вопросы.

## 1) Быстрый scope

Модуль поведения NPC состоит из:
- thin-entrypoint скриптов `npc_*.nss`;
- единого фасада `npc_core.nss`;
- include-подсистем (lifecycle/queue/activity/metrics/LOD/runtime modes).

Цель настройки — подключить hooks, проверить контракты и зафиксировать рабочий baseline перед rollout.

## 2) Пошаговая настройка

### Шаг 1. Подключите event hooks к `npc_*.nss`

В toolset должны быть привязаны канонические entrypoints:
- `OnModuleLoad` -> `npc_module_load`
- `OnSpawn` -> `npc_spawn`
- `OnPerception` -> `npc_perception`
- `OnDamaged` -> `npc_damaged`
- `OnDeath` -> `npc_death`
- `OnDialogue` -> `npc_dialogue`
- `OnAreaEnter` -> `npc_area_enter`
- `OnAreaExit` -> `npc_area_exit`
- `OnHeartbeat/area tick dispatcher` -> `npc_area_tick`
- maintenance watchdog -> `npc_area_maintenance`

> Все перечисленные файлы должны оставаться thin-wrapper (только include `npc_core` и проксирование в `NpcBhvrOn*`).

### Шаг 2. Проверьте include-контур

Убедитесь, что `npc_core` доступен компилятору и в сборку входят include-файлы из `src/modules/npc`.

Минимальный smoke-компиляторный прогон:

```bash
bash scripts/compile.sh
```

### Шаг 3. Настройте authoring только через human-facing ключи

Для новых NPC используйте:
- `npc_cfg_role`
- `npc_cfg_identity_type`
- `npc_cfg_slot_dawn_route`
- `npc_cfg_slot_morning_route`
- `npc_cfg_slot_afternoon_route`
- `npc_cfg_slot_evening_route`
- `npc_cfg_slot_night_route`
- (опционально) `npc_cfg_alert_route`, `npc_cfg_force_reactive`, `npc_cfg_allow_physical_hide`

Legacy/low-level runtime ключи считаются compatibility-слоем, а не основным authoring-путём.

### Шаг 4. Включите lifecycle и dispatch режимы на area/module уровне

Проверьте, что runtime может читать:
- lifecycle state (`RUNNING/PAUSED/STOPPED`);
- dispatch mode (`AMBIENT_ONLY/HYBRID/REACTIVE_ONLY`);
- tick budgets (`npc_cfg_tick_max_events`, `npc_cfg_tick_soft_budget_ms`).

Рекомендуемый старт: оставить defaults, затем тюнить по метрикам degraded mode и queue pressure.

### Шаг 5. Прогоните обязательные проверки

```bash
bash scripts/test_npc_smoke.sh
bash scripts/check_npc_lifecycle_contract.sh
bash scripts/check_npc_legacy_compat_contract.sh
bash scripts/test_npc_activity_contract.sh
bash scripts/test_npc_fairness.sh
```

Если используется readiness-контур, дополнительно:

```bash
python3 scripts/audit_npc_rollout_readiness.py --repo-root . --scan src
bash scripts/test_npc_rollout_readiness_contract.sh
```

### Шаг 6. Зафиксируйте эксплуатационные артефакты

После успешных прогонов обновите:
- `docs/reports/npc_rollout_readiness_report.{json,md}`;
- `docs/perf/reports/npc_gate_summary_latest.md`;
- `docs/perf/npc_baseline_report.md` (при изменении perf-профиля).

## 3) Мини-чеклист перед pilot/go-live

- Hooks подключены и не переопределены сторонними скриптами.
- Area lifecycle переключается корректно (`RUNNING/PAUSED/STOPPED`).
- Очередь не уходит в постоянный overflow/degraded mode.
- Валидация route/tag проходит без массовых fallback-инцидентов.
- LOD/hidden режимы не ломают реактивный combat-путь.

## 4) FAQ

### Q1: Где основная точка входа в логику NPC?
`npc_core.nss`. Все `npc_*.nss` entrypoints должны быть thin-wrapper и вызывать только `NpcBhvrOn*` API.

### Q2: Что важнее для новых контент-авторов — schedule windows или slot routes?
Slot routes. Schedule windows и legacy semantic slots — compatibility-слой, не канонический authoring-путь.

### Q3: Можно ли отключить `OnPerception`/`OnDamaged` для мирных NPC?
Да. Для ambient-layer это допустимо: reactive hooks обязательны только для reactive-flow.

### Q4: Как понять, что сервер не справляется с нагрузкой NPC?
Смотрите метрики деградации: `npc_tick_degraded_mode`, `npc_tick_budget_exceeded_total`, `npc_queue_pending_total`, `npc_queue_deferred_total`, а также dropped/overflow показатели.

### Q5: Почему NPC «замирают» при пустых областях?
Это ожидаемо: lifecycle переводит area в `PAUSED/STOPPED`, чтобы снизить стоимость idle-симуляции без игроков.

### Q6: Что делать, если route/profile указан с ошибкой?
Runtime применит детерминированный fallback (`default_route`, `default`), но контент стоит исправить, чтобы не терять ожидаемый сценарий поведения.

### Q7: Когда использовать physical hide?
Только как opt-in (`npc_cfg_lod_physical_hide_enabled` + per-NPC allow). Базовый источник истины остаётся logical projection.

### Q8: Какие документы читать после этого FAQ?
1. `docs/npc_behavior_audit.md` — полная карта подсистем и рисков.
2. `docs/npc_runtime_orchestration.md` — lifecycle/tick оркестрация.
3. `docs/npc_toolset_authoring_contract.md` — authoring для контент-команд.
