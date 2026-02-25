# Ambient Life V3 — Human-facing authoring contract

Этот документ — **канонический практический контракт для контентщика**: какие locals ставить вручную в toolset.

> Внутренний runtime-справочник (`npc_*`, cluster/LOD/tick internals, legacy bridge subset) вынесен в `docs/npc_runtime_internal_contract.md`.

## 1) Hook scripts (обязательная привязка)

- Module OnLoad: `npc_module_load`
- Area OnEnter / OnExit: `npc_area_enter` / `npc_area_exit`
- Area tick/maintenance: `npc_area_tick`, `npc_area_maintenance`
- Creature hooks:
  - OnSpawn: `npc_spawn`
  - OnPerception: `npc_perception` (если нужен reactive-path)
  - OnDamaged: `npc_damaged` (если нужен reactive-path)
  - OnDeath: `npc_death`
  - OnDialogue: `npc_dialogue`

## 2) NPC authoring locals (канонический путь)

### Обязательные

- `npc_cfg_role`
- `npc_cfg_slot_dawn_route`
- `npc_cfg_slot_morning_route`
- `npc_cfg_slot_afternoon_route`
- `npc_cfg_slot_evening_route`
- `npc_cfg_slot_night_route`

### Опциональные

- `npc_cfg_force_reactive` (`0/1`) — **единственный канонический human-facing override** для reactive-пути
- `npc_cfg_allow_physical_hide` (`0/1`)
- `npc_cfg_alert_route` (отдельный route только для режима `alert`)

### Preset values

**Role presets:**
- `citizen`
- `worker`
- `merchant`
- `guard`
- `innkeeper`
- `static`

## 3) Area authoring locals (ставятся вручную)

### Минимум

- `npc_cfg_city`
- `npc_cfg_cluster`
- `npc_cfg_area_profile`

### Preset values (`npc_cfg_area_profile`)

- `city_exterior`
- `shop_interior`
- `house_interior`
- `tavern`
- `guard_post`

Из `npc_cfg_area_profile` фасад автоматически выставляет runtime defaults (dispatch/lifecycle/LOD/hide/cluster tuning), если низкоуровневые ключи не заданы явно.

## 4) Каноническая модель поведения

Каноническая цепочка authoring/runtime:

`slot (time-of-day) -> route of this slot -> waypoint -> activity`

- Слот выбирается по времени суток.
- Для каждого slot берётся route из `npc_cfg_slot_*_route` (через фасад в `npc_route_profile_slot_*`).
- Дальше применяется waypoint/route-point логика.
- `activity` берётся только с waypoint (`npc_route_activity_<route>_<idx>`): slot **не** задаёт activity напрямую.

## 5) Режимы поведения

Поддерживаются только два режима:

- `daily` — обычная slot-модель (`slot -> route -> waypoint -> activity`).
- `alert` — служебный временный override.

Если задан `npc_cfg_alert_route`, он используется как route override для `alert`; иначе остаётся обычный slot fallback.

## 6) Как работает facade

Пайплайн:

`npc_cfg_* authoring -> facade normalization/derived config -> существующий npc_* runtime`

- Внутренние `npc_*` locals **не удалены** и остаются runtime truth.
- Основной ручной интерфейс — slot-route locals + role/area profile.
- Role (`npc_cfg_role`) остаётся archetype/default-policy (ambient/reactive/hide), но больше не является скрытым расписанием.
- Низкоуровневые ручки (`npc_dispatch_mode`, `npc_runtime_layer`, `npc_cfg_layer`, `npc_cfg_reactive`, `npc_npc_sim_lod`, runtime counters/diagnostics locals) — internal/runtime-only и не считаются каноническим authoring-путём.
- Если низкоуровневые `npc_*` уже заданы явно, фасад не перетирает их «в лоб».

## 7) Legacy / compatibility path (deprecated)

Старый пресетный путь сохранён только для совместимости и миграций:

- `npc_cfg_schedule`
- `npc_cfg_work_route`
- `npc_cfg_home_route`
- `npc_cfg_leisure_route`

Legacy schedule presets (`day_worker`, `day_shop`, `night_guard`, `tavern_late`, `always_home`, `always_static`, `custom`) считаются **secondary/deprecated authoring path** и не являются канонической моделью для нового контента.
`custom` остаётся только как deprecated compatibility-вариант (ограниченный fallback до `npc_route_profile_default`), а не как свободный escape hatch для произвольных runtime locals.

## 8) Пример (канонический)

### Кузнец (slot-маршруты)

NPC:
- `npc_cfg_role=worker`
- `npc_cfg_slot_dawn_route=smith_home_loop`
- `npc_cfg_slot_morning_route=smith_work_loop`
- `npc_cfg_slot_afternoon_route=smith_work_loop`
- `npc_cfg_slot_evening_route=market_evening_walk`
- `npc_cfg_slot_night_route=smith_home_loop`

Area (улица):
- `npc_cfg_city=neverwinter`
- `npc_cfg_cluster=blacklake`
- `npc_cfg_area_profile=city_exterior`
