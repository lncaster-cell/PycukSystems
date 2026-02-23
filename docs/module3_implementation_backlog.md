# Module 3 Implementation Backlog

Документ переводит стратегию из `docs/module3_al_vs_npc_behavior_matrix.md` в исполняемый план работ (матрица = **что и почему**, backlog = **как и в какой последовательности**).

## Синхронизация со стратегической матрицей

> Обновляйте чекбоксы в этом разделе и в разделе **Release criteria for Module 3** матрицы синхронно.

- [ ] **M3-CHECK-01 — Registry overflow check** (матрица: `Registry overflow check`)
- [ ] **M3-CHECK-02 — Route warmup check** (матрица: `Route warmup check`)
- [ ] **M3-CHECK-03 — Silent degradation diagnostics check** (матрица: `Silent degradation diagnostics check`)
- [ ] **M3-CHECK-04 — Perf gate linkage check** (матрица: `Perf gate linkage check`)

---

## Epic 1. Runtime Core (lifecycle/queue/priority)

### Task RC-1 — Lifecycle area-loop и state contract
- **Артефакты:**
  - `tools/module3_behavior_system/module3_core.nss`
  - `tools/module3_behavior_system/module3_orchestrator.nss`
  - `tools/module3_behavior_system/module3_constants.nss`
- **Definition of Done:**
  - Реализованы состояния `RUNNING/PAUSED/STOPPED` для area-loop.
  - Есть auto-start policy, idle-stop окно и корректный resume path.
  - Entrypoint-скрипты остаются thin-wrapper без бизнес-логики.
- **Минимальные проверки/метрики:**
  - Запуск smoke-сценария `steady` не содержит lifecycle assertion/ошибок в логах.
  - Фиксируются метрики `area_loop_start_total`, `area_loop_pause_total`, `area_loop_resume_total`.
- **Риски и зависимости:**
  - **Зависимости:** существующий lifecycle-паттерн из `tools/npc_behavior_system/npc_behavior_core.nss`.
  - **Риски:** race-condition при pause/resume; рассинхрон area state и queue drain.

### Task RC-2 — Bounded queue, coalescing и priority buckets
- **Артефакты:**
  - `tools/module3_behavior_system/module3_core.nss`
  - `tools/module3_behavior_system/module3_queue_inc.nss`
  - `docs/perf/module3_perf_gate.md`
- **Definition of Done:**
  - Внедрены `CRITICAL/HIGH/NORMAL/LOW` buckets и bounded queue.
  - Реализованы deferred/eviction guardrails и starvation-safe scheduling.
  - Добавлена защита CRITICAL-reserve для событий высокого приоритета.
- **Минимальные проверки/метрики:**
  - На `burst` и `starvation-risk` профилях выполняются целевые p95/p99 из perf-gate.
  - Метрики `queue_depth_p95`, `queue_overflow_total`, `deferred_rate` доступны в отчёте.
- **Риски и зависимости:**
  - **Зависимости:** анализатор `scripts/analyze_module3_fairness.py`, сценарии `docs/perf/fixtures/module3/*.csv`.
  - **Риски:** агрессивный coalescing может терять важные сигналы; unfairness при перекосе приоритетов.

### Task RC-3 — Dense area-registry + overflow fallback
- **Артефакты:**
  - `tools/module3_behavior_system/module3_core.nss`
  - `tools/module3_behavior_system/module3_registry_inc.nss`
  - `docs/module3_al_vs_npc_behavior_matrix.md`
- **Definition of Done:**
  - Реализован плотный реестр (`count + slot[index]`) с prune/swap-компакцией.
  - При переполнении нет порчи существующих записей и активируется fallback-обработка.
  - Чекбокс **M3-CHECK-01** может быть закрыт по результатам stress-профиля.
- **Минимальные проверки/метрики:**
  - Fault-injection «overflow» не приводит к падению loop.
  - Метрики `registry_overflow_total` и `registry_reject_total` растут предсказуемо.
- **Риски и зависимости:**
  - **Зависимости:** ограничения из `tools/AUDIT.md` по overflow guardrails.
  - **Риски:** ошибки в swap/prune ломают адресацию NPC; неконсистентные индексы после cleanup.

---

## Epic 2. Activity Layer (порт AL primitives)

### Task AL-1 — Библиотека AL activity primitives в namespace Module 3
- **Артефакты:**
  - `tools/module3_behavior_system/module3_activity_inc.nss`
  - `tools/module3_behavior_system/module3_activity_routes_inc.nss`
  - `tools/module3_behavior_system/module3_activity_slots_inc.nss`
- **Definition of Done:**
  - Перенесены базовые примитивы: route-point, slot activity, custom/numeric animations.
  - Legacy keyspace AL не копируется напрямую; используется namespace Module 3.
  - Слой активностей совместим с runtime state contract (`IDLE/ALERT/COMBAT`).
- **Минимальные проверки/метрики:**
  - Контентные smoke-тесты подтверждают запуск activity без нарушения lifecycle.
  - Метрика `activity_dispatch_total` разделяется по типам примитивов.
- **Риски и зависимости:**
  - **Зависимости:** источники `tools/al_system/*` + runtime API Module 3.
  - **Риски:** несовместимость семантики AL с текущими area guardrails.

### Task AL-2 — Route cache warmup policy и idempotent invalidate
- **Артефакты:**
  - `tools/module3_behavior_system/module3_core.nss`
  - `tools/module3_behavior_system/module3_activity_inc.nss`
  - `docs/perf/module3_perf_gate.md`
- **Definition of Done:**
  - Warmup помечается area-флагами `routes_cached`/`routes_cache_version`.
  - Повторный warmup идемпотентен и не вызывает re-scan без explicit invalidate.
  - Чекбокс **M3-CHECK-02** может быть закрыт по perf-сценарию warmup.
- **Минимальные проверки/метрики:**
  - В сценарии repeated OnEnter `route_cache_rescan_total` не растёт без invalidate.
  - `route_cache_hit_ratio` остаётся в согласованном диапазоне после прогрева.
- **Риски и зависимости:**
  - **Зависимости:** политика из audit guardrails и конфигурация prewarm.
  - **Риски:** неоптимальный warmup создаёт startup spikes на крупных областях.

### Task AL-3 — Activity constraints и group ambient orchestration
- **Артефакты:**
  - `tools/module3_behavior_system/module3_activity_constraints_inc.nss`
  - `tools/module3_behavior_system/module3_activity_group_inc.nss`
  - `docs/design.md`
- **Definition of Done:**
  - Портированы ограничения pair/training/bar и групповые ambient-сценарии.
  - Ограничения работают как declarative rules, а не ad-hoc ветвления в hooks.
- **Минимальные проверки/метрики:**
  - Regression-набор контентных сцен проходит без deadlock в занятых слотах.
  - Метрика `activity_constraint_violation_total` фиксирует конфликтные назначения.
- **Риски и зависимости:**
  - **Зависимости:** стабильный API registry/route cache из Epic Runtime Core.
  - **Риски:** рост сложности координации групповых сценариев и конфликтов слотов.

---

## Epic 3. Metrics/Persistence contract

### Task MP-1 — Единый metrics API + reason-codes деградации
- **Артефакты:**
  - `tools/module3_behavior_system/module3_metrics_inc.nss`
  - `tools/module3_behavior_system/module3_core.nss`
  - `README.md` (раздел про метрики Module 3)
- **Definition of Done:**
  - Любая деградационная ветка пишет reason-code (`OVERFLOW`, `QUEUE_PRESSURE`, `ROUTE_MISS`, `DISABLED`).
  - Введён единый helper инкремента/агрегации метрик вместо прямых `SetLocalInt`.
  - Чекбокс **M3-CHECK-03** может быть закрыт по fault-injection отчётам.
- **Минимальные проверки/метрики:**
  - Fault-injection профили создают `degradation_events_total` и `degradation_by_reason_*`.
  - Включаемый debug-аудит остаётся rate-limited (`diagnostic_dropped_total` контролируется).
- **Риски и зависимости:**
  - **Зависимости:** существующий telemetry-style из `npc_behavior`.
  - **Риски:** кардинальность reason-codes и рост накладных расходов на логирование.

### Task MP-2 — Контракт write-behind persistence ключей
- **Артефакты:**
  - `tools/module3_behavior_system/module3_persistence_contract.md`
  - `tools/module3_behavior_system/module3_metrics_inc.nss`
  - `docs/npc_persistence.md`
- **Definition of Done:**
  - Зафиксирован whitelist ключей для write-behind sink и период flush.
  - Добавлены правила версионирования keyspace для безопасных миграций.
- **Минимальные проверки/метрики:**
  - Contract-check script валидирует, что runtime пишет только разрешённые ключи.
  - Smoke-проверка flush подтверждает отсутствие потерь на штатном shutdown.
- **Риски и зависимости:**
  - **Зависимости:** NWNX/SQLite pipeline и общие persistence guardrails проекта.
  - **Риски:** дрейф схемы ключей между runtime и sink; конфликт версий на rollout.

---

## Epic 4. Perf Validation & Gate

### Task PG-1 — Сценарии perf-gate для steady/burst/starvation-risk
- **Артефакты:**
  - `docs/perf/module3_perf_gate.md`
  - `scripts/run_module3_bench.sh`
  - `scripts/analyze_module3_fairness.py`
  - `docs/perf/fixtures/module3/steady.csv`
  - `docs/perf/fixtures/module3/burst.csv`
  - `docs/perf/fixtures/module3/starvation_risk.csv`
- **Definition of Done:**
  - Для каждого профиля описаны входные параметры, pass/fail thresholds и артефакты отчёта.
  - Документирован порядок прогона bench + analyzer для CI/ручной валидации.
  - Чекбокс **M3-CHECK-04** может быть закрыт после проверки покрытия всех guardrails.
- **Минимальные проверки/метрики:**
  - Автоанализатор формирует p95/p99 по latency/queue/deferred/overflow.
  - Отчёт содержит явный verdict (`PASS`/`FAIL`) по каждому профилю.
- **Риски и зависимости:**
  - **Зависимости:** валидные fixture-файлы и стабильность benchmark harness.
  - **Риски:** невалидные входные CSV или сдвиг baseline без обновления порогов.

### Task PG-2 — Fault-injection профили для audit guardrails
- **Артефакты:**
  - `docs/perf/module3_perf_gate.md`
  - `docs/perf/fixtures/module3/` (fault-injection наборы)
  - `scripts/analyze_module3_fairness.py`
- **Definition of Done:**
  - Отдельно покрыты overflow, pause/resume fault, route cache invalidate и silent degradation.
  - Каждый профиль связывается с чекбоксами **M3-CHECK-01/02/03**.
- **Минимальные проверки/метрики:**
  - В каждом fault-профиле есть ожидаемые counter deltas и причина деградации.
  - Регрессия считается проваленной, если reason-code/метрика не наблюдается.
- **Риски и зависимости:**
  - **Зависимости:** корректная генерация fault-профилей и поддержка debug-аудита.
  - **Риски:** ложноположительные FAIL из-за нестабильности тестового окружения.

---

## Порядок исполнения (рекомендуемый)

1. RC-1 → RC-2 → RC-3 (закрыть runtime-контур и overflow safety).
2. AL-1 → AL-2 → AL-3 (порт контентного слоя поверх готового runtime).
3. MP-1 → MP-2 (зафиксировать наблюдаемость и persistence-контракт).
4. PG-1 → PG-2 (закрыть perf gate и audit-derived проверки).
