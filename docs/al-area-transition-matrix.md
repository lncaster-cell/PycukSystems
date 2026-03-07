# AL Area Mode Contract and Transition Matrix

Обновлено: 2026-03-07

Документ фиксирует **текущий реализованный** контракт area mode в `scripts/al_prototype`.

## 1) Каноничные enum (источник истины)

Источник: `scripts/al_prototype/al_area_constants_inc.nss`.

- `AL_AREA_MODE_COLD = 0`
- `AL_AREA_MODE_WARM = 1`
- `AL_AREA_MODE_HOT = 2`
- `AL_AREA_MODE_OFF = 3`

> Важно: это актуальный порядок enum. Любые старые документы/скриншоты с `OFF=0` считаются устаревшими.

## 2) Каноничные area locals

- `al_area_mode` (`AL_AREA_MODE_LOCAL_KEY`) — основной local с режимом.
- `al_quarter_id` (`AL_AREA_QUARTER_LOCAL_KEY`) — идентификатор квартала (используется как metadata-поле).
- `al_adjacent_areas` (`AL_AREA_ADJ_LIST_LOCAL_KEY`) — CSV-теги соседних area для one-hop прогрева.
- `al_adj_interior_whitelist` (`AL_AREA_ADJ_INTERIOR_WHITELIST_LOCAL_KEY`) — CSV interior-соседей, которым разрешён прогрев.

## 3) Legacy fallback

Если `al_area_mode` не задан или содержит невалидное значение, применяется `AL_GetAreaModeLegacyDefault`:

- interior-area (`al_is_interior=1`) -> `COLD`;
- иначе, при `al_player_count > 0` -> `HOT`;
- иначе -> `COLD`.

## 4) Реально применяемые переходы

| Событие | From | To | Где происходит |
|---|---|---|---|
| Первый counted-игрок входит | `COLD/WARM` | `HOT` | `al_area_onenter` |
| Последний counted-игрок выходит/disconnect | `HOT/WARM` | `COLD` | `AL_HandleAreaBecameEmpty` |
| Источник HOT активирует соседей | `< WARM` | `WARM` | `AL_SoftActivateAdjacentAreas` |
| Завершился warm-tail (`al_tick_warm_left`) | `HOT` | `WARM` | `AreaTick` |
| Контент/скрипт принудительно отключает area | `*` | `OFF` | через `al_area_mode=3` |

## 5) Runtime-инварианты

1. Tick не должен исполняться в `OFF`/`COLD`.
2. Tick не должен исполняться при `al_player_count <= 0`.
3. Прогрев соседей никогда не поднимает режим выше `WARM`.
4. Interior-соседи прогреваются только через whitelist.
5. При очистке area token увеличивается, старые отложенные тики становятся stale и не исполняются.

## 6) Примечания по эксплуатации

- Если нужно «всегда живую» area без игроков, явно держите `al_area_mode=HOT` и не давайте empty-cleanup переводить её в `COLD`.
- Для service/maintenance area используйте `OFF` и не рассчитывайте на wake-path.
- Для наблюдаемости включайте `al_debug=1` точечно на staging/debug-сценах, а не глобально.
