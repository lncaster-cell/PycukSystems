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
│  └─ при al_player_count==0 вызывает единый helper `AL_HandleAreaBecameEmpty`
├─ al_mod_onleave.nss
│  ├─ fallback для дисконнекта клиента: декрементирует al_player_count
│  └─ при al_player_count==0 вызывает тот же `AL_HandleAreaBecameEmpty`
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
│  ├─ на `AL_EVT_RESYNC` сначала переинициализирует pair subsystem
│  ├─ пересобирает route для nSlot только по NPC local `alwp<slot>`
│  ├─ управляет route loop и повторной доставкой AL_EVT_ROUTE_REPEAT
│  └─ применяет активность/анимацию без legacy fallback-источников
└─ al_npc_ondeath.nss
   ├─ чистит связи training/bar пар
   ├─ сбрасывает area-кэш пар (если погиб ключевой NPC)
   └─ удаляет NPC из registry

Domain includes
├─ al_npc_reg_inc.nss
│  ├─ registry на area locals: al_npc_count + al_npc_<idx>
│  ├─ AL_RegisterNPC / AL_UnregisterNPC / AL_SyncAreaNPCRegistry
│  ├─ AL_HideRegisteredNPCs / AL_UnhideAndResyncRegisteredNPCs
│  ├─ AL_HandleAreaBecameEmpty(area) — единая обработка empty-area
│  └─ AL_BroadcastUserEvent(area, event)
├─ al_npc_routes.nss
│  ├─ route cache на NPC locals: r<slot>_n, r<slot>_<idx>, ...
│  ├─ runtime route-state: r_slot, r_idx, r_active
│  ├─ AL_QueueRoute() (Move/Jump/Repeat)
│  └─ AL_HandleRouteAreaTransition() (смена area, перерегистрация, ресинк)
├─ al_npc_acts_inc.nss
│  ├─ AL_GetWaypointActivityForSlot() строго из waypoint `al_activity`
│  ├─ проверка route requirements / training / bar pair
│  └─ применение custom/numeric анимаций
├─ al_npc_pair_inc.nss
│  └─ AL_InitTrainingPartner / AL_InitBarPair (runtime-resync пар)
└─ al_acts_inc.nss
   ├─ enum activity-констант
   ├─ mapping activity -> custom/numeric animation set
   └─ правила activity requirements (waypoint tag, training pair, bar pair)
```

---

## 2) Жизненный цикл

### 2.1 Вход первого игрока -> wake-контур и запуск `AreaTick`
1. `al_area_onenter.nss` обрабатывает только PC, сбрасывает anti-double-exit флаг на игроке (`al_exit_counted`).
2. Увеличивает `al_player_count`.
3. Если это **первый** игрок (`al_player_count == 1`):
   - выполняет wake-цепочку в фиксированном порядке (см. §2.1.1),
   - планирует первый `AreaTick(area, token)` через `AL_TICK_PERIOD`.

#### 2.1.1 Wake-порядок (контракт)

Wake всегда описывается как единый канонический порядок шагов:

1. **Bump token** — инкремент `al_tick_token` (новая wake-эпоха).
2. **Slot compute** — вычисление и запись `al_slot = AL_ComputeTimeSlot()`.
3. **Registry sync** — `AL_SyncAreaNPCRegistry()`.
4. **Route cache readiness** — подготовка route cache для area (`AL_CacheAreaRoutes`/эквивалентная гарантия готовности кэша).
5. **Unhide + RESYNC** — `AL_UnhideAndResyncRegisteredNPCs`.
6. **Schedule tick** — первый `DelayCommand(... AreaTick(area, token))`.

Для каждого NPC внутри шага 5 закреплён обязательный wake-контракт:
- доставка `AL_EVT_RESYNC` обязательна для любого wake-варианта (включая fast wake);
- до применения activity/route обязателен проход `AL_InitTrainingPartner` + `AL_InitBarPair`;
- сразу после pair-init обязателен `AL_RevalidateAreaPairLinksForWake`.

#### 2.1.2 Обязательность шагов (COLD/WARM)

- **COLD wake (первый запуск после empty-area / сброшенного состояния):** шаги 1–6 обязательны.
- **WARM wake (повторный wake без полного teardown):**
  - **обязательные:** 1, 2, 3, 5, 6;
  - **опциональный:** 4 (можно пропустить только если есть валидный признак, что area route-cache уже готов и актуален для текущей wake-эпохи).

#### 2.1.3 Диагностический маркер wake-эпохи (area)

Для дебага в контракте фиксируется area-level маркер wake-эпохи:

- `al_wake_epoch` — монотонный локал-счётчик (инкремент на каждом wake),
- опционально: `al_wake_epoch_ts` — timestamp последнего wake.

Маркер используется только для диагностики/трассировки и не заменяет `al_tick_token` как runtime-guard актуальности тика.

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

### 2.3 Выход последнего игрока / дисконнект -> единый empty-area handler
1. `al_area_onexit.nss` (обычный выход из area) и `al_mod_onleave.nss` (дисконнект/leave клиента) обрабатывают только PC и защищаются от двойного учёта через `al_exit_counted`.
2. Оба скрипта уменьшают `al_player_count` (не ниже 0).
3. Если после декремента игроков не осталось (`al_player_count == 0`), оба события вызывают единый helper `AL_HandleAreaBecameEmpty(oArea)`.
4. `AL_HandleAreaBecameEmpty` централизованно выполняет:
   - инкремент `al_tick_token` (инвалидация ранее запланированных `AreaTick`),
   - `DeleteLocalInt(oArea, "al_tick_scheduled_token")` (reset дедупликации планировщика тиков),
   - `DeleteLocalInt(oArea, "al_routes_cached")` (форс полной пересборки route-cache при следующем запуске),
   - `AL_HideRegisteredNPCs` (freeze NPC), где перед hide применяется правило sleep-reset: очистка action queue + возврат collision/state в безопасный baseline (`al_sleep_*` сброшены).

### 2.4 Порядок обработки `al_exit_counted` и `al_last_area` по всем exit-сценариям

| Сценарий | Порядок событий | `al_exit_counted` | `al_last_area` | Результат по `al_player_count` |
|---|---|---|---|---|
| Обычный переход PC A->B (оба area в модуле) | `al_area_onexit(A)` -> `al_area_onenter(B)` | Ставится в `1` на `OnExit`, затем удаляется на `OnEnter` | На `OnEnter` перезаписывается на `B` | `A: -1`, `B: +1`; двойной декремент исключён |
| Дисконнект после `OnExit`, но до `OnEnter` (transition/лоадинг) | `al_area_onexit(A)` -> `al_mod_onleave` | Уже `1`, поэтому `OnClientLeave` завершится early-return | Остаётся последняя валидная area (обычно `A`) до следующего входа | Декремент выполняется только один раз в `A` |
| Дисконнект без `OnExit` (например, сетевой обрыв в area) | `al_mod_onleave` | Если `0`, ставится в `1` внутри `OnClientLeave` | Берётся `GetArea(oLeaving)`; если invalid — fallback в `al_last_area` | Один декремент в найденной area; защита от negative сохраняется |
| Массовый релог (N клиентов почти одновременно) | N вызовов `OnExit/OnClientLeave` в произвольном порядке | На каждом PC флаг ставится максимум один раз до следующего `OnEnter` | Для каждого PC локаль очищается/обновляется при повторном входе | Для каждой area счётчик уменьшается ровно на число уникально вышедших PC |

Практический инвариант: `al_exit_counted` живёт только между событием выхода и следующим `al_area_onenter`; `al_last_area` — это страховка для leave-событий, где `GetArea` уже недоступен.

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
| `al_event_noise_total` | int | Счётчик всех обработанных AL-событий на area (для runtime-профилирования шума). |
| `al_event_noise_route_repeat` | int | Счётчик обработок `AL_EVT_ROUTE_REPEAT` на area (целевая метрика шумной переочереди). |

Дополнительно (по контексту маршрутов): `al_routes_cached`, `al_route_*` используются для area-level кэша waypoint/tag данных.
`al_route_index` на waypoint (если используется) должен быть в диапазоне `0..1023`; значения вне диапазона игнорируются при построении area-cache и логируются в debug.

### 3.2 NPC locals

| Local key | Тип | Назначение |
|---|---|---|
| `r_slot` | int | Активный слот маршрута, для которого сейчас запущен route-loop. |
| `r_idx` | int | Текущий индекс точки в активном маршруте. |
| `r_active` | int/bool | Флаг, что route-loop активен и может принимать `AL_EVT_ROUTE_REPEAT`. |
| `al_last_slot` | int | Последний применённый слот активности; защита от лишних повторных применений. |
| `al_last_area` | object | Последняя area NPC для корректного unregister/register при переходах. |
| `al_anim_next` | int | Антиспам-маркер времени для повторной анимации на `AL_EVT_ROUTE_REPEAT`. |
| `al_sleep_docked` | int/bool | Флаг, что NPC сейчас припаркован в sleep docking-позиции. |
| `al_sleep_approach_tag` | string | Tag `approach`-waypoint для возврата из docked sleep. |

### 3.3 Freeze side effects (ключевые local-поля)

| Local key | Где меняется при freeze | Что происходит в freeze | Что происходит после wake (`AL_EVT_RESYNC`) |
|---|---|---|---|
| `al_tick_token` (area) | area-level | Инкрементируется для инвалидации старых `AreaTick(area, token)` | На новом onenter снова инкрементируется и используется для планирования нового валидного тика. |
| `al_tick_scheduled_token` (area) | area-level | Удаляется, чтобы сбросить dedupe «тик уже запланирован» | Выставляется заново при первом `AL_ScheduleNextTick` в новом цикле. |
| `al_routes_cached` (area) | area-level | Удаляется, forcing full recache маршрутов | Ставится обратно в `1` после `AL_CacheAreaRoutes` в новом рабочем цикле. |
| `r_active` (NPC) | NPC freeze-reset | Явно очищается в `FALSE` перед hide | На `AL_EVT_RESYNC` route поднимается заново только из актуального `nSlot` и собранного route-loop. |
| `r_slot` (NPC) | NPC freeze-reset | Явно очищается в `-1` перед hide | На `AL_EVT_RESYNC` переустанавливается из `area.al_slot` во время нового старта route-loop. |
| `r_idx` (NPC) | NPC freeze-reset | Явно очищается в `-1` перед hide | На `AL_EVT_RESYNC` индекс рассчитывается заново от первой валидной точки текущего маршрута. |
| `al_anim_next` (NPC) | freeze не трогает | Сохраняется throttle-маркер анимации | Используется как есть; повторная анимация допускается только когда наступит окно по anti-spam логике. |
| `al_sleep_docked` (NPC) | NPC freeze-reset | Явно очищается в `FALSE` перед hide | На wake sleep-активность стартует с чистого состояния docking. |
| `al_sleep_approach_tag` (NPC) | NPC freeze-reset | Явно очищается в пустую строку перед hide | При следующем sleep-проходе tag выбирается заново из актуального route/waypoint-контекста. |
| collision (`SetCollision`) | NPC freeze-reset | Принудительно возвращается в `TRUE` перед hide | После wake collision управляется обычной activity-логикой без наследования freeze-артефактов. |

### 3.4 OFF transition policy (owner decision)

Переход в `OFF` для AL-контура (area без игроков / explicit disable) должен иметь явную, фиксированную политику на уровне владельца подсистемы:

- **Вариант A (рекомендуемый по умолчанию):** очищать runtime links и route locals в freeze-path (`r_*`, runtime pair-links, sleep-state), чтобы re-enter в AL всегда шёл через полностью чистый `AL_EVT_RESYNC`.
- **Вариант B (допустим только по отдельному решению владельца):** сохранять runtime links/route locals до re-enter; при этом owner обязан документировать, какие поля считаются переносимыми между OFF/ON и как предотвращается stale-state.

До формального решения владельца поведение считается **owner-gated** и не должно меняться точечно в отдельных скриптах без обновления этого раздела.

---

## 4) Таблица событий

| Event | Кто генерирует | Trigger-условие | Что делает получатель (`al_npc_onud.nss`) |
|---|---|---|---|
| `AL_EVT_SLOT_0 .. AL_EVT_SLOT_5` | `AreaTick` через `AL_BroadcastUserEvent` | Зафиксирована смена `al_slot` в area | NPC переключает поведение на слот, обновляет route/activity, при необходимости запускает новый route-loop. |
| `AL_EVT_RESYNC` | `al_area_onenter`, `AL_UnhideAndResyncRegisteredNPCs`, `al_npc_onspawn`, `AL_HandleRouteAreaTransition` | Нужна полная пересинхронизация NPC с текущим состоянием area (обязательно для любого wake, включая fast wake) | Берёт `nSlot` из `area.al_slot`, сбрасывает `al_last_slot=-1`, обязательно выполняет `AL_InitTrainingPartner` + `AL_InitBarPair` + `AL_RevalidateAreaPairLinksForWake`, затем пересобирает route/activity с нуля. |
| `AL_EVT_ROUTE_REPEAT` | сам NPC (через `ActionDoCommand(SignalEvent(...))`) | Завершён проход по route без межзонового transition, либо запланирован repeat-пульс | Продолжает route-loop в текущем `r_slot`; игнорируется если `r_active==FALSE`, route пустой или слот устарел. Для single-point route повторная переочередь ограничивается только в WARM-состоянии area (`al_player_count > 0`). |

---

## 5) Ограничения и инварианты

1. **Лимит registry:** `AL_MAX_NPCS = 100`. При переполнении новые NPC не регистрируются (опционально пишется debug-сообщение).
2. **Лимит точек маршрута NPC:** `AL_ROUTE_MAX_POINTS = 10` (см. `al_constants_inc.nss`). `AL_CacheRouteFromTag` копирует не более этого числа точек из area-cache в NPC locals; при `al_debug=1` на NPC или area выводится сообщение о том, что маршрут по тегу был усечён до лимита.
3. **Инвариант плотного массива registry:** `al_npc_0..al_npc_count-1` без дыр; удаление делается swap-with-last (`AL_PruneRegistrySlot`).
4. **Смена area через route jump:** `AL_HandleRouteAreaTransition` обязательно делает:
   - `AL_UnregisterNPC` из старой area,
   - обновление `al_last_area`,
   - `AL_RegisterNPC` в новой area,
   - если в новой area нет игроков — NPC скрывается и route очищается,
   - `AL_EVT_RESYNC` для выравнивания состояния.
5. **Источник активности:** активность берётся только из `al_activity` текущего waypoint маршрута; если точка/активность некорректна — используется безопасный `AL_ACT_NPC_ACT_ONE`.
6. **Обработка скрытого состояния:** при `AL_ACT_NPC_HIDDEN` активный route прекращается (clear actions + сброс runtime route locals).
7. **Симметрия bar-пары:** активности `AL_ACT_NPC_BARMAID` и `AL_ACT_NPC_BARTENDER` обе требуют валидный local `al_bar_pair`; при потере партнёра обе роли одинаково деградируют в `AL_ACT_NPC_ACT_ONE`.
8. **Актуальность `*_ref`-локалов пар:** `al_training_npc*_ref` и `al_bar_*_ref` должны обновляться при замене ключевых NPC; при невалидном/"мёртвом" ref runtime-пара очищается и остаётся в безопасном unbound-состоянии до появления валидной ссылки.
9. **Fallback после wake/resync для парных активностей:** если после `AL_InitTrainingPartner`/`AL_InitBarPair` пара остаётся невалидной, activity не «дрейфует» в stale-state — применяется явный защитный режим `AL_ACT_NPC_ACT_ONE` (в debug-area дополнительно пишется диагностическое сообщение о fallback).

---

## 6) Известные риски и рекомендации по расширению

### 6.1 Известные риски

1. **Тихое переполнение registry:** при достижении `AL_MAX_NPCS` лишние NPC не получают событий (скрытое функциональное выпадение).
2. **Расхождение route tag vs activity requirements:** если activity требует специальный tag (`AL_WP_PACE`, `AL_WP_WWP`), а route tag другой/пустой, система принудительно переключится в `AL_ACT_NPC_ACT_ONE`.
3. **Ошибки в transition metadata у waypoint:** неполный `al_transition_*` может ломать межзоновые переходы и вызывать неожиданные route reset/resync.
4. **Переизбыток `AL_EVT_ROUTE_REPEAT`:** при большом числе NPC возможен шум событий и частые ActionQueue перестроения.
5. **Зависимости на парные роли (training/bar):** смерть/деспаун одного NPC приводит к деградации активности второго в `AL_ACT_NPC_ACT_ONE`.

### 6.2 Рекомендации по расширению

### 6.2.1 Минимальная модель кварталов и соседства area (без глобального scheduler)

Цель: обеспечить локальный прогрев/охлаждение area без введения централизованного оркестратора.

**Минимальные locals на area:**
1. `al_quarter_id` (`string`) — квартал, к которому принадлежит area.
2. `al_adjacent_areas` (`string`, CSV по area-tag) — прямые соседи area.
3. `al_area_heat` (`int`) — текущее состояние прогрева:
   - `0` = `COLD`
   - `1` = `WARM`
   - `2` = `HOT`

Этого достаточно для локального резолва соседства «по месту», когда событие пробуждения/активности обрабатывается в конкретной area и распространяется максимум на 1 hop по adjacency.

### 6.2.2 Правила резолва соседства

1. Если area-источник получает/удерживает `HOT`, её прямые соседи из `al_adjacent_areas` могут подниматься в `WARM`.
2. Повышение соседей ограничивается уровнем `WARM` (без автоматического каскада `WARM -> HOT` только из-за соседства).
3. При отсутствии у соседа валидной конфигурации прогрев не эскалируется выше локального fallback, чтобы не разгонять «ложный heat-wave».

### 6.2.3 Правило для interior area

`Interior`-area по умолчанию маркируется кандидатом в `COLD`, если одновременно:
1. нет прямого wake-триггера (игрок, системный ресинк, сценарное событие);
2. нет явного принудительного heat-state из контента/скрипта.

Это правило нужно для стабилизации фоновой нагрузки: interior зоны не удерживаются в `WARM/HOT` только по историческому состоянию.

### 6.2.4 Fallback при неполном adjacency-конфиге

При битом/неполном `al_adjacent_areas` (пустой CSV, несуществующие tag, циклические ссылки с отсутствующими целями):
1. рантайм **не должен** молча игнорировать проблему;
2. в debug-режиме (`al_debug=1`) должна появляться явная запись о fallback-пути;
3. area продолжает работать в локальном режиме (обновление собственного `al_area_heat` без обязательного уведомления соседей);
4. обработка не прерывает текущий area-tick и не ломает базовые `AL_EVT_*`-циклы.

#### Новые активности
1. Добавить константу в `al_acts_inc.nss`.
2. Прописать анимации в `AL_GetActivityCustomAnims` и/или `AL_GetActivityNumericAnims`.
3. Если нужно — задать требования в `AL_GetActivityWaypointTag`, `AL_ActivityRequiresTrainingPartner`, `AL_ActivityRequiresBarPair`.
4. Проверить, что `al_activity` проставлен на всех waypoint целевого маршрута.

#### Новые route tags
1. Выбрать нейминг вида `AL_WP_<TAG>` и задать его напрямую в NPC locals `alwp0` и `alwp5`.
2. Проверить, что соответствующие waypoint действительно существуют в area и доступны для кэша.
3. Для межзоновых маршрутов валидировать `al_transition_location` или набор `al_transition_area/x/y/z/facing`.
4. Прогнать сценарии:
   - вход первого игрока,
   - смена временного слота,
   - transition в area без игроков,
   - возврат игроков и `AL_EVT_RESYNC`.

---


### 6.3 Настройка сна через 2 waypoint и walkmesh
1. На route-waypoint сна (где `al_activity` указывает sleep-loop) задайте одну из схем:
   - `al_bed_tag=<BED_ID>` + пара waypoint `<BED_ID>_approach` и `<BED_ID>_pose`;
   - либо явные теги: `al_bed_approach_wp=<tag>`, `al_bed_pose_wp=<tag>`.
2. Требования к позиционированию:
   - `approach` должен стоять на проходимом walkmesh (NPC приходит туда через `ActionMoveToLocation`);
   - `pose` допускается на кровати/вне walkmesh, т.к. укладка выполняется `ActionJumpToLocation` с временным `SetCollision(FALSE)`.
3. Поведение рантайма:
   - при успешном docking ставятся локалы `al_sleep_docked=1`, `al_sleep_approach_tag=<tag>`;
   - при выходе из сна NPC прыгает обратно в `approach`, затем возвращает `SetCollision(TRUE)`;
   - при freeze area (`al_player_count -> 0`) до `SetScriptHidden(TRUE)` выполняется принудительный sleep-reset: чистятся действия, сбрасываются `al_sleep_*`, collision возвращается в TRUE (чтобы не оставлять подвешенный sleep/collision-state на период hide);
   - если `approach` не найден, включается fallback: сон без docking (анимация на месте/«на полу»).
4. Freeze/post-wake reset-поля (обязательный sanity check):
   - `al_sleep_docked` (delete);
   - `al_sleep_approach_tag` (delete);
   - `r_active`, `r_slot`, `r_idx` (delete);
   - collision NPC принудительно возвращается в `TRUE`.
5. Совместимость:
   - reset не конфликтует с `AL_StopSleepAtBed`: helper вызывается только когда `al_sleep_docked=1`; после freeze-пути локал очищен и повторный вызов безопасно no-op;
   - очистка `r_active/r_slot/r_idx` гарантирует, что после wake запускается полный `AL_EVT_RESYNC`, а не «грязное» продолжение старого repeat-цикла.

## 7) Полный аудит модуля поведения (AL) — 2026-03-01

Ниже зафиксирован результат ревизии runtime-поведения NPC (`al_npc_onud` + `al_npc_acts_inc` + `al_npc_routes`) и связанного orchestration-слоя area/registry.

### 7.1 Что проверено

1. **Событийный контур поведения NPC**
   - входные события `AL_EVT_SLOT_*`, `AL_EVT_RESYNC`, `AL_EVT_ROUTE_REPEAT`;
   - защита от дублирования обработки через `al_last_slot`;
   - валидация слота и guard-ветки для устаревшего route repeat.
2. **Маршруты и переходы между area**
   - пересборка route по `alwp<slot>`;
   - копирование activity/transition-метаданных из area-cache;
   - lifecycle при `ActionJumpToLocation` и `AL_HandleRouteAreaTransition`.
3. **Применение активности/анимаций**
   - fallback-поведение при невалидной активности;
   - проверки требований активности (route-tag, training partner, bar pair);
   - антиспам анимаций на repeat через `al_anim_next`.
4. **Согласованность с area-циклом**
   - работа `al_tick_token` и остановка устаревших тиков;
   - hide/unhide при `al_player_count == 0/ >0`;
   - синхронизация registry на тике и при переходах.

### 7.2 Подтверждённые инварианты

1. **NPC не может жить в «битом» repeat-цикле слота:** repeat-ветка игнорируется, если route не активен/пуст или если `al_last_slot != r_slot`.
2. **Route всегда пересобирается из актуального `alwp<slot>`:** при смене desired-tag старый кэш очищается до копирования нового.
3. **Активность берётся из route-point metadata, а не из поиска waypoint в рантайме:** invalid/empty activity стабильно деградирует в `AL_ACT_NPC_ACT_ONE`.
4. **Требовательные активности защищены от разрыва пар/тегов:** при отсутствии training/bar-партнёра или нужного route-tag выполняется безопасный fallback.
5. **Межзоновые переходы не оставляют NPC в старом registry:** перед resync NPC перерегистрируется в актуальной area.

### 7.3 Выявленные риски (актуализировано)

1. **Непрозрачная деградация активности:** при несоблюдении требований (tag/пара) система молча уходит в `AL_ACT_NPC_ACT_ONE`, что может выглядеть как «сломанная постановка», а не как защитный режим.
2. **Чувствительность к качеству route metadata:** пустые/битые точки (`location` вне area, отсутствующий `_activity`, неконсистентный `_jump`) приводят к обнулению route-эффекта без явной ошибки для билдера локации.
3. **Event-noise при больших массах NPC:** `AL_EVT_ROUTE_REPEAT` остаётся основным механизмом повторного цикла и при плотной массовке может давать всплеск очередей действий.
4. **Ограничение на длину route:** всё, что длиннее `AL_ROUTE_MAX_POINTS`, тихо усекается (debug-сигнал виден только при `al_debug=1`).

### 7.4 Операционные рекомендации после аудита

1. Для staging/приёмки включать `al_debug=1` на area минимум на один суточный цикл, чтобы поймать:
   - route truncation;
   - area-mismatch route points;
   - переполнение registry.
2. После правок waypoint обязательно прогонять smoke-сценарии:
   - базовый: `onenter (1-й игрок)` -> `slot switch` -> `route repeat` -> `empty area` -> `resync`;
   - QA на freeze/wake: `sleep/pair activity active` -> `freeze (area empty)` -> `wake (player enter)` -> проверка корректного `AL_EVT_RESYNC` без reuse старых `r_active/r_slot/r_idx`.
3. Для парных ролей (training/bar) добавить в контент-процесс обязательный шаг ревизии `*_ref`-локалов после замены blueprint/респауна ключевых NPC.
4. Для особо загруженных area держать маршруты короткими и валидными по индексации, чтобы уменьшить шум `AL_EVT_ROUTE_REPEAT` и лишние clear/requeue.

### 7.4 QA-сценарии для проверки переходов и reconnect

1. **Быстрый переход area->area (A->B->A за минимальное время):**
   - шаги: пройти триггер A->B и сразу вернуться B->A; повторить 10+ раз;
   - ожидание: `al_player_count` в обеих area не уходит в минус и возвращается к исходному;
   - ожидание: на каждом входе `al_exit_counted` сбрасывается, `al_last_area` указывает на текущую area после `OnEnter`.
2. **Дисконнект в transition (после `OnExit`, до `OnEnter`):**
   - шаги: начать межзоновый переход и оборвать клиент в экране загрузки;
   - ожидание: `OnClientLeave` не делает второй декремент из-за `al_exit_counted=1`;
   - ожидание: old-area корректно доходит до `al_player_count==0` и один раз запускает `AL_HandleAreaBecameEmpty`.
3. **Массовый релог (burst reconnect):**
   - шаги: 15-30 клиентов одновременно выйти и зайти обратно в одну/несколько area;
   - ожидание: нет отрицательных счётчиков игроков, нет «залипших» скрытых NPC после возврата первого игрока;
   - ожидание: `AL_EVT_RESYNC` приходит однократно на unhide-цикл area, без каскадного дублирования.
4. **Transition-mode без двойного freeze/wake:**
   - шаги: отправить NPC по межзоновому route в area без игроков, затем завести туда игрока;
   - ожидание: при переходе в пустую area NPC скрывается ровно один раз (`SetScriptHidden(TRUE)` только если до этого был видим);
   - ожидание: при входе игрока NPC просыпается/размораживается ровно один раз (`SetScriptHidden(FALSE)` только если был скрыт), после чего получает единичный `AL_EVT_RESYNC`.
