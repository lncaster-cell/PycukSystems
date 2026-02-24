# Аудит мусорного кода (исключая `third_party` и компилятор)

Дата: 2026-02-23

## Область аудита

Проверены каталоги `src/`, `scripts/`, `docs/`, `benchmarks/` c исключением:

- `third_party/**`
- `third_party/toolchain/NWNScriptCompiler.exe`

Основной фокус — `src/modules/npc_behavior`.

## Что считалось «мусором»

- временные debug-артефакты, не участвующие в production-потоке;
- скрипты/обертки без фактических внешних ссылок в репозитории;
- TODO-комментарии про уже удалённую/перенесённую логику, которые могут вводить в заблуждение при сопровождении.

## Найденные кандидаты

### 1) Debug entrypoints без ссылок из runtime-цепочки

Файлы:

- `docs/legacy/tools_reference/npc_behavior_system/npc_behavior_area_enter_debug.nss`
- `docs/legacy/tools_reference/npc_behavior_system/npc_behavior_area_exit_debug.nss`
- `docs/legacy/tools_reference/npc_behavior_system/npc_behavior_module_load_debug.nss`

Наблюдение:

- внутри репозитория нет ссылок на эти имена, кроме самих файлов;
- в production-документации явно указано, что `*_debug.nss` не должны назначаться как стандартные event-hook entrypoints.

Риск:

- «шум» в модуле; легко перепутать при ручном назначении скриптов в toolset;
- поддержка двух почти идентичных entrypoints (prod/debug) повышает риск дрейфа поведения.

Рекомендация:

- вынести debug entrypoints в отдельный каталог (`docs/legacy/tools_reference/npc_behavior_system/debug/`) или удалить из ветки runtime-скриптов, оставив только при необходимости локальной диагностики.

### 2) Временный debug helper `al_dbg.nss`

Файл:

- `docs/legacy/tools_reference/npc_behavior_system/al_dbg.nss`

Наблюдение:

- сам файл помечен как `Temporary debug chat logger`;
- используется только debug entrypoints, не production.

Риск:

- технический долг: helper живёт рядом с боевыми скриптами и выглядит как часть постоянного контракта модуля.

Рекомендация:

- перенести helper рядом с debug entrypoints или удалить, если диагностика закрыта.

### 3) Compat-обертка `NpcBehaviorOnCombatRound`

Файл:

- `docs/legacy/tools_reference/npc_behavior_system/npc_behavior_core.nss`

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
rg -n "TODO|FIXME|TEMP|Temporary|debug|DEBUG|compat" docs/legacy/tools_reference/npc_behavior_system --glob '!third_party/**'
for f in docs/legacy/tools_reference/npc_behavior_system/*.nss; do b=$(basename "$f" .nss); c=$(rg -n "\b${b}\b" src docs --glob '!third_party/**' | wc -l); echo "$b $c"; done | sort
```


## Статус cleanup

- Debug entrypoints `npc_behavior_area_enter_debug.nss`, `npc_behavior_area_exit_debug.nss`, `npc_behavior_module_load_debug.nss` удалены из `docs/legacy/tools_reference/npc_behavior_system/`.
- Временный debug helper `al_dbg.nss` удалён из `docs/legacy/tools_reference/npc_behavior_system/`.
- README модуля обновлён: зафиксировано отсутствие debug-ветки в runtime-дереве.

## Повторный поиск (2026-02-24)

Проведён повторный grep-аудит по ключевым маркерам (`TODO|FIXME|TEMP|Temporary|debug|DEBUG|hack|HACK|deprecated|compat`) в каталогах `src/`, `docs/`, `benchmarks/`, `scripts/` с теми же исключениями (`third_party/**`, `third_party/toolchain/NWNScriptCompiler.exe`).

Итог:

- новых runtime debug-entrypoint файлов в `docs/legacy/tools_reference/npc_behavior_system/` не появилось;
- удалённые ранее `*_debug.nss` и `al_dbg.nss` по-прежнему отсутствуют;
- вхождения `debug/compat` остаются в документации, в legacy AL-диагностике (`al_debug`) и в явном compat-wrapper `NpcBehaviorOnCombatRound`, что соответствует зафиксированному переходному состоянию.

Вывод: новых кандидатов на cleanup в рамках текущего прохода не выявлено.

### Команды повторной проверки

```bash
rg -n "TODO|FIXME|TEMP|Temporary|debug|DEBUG|hack|HACK|deprecated|compat" src docs benchmarks scripts --glob '!third_party/**' --glob '!third_party/toolchain/NWNScriptCompiler.exe'
rg -n "NpcBehaviorOnCombatRound|al_debug|_debug\.nss" src docs --glob '!third_party/**'
```
