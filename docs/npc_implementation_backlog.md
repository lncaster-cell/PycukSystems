# NPC Implementation Backlog

Документ фиксирует технический бэклог по внедрению серверных NPC-систем с фокусом на надежность, предсказуемую производительность и поэтапную валидацию в продакшен-условиях.

---

## Текущий статус (обновление)

- **Task 3.2 (частично):** в `src/modules/npc_behavior/npc_behavior_core.nss` внедрены базовые runtime guardrails (bounded queue, coalesce, degraded mode, overflow handling c CRITICAL reserve).
- **Следующий шаг по Task 3.2:** вынести area lifecycle (`RUNNING/PAUSED/STOPPED`) в отдельный area-controller script и добавить сценарные perf-проверки под queue fairness.

---

## Epic 1. NWNX/SQLite foundation

### Task 1.1 — Подключение NWNX-плагинов и базового SQLite-конфига
- **Артефакты:**
  - `docker-compose.yml` (или runtime compose/stack файл)
  - `nwnx/nwnx_config.ini` (или эквивалентный runtime конфиг)
  - `scripts/bootstrap_nwnx.sh` (инициализация окружения)
- **Definition of Done:**
  - NWNX стартует в контейнере/инстансе без критических ошибок.
  - SQLite-плагин загружен и доступен из NWScript.
  - Путь к БД и политика WAL (`journal_mode=WAL`) заданы явно.
- **Минимальные метрики/проверки:**
  - Лог старта содержит строки об успешной загрузке NWNX и SQLite-плагина.
  - Smoke-тест NWScript-запроса `SELECT 1` проходит на live runtime.
  - Время cold-start сервера не деградировало более чем на 10% относительно текущего baseline.
- **Риски/зависимости:**
  - Зависимость от версии NWNX и совместимости с текущим билдом сервера.
  - Риск ошибок монтирования volume для файла БД.

### Task 1.2 — Базовые operational guardrails для SQLite
- **Артефакты:**
  - `ops/sqlite_maintenance.md`
  - `scripts/sqlite_healthcheck.sh`
  - `monitoring/sqlite_dashboards.json` (или эквивалент)
- **Definition of Done:**
  - Описаны правила vacuum/checkpoint/backup.
  - Есть регулярный healthcheck доступности и write/read latency.
- **Минимальные метрики/проверки:**
  - p95 latency простого read/write < 20 ms при nominal load.
  - Healthcheck алертит при недоступности БД > 30 секунд.
- **Риски/зависимости:**
  - Риск lock-contention при росте частоты записи.
  - Зависимость от корректного scheduler/cron в окружении.

---

## Epic 2. Data layer + migrations

### Task 2.1 — Проектирование схемы NPC состояния
- **Артефакты:**
  - `db/schema/npc_state.sql`
  - `db/schema/npc_blackboard.sql`
  - `docs/data_model_npc.md`
- **Definition of Done:**
  - Таблицы для identity/state/blackboard/versioning задокументированы.
  - Индексы покрывают основные read-paths (lookup by npc_id, area_id, updated_at).
- **Минимальные метрики/проверки:**
  - `EXPLAIN QUERY PLAN` не показывает full-scan для критичных запросов.
  - Контрольный апдейт 10k записей выполняется в целевом SLA (например, < 2s батчом).
- **Риски/зависимости:**
  - Риск переусложнения схемы до появления реальных профилей нагрузки.
  - Зависимость от согласования формата сериализации blackboard.

### Task 2.2 — Миграционный фреймворк и версионирование
- **Артефакты:**
  - `db/migrations/*.sql`
  - `scripts/migrate.sh` / `tools/migrator`
  - `db/schema_migrations.sql`
- **Definition of Done:**
  - Миграции идемпотентны и применяются последовательно по версиям.
  - Есть rollback-стратегия (или clearly documented forward-only policy).
- **Минимальные метрики/проверки:**
  - CI job выполняет apply migrations на пустую и на «грязную» БД.
  - Проверка целостности (`PRAGMA integrity_check`) после миграций = `ok`.
- **Риски/зависимости:**
  - Риск несовместимых schema changes для уже сохраненных NPC.
  - Зависимость от дисциплины версионирования при параллельной разработке.

---

## Epic 3. Area orchestration

### Task 3.1 — Lifecycle-оркестрация NPC по area events
- **Артефакты:**
  - `src/npc/area_orchestrator.*`
  - `src/npc/spawn_registry.*`
  - `scripts/nwscript/area_hooks.nss`
- **Definition of Done:**
  - На OnEnter/OnExit area корректно активируются/деактивируются NPC runtime-контексты.
  - Нет утечек runtime state при unload area.
- **Минимальные метрики/проверки:**
  - После 100 циклов enter/exit число активных runtime-контекстов стабильно.
  - Время активации area-контекста < 100 ms (p95).
- **Риски/зависимости:**
  - Риск race-condition при одновременных событиях area load/unload.
  - Зависимость от стабильности event hooks в NWScript.

### Task 3.2 — Разделение «hot» и «cold» NPC наборов
- **Артефакты:**
  - `src/npc/area_scheduler.*`
  - `src/npc/presence_policy.*`
  - `docs/npc_presence_policy.md`
- **Definition of Done:**
  - Политика, какие NPC тикают каждый frame/tick и какие переводятся в пониженный режим, реализована.
  - Добавлены конфигурируемые пороги distance/activity.
- **Минимальные метрики/проверки:**
  - CPU budget на NPC в пустой area снижается минимум на 30% относительно naive always-on.
  - Переходы hot↔cold не ломают консистентность state.
- **Риски/зависимости:**
  - Риск «просыпающихся» NPC с устаревшим blackboard.
  - Зависимость от корректных эвристик presence/activity.

---

## Epic 4. Write-behind DB writer + circuit breaker

### Task 4.1 — Реализация write-behind очереди и батч-флашинга
- **Артефакты:**
  - `src/persistence/write_behind_queue.*`
  - `src/persistence/batch_writer.*`
  - `config/persistence.toml`
- **Definition of Done:**
  - Изменения NPC state буферизуются и пишутся батчами по интервалу/объему.
  - Есть graceful shutdown с обязательным drain очереди.
- **Минимальные метрики/проверки:**
  - Under load: batch write throughput > single-write baseline минимум в 2 раза.
  - Потеря данных при штатном shutdown = 0 записей.
- **Риски/зависимости:**
  - Риск роста очереди и memory pressure при деградации БД.
  - Зависимость от backpressure-механизмов на producer стороне.

### Task 4.2 — Circuit breaker для DB-доступа + деградационный режим
- **Артефакты:**
  - `src/persistence/circuit_breaker.*`
  - `src/persistence/retry_policy.*`
  - `docs/failure_modes_npc_persistence.md`
- **Definition of Done:**
  - Реализованы состояния breaker (closed/open/half-open), таймауты и пороги ошибок.
  - При open breaker система переходит в контролируемый degraded mode.
- **Минимальные метрики/проверки:**
  - Fault-injection тесты демонстрируют корректное открытие/закрытие breaker.
  - Recovery to closed state происходит автоматически после window успешных операций.
- **Риски/зависимости:**
  - Риск каскадной деградации при слишком агрессивных retry.
  - Зависимость от точных телеметрических сигналов ошибок DB.

---

## Epic 5. BT/HFSM runtime

### Task 5.1 — Базовый runtime behavior tree
- **Артефакты:**
  - `src/ai/bt/runtime.*`
  - `src/ai/bt/nodes/*`
  - `docs/ai/bt_contract.md`
- **Definition of Done:**
  - Поддержаны минимум: Selector, Sequence, Condition, Action.
  - Tick-модель детерминирована и повторяема при одинаковом seed/state.
- **Минимальные метрики/проверки:**
  - Unit tests на семантику узлов и short-circuit поведение.
  - p95 tick-time одного NPC в целевом диапазоне (например, < 0.5 ms).
- **Риски/зависимости:**
  - Риск взрывного роста сложности при отсутствии строгого node API.
  - Зависимость от стабильного blackboard API.

### Task 5.2 — HFSM-слой поверх BT для high-level состояний
- **Артефакты:**
  - `src/ai/hfsm/runtime.*`
  - `src/ai/hfsm/transitions.*`
  - `docs/ai/hfsm_state_map.md`
- **Definition of Done:**
  - Состояния высокого уровня (Idle/Patrol/Combat/Flee и т.п.) управляют выбором BT-поддеревьев.
  - Transition guards покрывают основные edge-cases.
- **Минимальные метрики/проверки:**
  - Scenario tests проходят для ключевых боевых и небоевых переходов.
  - Нет deadlock/oscillation между состояниями в тестах длительностью >= 10 минут симуляции.
- **Риски/зависимости:**
  - Риск конфликтов между HFSM guards и BT conditions.
  - Зависимость от четкой приоритизации state transitions.

---

## Epic 6. Optional GOAP/RPC planner

### Task 6.1 — Прототип GOAP планировщика (опционально)
- **Артефакты:**
  - `src/ai/goap/planner.*`
  - `src/ai/goap/actions/*`
  - `docs/ai/goap_evaluation.md`
- **Definition of Done:**
  - Есть рабочий прототип для ограниченного набора целей/действий.
  - Добавлен feature-flag для безопасного отключения GOAP.
- **Минимальные метрики/проверки:**
  - План строится в ограничение по времени (например, < 5 ms для тестовой задачи).
  - Не менее 80% regression-сценариев выдают валидный план.
- **Риски/зависимости:**
  - Риск непредсказуемого CPU spikes на сложных графах состояний.
  - Зависимость от качественного cost-моделирования действий.

### Task 6.2 — RPC planner adapter (внешний сервис, опционально)
- **Артефакты:**
  - `src/ai/planner_rpc/client.*`
  - `proto/planner.proto` (или JSON schema)
  - `docs/ai/rpc_planner_sla.md`
- **Definition of Done:**
  - Локальный runtime может отправить planning request и получить безопасный fallback при timeout/error.
  - Контракт версии API зафиксирован.
- **Минимальные метрики/проверки:**
  - p95 RPC round-trip < согласованного SLA.
  - Таймауты не приводят к block главного AI tick loop.
- **Риски/зависимости:**
  - Риск сетевой нестабильности и роста tail latency.
  - Зависимость от availability внешнего planner-сервиса.

---

## Epic 7. Perf baseline + stress tests

### Task 7.1 — Формирование baseline производительности
- **Артефакты:**
  - `benchmarks/npc_baseline/*`
  - `scripts/run_npc_bench.sh`
  - `docs/perf/npc_baseline_report.md`
- **Definition of Done:**
  - Зафиксированы baseline-метрики по CPU, memory, DB latency и tick budget.
  - Репорт воспроизводим в CI/локально по единому сценарию.
- **Минимальные метрики/проверки:**
  - Benchmark запускается автоматически и сохраняет результаты в артефакты CI.
  - Есть сравнение against previous baseline (дельта по ключевым метрикам).
- **Риски/зависимости:**
  - Риск «шумных» замеров без стабилизации окружения.
  - Зависимость от фиксированного тестового seed и детерминированного сценария.

### Task 7.2 — Стресс/soak тесты и эксплуатационные пороги
- **Артефакты:**
  - `tests/stress/npc_stress_suite.*`
  - `tests/soak/npc_soak_suite.*`
  - `docs/perf/npc_operational_thresholds.md`
- **Definition of Done:**
  - Есть стресс-тест на пиковую нагрузку и soak-тест длительной стабильности.
  - Определены go/no-go пороги для релиза.
- **Минимальные метрики/проверки:**
  - Стресс-тест подтверждает отсутствие критических ошибок при целевом количестве NPC.
  - Soak-тест (например, 6–12 часов) без memory leak тренда и без роста error-rate.
- **Риски/зависимости:**
  - Риск нерепрезентативных тестов без realistic workload.
  - Зависимость от доступности выделенного окружения для длительных прогонов.

---

## Приоритизация и порядок реализации (предложение)
1. Epic 1 → 2 (инфраструктурная база).
2. Epic 3 → 4 (runtime orchestration и надежная персистентность).
3. Epic 5 (ядро AI исполнения).
4. Epic 7 (фиксация baseline до/после оптимизаций).
5. Epic 6 (опционально, только после стабилизации основного цикла).
