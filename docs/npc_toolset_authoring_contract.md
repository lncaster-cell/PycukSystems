# Ambient Life V3 — Human-facing authoring contract

Этот документ — **практический контракт для контентщика**: какие locals ставить вручную в toolset.

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

## 2) NPC authoring locals (ставятся вручную)

### Обязательные

- `npc_cfg_role`
- `npc_cfg_schedule`
- `npc_cfg_work_route`
- `npc_cfg_home_route`

### Опциональные

- `npc_cfg_leisure_route`
- `npc_cfg_force_reactive` (`0/1`)
- `npc_cfg_allow_physical_hide` (`0/1`)

### Preset values

**Role presets:**
- `citizen`
- `worker`
- `merchant`
- `guard`
- `innkeeper`
- `static`

**Schedule presets:**
- `day_worker`
- `day_shop`
- `night_guard`
- `tavern_late`
- `always_home`
- `always_static`
- `custom` (escape hatch: ручной контроль schedule/runtime locals)

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

## 4) Waypoint/route authoring

- Используется существующий `npc_route_*` keyspace (`count/loop/tag/activity/pause`).
- Route id/tag: `[a-z0-9_]`, как и раньше.
- `npc_cfg_work_route|home_route|leisure_route` задают пресетный маршрутный каркас, а runtime разворачивает это в `npc_activity_*` + route-profile locals.

## 5) Как работает facade

Пайплайн:

`npc_cfg_* authoring -> facade normalization/derived config -> существующий npc_* runtime`

- Внутренние `npc_*` locals **не удалены** и остаются runtime truth.
- Но они больше не являются основным ручным интерфейсом.
- Если низкоуровневые `npc_*` уже заданы явно, фасад не перетирает их «в лоб».

## 6) Примеры

### Кузнец (дневной рабочий)

NPC:
- `npc_cfg_role=worker`
- `npc_cfg_schedule=day_worker`
- `npc_cfg_work_route=smith_work_loop`
- `npc_cfg_home_route=smith_home_loop`
- `npc_cfg_leisure_route=market_evening_walk`

Area (улица):
- `npc_cfg_city=neverwinter`
- `npc_cfg_cluster=blacklake`
- `npc_cfg_area_profile=city_exterior`

### Стражник (ночной)

NPC:
- `npc_cfg_role=guard`
- `npc_cfg_schedule=night_guard`
- `npc_cfg_work_route=north_gate_patrol`
- `npc_cfg_home_route=guard_barracks`
- `npc_cfg_force_reactive=1`

Area (пост):
- `npc_cfg_city=neverwinter`
- `npc_cfg_cluster=north_gate`
- `npc_cfg_area_profile=guard_post`

### Торговец (лавка)

NPC:
- `npc_cfg_role=merchant`
- `npc_cfg_schedule=day_shop`
- `npc_cfg_work_route=shop_counter_loop`
- `npc_cfg_home_route=merchant_home`

Area (интерьер лавки):
- `npc_cfg_city=neverwinter`
- `npc_cfg_cluster=market_square`
- `npc_cfg_area_profile=shop_interior`
