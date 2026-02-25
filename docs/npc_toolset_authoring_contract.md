# Ambient Life V3 — Human-facing authoring contract

Этот документ — **практический контракт для контентщика**: какие locals ставить вручную в toolset и как NPC будет жить по смыслу.

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
- `custom` (advanced mode)

## 3) Каноническая slot-модель (human-facing)

Runtime использует 3 технических slot (`default`, `priority`, `critical`), но для авторинга модель суток фиксирована как 4 human-slots:

- **Утро (06:00–08:00)** — переход из дома к дневной активности.
- **Рабочий день (08:00–18/19:00)** — основной work/shop slot.
- **Вечер (18/19:00–22:00)** — leisure/home slot.
- **Ночь (22:00–06:00)** — rest/home либо ночной patrol для `night_guard`.

Маппинг в runtime:
- `priority` = активный рабочий/патрульный интервал.
- `critical` = “дом/безопасный якорь” (реанкор домой).
- `default` = вечерние и переходные окна (обычно leisure/home fallback).

Эта модель стабильна для preset-ов: контентщик понимает, где NPC работает, где отдыхает и где спит.

## 4) Role semantics (что означает роль)

Role задаёт **архетип** NPC (слой поведения + ожидания по маршрутам), schedule задаёт **временной профиль**.

- `citizen`
  - default layer: ambient.
  - use-case: обычные горожане.
  - expected routes: home обязательно; work/leisure по ситуации.
  - без leisure route: fallback к home, затем к work.

- `worker`
  - default layer: ambient.
  - use-case: ремесленники/работяги (днём на работе, ночью дома).
  - expected routes: work + home.
  - без leisure route: fallback к home.

- `merchant`
  - default layer: ambient.
  - use-case: лавочники (shop днём, home вечером/ночью).
  - expected routes: work(shop) + home.
  - без leisure route: fallback к home.

- `guard`
  - default layer: reactive.
  - use-case: патрули/посты, особенно ночью.
  - expected routes: work(patrol) + home/rest anchor.
  - без leisure route: fallback к work, затем home (чтобы guard не выпадал из патруля).

- `innkeeper`
  - default layer: ambient.
  - use-case: трактирщики с поздней активностью.
  - expected routes: work(tavern) + home.
  - без leisure route: fallback к work, затем home.

- `static`
  - default layer: ambient + schedule disabled by default profile.
  - use-case: декорационный/stationary NPC.
  - expected routes: любой anchor route (обычно home).
  - не участвует в обычной “живой” ротации.

## 5) Schedule semantics (что означает расписание)

Schedule определяет, какие slot считаются work/home/leisure/rest и какие fallback применяются.

- `day_worker`
  - `priority` (08:00–18:00): work.
  - `default` (остальное): home/leisure.
  - safe fallback: если work нет -> leisure -> home.
  - реанкор домой: вечер/ночь через `default` route.

- `day_shop`
  - `priority` (08:00–19:00): work(shop).
  - `default` (остальное): home.
  - safe fallback: при отсутствии work — home.
  - остаётся на work route только в дневном окне.

- `night_guard`
  - `critical` (20:00–06:00): work/night patrol.
  - `priority` (06:00–20:00): rest/home.
  - `default`: home fallback.
  - реанкор домой: дневное окно.

- `tavern_late`
  - `priority` (18:00–02:00): work/leisure tavern loop.
  - `default`: home/rest.
  - safe fallback: при отсутствии leisure — work, затем home.
  - ночью после 02:00 возвращается домой.

- `always_home`
  - schedule always-on, `critical` 00:00–23:00.
  - всегда держится на home anchor.
  - safe fallback: home -> work -> leisure.

- `always_static`
  - schedule disabled.
  - остаётся на static anchor (`home` -> `work` -> `leisure`).
  - safe fallback: safe idle, если routes не заданы.

- `custom` (advanced)
  - facade выставляет только безопасный route fallback и стартовый slot.
  - временные окна (`npc_schedule_*`) и тонкая логика — вручную.
  - для обычных NPC не рекомендуется.

## 6) Resolver role + schedule + routes

Итоговое поведение определяется связкой:

1. **role** (архетип/слой: ambient vs reactive, тип fallback для leisure).
2. **schedule** (временные окна slot).
3. **наличие route-ов** (work/home/leisure).

Примеры резолва:
- `worker + day_worker` -> work днём, home ночью.
- `merchant + day_shop` -> shop днём, home вечером/ночью.
- `guard + night_guard` -> patrol ночью, rest/home днём.
- `citizen + always_home` -> почти всегда home.
- `static + any_non_custom_schedule` -> принудительно `always_static`.

Role-aware defaults, если `npc_cfg_schedule` пуст/невалиден:
- `merchant` -> `day_shop`
- `guard` -> `night_guard`
- `innkeeper` -> `tavern_late`
- `static` -> `always_static`
- остальные -> `day_worker`

## 7) Fallback rules (простые и прозрачные)

Route fallback в фасаде:

- `home` = home -> work -> leisure
- `leisure`:
  - для `guard`/`innkeeper`: leisure -> work -> home
  - для остальных: leisure -> home -> work
- `work` = work -> leisure -> home
- static anchor = home -> work -> leisure

Если route не задан вообще, используется safe idle (NPC не уходит в хаос и не ломает runtime).

## 8) Ограничение custom как escape hatch

`custom` — это **advanced mode**, а не массовый путь.

Минимум для `custom`:
- `npc_cfg_work_route` и `npc_cfg_home_route` (чтобы были безопасные anchor’ы),
- при необходимости `npc_cfg_leisure_route`,
- вручную задать schedule locals только если действительно нужна нестандартная сетка времени.

Обычный контент-сетап (80% NPC) должен использовать готовые preset-ы role/schedule без low-level runtime locals.

## 9) Area authoring locals (ставятся вручную)

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

## 10) Практические recipes

### Кузнец (дневной worker)

NPC:
- `npc_cfg_role=worker`
- `npc_cfg_schedule=day_worker`
- `npc_cfg_work_route=smith_work_loop`
- `npc_cfg_home_route=smith_home_loop`

Ожидаемая жизнь по слотам:
- утро/день: кузница (work)
- вечер/ночь: дом (home)

Минимум route: work + home.

### Торговец (лавка)

NPC:
- `npc_cfg_role=merchant`
- `npc_cfg_schedule=day_shop`
- `npc_cfg_work_route=shop_counter_loop`
- `npc_cfg_home_route=merchant_home`

Ожидаемая жизнь по слотам:
- день: лавка
- вечер/ночь: дом

Минимум route: work + home.

### Стражник (ночной)

NPC:
- `npc_cfg_role=guard`
- `npc_cfg_schedule=night_guard`
- `npc_cfg_work_route=north_gate_patrol`
- `npc_cfg_home_route=guard_barracks`
- `npc_cfg_force_reactive=1` (опционально, чтобы явно зафиксировать reactive)

Ожидаемая жизнь по слотам:
- ночь: patrol/work
- день: казарма/rest

Минимум route: work + home.

### Трактирщик (поздний)

NPC:
- `npc_cfg_role=innkeeper`
- `npc_cfg_schedule=tavern_late`
- `npc_cfg_work_route=tavern_bar_loop`
- `npc_cfg_home_route=innkeeper_room`

Ожидаемая жизнь по слотам:
- вечер до поздней ночи: трактир
- поздняя ночь/утро: домой

Минимум route: work + home.

### Обычный житель

NPC:
- `npc_cfg_role=citizen`
- `npc_cfg_schedule=always_home`
- `npc_cfg_home_route=house_idle_loop`

Ожидаемая жизнь по слотам:
- почти всегда home/rest

Минимум route: home.

## 11) Как работает facade

Пайплайн:

`npc_cfg_* authoring -> facade normalization/derived config -> существующий npc_* runtime`

- Внутренние `npc_*` locals **не удалены** и остаются runtime truth.
- Но они больше не являются основным ручным интерфейсом.
- Если низкоуровневые `npc_*` уже заданы явно, фасад не перетирает их «в лоб».
