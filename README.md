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
- `docs/` — архитектура, исследования производительности, ADR/диздоки.
- `scripts/` — утилиты подготовки workspace и проверок.
- `tools/` — вспомогательные генераторы и валидаторы для development-пайплайнов.
- `src/core/` — event-driven ядро и общие runtime-сервисы.
- `src/controllers/` — area-tick контроллеры и планировщики.
- `src/modules/npc_behavior/` — модуль поведения NPC (первая итерация).
- `src/integrations/nwnx_sqlite/` — интеграция персистентности через NWNX.
- `benchmarks/` — сценарии и результаты микро/нагрузочных измерений.

## Быстрый старт (подготовка workspace)
```bash
bash scripts/setup_env.sh
```

Скрипт подготавливает базовую структуру директорий проекта для пошаговой разработки.

### Компиляция скриптов
```bash
bash scripts/compile.sh
```

Переопределения для нестандартной среды:
- `NWN_COMPILER` — путь до компилятора (исполняемый файл, `.exe` или команда из `PATH`).
- `NWN_COMPILER_RUNNER` — принудительный раннер для `.exe` (например, `mono`, `wine`, `/usr/lib/wine/wine64`).
- `NWN_INCLUDE_PATHS` — include-пути для компилятора.
- Для `tools/NWNScriptCompiler.exe` (PE32) нужен рабочий `wine32` и поддержка IA32 в ядре; без этого в Linux-контейнере такой `.exe` не запустится.

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
