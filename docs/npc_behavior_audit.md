# Полный аудит модуля поведения NPC (актуальное состояние)

> Версия аудита основана на текущем коде из `src/modules/npc` и связанных include интеграциях `src/integrations/nwnx_sqlite`.
>
> В аудит **не включались** `third_party/` и компилятор внутри этой папки (по вашему правилу).

## 1) Границы модуля и входные точки

Модуль NPC работает как area-local runtime-контур с тонкими hook-скриптами и единым фасадом `npc_core`.

### Event hooks

- `npc_module_load` → `NpcBhvrOnModuleLoad`
- `npc_spawn` → `NpcBhvrOnSpawn`
- `npc_perception` → `NpcBhvrOnPerception`
- `npc_damaged` → `NpcBhvrOnDamaged`
- `npc_death` → `NpcBhvrOnDeath`
- `npc_dialogue` → `NpcBhvrOnDialogue`
- `npc_area_enter` → `NpcBhvrOnAreaEnter`
- `npc_area_exit` → `NpcBhvrOnAreaExit`
- `npc_area_tick` → `NpcBhvrOnAreaTick`
- `npc_area_maintenance` → `NpcBhvrOnAreaMaintenance`

Именно эти обработчики формируют полный жизненный цикл NPC-поведения в мире.

---

## 2) Состояния area-controller и что они делают

Контроллер области имеет 3 состояния:

- `STOPPED (0)` — активный loop выключен, очередь и registry очищены.
- `RUNNING (1)` — рабочий тиковый цикл (интервал 1 секунда), обработка очереди, idle fan-out, flush write-behind.
- `PAUSED (2)` — редкий watchdog-тик (30 секунд), без штатного event-drain как в RUNNING.

### Переходы

- **Activate**: применяется runtime-конфиг бюджетов, прогревается route cache, запускаются tick + maintenance таймеры.
- **Pause**: фиксируется состояние `PAUSED`, запускается maintenance watchdog.
- **Stop**: выполняется maintenance, затем state=`STOPPED`, сбрасываются таймеры, route cache, idle cursor и очередь.

### Что это означает в игре

- Если в области есть игроки/активность — поведение NPC «живое» и обновляется каждую секунду.
- Если игроков нет — область может уйти в паузу/остановку, чтобы не тратить ресурсы сервера.
- При возвращении активности area снова активируется и продолжает поведенческий цикл.

---

## 3) Очередь событий и приоритеты

### Приоритеты

- `CRITICAL`
- `HIGH`
- `NORMAL`
- `LOW`

Очередь ограничена (`NPC_BHVR_QUEUE_MAX=64`) и хранится bucket-ами по приоритету.

### Как событие попадает в работу

1. Событие enqueue-ится в area queue.
2. Если NPC уже в очереди — выполняется **coalesce** (дубликат не создаётся, приоритет может быть повышен).
3. Для причины `damage` действует форс-эскалация до `CRITICAL`.

### Overflow-поведение

- Для non-critical входящих событий при переполнении применяется guardrail: попытка вытеснить хвост низших приоритетов.
- Если вытеснение невозможно — событие помечается `dropped`, метрики фиксируют деградацию.
- CRITICAL/урон не должны «тихо растворяться» как обычные low-priority сигналы.

### Fairness внутри области

- `CRITICAL` обслуживается первым и bypass-ит starvation fairness.
- Для `HIGH/NORMAL/LOW` действует курсор + starvation streak guard (`NPC_BHVR_STARVATION_STREAK_LIMIT=3`).
- Это предотвращает вечное голодание lower-bucket при постоянном потоке high-bucket.

### Что это означает в игре

- Боевая/критичная реакция NPC сохраняет приоритет даже под нагрузкой.
- Вторичные реакции (например, косметические/фоновые) могут откладываться или отбрасываться при перегрузе.

---

## 4) Тиковый конвейер (tick pipeline)

В `RUNNING` каждый тик проходит одинаковые стадии:

1. **Idle fan-out gate**
   - Если pending-очередь пуста, запускается ограниченный idle-broadcast по registry NPC.
   - Если очередь не пуста, idle fan-out пропускается (бюджет уходит на drain очереди).

2. **Нормализация бюджетов**
   - `tick_max_events` и `tick_soft_budget_ms` приводятся к допустимым границам.
   - Учитывается `carryover` с предыдущего деградированного тика.

3. **Budgeted queue processing**
   - Обработка событий идёт до исчерпания event budget и/или soft time budget.

4. **Degradation + carryover**
   - Если бюджет исчерпан при наличии pending backlog, фиксируется degraded mode,
     выставляется reason-code и переносится ограниченный carryover.

5. **Deferred reconcile/trim**
   - Контроль deferred-total, trim overflow выше cap, синхронизация totals при мутации.

6. **Telemetry + flush + idle-stop**
   - Метрики backlog/processed/degradation.
   - Write-behind flush в SQLite при выполнении условий.
   - Если игроков нет и очередь пуста — auto-stop области.

### Что это означает в игре

- NPC не «залипают» под burst-нагрузкой: система деградирует управляемо, а не блокируется.
- Поведение подстраивается под бюджет сервера, сохраняя приоритет критичных событий.

---

## 5) Реестр NPC (registry) и idle-поведение

Registry — area-local индекс NPC-объектов (до `NPC_BHVR_REGISTRY_MAX=100`).

### Назначение

- Быстрый обход NPC для фонового idle-такта без full-scan области каждый тик.
- Работа через slot+index пары с компактированием невалидных записей в maintenance.

### Idle dispatch

- `NpcBhvrRegistryBroadcastIdleTickBudgeted` обходит registry по курсору.
- За тик обрабатывается ограниченное количество NPC (адаптивный бюджет).
- Сохраняются per-tick метрики: сколько idle обработано и сколько осталось.

### Что это означает в игре

- Фоновая «жизнь» NPC (анимации/роуты/слоты) поддерживается равномерно,
  но не «съедает» ресурсы при перегруженной event-очереди.

---

## 6) Игровое поведение NPC (activity subsystem)

Activity-подсистема управляет тем, **что NPC делает в мире** в idle/реактивных переходах:

- слот активности (`default/priority/critical`),
- маршрут (`route`),
- waypoint progression,
- action/emote/activity_id,
- cooldown и timestamp последнего перехода,
- schedule-aware выбор слота по часам.

### Ключевой принцип

`NpcBhvrActivityOnIdleTick` вызывается:
- либо из queue processing (когда событие dequeued для NPC),
- либо из registry idle broadcast (когда очередь пуста).

То есть поведение NPC всегда идёт через единый activity-dispatch путь.

### Расписания (schedule-aware slots)

Если `npc_activity_schedule_enabled=1`, слот выбирается по окнам:

- `npc_schedule_start_critical` / `npc_schedule_end_critical`
- `npc_schedule_start_priority` / `npc_schedule_end_priority`

Правила:
- `start == end` → окно считается пустым (защита от accidental always-on),
- `start < end` → обычное дневное окно,
- `start > end` → окно через полночь.

Приоритет выбора слота: `critical` → `priority` → `default`.

### Waypoint/route механика

Если для route задан count/tag, activity-state получает waypoint-суффиксы
и продвигает `npc_activity_wp_index` с учётом loop-policy.

### Валидация идентификаторов

- routeId: `1..32`, только `[a-z0-9_]`, иначе fallback `default_route`.
- routeTag: `1..24`, только `[a-z0-9_]`, иначе fallback `default`.

### Что это означает в игре

- NPC следуют предсказуемым сценариям (патруль, рутина, safe-state) по слотам/расписанию.
- Контент с невалидными route/tag не ломает runtime — применяется детерминированный fallback.

---

## 7) Pending/deferred контракты и целостность состояния

Для каждого NPC поддерживается pending-state (priority/reason/status/updated_at)
в двух зеркалах:

- NPC-local,
- area-local (диагностическое зеркало по subject-tag).

### Важные инварианты

- Terminal-clear (`processed/dropped/death`) очищает pending явно.
- Deferred не должен неявно очищать pending до terminal transition.
- `updated_at` пишется монотонно и с секундной точностью.

### Зачем это нужно

- Диагностика queue pipeline по конкретному NPC.
- Устойчивость к частичным сбоям и self-heal reconcile в maintenance.

---

## 8) Maintenance loop и self-heal

`npc_area_maintenance` выполняется реже основного тика и отвечает за тяжёлые операции:

- reconcile deferred-total,
- compact invalid registry entries,
- периодический self-heal консистентности area-local runtime-структур.

Это сознательно вынесено из hot-path, чтобы не увеличивать стоимость каждого `npc_area_tick`.

---

## 9) Персистентность и SQLite write-behind

На `OnModuleLoad` вызываются `NpcSqliteInit` и `NpcSqliteHealthcheck`.
В тике используется write-behind-модель:

- enqueue помечает dirty,
- flush выполняется по batch/interval политике.

### Что это означает в игре

- Снижение write-amplification при массовых NPC-событиях.
- Более предсказуемая стоимость IO относительно runtime-такта.

---

## 10) Карта «механизм → где участвует»

| Механизм | Где в коде | В какой работе участвует |
|---|---|---|
| Area lifecycle (`RUNNING/PAUSED/STOPPED`) | `npc_lifecycle_inc.nss` | Запуск/пауза/остановка area AI и таймеров |
| Bounded priority queue | `npc_queue_inc.nss` | Приём и упорядочивание реактивных событий NPC |
| Fairness + starvation guard | `npc_tick_inc.nss` | Справедливый drain `HIGH/NORMAL/LOW` при постоянной нагрузке |
| Degraded mode + carryover | `npc_tick_inc.nss` | Управляемая деградация при переполнении бюджета |
| Deferred reconcile/trim | `npc_tick_inc.nss`, `npc_queue_deferred_inc.nss` | Self-heal и удержание deferred backlog в cap |
| Registry idle broadcast | `npc_registry_inc.nss` | Фоновое поведение NPC при пустой очереди |
| Activity dispatch / routes / schedules | `npc_activity_inc.nss` (+ related includes) | Игровая «рутина» NPC, слоты, маршруты, анимационный контекст |
| Pending mirrors | `npc_queue_inc.nss`, `npc_queue_pending_inc.nss` | Диагностика и консистентность состояния по каждому NPC |
| Write-behind SQLite | `npc_tick_inc.nss`, `src/integrations/nwnx_sqlite/*` | Пакетная запись runtime-изменений без перегруза hot-path |
| Metrics | `npc_metrics_inc.nss` + вызовы во всех include | Наблюдаемость и эксплуатационный контроль поведения |

---

## 11) Практические выводы аудита

1. Модуль уже реализует production-подход: приоритеты, bounded queue, деградация, self-heal maintenance, адаптивный idle-budget.
2. Игровое поведение NPC централизовано через activity subsystem; это упрощает расширение контента без изменения базового tick-контракта.
3. Наибольшая операционная ценность — в метриках деградации/overflow/deferred: они напрямую показывают, хватает ли бюджеты текущему контенту.
4. Для контент-команд критично соблюдать валидные route/tag и корректно настраивать schedule-окна, иначе поведение уйдёт в fallback-сценарии.

