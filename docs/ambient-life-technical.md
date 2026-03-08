# Ambient Life — Technical Documentation

Обновлено: 2026-03-08

## 1. Назначение модуля

Ambient Life (AL) управляет «фоновым» поведением NPC в area через:

- slot-based расписание (`0..5`, шаг 4 часа);
- area lifecycle (wake/freeze);
- реестр NPC на уровне area;
- route/activity execution и safety fallback.

Модуль реализован в `scripts/al_prototype` и рассчитан на устойчивую работу в условиях неполного/ошибочного контента.

## 2. Основные runtime-компоненты

### 2.1 Area lifecycle

- `al_area_onenter`:
  - учитывает counted-игрока;
  - на первом игроке переводит area в `HOT`;
  - запускает wake path (cache/sync/unhide/resync/tick schedule);
  - выполняет soft-activation соседей.

- `al_area_onexit`:
  - декрементирует счётчик игроков через helper;
  - при последнем игроке запускает freeze path.

- `al_mod_onleave`:
  - закрывает edge-case disconnect, когда обычный OnExit может не сработать.

### 2.2 Tick pipeline

Файл: `al_area_tick_inc.nss`.

- `AreaTick` валидирует token (`al_tick_token`);
- tick останавливается в `OFF`/`COLD` и при `al_player_count <= 0`;
- период зависит от режима:
  - `HOT` -> `AL_TICK_PERIOD_HOT = 15.0`
  - `WARM` -> `AL_TICK_PERIOD_WARM = 30.0`
  - иначе -> `AL_TICK_PERIOD_COLD = 45.0`
- раз в `AL_SYNC_TICK_INTERVAL` выполняется `AL_SyncAreaNPCRegistry`;
- при смене slot отправляется `AL_EVT_SLOT_0 + slot`.

### 2.3 NPC registry

Файл: `al_npc_reg_inc.nss`.

- storage: `al_npc_count`, `al_npc_0..al_npc_99`;
- upper bound: `AL_MAX_NPCS = 100`;
- удаление — `swap-with-last`, массив всегда dense;
- sync удаляет invalid/stale ссылки и переносит NPC между area при смене локации.

### 2.4 Route/activity слой

- activity ID и metadata: `al_acts_inc.nss`;
- route cache: `al_route_cache_inc.nss`;
- execution и fallback: `al_npc_onud.nss` -> `al_npc_activity_apply_inc.nss` -> `al_npc_sleep_inc.nss` -> `al_npc_pair_revalidate_inc.nss` -> `al_npc_routes.nss`.

Примечание: `scripts/al_prototype/al_npc_acts_inc.nss` сохраняется только как legacy/compat-артефакт и не участвует в актуальном runtime-потоке. Не вносите исправления в эту неиспользуемую ветку логики.

## 3. Контракт area modes

Каноничные значения:

- `COLD=0`
- `WARM=1`
- `HOT=2`
- `OFF=3`

Источник: `al_area_constants_inc.nss`.

### 3.1 AL_GetAreaModeOrLegacy

Если `al_area_mode` невалиден/пустой:

- interior (`al_is_interior=1`) -> `COLD`;
- иначе, при игроках -> `HOT`;
- иначе -> `COLD`.

### 3.2 Soft-activation соседей

- источник: `AL_SoftActivateAdjacentAreas`;
- входной список: `al_adjacent_areas` (CSV тегов area);
- сосед поднимается максимум до `WARM`;
- interior-соседи требуют whitelist (`al_adj_interior_whitelist`);
- при ошибках конфигурации в debug-режиме выводится fallback-лог.

## 4. События и идентификаторы

Источник: `al_constants_inc.nss`.

- `AL_EVT_SLOT_0..AL_EVT_SLOT_5` (`3000..3005`)
- `AL_EVT_RESYNC = 3006`
- `AL_EVT_ROUTE_REPEAT = 3007`

Ограничители repeat-событий:

- `AL_ROUTE_REPEAT_MIN_GAP_SECONDS_HOT = 1`
- `AL_ROUTE_REPEAT_MIN_GAP_SECONDS_WARM = 2`

## 5. Контентный контракт

### 5.1 NPC

Минимум:

- `alwp*` слоты (или `al_enabled=1` как маркер участия);
- валидная area и creature type.

### 5.2 Waypoints

- `al_activity` обязателен;
- `al_route_index` (`0..1023`) — опциональный индекс точки маршрута;
  - при наличии хотя бы одного валидного `al_route_index` в группе одного route-tag включается indexed-режим;
  - waypoint без валидного индекса в indexed-режиме отбрасываются;
  - при полном отсутствии индексов маршрут строится в dense/fallback-режиме;
  - `al_route_index_set` считается legacy-совместимостью и не является частью актуального контракта данных.
- для межзонового перехода используется waypoint-based контракт:
  - на source-waypoint задаётся `al_transition_area_tag` (тип string, tag area назначения);
  - опционально задаётся `al_transition_waypoint_tag` (тип string, tag waypoint в target area);
  - если `al_transition_waypoint_tag` не задан, используется tag текущего source-waypoint.
- route cache резолвит переход как `area tag -> waypoint tag -> location` без координатных locals.

### 5.3 Area

- `al_area_mode` (опционально, если хотите explicit policy);
- `al_is_interior` для interior-policy;
- `al_adjacent_areas` / `al_adj_interior_whitelist` для соседства;
- `al_debug=1` для локальной диагностики.

### 5.4 Training pair contract

- Training-пара (`AL_InitTrainingPartner`) определяется через area object refs:
  - `al_training_npc1_ref` для роли `npc1`;
  - `al_training_npc2_ref` для роли `npc2`.
- Tag-based определение ролей (`FACTION_NPC1/FACTION_NPC2`) не является частью актуального контракта.
- Если NPC не совпадает ни с одним training ref, runtime-пара для него не связывается.

## 6. Safety и fallback-поведение

1. При freeze у NPC очищается runtime route-state (`r_active`, `r_slot`, `r_idx`).
2. Перед/после sleep-docking принудительно нормализуется collision.
3. При невалидном route/activity NPC переходит в безопасное поведение.
4. При заполнении registry новые NPC не добавляются; debug-сообщения троттлятся.

## 7. Производительность

Практические рекомендации:

- на массовых сценах сокращать route длину и число NPC с частым repeat;
- включать `al_debug=1` точечно, а не глобально;
- проверять плотность registry и частоту route repeats на staging.

## 8. Диагностика

### 8.1 Что смотреть в locals

- Area: `al_player_count`, `al_area_mode`, `al_tick_token`, `al_tick_scheduled_token`, `al_slot`, `al_npc_count`.
- NPC: `r_active`, `r_slot`, `r_idx`, `al_last_area`, sleep locals.

### 8.2 Типовые симптомы

- NPC «мертв» после wake: обычно broken `alwp*`/route-tag или invalid waypoint metadata.
- Area не охлаждается: чаще всего некорректный player counting.
- Сосед не прогревается: ошибка в `al_adjacent_areas` или interior не в whitelist.

## 9. Связанные документы

- `docs/al-area-transition-matrix.md`
- `docs/ambient-life-interior-hot-warm-cold-contract.md`
- `docs/area-modes-roadmap.md`
- `docs/ambient-life-qa-2026-03-07.md`
- `docs/behavior-module-audit-2026-03-04.md`
