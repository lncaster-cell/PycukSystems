# INSTALLATION — Ambient Life v2 (NWN2)

## 1. Подготовка

Убедитесь, что в модуле доступны скрипты из `scripts/` и include-файлы компилируются без конфликтов имён.

Минимально необходимые файлы:
- `al_constants_inc.nss`
- `al_npc_reg_inc.nss`
- `al_area_tick_inc.nss`
- `al_npc_routes.nss`
- `al_npc_acts_inc.nss`
- `al_area_onenter.nss`
- `al_area_onexit.nss`
- `al_area_tick.nss`
- `al_npc_onspawn.nss`
- `al_npc_onud.nss`
- `al_npc_ondeath.nss`
- `al_mod_onleave.nss`

## 2. Привязка event-скриптов в toolset

### На Area

- **OnEnter** → `al_area_onenter`
- **OnExit** → `al_area_onexit`
- (опционально) heartbeat области не требуется для Ambient Life.

### На NPC (управляемых Ambient Life)

- **OnSpawn** → `al_npc_onspawn`
- **OnUserDefined** → `al_npc_onud`
- **OnDeath** → `al_npc_ondeath`

### На Module

- **OnClientLeave** → `al_mod_onleave`

## 3. Настройка областей

Обязательные/рабочие locals на Area (создаются скриптами автоматически):
- `al_player_count`, `al_tick_token`, `al_slot`, `al_npc_count`, `al_sync_tick`

Опциональные преднастройки:
- training pair refs:
  - `al_training_npc1_ref`
  - `al_training_npc2_ref`
- bar pair refs:
  - `al_bar_bartender_ref`
  - `al_bar_barmaid_ref`

Для отладки можно включить:
- `al_debug = 1` на Area/NPC.

## 4. Настройка маршрутов

Маршруты читаются по тегам waypoint.

Практические правила:
1. Используйте стабильные теги waypoint для маршрутов.
2. Если нужен строгий порядок точек, задавайте `al_route_index` и маркер `al_route_index_set`.
3. Следите за уникальностью индексов внутри одного route-tag.

## 5. Проверка запуска (smoke)

1. Зайти первым игроком в область:
   - `al_player_count` должен стать `1`;
   - NPC должны раскрыться и получить `AL_EVT_RESYNC`.
2. Дождаться тика/смены слота:
   - при смене слота ожидаются `AL_EVT_SLOT_x`.
3. Выйти последним игроком:
   - `al_player_count` должен стать `0`;
   - NPC должны быть скрыты, старые тики погашены через `al_tick_token`.

## 6. Ограничения и эксплуатация

- `AL_MAX_NPCS = 100` на область.
- При превышении лимита лишние NPC не попадут в управление системой.
- Для больших областей учитывайте стоимость первого кеширования waypoint’ов.
