# PycukSystems

Модульная библиотека скриптов для персонального сервера **Neverwinter Nights 2** с приоритетом на производительность и поэтапную разработку механик.

## Архитектурная концепция (кратко)
**Гибрид:** event-driven ядро + локальные area-tick контроллеры (бакетирование, jitter, step-based handlers) + SQLite как персистентный слой через NWNX; глобальный менеджер используется только для метрик и межобластных задач.

Подробности: `docs/design.md`.

## Текущий фокус первой итерации
Первый целевой модуль — **поведение NPC**:
- реакция на события (вход в персепшен, бой, idle);
- управление нагрузкой через area-tick и бакеты;
- хранение долгоживущего состояния/метрик в SQLite (через NWNX).

Детали по схеме и эксплуатационным правилам персистентности NPC: `docs/npc_persistence.md`.

Чеклист приёмки и минимальных проверок для Phase 1: `docs/npc_phase1_test_checklist.md`.

Матрица для подготовки третьего модуля («лучшее из AL» vs «лучшее из npc_behavior»): `docs/npc_bhvr_al_vs_npc_behavior_matrix.md`.

Исполняемый бэклог старта Module 3: `docs/npc_bhvr_implementation_backlog.md`.
Отдельный perf-gate для Module 3 (гибрид AL/NPC): `docs/perf/npc_bhvr_perf_gate.md`.

## Структура репозитория
- `docs/` — архитектура, исследования производительности, ADR/диздоки.
- `scripts/` — утилиты подготовки workspace и проверок.
- `tools/` — вспомогательные генераторы и валидаторы для development-пайплайнов.
  - `tools/al_system/` — документация и материалы по Ambient Life system.
  - `tools/npc_behavior_system/` — runtime-скрипты NPC behavior system (entrypoints + core).
  - `src/modules/npc_bhvr/` — официальный runtime-контур подготовки Module 3 (core + includes + thin entrypoints).
- `src/core/` — event-driven ядро и общие runtime-сервисы (**зарезервировано**, см. `src/core/README.md`).
- `src/controllers/` — area-tick контроллеры и планировщики (**зарезервировано**, см. `src/controllers/README.md`).
- `src/modules/npc_behavior/` — redirect-документация для модуля NPC behavior (скрипты перенесены в `tools/npc_behavior_system/`).
- Source of truth для runtime-скриптов NPC behavior: `tools/npc_behavior_system/` (путь `src/modules/npc_behavior/` не используется как production runtime).
- `src/integrations/nwnx_sqlite/` — интеграция персистентности через NWNX (**зарезервировано**, см. `src/integrations/nwnx_sqlite/README.md`).
- `benchmarks/` — сценарии и результаты микро/нагрузочных измерений.

### Внешние/эталонные скрипты (read-only архив)
- `third_party/nwn2_stock_scripts/` — архив стоковых NWN2-скриптов для include/reference.
- Каталог не является частью нашего доменного кода и должен обновляться только пакетно (без точечных ручных правок).

### Как не «утонуть» в сторонних файлах при поиске и ревью
- Ищите по нашему коду прицельно: `rg "<query>" src scripts docs`.
- Для `git grep` исключайте архив: `git grep "<query>" -- . ':(exclude)third_party/nwn2_stock_scripts'`.
- Для обзора изменений используйте pathspec: `git diff -- src scripts docs`.

## Быстрый старт (подготовка workspace)
```bash
bash scripts/setup_env.sh
```

Скрипт подготавливает базовую структуру директорий проекта для пошаговой разработки.

### Компиляция скриптов

Запуск компилятора выполняется **только** в GitHub Actions на `windows-latest` через workflow `.github/workflows/compile.yml`.

Локальный запуск `tools/NWNScriptCompiler.exe` в Linux/WSL окружении не поддерживается.

Поддерживаемые режимы workflow: `check`, `build`, `optimize`, `bugscan`.

- Результаты и статус сборки смотрите в разделе **Actions** вашего репозитория.
- Для диагностики падений используйте артефакты **logs-${mode}** и исправляйте ошибки только по конкретным строкам (`file:line`, `NSCxxxx`) из `logs-${mode}.log`.
- После успешного запуска `build`/`optimize` скачайте артефакт **compiled-ncs-${mode}** (содержимое папки `output/` с `.ncs` файлами).
- Include-пути для компилятора берутся из `third_party/nwn2_stock_scripts/`, `src/`, `tools/npc_behavior_system/`, `scripts/` и `third_party/nwnx_includes/` (см. `scripts/compile.sh`).

### Где лежат NWNX include-файлы и зачем

NWNX include-файлы вынесены в `third_party/nwnx_includes/`.

Это отделяет внешние зависимости от проектных `.nss` скриптов в `src/`, упрощает обновление NWNX include-набора и позволяет явно подключать их через include path в `scripts/compile.sh`.

## Observability contract (Phase 1)

Для модуля `tools/npc_behavior_system` метрики Phase 1 пишутся через единый helper в `npc_behavior_core.nss`, а ключи подготовлены под будущий write-behind sink.

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
RUNS=3 bash scripts/run_npc_bench.sh scenario_a_nominal
```

Ограничение: переменная `RUNS` должна быть целым числом `>= 1`.

### Как запускать baseline для Module 3

```bash
RUNS=3 bash scripts/run_npc_bhvr_bench.sh steady
python3 scripts/analyze_npc_bhvr_fairness.py --input docs/perf/fixtures/npc_bhvr/steady.csv
```

Критерии pass/fail (gate):
- area-tick latency: `p95 <= 20 ms`, `p99 <= 25 ms`;
- queue depth: `p95 <= 64`, `p99 <= 80`;
- deferred rate: `<= 0.35`;
- overflow rate: `<= 0.02`;
- budget overrun rate: `<= 0.10`.

Для стресс-проверки используйте сценарии `burst` и `starvation-risk` через `scripts/run_npc_bhvr_bench.sh` и проверяйте результаты тем же analyzer-скриптом.

## Принцип принятия архитектурных решений
Перед принятием любого архитектурного решения выполняется короткий performance-research цикл:
1. Сформулировать гипотезу.
2. Подготовить микро-бенч/нагрузочный сценарий.
3. Измерить p50/p95/p99 времени и вклад в tick budget.
4. Принять решение только по лучшему варианту по производительности и стоимости поддержки.
