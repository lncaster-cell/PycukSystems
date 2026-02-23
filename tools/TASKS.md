# TASKS

## Module 3 Preparation

### Phase A — Foundation (core + metrics)

#### Epic 1: Runtime core (lifecycle/queue)

- [ ] **Task 1.1: Stabilize lifecycle bootstrap and shutdown hooks**
  - **Owner role:** runtime
  - **Dependency:** none (entry task)
  - **DoD:** module load/spawn/exit handlers call unified lifecycle API without duplicate registration; smoke сценарий проходит без ошибок компиляции.
  - **Links:** `tools/module3_behavior_system/module3_core.nss`, `tools/module3_behavior_system/module3_behavior_module_load.nss`, `tools/module3_behavior_system/module3_behavior_spawn.nss`, `tools/module3_behavior_system/module3_behavior_area_exit.nss`

- [ ] **Task 1.2: Implement deterministic queue scheduling rules**
  - **Owner role:** runtime
  - **Dependency:** Task 1.1
  - **DoD:** очередь обрабатывается в фиксированном порядке при равных приоритетах; добавлены комментарии по инвариантам очереди и обработке backpressure.
  - **Links:** `tools/module3_behavior_system/module3_core.nss`, `tools/module3_behavior_system/module3_behavior_area_tick.nss`, `tools/module3_behavior_system/README.md`

- [ ] **Task 1.3: Add overflow-safe queue guards**
  - **Owner role:** runtime
  - **Dependency:** Task 1.2
  - **DoD:** при переполнении включается graceful degradation (drop/defer policy), логика не ломает основной tick-loop.
  - **Links:** `tools/module3_behavior_system/module3_core.nss`, `tools/module3_behavior_system/module3_metrics_inc.nss`, `docs/perf/queue_overflow.md`

#### Epic 2: Metrics layer (единый API)

- [ ] **Task 2.1: Define unified metrics contract for runtime/activity/perf**
  - **Owner role:** runtime
  - **Dependency:** Task 1.1
  - **DoD:** единый API метрик (инициализация, инкременты, тайминги) задокументирован и используется runtime-кодом.
  - **Links:** `tools/module3_behavior_system/module3_metrics_inc.nss`, `tools/module3_behavior_system/README.md`, `docs/perf/metrics_contract.md`

- [ ] **Task 2.2: Wire queue/lifecycle instrumentation to the contract**
  - **Owner role:** runtime
  - **Dependency:** Task 1.2, Task 2.1
  - **DoD:** ключевые точки lifecycle и queue публикуют метрики с едиными именами и тегами.
  - **Links:** `tools/module3_behavior_system/module3_core.nss`, `tools/module3_behavior_system/module3_behavior_area_tick.nss`, `tools/module3_behavior_system/module3_metrics_inc.nss`

- [ ] **Task 2.3: Add baseline metrics collection scripts**
  - **Owner role:** perf
  - **Dependency:** Task 2.2
  - **DoD:** скрипты запускают базовый сбор метрик и сохраняют артефакты для сравнения регрессий.
  - **Links:** `scripts/collect_module3_metrics.sh`, `scripts/compare_module3_baseline.sh`, `docs/perf/baseline.md`

### Phase B — Behavior migration (activity layer)

#### Epic 3: Activity layer (порт AL primitives)

- [ ] **Task 3.1: Port AL primitive interfaces into module3 activity include**
  - **Owner role:** runtime
  - **Dependency:** Task 2.1
  - **DoD:** базовые AL primitives (register, route, dispatch helpers) доступны через `module3_activity_inc.nss` и совместимы с runtime core.
  - **Links:** `tools/module3_behavior_system/module3_activity_inc.nss`, `tools/al_system/al_acts_inc.nss`, `tools/al_system/al_npc_reg_inc.nss`

- [ ] **Task 3.2: Migrate event adapters (enter/exit/perception/dialogue/damage/death)**
  - **Owner role:** runtime
  - **Dependency:** Task 3.1, Task 1.2
  - **DoD:** обработчики событий маршрутизируются через activity layer без прямых legacy вызовов.
  - **Links:** `tools/module3_behavior_system/module3_behavior_area_enter.nss`, `tools/module3_behavior_system/module3_behavior_area_exit.nss`, `tools/module3_behavior_system/module3_behavior_perception.nss`, `tools/module3_behavior_system/module3_behavior_dialogue.nss`, `tools/module3_behavior_system/module3_behavior_damaged.nss`, `tools/module3_behavior_system/module3_behavior_death.nss`

- [ ] **Task 3.3: Update docs for AL primitive parity and migration notes**
  - **Owner role:** docs
  - **Dependency:** Task 3.2
  - **DoD:** описаны покрытые AL primitives, ограничения и remaining gaps; добавлен чеклист для ревью миграции.
  - **Links:** `tools/module3_behavior_system/README.md`, `tools/al_system/README.md`, `docs/perf/activity_migration_impact.md`

### Phase C — Quality gate (perf validation)

#### Epic 4: Perf validation (fairness/overflow сценарии)

- [ ] **Task 4.1: Create fairness scenario suite for scheduler behavior**
  - **Owner role:** perf
  - **Dependency:** Task 1.2, Task 2.2, Task 3.2
  - **DoD:** сценарии проверяют отсутствие starvation между конкурентными активностями на длительном прогоне.
  - **Links:** `scripts/perf_fairness_suite.sh`, `docs/perf/fairness_scenarios.md`, `tools/module3_behavior_system/module3_behavior_area_tick.nss`

- [ ] **Task 4.2: Create overflow and recovery scenario suite**
  - **Owner role:** perf
  - **Dependency:** Task 1.3, Task 2.3
  - **DoD:** сценарии подтверждают корректное поведение при пиковом давлении и восстановлении после overflow.
  - **Links:** `scripts/perf_overflow_suite.sh`, `docs/perf/overflow_scenarios.md`, `tools/module3_behavior_system/module3_core.nss`

- [ ] **Task 4.3: Define perf gate and reporting template**
  - **Owner role:** docs
  - **Dependency:** Task 4.1, Task 4.2
  - **DoD:** зафиксированы пороги gate (fairness, latency, overflow recovery), формат отчёта и порядок публикации результатов.
  - **Links:** `docs/perf/perf_gate.md`, `docs/perf/report_template.md`, `scripts/publish_perf_report.sh`

## Execution order (anti-blocking)

- **Phase A (core + metrics):** сначала стабилизируем lifecycle/queue и единый metrics API, чтобы все последующие слои работали на общей платформе.
- **Phase B (activity):** после готовности foundation переносим AL primitives и event adapters, минимизируя конфликт интерфейсов.
- **Phase C (perf-gate):** когда core/metrics/activity интегрированы, запускаем fairness/overflow валидацию и закрываем perf gate.
