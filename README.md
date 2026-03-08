# Ambient Life: активности и полная настройка

## 1) Какие скрипты куда назначать

Назначьте скрипты в Toolset строго по событиям:

- **Area**
  - `OnEnter` → `al_area_onenter`
  - `OnExit` → `al_area_onexit`
  - `OnHeartbeat` (или эквивалент area tick) → `al_area_tick`
- **NPC (Creature)**
  - `OnSpawn` → `al_npc_onspawn`
  - `OnUserDefined` → `al_npc_onud`
  - `OnDeath` → `al_npc_ondeath`
- **Module**
  - `OnClientLeave` → `al_mod_onleave`

---

## 2) Какие locals куда прописывать

### 2.1 NPC locals (обязательно для участия в AL)

- `alwp0` … `alwp5` — теги route-waypoint по слотам суток.
- Допустимый минимум: задать только часть слотов (например, `alwp0` и `alwp1` для сна), но лучше заполнять все 6.
- `al_enabled=1` — опциональный маркер участия NPC в AL, если маршруты будут назначены позже.

### 2.2 Waypoint locals (обязательно для каждой route-точки)

- `al_activity` — ID активности в данной точке маршрута.
- `al_route_index` — опциональный индекс точки маршрута (`0..1023`) для явного порядка.
  - Для явного признака «индекс задан» используйте `al_route_index_present=1`.
  - Сначала читается новый ключ `al_route_index_present=1`; при его отсутствии используется legacy `al_route_index_set=1`.
  - Если хотя бы у одной waypoint с тегом маршрута задан валидный `al_route_index` (включая `0`) и найден любой из флагов присутствия, тег работает в indexed-режиме.
  - В indexed-режиме waypoint без валидного `al_route_index` или без флага присутствия (по dual-key правилу) пропускаются.
  - Если индекс не задан ни у одной waypoint маршрута, порядок строится в dense/fallback-режиме (как раньше).

Для перехода в другую area (межзоновые точки) актуальный контракт такой:

- `al_transition_area_tag` (**string local**) — **обязателен** для межзонового перехода; это tag целевой area.
- `al_transition_waypoint_tag` (**string local**) — **опционален**; это tag waypoint в целевой area.
  - Если `al_transition_waypoint_tag` не задан, используется tag текущего source-waypoint.

Устаревшие/неактуальные для контентного контракта пункты (не использовать в toolset):

- `al_transition_location`
- `al_transition_area`
- `al_transition_x`, `al_transition_y`, `al_transition_z`, `al_transition_facing`

Источник истины по runtime-логике переходов: `scripts/al_prototype/al_route_cache_inc.nss` (блок transition setup в `AL_CacheAreaRoutes`).

### 2.3 Настройка сна через waypoint locals

На sleep-route waypoint укажите:

- `al_bed_tag=<bed_id>`

И создайте в той же area две waypoint-точки по шаблону тегов:

- `<bed_id>_approach` — точка подхода к кровати,
- `<bed_id>_pose` — точка укладки (поза сна).

Если `al_bed_tag`/bed-точки не заданы, bed-docking не сработает, и NPC уйдёт в fallback-проигрывание сна без корректной привязки к кровати.

### 2.4 Area locals (рекомендуется)

- Для explicit-режима area нужно выставлять **оба** local:
  - `al_area_mode=<0..3>` — режим area: `0=COLD`, `1=WARM`, `2=HOT`, `3=OFF`.
  - `al_area_mode_is_set=1` — флаг, что `al_area_mode` задан явно.
- Короткий пример для OFF: `al_area_mode=3` + `al_area_mode_is_set=1`.
- Если `al_area_mode_is_set` отсутствует, используется legacy fallback (по `al_is_interior` / player_count), а не значение `al_area_mode`.
- `al_is_interior=1` — пометка интерьерной area.
- `al_adjacent_areas` — CSV тегов соседних area для soft-activation.
- `al_adj_interior_whitelist` — CSV интерьерных соседей, которых можно прогревать.
- `al_debug=1` — отладочные сообщения для area.

### 2.5 Training pair refs (контракт спаривания)

Для тренировочной пары (`AL_ACT_NPC_TRAINING_ONE` / `AL_ACT_NPC_TRAINING_TWO`) роль NPC определяется **только object refs на area**, а не тегами NPC:

- `al_training_npc1_ref` — object local на area для стороны `npc1`.
- `al_training_npc2_ref` — object local на area для стороны `npc2`.

Если NPC не совпал ни с одним из этих refs, training-pair для него не инициализируется.

---

## 3) Сон НПЦ — максимально просто

Если нужно «просто чтобы НПЦ спал», сделайте **ровно 4 шага**:

1. У NPC поставьте locals:
   - `alwp0 = <tag_sleep_wp>`
   - `alwp1 = <tag_sleep_wp>`
2. На waypoint с тегом `<tag_sleep_wp>` поставьте:
   - `al_activity = 5` (обычный сон в кровати)
   - `al_bed_tag = <bed_id>`
3. В той же area создайте 2 waypoint:
   - `<bed_id>_approach`
   - `<bed_id>_pose`
4. Проверьте, что у NPC назначен `OnSpawn -> al_npc_onspawn`.

Готово: в ночные слоты (`alwp0/alwp1`, примерно 00:00–08:00) НПЦ пойдёт спать.

> Если хотите упростить ещё сильнее: используйте один и тот же `<tag_sleep_wp>` для `alwp0` и `alwp1`.

---

## 4) Справочник активностей (ID)

### 4.1 Базовые NPC активности

- `0` — `AL_ACT_NPC_HIDDEN`
- `1` — `AL_ACT_NPC_ACT_ONE`
- `2` — `AL_ACT_NPC_ACT_TWO`
- `3` — `AL_ACT_NPC_DINNER`
- `4` — `AL_ACT_NPC_MIDNIGHT_BED`
- `5` — `AL_ACT_NPC_SLEEP_BED`
- `6` — `AL_ACT_NPC_WAKE`
- `7` — `AL_ACT_NPC_AGREE`
- `8` — `AL_ACT_NPC_ANGRY`
- `9` — `AL_ACT_NPC_SAD`
- `10` — `AL_ACT_NPC_COOK`
- `11` — `AL_ACT_NPC_DANCE_FEMALE`
- `12` — `AL_ACT_NPC_DANCE_MALE`
- `13` — `AL_ACT_NPC_DRUM`
- `14` — `AL_ACT_NPC_FLUTE`
- `15` — `AL_ACT_NPC_FORGE`
- `16` — `AL_ACT_NPC_GUITAR`
- `17` — `AL_ACT_NPC_WOODSMAN`
- `18` — `AL_ACT_NPC_MEDITATE`
- `19` — `AL_ACT_NPC_POST`
- `20` — `AL_ACT_NPC_READ`
- `21` — `AL_ACT_NPC_SIT`
- `22` — `AL_ACT_NPC_SIT_DINNER`
- `23` — `AL_ACT_NPC_STAND_CHAT`
- `24` — `AL_ACT_NPC_TRAINING_ONE`
- `25` — `AL_ACT_NPC_TRAINING_TWO`
- `26` — `AL_ACT_NPC_TRAINER_PACE`
- `27` — `AL_ACT_NPC_WWP`
- `28` — `AL_ACT_NPC_CHEER`
- `29` — `AL_ACT_NPC_COOK_MULTI`
- `30` — `AL_ACT_NPC_FORGE_MULTI`
- `31` — `AL_ACT_NPC_MIDNIGHT_90`
- `32` — `AL_ACT_NPC_SLEEP_90`
- `33` — `AL_ACT_NPC_THIEF`
- `36` — `AL_ACT_NPC_THIEF2`
- `37` — `AL_ACT_NPC_ASSASSIN`
- `38` — `AL_ACT_NPC_MERCHANT_MULTI`
- `39` — `AL_ACT_NPC_KNEEL_TALK`
- `41` — `AL_ACT_NPC_BARMAID`
- `42` — `AL_ACT_NPC_BARTENDER`
- `43` — `AL_ACT_NPC_GUARD`

### 4.2 Wrapper-активности locate (диапазон 91..98)

- `91` — `AL_ACT_LOCATE_LOOK`
- `92` — `AL_ACT_LOCATE_IDLE`
- `93` — `AL_ACT_LOCATE_SIT`
- `94` — `AL_ACT_LOCATE_KNEEL`
- `95` — `AL_ACT_LOCATE_TALK`
- `96` — `AL_ACT_LOCATE_CRAFT`
- `97` — `AL_ACT_LOCATE_MEDITATE`
- `98` — `AL_ACT_LOCATE_STEALTH`

---

## 5) Минимальный чек-лист запуска

1. Скрипты назначены на события Area/NPC/Module.
2. У каждого AL-NPC есть `alwp*` (минимум sleep-слоты).
3. На route-waypoint заполнен `al_activity`.
4. Для сна настроены `al_bed_tag`, `<bed_id>_approach`, `<bed_id>_pose`.
5. Area не в `OFF`, и корректно считаются вход/выход игроков.

---

## 6) Валидация AL-контента перед публикацией

Для быстрой проверки контента добавлен standalone-скрипт:

- `scripts/al_prototype/al_content_validator.nss`

### Как запускать

1. Скомпилируйте `al_content_validator` в Toolset/серверной сборке.
2. Выполните скрипт на модуле (например через консоль/DM-команду):
   - `dm_runscript al_content_validator`
   - или `ExecuteScript("al_content_validator", GetModule())`.
3. Откройте лог сервера (`nwserverLog1.txt`) и найдите блоки `[AL-VALIDATOR]`.

### Что проверяет

- AL-NPC контракт участия: наличие `alwp0..alwp5` и/или `al_enabled`.
- Валидность `al_activity` на route-waypoints.
- Межзоновые переходы: `al_transition_area_tag` и `al_transition_waypoint_tag`.
- Indexed-route согласованность: `al_route_index` + флаг присутствия (`al_route_index_present`/legacy `al_route_index_set`).

### Ожидаемый формат отчёта

Пример строк:

```
[AL-VALIDATOR][critical] area='market_sq' object='wp_market_sleep' reason='unknown al_activity=777'
[AL-VALIDATOR][warning] area='market_sq' object='blacksmith_01' reason='al_enabled=1 set without any alwp0..alwp5 route slots'
[AL-VALIDATOR] Summary: critical=1, warning=1, info=0
```

Pass-case (успешные проверки без замечаний) в текущем контракте **не логируется отдельными `info`-строками**.
Поэтому в большинстве запусков `info` в summary будет `0`.

Категории:

- `critical` — ошибка контента, требующая исправления до релиза.
- `warning` — потенциально проблемная/неполная конфигурация.
- `info` — служебный уровень (в текущем silent-режиме обычно остаётся `0`).
