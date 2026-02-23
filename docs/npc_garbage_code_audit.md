# Аудит мусорного кода (исключая `third_party` и компилятор)

Дата: 2026-02-23

## Область аудита

Проверены каталоги `src/`, `scripts/`, `docs/`, `benchmarks/`, `tools/` c исключением:

- `third_party/**`
- `tools/NWNScriptCompiler.exe`

Основной фокус — `src/modules/npc_behavior`.

## Что считалось «мусором»

- временные debug-артефакты, не участвующие в production-потоке;
- скрипты/обертки без фактических внешних ссылок в репозитории;
- TODO-комментарии про уже удалённую/перенесённую логику, которые могут вводить в заблуждение при сопровождении.

## Найденные кандидаты

### 1) Debug entrypoints без ссылок из runtime-цепочки

Файлы:

- `src/modules/npc_behavior/npc_behavior_area_enter_debug.nss`
- `src/modules/npc_behavior/npc_behavior_area_exit_debug.nss`
- `src/modules/npc_behavior/npc_behavior_module_load_debug.nss`

Наблюдение:

- внутри репозитория нет ссылок на эти имена, кроме самих файлов;
- в production-документации явно указано, что `*_debug.nss` не должны назначаться как стандартные event-hook entrypoints.

Риск:

- «шум» в модуле; легко перепутать при ручном назначении скриптов в toolset;
- поддержка двух почти идентичных entrypoints (prod/debug) повышает риск дрейфа поведения.

Рекомендация:

- вынести debug entrypoints в отдельный каталог (`src/modules/npc_behavior/debug/`) или удалить из ветки runtime-скриптов, оставив только при необходимости локальной диагностики.

### 2) Временный debug helper `al_dbg.nss`

Файл:

- `src/modules/npc_behavior/al_dbg.nss`

Наблюдение:

- сам файл помечен как `Temporary debug chat logger`;
- используется только debug entrypoints, не production.

Риск:

- технический долг: helper живёт рядом с боевыми скриптами и выглядит как часть постоянного контракта модуля.

Рекомендация:

- перенести helper рядом с debug entrypoints или удалить, если диагностика закрыта.

### 3) Compat-обертка `NpcBehaviorOnCombatRound`

Файл:

- `src/modules/npc_behavior/npc_behavior_core.nss`

Наблюдение:

- в README зафиксировано, что канонический путь — `NpcBehaviorOnEndCombatRound`, а `NpcBehaviorOnCombatRound` оставлен как compatibility-wrapper.

Риск:

- само наличие compat-точки может маскировать устаревшие привязки на уровне модульных событий.

Рекомендация:

- провести одноразовую инвентаризацию event-hook назначений в модуле NWN2 и, если легаси-привязок нет, удалить wrapper в следующем cleanup-цикле.

## Что не менялось в этом коммите

- production-логика NPC не менялась;
- `third_party/**` и компилятор не анализировались и не модифицировались.

## Использованные команды

```bash
rg --files --glob '!third_party/**' --glob '!**/compiler/**'
rg -n "TODO|FIXME|TEMP|Temporary|debug|DEBUG|compat" src/modules/npc_behavior --glob '!third_party/**'
for f in src/modules/npc_behavior/*.nss; do b=$(basename "$f" .nss); c=$(rg -n "\\b${b}\\b" src --glob '!third_party/**' | wc -l); echo "$b $c"; done | sort
```
