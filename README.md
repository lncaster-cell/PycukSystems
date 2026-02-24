# PycukSystems


Модульная библиотека NWScript для персонального сервера **Neverwinter Nights 2**.
Текущий фокус репозитория — **runtime-модуль поведения NPC** в `src/modules/npc/`.

## Актуальный этап разработки (на текущем состоянии репозитория)

Сейчас проект находится на стадии **runtime foundation + контрактная стабилизация NPC-модуля**:

- ✅ `src/modules/npc/` используется как единственный source of truth для поведения NPC;
- ✅ собран lifecycle-контур area-controller (`RUNNING / PAUSED / STOPPED`) с auto-start/idle pause/idle stop;
- ✅ работает bounded priority queue (CRITICAL/HIGH/NORMAL/LOW), starvation guard и degraded-mode;
- ✅ завершён базовый activity-layer (адаптерный слой + schedule-aware slot/route резолв);
- ✅ контрактные проверки и smoke-набор вынесены в `scripts/test_*` и `scripts/check_*`;
- ✅ perf-gate snapshot для baseline имеет статус **GO (PASS)** в `docs/perf/reports/npc_gate_summary_latest.md`.

Ключевая мысль: модуль уже пригоден для интеграции в toolset-пайплайн, а текущая разработка смещается от «сборки каркаса» к углублению behavior-логики и эксплуатационной зрелости.

## Где смотреть «истину» по NPC

- Runtime-модуль: `src/modules/npc/README.md`
- Исполняемый бэклог: `docs/npc_implementation_backlog.md`
- Runtime orchestration контракт: `docs/npc_runtime_orchestration.md`
- Контракт activity-слоя: `docs/npc_activity_contract_checklist.md`
- Персистентность: `docs/npc_persistence.md`
- Perf-gate и baseline:
  - `docs/perf/npc_perf_gate.md`
  - `docs/perf/npc_baseline_report.md`
  - `docs/perf/reports/npc_gate_summary_latest.md`

## Что уже реализовано в модуле поведения NPC

### 1) Runtime core

- Area lifecycle controller с устойчивыми переходами состояний.
- Очередь событий с приоритетами и контролем переполнения.
- Fairness/guardrails для предотвращения starvation.
- Pending-контракт (NPC-local + area-local зеркало).

### 2) Thin entrypoints

Поддерживается карта entrypoint-скриптов (`OnSpawn`, `OnPerception`, `OnDamaged`, `OnDeath`, `OnDialogue`, `Area enter/exit`, `OnModuleLoad`, area tick), где бизнес-логика централизована в core/include слоях.

### 3) Activity layer

- Адаптерный слой activity (`npc_activity_inc.nss`) без зависимости от legacy keyspace в runtime API.
- Schedule-aware выбор слотов и маршрутов.
- Контрактные проверки route/slot/last-ts и связанных runtime-полей.

### 4) Метрики и наблюдаемость

- Единый helper API метрик.
- Tick/degraded telemetry и reason-коды деградации.
- Подготовленная база для дальнейшего write-behind/persistence sink.

### 5) Инструменты качества

- Smoke и contract-check скрипты для lifecycle/fairness/activity.
- Нагрузочные сценарии и анализаторы для baseline/perf gate.

## Быстрый старт

```bash
bash scripts/setup_env.sh
```

## Проверки, которые стоит запускать регулярно

```bash
bash scripts/test_npc_smoke.sh
bash scripts/check_npc_lifecycle_contract.sh
bash scripts/test_npc_fairness.sh
bash scripts/test_npc_activity_contract.sh
```

## Baseline / perf-gate

Запуск baseline:

```bash
RUNS=3 bash scripts/run_npc_bench.sh steady
```

`run_npc_bench.sh` пишет только артефакты прогона в `benchmarks/npc_baseline/results/<timestamp>/` (включая `analysis/baseline_meta.json`) и **не изменяет tracked markdown-документы**.

Если нужно обновить commit SHA в `docs/perf/npc_baseline_report.md`, это делается явно отдельной командой:

```bash
bash scripts/update_baseline_report.sh
```

Дополнительный анализ fairness:

```bash
python3 scripts/analyze_npc_fairness.py --input docs/perf/fixtures/npc/steady.csv
```

Актуальный итоговый статус гейта всегда проверяется по `docs/perf/reports/npc_gate_summary_latest.md`.

## Компиляция

Компиляция `.nss -> .ncs` выполняется в GitHub Actions (`.github/workflows/compile.yml`) на `windows-latest`.
Локальный запуск Windows-компилятора в Linux/WSL для этого репозитория не является целевым сценарием.

## Структура репозитория (кратко)

- `src/modules/npc/` — активный NPC runtime-модуль
- `scripts/` — проверки, бенчмарки, вспомогательные утилиты
- `docs/` — контракты, бэклог, perf-документация
- `benchmarks/npc_baseline/` — артефакты baseline и gate
- `third_party/` — внешние include/инструменты/референсы

## Ближайший вектор развития NPC-модуля

- расширение behavior-слоя поверх готового runtime foundation;
- постепенное наращивание контентной activity-логики без нарушения thin-entrypoint/metrics контрактов;
- поддержание baseline freshness и guardrail-статусов при каждом существенном изменении runtime.
