# AL Area Mode Transition Matrix (HOT/WARM/COLD/OFF)

Документ фиксирует единый контракт по mode/transition reason и ключам area locals для Ambient Life.

## 1) Утверждённые enum

### 1.1 Area mode enum

Источник истины: `scripts/al_prototype/al_area_constants_inc.nss`.

- `AL_AREA_MODE_OFF = 0`
- `AL_AREA_MODE_COLD = 1`
- `AL_AREA_MODE_WARM = 2`
- `AL_AREA_MODE_HOT = 3`

### 1.2 Transition reason enum

Источник истины: `scripts/al_prototype/al_area_constants_inc.nss`.

- `AL_AREA_TRANSITION_REASON_UNSPECIFIED = 0`
- `AL_AREA_TRANSITION_REASON_LEGACY_PLAYERS_PRESENT = 1`
- `AL_AREA_TRANSITION_REASON_LEGACY_EMPTY = 2`
- `AL_AREA_TRANSITION_REASON_ENTER_FIRST_PLAYER = 3`
- `AL_AREA_TRANSITION_REASON_EXIT_LAST_PLAYER = 4`
- `AL_AREA_TRANSITION_REASON_NEIGHBOR_HEAT = 5`
- `AL_AREA_TRANSITION_REASON_CONTENT_OVERRIDE = 6`
- `AL_AREA_TRANSITION_REASON_SCRIPT_OVERRIDE = 7`
- `AL_AREA_TRANSITION_REASON_ADMIN_OVERRIDE = 8`

## 2) Утверждённые ключи locals

Источник истины: `scripts/al_prototype/al_area_constants_inc.nss`.

- `AL_AREA_MODE_LOCAL_KEY = "al_area_mode"`
- `AL_AREA_MODE_FLAGS_ENABLED_LOCAL_KEY = "al_area_mode_flags_enabled"`
- `AL_AREA_MODE_REASON_LOCAL_KEY = "al_area_mode_reason"`
- `AL_AREA_MODE_PREV_LOCAL_KEY = "al_area_mode_prev"`
- `AL_AREA_MODE_CHANGED_TS_LOCAL_KEY = "al_area_mode_changed_ts"`

## 3) Legacy fallback (обязательный default)

До включения mode-флагов на конкретной area (`al_area_mode_flags_enabled != TRUE`) действует legacy-резолв:

- `al_player_count > 0` -> `HOT`
- `al_player_count == 0` -> `COLD`

Это поведение является default и сохраняет текущую runtime-совместимость.

## 4) Transition matrix

Ниже — целевая матрица переходов состояний. Фактическое применение перехода может быть ограничено политикой рантайма, но причины и результат должны соответствовать этой таблице.

| From | To | Reason enum | Минимальное условие |
|---|---|---|---|
| OFF | COLD | `CONTENT_OVERRIDE` / `SCRIPT_OVERRIDE` / `ADMIN_OVERRIDE` | Явное включение area |
| OFF | WARM | `NEIGHBOR_HEAT` / override | Явный прогрев от соседа или override |
| OFF | HOT | `ENTER_FIRST_PLAYER` / override | Появился первый игрок или принудительный override |
| COLD | OFF | `CONTENT_OVERRIDE` / `SCRIPT_OVERRIDE` / `ADMIN_OVERRIDE` | Принудительное выключение |
| COLD | WARM | `NEIGHBOR_HEAT` / override | Прогрев от активной соседней area |
| COLD | HOT | `ENTER_FIRST_PLAYER` | Первый игрок вошёл в area |
| WARM | OFF | override | Принудительное выключение |
| WARM | COLD | `EXIT_LAST_PLAYER` / `LEGACY_EMPTY` | Нет игроков и нет поддерживающего прогрева |
| WARM | HOT | `ENTER_FIRST_PLAYER` | В area появился игрок |
| HOT | OFF | override | Принудительное выключение |
| HOT | COLD | `EXIT_LAST_PLAYER` / `LEGACY_EMPTY` | Последний игрок покинул area, warm-окно завершено |
| HOT | WARM | `EXIT_LAST_PLAYER` / `NEIGHBOR_HEAT` | Игроков нет, но допускается мягкий прогрев |

## 5) Инварианты

1. **Legacy-first:** если mode-флаги не включены на area, runtime обязан использовать legacy fallback.
2. **Enum-only:** любые значения mode/reason вне утверждённых enum считаются невалидными и не должны ломать fallback.
3. **Monotonic traceability:** при смене mode допускается запись `prev/reason/changed_ts` для диагностики; отсутствие этих полей не должно ломать runtime.
4. **No silent OFF escalation:** переход в `OFF` выполняется только явным override-контуром.
5. **Player dominance:** наличие игроков в area всегда имеет приоритет над пассивным охлаждением и должно приводить минимум к `HOT` (в legacy) либо к разрешённому policy-уровню с reason, отражающим событие входа.
