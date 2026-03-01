# Ambient Life: техническая документация

## 1) Архитектурная схема по файлам

```text
Area events
├─ al_area_onenter.nss
│  ├─ инкрементирует al_player_count
│  ├─ при первом игроке: al_tick_token++, al_slot=AL_ComputeTimeSlot()
│  ├─ кэширует training-партнёров
│  ├─ синхронизирует area-registry NPC
│  ├─ unhide + AL_EVT_RESYNC для каждого зарегистрированного NPC
│  └─ запускает DelayCommand(... AreaTick(area, token))
├─ al_area_onexit.nss
│  ├─ декрементирует al_player_count (с защитой от <0)
│  └─ при выходе последнего игрока: al_tick_token++, hide всех зарегистрированных NPC
└─ al_area_tick_inc.nss
   ├─ AL_ComputeTimeSlot() -> hour/4 (0..5)
   ├─ AreaTick(area, token)
   │  ├─ проверка player_count > 0
   │  ├─ проверка актуальности token
   │  ├─ периодическая AL_SyncAreaNPCRegistry()
   │  ├─ при смене слота: al_slot=новый, broadcast AL_EVT_SLOT_0..5
   │  └─ самопланирование следующего тика
   └─ AL_CacheAreaRoutes(): подготовка кэшей route-локейшенов по waypoint tag

NPC events
├─ al_npc_onspawn.nss
│  ├─ al_last_slot=-1
│  ├─ инициализирует training/bar пары
│  ├─ регистрирует NPC в area-registry
│  └─ если в area есть игроки: unhide + AL_EVT_RESYNC, иначе hide
├─ al_npc_onud.nss
│  ├─ единая точка обработки AL_EVT_SLOT_*, AL_EVT_RESYNC, AL_EVT_ROUTE_REPEAT
│  ├─ пересобирает/обновляет route для nSlot
│  ├─ управляет route loop и повторной доставкой AL_EVT_ROUTE_REPEAT
│  └─ применяет активность/анимацию (в т.ч. fallback)
└─ al_npc_ondeath.nss
   ├─ чистит связи training/bar пар
   ├─ сбрасывает area-кэш пар (если погиб ключевой NPC)
   └─ удаляет NPC из registry

Domain includes
├─ al_npc_reg_inc.nss
│  ├─ registry на area locals: al_npc_count + al_npc_<idx>
│  ├─ AL_RegisterNPC / AL_UnregisterNPC / AL_SyncAreaNPCRegistry
│  ├─ AL_HideRegisteredNPCs / AL_UnhideAndResyncRegisteredNPCs
│  └─ AL_BroadcastUserEvent(area, event)
├─ al_npc_routes.nss
│  ├─ route cache на NPC locals: r<slot>_n, r<slot>_<idx>, ...
│  ├─ runtime route-state: r_slot, r_idx, r_active
│  ├─ AL_QueueRoute() (Move/Jump/Repeat)
│  └─ AL_HandleRouteAreaTransition() (смена area, перерегистрация, ресинк)
├─ al_npc_acts_inc.nss
│  ├─ AL_GetWaypointActivityForSlot() + fallback activity
│  ├─ проверка route requirements / training / bar pair
│  └─ применение custom/numeric анимаций
└─ al_acts_inc.nss
   ├─ enum activity-констант
   ├─ mapping activity -> custom/numeric animation set
   └─ правила activity requirements (waypoint tag, training pair, bar pair)
```

---

## 2) Жизненный цикл

### 2.1 Вход первого игрока -> запуск `AreaTick`
1. `al_area_onenter.nss` обрабатывает только PC, сбрасывает anti-double-exit флаг на игроке (`al_exit_counted`).
2. Увеличивает `al_player_count`.
3. Если это **первый** игрок (`al_player_count == 1`):
   - увеличивает `al_tick_token` (новая «эпоха» тиков),
   - вычисляет и сохраняет `al_slot = AL_ComputeTimeSlot()`,
   - синхронизирует registry,
   - делает unhide NPC и отправляет им `AL_EVT_RESYNC`,
   - планирует первый `AreaTick(area, token)` через `AL_TICK_PERIOD`.

### 2.2 Смена слота времени (`AL_ComputeTimeSlot`) -> broadcast `AL_EVT_SLOT_*`
1. `AreaTick` выполняется циклически только если:
   - в area есть игроки,
   - переданный token совпадает с текущим `al_tick_token`.
2. Каждые `AL_SYNC_TICK_INTERVAL` тиков выполняется `AL_SyncAreaNPCRegistry`; при смене слота синхронизация делается дополнительно перед broadcast.
3. Новый слот считается как `GetTimeHour()/4` и ограничивается диапазоном `0..5`.
4. Если слот изменился:
   - `al_slot` обновляется,
   - area отправляет `AL_EVT_SLOT_0 + slot` всем NPC из registry,
   - цикл тика продолжается.

### 2.3 Выход последнего игрока -> hide NPC + invalidation token
1. `al_area_onexit.nss` обрабатывает только PC и защищается от двойного учёта выхода через `al_exit_counted`.
2. Уменьшает `al_player_count` (не ниже 0).
3. Если ушёл **последний** игрок (`al_player_count == 0`):
   - инкрементирует `al_tick_token` (инвалидация ранее запланированных `AreaTick`),
   - вызывает `AL_HideRegisteredNPCs` (скрытие NPC, очистка action queue при включённом флаге).

---

## 3) Модель данных (ключевые locals)

### 3.1 Area locals

| Local key | Тип | Назначение |
|---|---|---|
| `al_player_count` | int | Количество игроков в area; управляет включением/выключением симуляции. |
| `al_tick_token` | int | Токен «эпохи» тика. Старые DelayCommand-тиковки отбрасываются по несовпадению token. |
| `al_slot` | int (0..5) | Текущий 4-часовой слот времени. |
| `al_npc_count` | int | Размер плотного массива registry NPC в area. |
| `al_npc_<idx>` | object | Ссылка на зарегистрированного NPC по индексу 0..`al_npc_count-1`. |

Дополнительно (по контексту маршрутов): `al_routes_cached`, `al_route_*` используются для area-level кэша waypoint/tag данных.

### 3.2 NPC locals

| Local key | Тип | Назначение |
|---|---|---|
| `r_slot` | int | Активный слот маршрута, для которого сейчас запущен route-loop. |
| `r_idx` | int | Текущий индекс точки в активном маршруте. |
| `r_active` | int/bool | Флаг, что route-loop активен и может принимать `AL_EVT_ROUTE_REPEAT`. |
| `al_last_slot` | int | Последний применённый слот активности; защита от лишних повторных применений. |
| `al_last_area` | object | Последняя area NPC для корректного unregister/register при переходах. |

---

## 4) Таблица событий

| Event | Кто генерирует | Trigger-условие | Что делает получатель (`al_npc_onud.nss`) |
|---|---|---|---|
| `AL_EVT_SLOT_0 .. AL_EVT_SLOT_5` | `AreaTick` через `AL_BroadcastUserEvent` | Зафиксирована смена `al_slot` в area | NPC переключает поведение на слот, обновляет route/activity, при необходимости запускает новый route-loop. |
| `AL_EVT_RESYNC` | `al_area_onenter`, `AL_UnhideAndResyncRegisteredNPCs`, `al_npc_onspawn`, `AL_HandleRouteAreaTransition` | Нужна полная пересинхронизация NPC с текущим состоянием area | Берёт `nSlot` из `area.al_slot`, сбрасывает `al_last_slot=-1`, пересобирает route/activity с нуля. |
| `AL_EVT_ROUTE_REPEAT` | сам NPC (через `ActionDoCommand(SignalEvent(...))`) | Завершён проход по route без межзонового transition, либо запланирован repeat-пульс | Продолжает route-loop в текущем `r_slot`; игнорируется если `r_active==FALSE`, route пустой или слот устарел. |

---

## 5) Ограничения и инварианты

1. **Лимит registry:** `AL_MAX_NPCS = 100`. При переполнении новые NPC не регистрируются (опционально пишется debug-сообщение).
2. **Инвариант плотного массива registry:** `al_npc_0..al_npc_count-1` без дыр; удаление делается swap-with-last (`AL_PruneRegistrySlot`).
3. **Смена area через route jump:** `AL_HandleRouteAreaTransition` обязательно делает:
   - `AL_UnregisterNPC` из старой area,
   - обновление `al_last_area`,
   - `AL_RegisterNPC` в новой area,
   - если в новой area нет игроков — NPC скрывается и route очищается,
   - `AL_EVT_RESYNC` для выравнивания состояния.
4. **Fallback активности:** если route/требования не выполняются, выбирается fallback:
   - slot-specific `al_slot_activity_<slot>` (NPC -> area),
   - затем `al_default_activity` (NPC -> area),
   - если ничего не задано — `AL_ACT_NPC_ACT_ONE`.
5. **Обработка скрытого состояния:** при `AL_ACT_NPC_HIDDEN` активный route прекращается (clear actions + сброс runtime route locals).

---

## 6) Известные риски и рекомендации по расширению

### 6.1 Известные риски

1. **Тихое переполнение registry:** при достижении `AL_MAX_NPCS` лишние NPC не получают событий (скрытое функциональное выпадение).
2. **Расхождение route tag vs activity requirements:** если activity требует специальный tag (`AL_WP_PACE`, `AL_WP_WWP`), а route tag другой/пустой, система уйдёт в fallback activity.
3. **Ошибки в transition metadata у waypoint:** неполный `al_transition_*` может ломать межзоновые переходы и вызывать неожиданные route reset/resync.
4. **Переизбыток `AL_EVT_ROUTE_REPEAT`:** при большом числе NPC возможен шум событий и частые ActionQueue перестроения.
5. **Зависимости на парные роли (training/bar):** смерть/деспаун одного NPC приводит к деградации активности второго в fallback.

### 6.2 Рекомендации по расширению

#### Новые активности
1. Добавить константу в `al_acts_inc.nss`.
2. Прописать анимации в `AL_GetActivityCustomAnims` и/или `AL_GetActivityNumericAnims`.
3. Если нужно — задать требования в `AL_GetActivityWaypointTag`, `AL_ActivityRequiresTrainingPartner`, `AL_ActivityRequiresBarPair`.
4. Проверить fallback-поведение в `AL_GetWaypointActivityForSlot`.

#### Новые route tags
1. Выбрать нейминг вида `AL_WP_<TAG>` и согласовать его с `alwp<slot>` locals (если используется override на NPC).
2. Проверить, что соответствующие waypoint действительно существуют в area и доступны для кэша.
3. Для межзоновых маршрутов валидировать `al_transition_location` или набор `al_transition_area/x/y/z/facing`.
4. Прогнать сценарии:
   - вход первого игрока,
   - смена временного слота,
   - transition в area без игроков,
   - возврат игроков и `AL_EVT_RESYNC`.
