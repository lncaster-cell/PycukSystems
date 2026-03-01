# PycukSystems

## Ambient Life (AL)

### Что делает модуль
`Ambient Life` управляет «живым» поведением NPC в зависимости от времени и контекста:
- использует временные слоты (0..5) для переключения логики в течение суток;
- назначает маршруты перемещения и активности по слотам, с fallback на значения по умолчанию;
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
- `al_default_route`, `al_slot_route_0..5`;
- `al_default_activity`, `al_slot_activity_0..5`;
- `al_debug` (опционально, для отладки).

### Базовые требования к waypoint
Для корректной навигации и переходов у waypoint должны быть настроены:
- теги маршрутов (используемые маршрутной логикой AL);
- `al_activity` (тип/контекст активности в точке);
- `al_transition_location` (предпочтительный способ задания перехода);
- fallback-поля перехода: `al_transition_area`, `al_transition_x`, `al_transition_y`, `al_transition_z`, `al_transition_facing`.

### Troubleshooting
- **NPC не двигается** — проверьте наличие маршрута для текущего слота и корректность тегов waypoint.
- **NPC не активируется** — убедитесь, что в area есть игроки и NPC не находится в скрытом состоянии.
- **Парные активности не запускаются** — проверьте локальные ссылки `*_ref` (например, пары `al_training_npc1_ref`/`al_training_npc2_ref`, `al_bar_bartender_ref`/`al_bar_barmaid_ref`).
