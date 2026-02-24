# PycukSystems

Модульная библиотека скриптов для персонального сервера **Neverwinter Nights 2** с приоритетом на производительность и поэтапную разработку механик.

## Архитектурная концепция (кратко)
**Гибрид:** event-driven ядро + локальные area-tick контроллеры (бакетирование, jitter, step-based handlers) + SQLite как персистентный слой через NWNX; глобальный менеджер используется только для метрик и межобластных задач.

Подробности: `docs/design.md`.

## Текущий этап разработки (Phase 1 snapshot)
Текущий этап зафиксирован как **runtime foundation готов, baseline обновлён, perf/release gate имеет статус GO (PASS)**.

### Готово для NPC

- ✅ runtime-контур NPC в `src/modules/npc/*` собран и используется как canonical source;
- ✅ lifecycle/fairness/activity контрактные проверки автоматизированы и проходят локально;
- ✅ perf/release gate имеет статус `GO (PASS)`: baseline свежий (>=3 runs, <=14 days), активные guardrails проходят (см. `docs/perf/npc_baseline_report.md` и `docs/perf/reports/npc_gate_summary_latest.md`).

### Готово как platform capability для других механик

- ✅ legacy-cleanup milestone (`tools/*`) закрыт; legacy-архив больше не хранится в дереве репозитория;
- ✅ общий модульный контракт зафиксирован в `docs/module_contract.md` (thin-entrypoints, lifecycle API, метрики/деградационные сигналы);
- ✅ добавлены reusable-шаблоны для bootstrap нового модуля: `scripts/contracts/module.contract.template`, `scripts/contracts/check_module_contract.template.sh`, `scripts/test_module_smoke.template.sh`;
- ✅ добавлен проверяемый skeleton модуля: `src/modules/module_skeleton/*`.

Правило консистентности: при каждом обновлении baseline в `docs/perf/npc_baseline_report.md` синхронизируйте статус-блоки в этом разделе и в `src/modules/npc/README.md#current-readiness-snapshot`.

Операционный статус и readiness-детали:
- runtime readiness: `src/modules/npc/README.md`;
- ограничения длины идентификаторов и safe-лимиты NWN2: `src/modules/npc/README.md#ограничения-длины-идентификаторов-nwn2-и-safe-лимиты`;
- execution backlog и этапы: `docs/npc_implementation_backlog.md`;
- baseline/perf gate: `docs/perf/npc_baseline_report.md`, `docs/perf/reports/npc_gate_summary_latest.md`.

Детали по схеме и эксплуатационным правилам персистентности NPC: `docs/npc_persistence.md`.

Чеклист приёмки и минимальных проверок для Phase 1: `docs/npc_phase1_test_checklist.md`.

Исполняемый бэклог старта Module 3: `docs/npc_implementation_backlog.md`.
Отдельный perf-gate для Module 3 (гибрид AL/NPC): `docs/perf/npc_perf_gate.md`.

## Краткий каталог разработанных механизмов и функций

Ниже — сжатая сводка того, что уже реализовано в проекте на текущем этапе.

### 1) Runtime-механизмы NPC (ядро)
- Lifecycle area-controller: состояния `RUNNING/PAUSED/STOPPED`, auto-start, auto-idle-stop, watchdog-тик в `PAUSED`.
- Очередь событий: bounded queue (`NPC_BHVR_QUEUE_MAX=64`) с приоритетами `CRITICAL/HIGH/NORMAL/LOW`.
- Fairness/устойчивость: starvation guard, bypass для `CRITICAL`, degraded-mode и reason-codes.
- Pending-контракт: консистентные `npc_pending_*` (NPC-local) + зеркалирование `npc_queue_pending_*` (area-local).

### 2) Обработчики и точки входа (event hooks)
- Реализованы thin-entrypoint скрипты и маршрутизация в core для событий:
  `OnSpawn`, `OnPerception`, `OnDamaged`, `OnDeath`, `OnDialogue`,
  `Area OnEnter`, `Area OnExit`, `OnModuleLoad`, `Area tick loop`.
- Правило: бизнес-логика размещается в `npc_core.nss` и include-слоях, entrypoints остаются тонкими.

### 3) Activity/runtime-функциональность NPC
- Activity adapter-layer (`npc_activity_inc.nss`) с нормализацией slot/route и fallback-цепочками route-profile.
- Инициализация и сопровождение runtime-состояний activity (`npc_activity_*`, waypoint state, cooldown, last transition).
- Schedule-aware выбор слота (`critical/priority/default`) по временным окнам и предсказуемым правилам интерпретации.

### 4) Метрики и observability
- Единый helper API метрик (`NpcBhvrMetricInc/Add`) и контракт ключей `NPC_VAR_METRIC_*`.
- Runtime telemetry для tick/degraded-профиля (`processed_total`, budget/degraded counters, degradation reason).
- Подготовленная база для дальнейшего write-behind sink и эксплуатационного мониторинга.

### 5) Персистентность и интеграция
- Подготовлен слой интеграции персистентности через NWNX SQLite (`src/integrations/nwnx_sqlite/`).
- Отдельно документированы схема и эксплуатационные правила сохранения/восстановления NPC.

### 6) Тестирование, контракты и perf-инструменты
- Автоматизированы smoke/contract проверки lifecycle, fairness и activity-контрактов (набор `scripts/test_*` и `scripts/check_*`).
- Реализованы benchmark/gate инструменты (`scripts/run_npc_bench.sh`, `scripts/analyze_npc_fairness.py`).
- Поддерживается операционный контур perf-артефактов: baseline, gate-отчёты, дашборды и fixture-наборы.

Для технических деталей и карты hook-скриптов смотрите `src/modules/npc/README.md`.

## Структура репозитория
- `docs/` — архитектура, исследования производительности, ADR/диздоки.
- `scripts/` — утилиты подготовки workspace и проверок.
- `src/modules/npc/` — **единственный active runtime-контур** для текущей разработки и execution backlog (core + includes + thin entrypoints).
- `src/core/` — event-driven ядро и общие runtime-сервисы (**зарезервировано**, см. `src/core/README.md`).
- `src/controllers/` — area-tick контроллеры и планировщики (**зарезервировано**, см. `src/controllers/README.md`).
- Source of truth для активной разработки runtime NPC: `src/modules/npc/`.
- Legacy-референсы старых систем (`ambientlive`, `npc_behavior`) удалены из репозитория; поддерживается только текущий runtime-модуль `src/modules/npc/`.
- Исторические материалы по legacy-инструментам ищите вне рабочего дерева репозитория: в истории Git и опубликованных архивных артефактах проекта.
- `src/integrations/nwnx_sqlite/` — интеграция персистентности через NWNX (**зарезервировано**, см. `src/integrations/nwnx_sqlite/README.md`).
- `benchmarks/` — сценарии и результаты микро/нагрузочных измерений.

### Внешние/эталонные скрипты (read-only архив)
- `third_party/nwn2_stock_scripts/` — архив стоковых NWN2-скриптов для include/reference.
- Каталог не является частью нашего доменного кода и должен обновляться только пакетно (без точечных ручных правок).

### Как не «утонуть» в сторонних файлах при поиске и ревью
- Ищите по нашему коду прицельно: `rg "<query>" src scripts docs`.
- Для активного NPC-контура используйте scoped-поиск: `rg "<query>" src/modules/npc docs/npc_* scripts`.
- Для `git grep` исключайте архив: `git grep "<query>" -- . ':(exclude)third_party/nwn2_stock_scripts'`.
- Для обзора изменений используйте pathspec: `git diff -- src scripts docs`.

## Быстрый старт (подготовка workspace)
```bash
bash scripts/setup_env.sh
```

Скрипт подготавливает базовую структуру директорий проекта для пошаговой разработки.

### Компиляция скриптов

Запуск компилятора выполняется **только** в GitHub Actions на `windows-latest` через workflow `.github/workflows/compile.yml`.

Локальный запуск `third_party/toolchain/NWNScriptCompiler.exe` в Linux/WSL окружении не поддерживается.

Поддерживаемые режимы workflow: `check`, `build`, `optimize`, `bugscan`.

- Результаты и статус сборки смотрите в разделе **Actions** вашего репозитория.
- Для диагностики падений используйте артефакты **logs-${mode}** и исправляйте ошибки только по конкретным строкам (`file:line`, `NSCxxxx`) из `logs-${mode}.log`.
- После успешного запуска `build`/`optimize` скачайте артефакт **compiled-ncs-${mode}** (содержимое папки `output/` с `.ncs` файлами).
- Include-пути для компилятора берутся из `third_party/nwn2_stock_scripts/`, `src/`, `scripts/` и `third_party/nwnx_includes/` (см. `scripts/compile.sh`).

### Где лежат NWNX include-файлы и зачем

NWNX include-файлы вынесены в `third_party/nwnx_includes/`.

Это отделяет внешние зависимости от проектных `.nss` скриптов в `src/`, упрощает обновление NWNX include-набора и позволяет явно подключать их через include path в `scripts/compile.sh`.

## Observability contract (Phase 1)

Для active runtime-модуля `src/modules/npc` метрики Phase 1 пишутся через единый helper в `npc_core.nss`, а ключи подготовлены под будущий write-behind sink.

Ключи `NPC_VAR_METRIC_*` (полное соответствие `npc_behavior_core.nss`):

- **Per-NPC метрики**
  - `npc_metric_spawn_count`
  - `npc_metric_perception_count`
  - `npc_metric_damaged_count`
  - `npc_metric_physical_attacked_count`
  - `npc_metric_spell_cast_at_count`
  - `npc_metric_death_count`
  - `npc_metric_dialog_count`
  - `npc_metric_heartbeat_count`
  - `npc_metric_heartbeat_skipped_count`
  - `npc_metric_combat_round_count`

- **Per-area метрики**
  - `npc_area_metric_processed_count`
  - `npc_area_metric_skipped_count`
  - `npc_area_metric_deferred_count`
  - `npc_area_metric_queue_overflow_count`

- **Служебные/защитные метрики**
  - `npc_metric_intake_bypass_critical`

Правило сопровождения контракта: любые изменения в `NPC_VAR_METRIC_*` обязаны сопровождаться обновлением этого раздела `README.md`.


### Benchmark (NPC baseline)

Для запуска baseline-бенчмарка используйте:

```bash
RUNS=3 bash scripts/run_npc_bench.sh steady
```

Ограничение: переменная `RUNS` должна быть целым числом `>= 1`.

Поддерживаемые `profile` (должны совпадать с `resolve_fixture()` в `scripts/run_npc_bench.sh`):

- `steady`
- `burst`
- `starvation-risk`
- `overflow-guardrail`
- `tick-budget`
- `tick-budget-degraded`
- `fairness-checks`
- `warmup-rescan`

> [!IMPORTANT]
> При неизвестном `profile` скрипт завершится с ошибкой (`[ERR] Unknown scenario/profile: ...`) и кодом выхода `2`.

### Как запускать baseline для Module 3

```bash
RUNS=3 bash scripts/run_npc_bench.sh steady
python3 scripts/analyze_npc_fairness.py --input docs/perf/fixtures/npc/steady.csv
```

Критерии pass/fail (gate):
- area-tick latency: `p95 <= 20 ms`, `p99 <= 25 ms`;
- queue depth: `p95 <= 64`, `p99 <= 80`;
- deferred rate: `<= 0.35`;
- overflow rate: `<= 0.02`;
- budget overrun rate: `<= 0.10`.

Для стресс-проверки используйте сценарии `burst` и `starvation-risk` через `scripts/run_npc_bench.sh` и проверяйте результаты тем же analyzer-скриптом.

## Принцип принятия архитектурных решений
Перед принятием любого архитектурного решения выполняется короткий performance-research цикл:
1. Сформулировать гипотезу.
2. Подготовить микро-бенч/нагрузочный сценарий.
3. Измерить p50/p95/p99 времени и вклад в tick budget.
4. Принять решение только по лучшему варианту по производительности и стоимости поддержки.
