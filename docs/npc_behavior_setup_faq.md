# NPC Behavior Module: builder guide (пошаговая настройка + полный FAQ)

Документ для билдера/контентщика, который впервые подключает `src/modules/npc` в свой toolset.

> Важно: это **практический гайд**. Канонический человеко-ориентированный контракт: `docs/npc_toolset_authoring_contract.md`. Runtime/internal справочник: `docs/npc_runtime_internal_contract.md`.

---

## 1) Быстрый старт за 10 минут

1. Назначьте hook-скрипты (см. раздел 2).
2. На каждой area задайте минимум: `npc_cfg_city`, `npc_cfg_cluster`, `npc_cfg_area_profile`.
3. На каждом NPC задайте минимум: `npc_cfg_role` + `npc_cfg_slot_*_route`.
4. Проверьте, что маршруты/вейпоинты заведены (см. раздел 5).
5. Запустите контракты:

```bash
bash scripts/test_npc_smoke.sh
bash scripts/check_npc_lifecycle_contract.sh
bash scripts/test_npc_activity_contract.sh
```

Если эти шаги зелёные — система обычно готова к первому пилоту.

---

## 2) Куда назначить скрипты в toolset

Это самый частый вопрос билдера. Ниже каноническая карта привязки.

### Module

- `OnModuleLoad` -> `npc_module_load`

### Area

- `OnEnter` -> `npc_area_enter`
- `OnExit` -> `npc_area_exit`
- `OnHeartbeat` (или ваш area tick dispatcher) -> `npc_area_tick`
- maintenance/watchdog -> `npc_area_maintenance`

### Creature (NPC)

- `OnSpawn` -> `npc_spawn`
- `OnPerception` -> `npc_perception` *(если нужен reactive-path)*
- `OnDamaged` -> `npc_damaged` *(если нужен reactive-path)*
- `OnDeath` -> `npc_death`
- `OnDialogue` -> `npc_dialogue`

> Все `npc_*.nss` остаются thin-wrapper: include `npc_core` + вызов `NpcBhvrOn*`.

---

## 3) Какие локальные переменные ставить на NPC

Ниже — практический набор, с которого нужно начинать.

### 3.1 Обязательные NPC locals (канонический authoring)

- `npc_cfg_role`
- `npc_cfg_slot_dawn_route`
- `npc_cfg_slot_morning_route`
- `npc_cfg_slot_afternoon_route`
- `npc_cfg_slot_evening_route`
- `npc_cfg_slot_night_route`

### 3.2 Рекомендуемые/опциональные NPC locals

- `npc_cfg_identity_type` = `named|commoner`
- `npc_cfg_alert_route` — отдельный маршрут для alert-режима
- `npc_cfg_force_reactive` = `0|1`
- `npc_cfg_allow_physical_hide` = `0|1`

### 3.3 Что НЕ использовать как primary authoring

Для новых NPC не делайте ставку на:
- legacy schedule-путь (`npc_cfg_schedule`, work/home/leisure);
- semantic legacy slot-модель (`default|priority|critical`);
- low-level runtime locals как ручной UI контентщика.

---

## 4) Какие локальные переменные ставить на область (Area)

### 4.1 Минимум, который нужен всегда

- `npc_cfg_city`
- `npc_cfg_cluster`
- `npc_cfg_area_profile`

`npc_cfg_area_profile` пресеты:
- `city_exterior`
- `shop_interior`
- `house_interior`
- `tavern`
- `guard_post`

### 4.2 Когда нужны area runtime knobs

Обычно не нужны на первом запуске. Используйте только при тюнинге после метрик.

Чаще всего применяют:
- `npc_cfg_tick_max_events`
- `npc_cfg_tick_soft_budget_ms`
- LOD/cluster knobs из `docs/npc_runtime_internal_contract.md`

---

## 5) Какие локальные переменные ставить на вейпоинты

В этой системе builder обычно работает не «локалами вейпоинта», а **route-структурой на NPC/Area**.

### Каноническая route/waypoint модель

Для каждого route используются ключи:
- `npc_route_count_<route>` — количество waypoint-точек маршрута
- `npc_route_loop_<route>` — loop policy (`0|1`)
- `npc_route_tag_<route>` — route-tag
- `npc_route_pause_ticks_<route>` — пауза между шагами
- `npc_route_activity_<route>_<idx>` — activity на конкретной waypoint-фазе

Т.е. фактическая привязка поведения к waypoint делается через `<route> + <idx>` и `npc_route_activity_*`, а не через «случайные кастомные локалы» на объекте waypoint.

### Практический совет

- Сначала стабильно задайте `npc_cfg_slot_*_route`.
- Затем наполните route-профили `npc_route_*`.
- Проверяйте `npc_activity_route_effective` и `npc_activity_wp_index` в runtime для дебага.

---

## 6) Пошаговая настройка (расширенный runbook)

### Шаг 1. Hook wiring

Назначьте скрипты строго по разделу 2.

### Шаг 2. Базовая конфигурация area

На каждой рабочей area проставьте:
- `npc_cfg_city`
- `npc_cfg_cluster`
- `npc_cfg_area_profile`

### Шаг 3. Базовая конфигурация NPC

На каждом NPC проставьте:
- `npc_cfg_role`
- `npc_cfg_slot_*_route` на все 5 daypart-слотов
- опционально `npc_cfg_identity_type`, `npc_cfg_alert_route`

### Шаг 4. Маршруты/waypoint-фазы

Опишите route runtime locals (`npc_route_count_*`, `npc_route_tag_*`, `npc_route_activity_*`).

### Шаг 5. Reactive-path (при необходимости)

Если NPC должен реагировать на угрозы/урон:
- включите hooks `npc_perception` и `npc_damaged`;
- при необходимости задайте `npc_cfg_force_reactive=1`.

### Шаг 6. Тесты/контракты

```bash
bash scripts/test_npc_smoke.sh
bash scripts/check_npc_lifecycle_contract.sh
bash scripts/check_npc_legacy_compat_contract.sh
bash scripts/test_npc_activity_contract.sh
bash scripts/test_npc_fairness.sh
```

Readiness-контур (опционально):

```bash
python3 scripts/audit_npc_rollout_readiness.py --repo-root . --scan src
bash scripts/test_npc_rollout_readiness_contract.sh
```

### Шаг 7. Эксплуатационные артефакты

После изменений обновляйте:
- `docs/reports/npc_rollout_readiness_report.{json,md}`
- `docs/perf/reports/npc_gate_summary_latest.md`
- `docs/perf/npc_baseline_report.md` (если менялся perf-профиль)

---

## 7) Полный FAQ для билдера

### Q1. Какие локальные переменные вешать на NPC в первую очередь?
`npc_cfg_role` и пять `npc_cfg_slot_*_route` — это минимальный рабочий набор.

### Q2. Какие локальные переменные нужны на Area?
`npc_cfg_city`, `npc_cfg_cluster`, `npc_cfg_area_profile`.

### Q3. Какие локальные переменные нужны на Waypoint?
В каноническом контракте ключевые данные задаются route-локалами `npc_route_*` (count/tag/loop/pause/activity), а не custom-локалами вейпоинта.

### Q4. Куда назначить скрипты?
См. раздел 2: отдельно для Module, Area и Creature hooks. Это обязательная карта wiring.

### Q5. Можно ли использовать только часть скриптов?
Минимум — module load + area enter/exit + area tick/maintenance + npc spawn/death/dialogue. Reactive hooks (`perception`, `damaged`) подключайте когда нужен reactive-flow.

### Q6. Какой режим поведения у NPC основной?
`daily`: слот времени суток -> route -> waypoint-фаза -> activity.

### Q7. Когда используется alert-route?
Когда `npc_activity_mode=alert`; сначала ищется `npc_cfg_alert_route` / `npc_route_profile_alert`.

### Q8. Что будет при ошибке в route/tag?
Сработает deterministic fallback (`default_route`, `default`), но контент нужно исправить.

### Q9. Почему NPC могут «успокаиваться» в пустой области?
Это норма: lifecycle переводит area в экономичные состояния `PAUSED/STOPPED`.

### Q10. Как понять, что budgets слишком агрессивные?
Если растут `npc_tick_degraded_mode`, `npc_tick_budget_exceeded_total`, backlog/deferred/dropped — увеличивайте budgets аккуратно и проверяйте fairness.

### Q11. Где смотреть, какой route реально применяется?
В runtime-полях вроде `npc_activity_route_effective` и `npc_activity_slot_effective`.

### Q12. Можно ли сразу крутить low-level knobs?
Можно, но не рекомендуется для старта. Сначала canonical `npc_cfg_*`, потом целевой тюнинг по метрикам.

### Q13. Как не ошибиться новичку в проекте?
Следуйте ровно этому порядку:
1) hook wiring,
2) area минимум,
3) NPC минимум,
4) route/waypoint,
5) тесты,
6) только потом оптимизация.

---

## 8) Чеклист «builder-ready» перед передачей контента

- [ ] Hook scripts назначены корректно на Module/Area/Creature.
- [ ] На area есть `npc_cfg_city`, `npc_cfg_cluster`, `npc_cfg_area_profile`.
- [ ] На NPC есть `npc_cfg_role` + пять `npc_cfg_slot_*_route`.
- [ ] Route keys `npc_route_*` заполнены валидно.
- [ ] Reactive hooks включены только где нужны.
- [ ] Smoke/contracts зелёные.
- [ ] Нет массовых fallback/degraded инцидентов в метриках.

---

## 9) Связанные документы

1. `docs/npc_toolset_authoring_contract.md` — канонический human-facing контракт.
2. `docs/npc_runtime_internal_contract.md` — runtime/internal справочник.
3. `docs/npc_runtime_orchestration.md` — lifecycle/tick orchestration.
4. `docs/npc_behavior_audit.md` — системный аудит, риски, рекомендации.
