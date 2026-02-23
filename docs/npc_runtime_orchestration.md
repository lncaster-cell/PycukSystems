# NPC Runtime Orchestration

Документ фиксирует runtime-контракт оркестрации NPC для area-local контроллеров: как они живут, как дозируют нагрузку, как обеспечивают fairness и как деградируют без потери критических событий.

## 1. Жизненный цикл area-controller

Каждая область (area) обслуживается отдельным `area-controller`, который имеет три базовых состояния:

- `RUNNING` — активная обработка очередей и тиковых задач;
- `PAUSED` — контроллер не диспатчит обычные задачи, но сохраняет метрики/состояние и может принимать критичные события;
- `STOPPED` — контроллер выгружен, состояние сброшено до минимально необходимого для восстановления.

### Переходы состояний

- **Старт (`START`)**
  - Триггер: в область входит первый игрок, либо область помечена как always-on (`npc_area_always_on = TRUE`).
  - Действия:
    - инициализация очередей и бакетов;
    - восстановление минимального runtime-состояния NPC;
    - запуск тикового цикла с warmup-ограничением.

- **Пауза (`PAUSE`)**
  - Триггер: в области нет игроков дольше `idlePauseAfter` (local `npc_area_idle_pause_after_sec`, default 30s).
  - Действия:
    - остановка heavy/non-critical dispatch;
    - сохранение агрегированных метрик;
    - перевод не-критичных входящих событий в defer-режим.

- **Остановка (`STOP`)**
  - Триггер: область в `PAUSED` дольше `idleStopAfter` (local `npc_area_idle_stop_after_sec`, default 180s) или инициирован unload/reload.
  - Инвариант runtime-деактивации: area-controller переводится в `STOPPED` только при `active_pc_count == 0` (в т.ч. при обработке area `OnExit`).
  - Действия:
    - освобождение буферов и внутренних структур (очередь area и owner-slot state);
    - reconciliation per-owner pending перед reset очереди, чтобы не оставлять dangling pending на NPC;
    - нормализация degraded mode флага (`npc_area_degraded_mode = FALSE`), чтобы следующий `START` не наследовал stale-state;
    - сохранение checkpoint состояния, достаточного для fast-resume;
    - отписка от area-local таймеров.

### Возобновление

При новом входе игрока:

- `PAUSED -> RUNNING`: быстрый resume без полной реинициализации;
- `STOPPED -> RUNNING`: cold start с восстановлением checkpoint и временным ограничением throughput, чтобы избежать startup-spike.

---

## 2. Batch dispatch модель

### Параметры

- `bucketSize` — количество сущностей/задач в одном bucket для равномерной нарезки работы.
- `batchDelay` — минимальная пауза между пакетами dispatch в пределах одного area-controller.
- `queueCapacity` — максимальная ёмкость входной очереди событий на область.
- `tickProcessLimit` — верхний лимит обработок за тик (абсолютный budget cap).

### Модель обработки

1. Intake складывает события в bounded queue (`queueCapacity`).
2. Coalesce схлопывает дубликаты/серии по ключам (`npcId`, `eventType`, `window`).
3. Dispatch берёт порции:
   - не больше `bucketSize` за один micro-batch;
   - не чаще, чем раз в `batchDelay`;
   - суммарно не больше `tickProcessLimit` за тик.
4. Остаток остаётся в очереди до следующего тика/батча.

### Переполнение очереди

При достижении `queueCapacity`:

- критичные события не отбрасываются: используется owner-aware вытеснение реального pending-элемента (`LOW -> NORMAL -> HIGH`) из bounded queue с синхронным обновлением area depth/buckets и pending-счётчиков владельца;
- non-critical события не вытесняют чужие элементы и переводятся в defer/coalesce вместо немедленного исполнения;
- фиксируется метрика перегрузки (`queue_overflow_count`, `deferred_count`).

---

## 2.1 Контракт tick-интервалов NPC

Для `NpcBehaviorOnHeartbeat` и связанной проверки `should-process` используется секундная шкала без дробной части:

- `npc_tick_interval_idle_sec` и `npc_tick_interval_combat_sec` задаются в целых секундах;
- минимально допустимое значение интервала — `1`;
- значения `< 1` считаются невалидными и нормализуются к дефолтам состояния (`idle=6`, `combat=2`);
- сравнение "пора ли обрабатывать" выполняется в одной шкале `elapsed_seconds >= interval_seconds`.

## 3. Fairness между областями и hot-area streak

### Базовая fairness-политика

Глобальный оркестратор распределяет бюджет между областями по round-robin/weighted round-robin:

- каждая активная область получает минимум `minAreaQuota`;
- дополнительный бюджет выдаётся по приоритету backlog и критичности;
- ни одна область не может бесконечно удерживать глобальный тик-бюджет.

### Hot-area streak

`hot-area streak` — ситуация, когда одна область много тиков подряд имеет максимальный backlog.

Поведение системы:

- для hot-area вводится `streakCap`: верхняя граница подряд идущих тиков с повышенной квотой;
- после достижения `streakCap` применяется cooling-window:
  - hot-area получает только базовую квоту;
  - освободившийся бюджет распределяется между другими активными областями;
- критичные события hot-area продолжают обслуживаться вне очереди в пределах reserve-бюджета.

Итог: система предотвращает starvation «тихих» областей и при этом не теряет важные сигналы из горячей зоны.

---

## 4. Приоритеты событий и деградация

### Классы приоритета

- `CRITICAL`: боевые и safety-критичные события, влияющие на корректность состояния.
- `HIGH`: важные игровые реакции с заметным UX-эффектом.
- `NORMAL`: штатные обновления поведения.
- `LOW`: косметические/второстепенные задачи.

### Гарантии

- `CRITICAL` **не дропаются** даже при перегрузке (допускается owner-aware вытеснение low/non-critical и emergency reserve budget).
- Для `HIGH/NORMAL/LOW` применяется graceful degradation:
  - coalesce (объединение/дедупликация в non-critical окне);
  - defer (перенос на следующие тики);
  - без вытеснения чужих pending-элементов при overflow.

### Режим деградации

Когда метрики перегрузки превышают пороги (`queueFillRatio`, `tickOverrun`, `streakCap`), контроллер автоматически переключается в degraded mode:

- non-critical задачи не исполняются немедленно, а переводятся в defer-очередь;
- частота тяжёлых обработчиков снижается;
- при нормализации метрик выполняется плавный выход из деградации без burst-догона.

---

## 5. Минимальный псевдокод цикла

```pseudo
onTick(area):
  budget = computeTickBudget(area)

  # intake
  incoming = pollIncomingEvents(area)
  enqueueBounded(area.queue, incoming, queueCapacity)

  # coalesce
  coalesced = coalesceByKey(area.queue, window=coalesceWindow)
  prioritized = prioritize(coalesced)  # CRITICAL > HIGH > NORMAL > LOW

  # dispatch
  processed = 0
  while processed < tickProcessLimit and budget.hasTime():
    batch = takeNextBatch(
      prioritized,
      maxItems=bucketSize,
      minDelay=batchDelay,
      fairnessToken=acquireFairnessToken(area)
    )
    if batch.isEmpty():
      break

    runHandlers(batch)
    processed += batch.size

  # metering
  updateMetrics(area,
    queueDepth=area.queue.size,
    processed=processed,
    deferred=countDeferred(prioritized),
    dropped=countDropped(prioritized),
    overrun=budget.overrun())

  maybeToggleDegradedMode(area)
```

Этот цикл обязателен как минимальный контракт; конкретные оптимизации (например, многоуровневые очереди или adaptive `bucketSize`) могут добавляться без нарушения описанных гарантий.
