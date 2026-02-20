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

## Структура репозитория

### Наш код (рабочие каталоги проекта)
- `src/modules/...` — прикладные модули игровой логики (включая `src/modules/npc_behavior/`).
- `scripts/...` — утилиты проекта (подготовка workspace, компиляция, локальные проверки).
- `docs/...` — архитектура, перф-исследования, чеклисты, эксплуатационная документация.
- `tools/` — служебные инструменты пайплайна (например, компилятор `NWNScriptCompiler.exe`).
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

Локальная проверка компиляции доступна через:

```bash
bash scripts/compile.sh check
```

Поддерживаемые режимы: `check`, `build`, `optimize`, `bugscan`.

> Рекомендуется запуск через Windows (нативно или из WSL через `powershell.exe`). `wine`/`mono` оставлены как fallback-вариант.

Также можно запускать сборку в GitHub Actions на `windows-latest` через workflow `.github/workflows/nwn.yml`.

- Результаты и статус сборки смотрите в разделе **Actions** вашего репозитория.
- После успешного запуска откройте run и скачайте артефакт **compiled-ncs-${mode}** (содержимое папки `output/` с `.ncs` файлами).

## Observability contract (Phase 1)

Для модуля `src/modules/npc_behavior` метрики Phase 1 пишутся через единый helper в `npc_behavior_core.nss`, а ключи подготовлены под будущий write-behind sink.

Ключи метрик Phase 1:
- `npc_metric_spawn_count`
- `npc_metric_perception_count`
- `npc_metric_damaged_count`
- `npc_metric_death_count`
- `npc_metric_dialog_count`
- `npc_metric_heartbeat_count`
- `npc_metric_heartbeat_skipped_count`
- `npc_metric_combat_round_count`
- `npc_area_metric_processed_count`
- `npc_area_metric_skipped_count`
- `npc_area_metric_deferred_count`

## Принцип принятия архитектурных решений
Перед принятием любого архитектурного решения выполняется короткий performance-research цикл:
1. Сформулировать гипотезу.
2. Подготовить микро-бенч/нагрузочный сценарий.
3. Измерить p50/p95/p99 времени и вклад в tick budget.
4. Принять решение только по лучшему варианту по производительности и стоимости поддержки.
