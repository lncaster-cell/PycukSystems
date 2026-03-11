# ARCHITECTURE — Ambient Life v2

## 1. Цель

Ambient Life v2 управляет поведением NPC через событийную модель NWScript с минимальной серверной нагрузкой.

Базовый принцип: **нет фоновой логики на NPC**, вся координация идёт от области.

## 2. Архитектурная модель

### 2.1 Area Controller

Ключевые скрипты:
- `scripts/al_area_onenter.nss`
- `scripts/al_area_onexit.nss`
- `scripts/al_area_tick.nss`
- `scripts/al_area_tick_inc.nss`

Функции:
- считает игроков в области (`al_player_count`);
- активирует/деактивирует жизненный цикл;
- хранит токен тика (`al_tick_token`) для гашения старых `DelayCommand`;
- вычисляет слот суток `0..5`;
- рассылает NPC события слота и RESYNC.

### 2.2 NPC Agent

Ключевые скрипты:
- `scripts/al_npc_onspawn.nss`
- `scripts/al_npc_onud.nss`
- `scripts/al_npc_ondeath.nss`

Функции:
- регистрация NPC в реестре области;
- приём пользовательских событий (`AL_EVT_*`);
- применение активности и маршрута по текущему слоту;
- повтор маршрута через `AL_EVT_ROUTE_REPEAT`;
- очистка связей (training/bar pair) при смерти.

### 2.3 Registry Layer

Ключевой include:
- `scripts/al_npc_reg_inc.nss`

Функции:
- плотный массив `al_npc_0..al_npc_99` + `al_npc_count`;
- O(1) удаление (swap-remove);
- синхронизация “переехавших”/невалидных ссылок;
- массовые операции hide/unhide + RESYNC.

## 3. Событийный протокол

Константы в `scripts/al_constants_inc.nss`:
- `AL_EVT_SLOT_BASE = 3000`
- `AL_EVT_SLOT_0..AL_EVT_SLOT_5 = 3000..3005`
- `AL_EVT_RESYNC = 3006`
- `AL_EVT_ROUTE_REPEAT = 3007`

Обработка в `al_npc_onud.nss`:
- `RESYNC` — принудительная переоценка состояния по текущему `al_slot` области;
- `SLOT_x` — переключение на новый слот;
- `ROUTE_REPEAT` — продолжение маршрута без полной пересборки поведения.

## 4. Временная модель

- Сутки: 6 слотов по 4 часа (`slot = floor(GetTimeHour() / 4)`).
- Период тика: `AL_TICK_PERIOD = 45.0` сек реального времени.
- При неизменном слоте пересылка событий NPC не выполняется.

## 5. Маршруты и активности

Ключевые include:
- `scripts/al_npc_routes.nss`
- `scripts/al_npc_acts_inc.nss`

Механика:
- маршрут кешируется на NPC для текущего слота (`r<slot>_*` locals);
- выбор активности идёт через `AL_GetWaypointActivityForSlot`;
- `AL_ActivityHasRequiredRoute` проверяет соответствие route-tag требованиям активности;
- если требование активности не выполнено (нет маршрута/пары), fallback к безопасной активности.

## 6. Парные зависимости

Поддерживаются два типа пар:
- **training pair**: `FACTION_NPC1` ↔ `FACTION_NPC2`;
- **bar pair**: `al_bar_bartender_ref` ↔ `al_bar_barmaid_ref`.

Инициализация делается при спавне и/или при первой активации области.

## 7. Инварианты текущего этапа

1. Нет heartbeat/timer у NPC.
2. Один таймер на область только при `al_player_count > 0`.
3. Нет глобального поиска NPC для управления — только реестр.
4. Деактивация области гасит активность NPC (`SetScriptHidden`, очистка очередей).
5. Все управляемые NPC должны корректно регистрироваться через `al_npc_onspawn`.

## 8. Известные технические границы

- Лимит реестра: 100 NPC на область.
- Первичное кеширование маршрутов может быть заметным в очень больших областях.
- Корректность route-driven поведения зависит от дисциплины тегов waypoint и индексов.
