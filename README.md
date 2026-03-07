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

Для перехода в другую area (если используете межзоновые точки):

- предпочтительно: `al_transition_location`,
- либо fallback-набор:
  - `al_transition_area`
  - `al_transition_x`
  - `al_transition_y`
  - `al_transition_z`
  - `al_transition_facing`

### 2.3 Настройка сна через waypoint locals

На sleep-route waypoint укажите:

- `al_bed_tag=<bed_id>`

И создайте в той же area две waypoint-точки по шаблону тегов:

- `<bed_id>_approach` — точка подхода к кровати,
- `<bed_id>_pose` — точка укладки (поза сна).

Если `al_bed_tag`/bed-точки не заданы, bed-docking не сработает, и NPC уйдёт в fallback-проигрывание сна без корректной привязки к кровати.

### 2.4 Area locals (рекомендуется)

- `al_area_mode` — режим area: `0=COLD`, `1=WARM`, `2=HOT`, `3=OFF`.
- `al_is_interior=1` — пометка интерьерной area.
- `al_adjacent_areas` — CSV тегов соседних area для soft-activation.
- `al_adj_interior_whitelist` — CSV интерьерных соседей, которых можно прогревать.
- `al_debug=1` — отладочные сообщения для area.

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
