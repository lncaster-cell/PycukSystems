# PycukSystems

## Ambient Life (AL)

### Что делает модуль
`Ambient Life` управляет «живым» поведением NPC в зависимости от времени и контекста:
- использует временные слоты (0..5) для переключения логики в течение суток;
- назначает маршруты и активности строго по локалам waypoint, выбранным из NPC local `alwp0`, `alwp5`;
- скрывает/показывает NPC в зависимости от условий (например, наличия игроков в area);
- поддерживает служебные переходы между локациями через waypoint.

### Быстрый старт подключения в Toolset
Подключите следующие скрипты к событиям:

- **Area events**
  - `al_area_onenter`
  - `al_area_onexit`
  - `al_area_tick`
- **NPC events**
  - `al_npc_onspawn`
  - `al_npc_onud`
  - `al_npc_ondeath`
- **Module event**
  - `al_mod_onleave`

### Минимальные локальные переменные
Для базовой работы задайте:
- на NPC: `alwp0` и `alwp5` — теги waypoint-маршрутов для слотов 0 и 5;
- на waypoint: `al_activity` — активность в конкретной точке;
- `al_debug` (опционально, для отладки).

Для area-уровня квартальной принадлежности и соседства (без глобального scheduler) используйте минимальный набор:
- `al_quarter_id` (string) — идентификатор квартала текущей area;
- `al_adj_count` (int) + `al_adj_0..N` (string) — читаемый список tag соседних area;
- `al_area_heat` (int enum: `0=COLD`, `1=WARM`, `2=HOT`) — текущее «тепловое» состояние area.

Дополнительно (обратная совместимость):
- `al_adjacent_areas` (string CSV) — каноничный fallback-формат; скрипт кэширует разобранные значения в locals и переиспользует до изменения исходной строки.

Рекомендованный runtime-policy:
- если area-источник в состоянии `HOT`, прямые соседи из `al_adj_count` + `al_adj_0..N` могут быть повышены до `WARM`;
- interior-area по умолчанию фиксируется в `COLD`; исключения задаются отдельно через `al_interior_mode_whitelist=1` или `al_mode_pin`;
- если adjacency-конфиг неполный/битый, система пишет debug fallback при `al_debug=1` и продолжает работу в локальном режиме (без silent ошибок и без каскадного прогрева соседей).

### Полный список активностей (`al_activity`)
Ниже перечислены все активности, которые поддерживаются в `Ambient Life`.

#### NPC-активности
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

#### Wrapper-активности `locate` (диапазон `91..98`)
- `91` — `AL_ACT_LOCATE_LOOK`
- `92` — `AL_ACT_LOCATE_IDLE`
- `93` — `AL_ACT_LOCATE_SIT`
- `94` — `AL_ACT_LOCATE_KNEEL`
- `95` — `AL_ACT_LOCATE_TALK`
- `96` — `AL_ACT_LOCATE_CRAFT`
- `97` — `AL_ACT_LOCATE_MEDITATE`
- `98` — `AL_ACT_LOCATE_STEALTH`

### Базовые требования к waypoint
Для корректной навигации и переходов у waypoint должны быть настроены:
- теги маршрутов (используемые маршрутной логикой AL);
- `al_activity` (тип/контекст активности в точке);
- `al_transition_location` (предпочтительный способ задания перехода);
- fallback-поля перехода: `al_transition_area`, `al_transition_x`, `al_transition_y`, `al_transition_z`, `al_transition_facing`.

### Настройка сна через 2 waypoint (bed docking)
Новый поток сна работает не по одной точке, а по паре waypoint рядом с кроватью:

1. На route-waypoint сна (с нужным `al_activity`) задайте:
   - `al_bed_tag=<BED_ID>` и создайте waypoint с тегами `<BED_ID>_approach` и `<BED_ID>_pose`.
2. `approach`-точка должна стоять на валидном walkmesh (достижимая `ActionMoveToLocation`).
3. `pose`-точка может быть на/внутри кровати: до `ActionJumpToLocation` скрипт временно отключает collision у NPC.
4. При выходе из сна NPC возвращается к `approach`-точке и collision включается обратно.

Если `approach` не найден, система уходит в безопасный fallback (сон «на полу» без docking к кровати).


### Аудит
- Подробный аудит поведения NPC и рисков модуля см. в `docs/ambient-life-technical.md`, раздел **"7) Полный аудит модуля поведения (AL)"**.
- Актуальный технический аудит (2026-03-04): `docs/behavior-module-audit-2026-03-04.md`.

### Troubleshooting
- **NPC не двигается** — проверьте, что у NPC заданы `alwp0`/`alwp5` и что по этим тегам есть waypoint в area.
- **NPC не активируется** — проверьте `al_activity` на waypoint текущего маршрута, наличие игроков в area и скрытое состояние NPC.
- **Парные активности не запускаются** — проверьте локальные ссылки `*_ref` (например, пары `al_training_npc1_ref`/`al_training_npc2_ref`, `al_bar_bartender_ref`/`al_bar_barmaid_ref`).
- **После замены ключевых NPC** обязательно обновляйте `*_ref`-локалы на area (для training/bar пар), иначе система оставит пару в безопасном unbound-состоянии до появления валидной ссылки.
- **Сон не докуется к кровати** — проверьте, что route-waypoint содержит `al_bed_tag`, а `approach`-точка находится на walkmesh; `pose`-точка может быть вне walkmesh, если нужна точная укладка на кровать.
