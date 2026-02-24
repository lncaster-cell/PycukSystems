# RFC: behavior_v3 — конвергенция AL и npc_behavior

## 1. Цель

`behavior_v3` задаёт единый рантайм для NPC, объединяя сильные стороны исторической AL-системы и текущего `npc_behavior`-контура. Задача RFC — зафиксировать решения по паттернам, определить минимальный ядровой контракт и дать поэтапный план миграции.

## 2. Таблица сравнения и решения

| Паттерн | AL | `npc_behavior` | Решение | Обоснование |
| --- | --- | --- | --- | --- |
| Area lifecycle | Базовая area-ориентация и ownership в пределах области. | Явные состояния lifecycle и контролируемая работа area loop. | **Adapt** | Берём lifecycle-семантику из `npc_behavior`, но сохраняем AL-принцип area-local ownership как архитектурный инвариант для v3. |
| Registry | Плотный area-registry с предсказуемым обходом и компактным хранением. | Registry присутствует опосредованно через intake/runtime-структуры, без явного dense-API на уровне контрактов. | **Adapt** | Dense-registry из AL полезен для масштабируемого широковещательного/пакетного обхода NPC; адаптируется к v3 keyspace и инвариантам cleanup. |
| Route cache | Практика кэширования маршрутных точек и повторного использования без постоянного пересканирования области. | Фокус на runtime-очереди и событиях; route cache обычно вынесен в контентный слой. | **Adopt** | Прямо включаем route cache как обязательный performance guardrail в v3 для снятия пиков первого прохода и уменьшения CPU churn. |
| Low-overhead slot dispatch | Лёгкий dispatch активностей через slot/role-паттерны с минимальным оверхедом. | Сильная оркестрация через очереди/приоритеты, но slot-dispatch не является отдельным ядровым примитивом. | **Adapt** | Сохраняем AL-подход как thin-dispatch слой поверх v3 scheduler, ограничив его рамками core-контракта и observability. |
| Priority queues | Нет развитого приоритетного исполнения (в основном равномерный обход). | Чёткая модель приоритетов и bounded queue. | **Adopt** | Это критическая основа управляемой деградации и контроля latency; переносится в v3 без упрощений. |
| Degraded mode | Деградация неформализована и неоднородна. | Есть bounded/deferred/overflow-поведение с правилами отказа. | **Adopt** | v3 обязан иметь явный degraded mode с reason codes и лимитами, чтобы исключить silent-failure. |
| Telemetry contract | Локальные debug-метки без строгого контракта метрик. | Единый контракт метрик и событий наблюдаемости. | **Adopt** | Для эксплуатации и perf-gate v3 нужен единый telemetry contract; AL debug остаётся только как dev-дополнение. |
| Unified hostile-check | Проверки hostile/cbat-переходов фрагментированы по контентной логике. | Единая hostile-check логика и state-transition-контур. | **Adopt** | Для предсказуемости боевых переходов и уменьшения расхождений в поведении нужна централизованная проверка в core. |

## 3. Минимальный ядровой контракт `behavior_v3_core`

### 3.1 Lifecycle области

`behavior_v3_core` обязан поддерживать три операции:

1. **area activation** — запуск area-loop, инициализация служебных структур (`registry`, `pending`, `metrics`).
2. **area pause** — временная остановка обработки без потери инвариантов очереди/состояния.
3. **area deactivate** — контролируемый stop с cleanup pending-данных и освобождением area-ресурсов.

### 3.2 Per-NPC pending priority model

Для каждого NPC должна существовать запись pending-состояния:

- текущий эффективный приоритет (`CRITICAL/HIGH/NORMAL/LOW`);
- причина постановки (trigger/reason code);
- статус обработки (queued/running/deferred/dropped);
- время последнего обновления (для fairness/anti-starvation).

Модель должна поддерживать coalescing событий одного NPC и защиту от бесконечного роста очереди.

### 3.3 Budgeted tick loop

Area-loop выполняется с бюджетом на тик:

- лимит событий/работ на тик;
- лимит времени тика (soft budget);
- детерминированные правила переноса хвоста на следующий тик;
- встроенный degraded mode при превышении бюджета.

### 3.4 Observability метрики

Минимальный набор метрик `behavior_v3_core`:

- lifecycle: `areas_activated_total`, `areas_paused_total`, `areas_deactivated_total`;
- очередь/нагрузка: `queue_depth`, `queue_overflow_total`, `deferred_total`, `dropped_total`;
- справедливость/латентность: `pending_age_ms`, `tick_duration_ms`, `tick_budget_exceeded_total`;
- качество обработки: `processed_total`, `coalesced_total`, `degraded_mode_total`, `hostile_check_total`.

## 4. Migration-план в behavior_v3

### Этап 1 — Contract freeze и адаптеры совместимости

**Цель:** зафиксировать `behavior_v3_core` API и сделать тонкие адаптеры для AL и `npc_behavior` без изменения контентной логики.

**Работы:**
- формализация lifecycle/pending/tick/metrics контракта;
- адаптер AL (`al_to_v3_adapter`) для registry/route/slot-паттернов;
- адаптер `npc_behavior_to_v3_adapter` для queue/priority/hostile/telemetry.

**Критерии готовности:**
- оба адаптера собираются и выполняют smoke-сценарии;
- нет regressions по базовым lifecycle-инвариантам;
- метрики v3 генерируются одинаково для обоих источников событий.

### Этап 2 — Dual-run и валидация эквивалентности

**Цель:** запустить v3 параллельно с текущими системами в режиме сравнения.

**Работы:**
- shadow execution (v3 принимает те же события);
- сверка приоритетов, dropped/deferred поведения и hostile transitions;
- сравнение perf и деградационных сценариев.

**Критерии готовности:**
- отклонения по ключевым метрикам в согласованных пределах;
- отсутствуют неконтролируемые overflow/silent degradation;
- подтверждена эквивалентность критичных state transitions.

### Этап 3 — Controlled cutover по зонам/area-группам

**Цель:** постепенно перевести production-зоны на `behavior_v3_core`.

**Работы:**
- поэтапное включение feature-flag по area cohorts;
- rollback-механизм до legacy исполнения;
- усиленный мониторинг очереди/latency/degraded mode.

**Критерии готовности:**
- стабильность SLO по тик-бюджету и latency;
- не требуется ручное оперативное вмешательство чаще оговорённого порога;
- rollback тестирован и остаётся работоспособным.

### Этап 4 — Decommission legacy путей

**Цель:** вывести из эксплуатации дублирующие AL/npc_behavior runtime-ветки.

**Работы:**
- удаление временных адаптеров и shadow-сравнений;
- фиксация финального telemetry dashboard/alerting;
- обновление документации и runbook.

**Критерии готовности:**
- все целевые area работают на v3;
- legacy-код не участвует в runtime execution path;
- perf и операционные показатели не хуже согласованного baseline.

## 5. Решение RFC

Принять `behavior_v3_core` как обязательный минимальный стандарт. Интеграция AL и `npc_behavior` выполняется через controlled migration с адаптируемыми AL-паттернами (area ownership, registry, route cache, slot dispatch) и прямым переносом критичных runtime-практик `npc_behavior` (priority queues, degraded mode, telemetry contract, unified hostile-check).
