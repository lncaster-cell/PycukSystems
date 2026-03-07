# PycukSystems

## Ambient Life (AL)

`Ambient Life` — модуль событийного поведения NPC для NWN2, построенный вокруг area lifecycle и slot-based расписания (6 слотов в сутки).

## Что делает модуль

- включает/замораживает area по присутствию игроков;
- поддерживает режимы area: `COLD`, `WARM`, `HOT`, `OFF`;
- держит реестр NPC на area и синхронизирует его в тиках;
- исполняет активности NPC через маршруты waypoint (`alwp0..alwp5`);
- безопасно деградирует в fallback-поведение при невалидном контенте;
- поддерживает мягкий one-hop прогрев соседних area из `HOT`-источника.

## Быстрое подключение в Toolset

Подключите скрипты к стандартным событиям:

- **Area**
  - `al_area_onenter`
  - `al_area_onexit`
  - `al_area_tick`
- **NPC**
  - `al_npc_onspawn`
  - `al_npc_onud`
  - `al_npc_ondeath`
- **Module**
  - `al_mod_onleave`

## Минимальная конфигурация

### NPC locals

- `alwp0` … `alwp5` — теги route-waypoint по слотам (достаточно `alwp0` и `alwp5` для простого профиля).
- Альтернатива: `al_enabled=1` (маркер участия в AL, если маршруты задаются позже).

### Waypoint locals

- `al_activity` — ID активности.
- Для межзоновых переходов (fallback-цепочка):
  - `al_transition_location` **или**
  - `al_transition_area`, `al_transition_x`, `al_transition_y`, `al_transition_z`, `al_transition_facing`.

### Area locals

- `al_area_mode` — явный режим area (`0=COLD`, `1=WARM`, `2=HOT`, `3=OFF`).
- `al_is_interior=1` — интерьерная area (по контракту по умолчанию уходит в `COLD`).
- `al_adjacent_areas` — CSV-теги соседних area для soft-activation.
- `al_adj_interior_whitelist` — CSV-теги interior-соседей, которым разрешён прогрев.
- `al_debug=1` — диагностические сообщения в чат area.

## Ключевые runtime-инварианты

- Tick не исполняется в `OFF` и `COLD`.
- Tick не исполняется без игроков в area.
- В `HOT` тик быстрее (`15s`), в `WARM` медленнее (`30s`), `COLD` дефолтно (`45s`).
- Реестр area ограничен `AL_MAX_NPCS=100`.
- Route на NPC ограничен `AL_ROUTE_MAX_POINTS=10`.

## Активности

Полный список activity ID и wrapper-активностей `91..98` описан в `scripts/al_prototype/al_acts_inc.nss`.

## Документация

- Архитектура и контракты: `docs/ambient-life-technical.md`
- Контракт режимов area: `docs/al-area-transition-matrix.md`
- Контракт интерьеров: `docs/ambient-life-interior-hot-warm-cold-contract.md`
- Roadmap: `docs/area-modes-roadmap.md`
- QA checklists: `docs/ambient-life-qa-2026-03-07.md`
- Технический аудит: `docs/behavior-module-audit-2026-03-04.md`

## Troubleshooting

- **NPC не двигается:** проверьте `alwp*` на NPC и наличие waypoint с соответствующими тегами в area.
- **Area не «просыпается»:** проверьте, что в `OnEnter/OnExit` реально приходят counted-игроки и area не в `OFF`.
- **Соседи не прогреваются:** проверьте `al_adjacent_areas`; для interior-соседа нужен `al_adj_interior_whitelist`.
- **Парные роли (training/bar) распались:** обновите `al_training_npc*_ref` / `al_bar_*_ref` после замены NPC.
