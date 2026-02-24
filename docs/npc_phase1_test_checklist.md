# NPC Phase 1 Test Checklist

Чеклист для приёмки первой фазы NPC-модуля с привязкой к архитектурным терминам и SLO/perf-gate из `docs/design.md` и runtime-контракту из `docs/npc_runtime_orchestration.md`.

## Классификация проверок

## Canonical runtime references

Используйте только актуальные runtime-пути для NPC Bhvr:
- Runtime module: `src/modules/npc/*`
- Runtime README: `src/modules/npc/README.md`
- Backlog/readiness: `docs/npc_implementation_backlog.md`
- Perf gate: `docs/perf/npc_perf_gate.md`

Legacy `tools/*` не являются active runtime; исторические материалы находятся в `docs/legacy/tools_reference/*`.


- **Blocking (merge gate)** — проверка обязательна для merge.
- **Informational** — полезная диагностика, но не блокирует merge сама по себе.

## Этап 1. Структура файлов и entrypoints

**Цель:** подтвердить, что файлы модуля NPC и точки входа событий присутствуют и согласованы со структурой event-driven ядра.

**DoD:**
- В наличии `npc_core.nss` и event-файлы (`spawn`, `perception`, `damaged`, `death`, `dialogue`).
- Для каждого On\* entrypoint есть явный handler/роутинг в core.
- Нет «висячих» entrypoints без реализации в модуле.

**Минимальные команды:**
```bash
rg --files src/modules/npc
rg -n "void main\(" src/modules/npc/npc_behavior_*.nss
rg -n "NpcBehaviorOn(Spawn|Perception|Damaged|Death|Dialogue|PhysicalAttacked|SpellCastAt|Heartbeat)|NpcBehaviorOnAreaTick" src/modules/npc
```

**Тип проверки:** **Blocking (merge gate)**.

---

## Этап 2. Маршрутизация всех On\* в core

**Цель:** проверить, что все On\* события проходят через единый `npc_core` (единая точка оркестрации и деградации).

**DoD:**
- Каждый On\* entrypoint в event-файлах вызывает функцию в core (прямо или через единый routing-wrapper).
- Нет обхода core для штатных `CRITICAL/HIGH/NORMAL/LOW` путей.
- Термины и поведение согласованы с runtime-контрактом: bounded queue, coalesce, dispatch с `tickProcessLimit`, graceful degradation.

**Минимальные команды:**
```bash
rg -n "void main\(" src/modules/npc/npc_behavior_*.nss
rg -n "npc_core|NpcBhvrOn|NpcBehaviorOn" src/modules/npc/npc_behavior_*.nss
rg -n "CRITICAL|HIGH|NORMAL|LOW|queue|coalesce|defer|tickProcessLimit|degraded" docs/design.md docs/npc_runtime_orchestration.md
```

**Тип проверки:** **Blocking (merge gate)**.

---

## Этап 3. Smoke-сценарии поведения

**Цель:** подтвердить базовую работоспособность ключевых веток поведения NPC.

### 3.1 Spawn
**DoD:**
- OnSpawn инициализирует runtime-state NPC.
- NPC корректно регистрируется в area-controller очереди/бакете.

### 3.2 Perception
**DoD:**
- OnPerception приводит к ожидаемой реакции (alert/aggro/target update).
- Событие маршрутизируется через core, без обхода деградационного контура.

### 3.3 Damaged
**DoD:**
- OnDamaged обновляет боевое состояние и приоритеты корректно.
- `CRITICAL`/боевые события не дропаются в деградации.

### 3.4 Death
**DoD:**
- OnDeath выполняет cleanup состояния и снимает NPC из активной обработки.
- Нет повторной обработки «мертвого» NPC в последующих тиках.

### 3.5 Dialogue
**DoD:**
- OnDialogue переводит NPC в корректный интерактивный/нейтральный контекст.
- Диалоговые события не ломают tick orchestration и не создают queue-storm.

**Минимальные команды (репрезентативный набор):**
```bash
# 1) статическая проверка наличия On* и маршрутизации
rg -n "OnSpawn|OnPerception|OnDamaged|OnDeath|OnDialogue" src/modules/npc
rg -n "core|Dispatch|Route|Handle" src/modules/npc/npc_behavior_*.nss

# 2) логовый smoke в рантайме сервера (пример)
# tail -f /path/to/server.log | rg "npc_behavior|spawn|perception|damaged|death|dialogue|defer|dropped"
```

**Тип проверки:**
- **Blocking (merge gate):** статическая маршрутизация.
- **Informational:** runtime-лог smoke (если нет стенда/сервера в CI).

---

## SLO/perf ориентиры для интерпретации результатов

Эти ориентиры не заменяют отдельный perf-бенч, но используются как пороги «красных флагов» при фазе 1:

- `p95 area-tick latency <= 12 ms`.
- `queue depth`: p95 `<= 200`, p99 `<= 300`.
- `dropped/deferred events <= 0.5%` за 10-минутное окно.
- `tick budget overruns <= 1%` тиков.

Если изменение ухудшает perf-gate относительно baseline (старше 14 дней недопустим), merge должен быть заблокирован до rollback/tuning.

## Template for NPC Bhvr

Ниже шаблон для старта следующего модуля с той же структурой этапов и canonical-path подходом.

### Stage 1 — files

**Goal:** подтвердить, что файлы нового модуля размещены в `src/modules/npc/` (для NPC Bhvr используйте canonical path `src/modules/<module_name>/`) и не указывают на legacy-пути.

```bash
MODULE_DIR="src/modules/npc" # replace with src/modules/<module_name> for NPC Bhvr
rg --files "$MODULE_DIR"
```

### Stage 2 — entrypoints

**Goal:** подтвердить, что все event entrypoints объявлены отдельными thin-hook скриптами и содержат `void main()`.

```bash
MODULE_DIR="src/modules/npc" # replace with src/modules/<module_name> for NPC Bhvr
rg -n "void main\(" "$MODULE_DIR"/*.nss
rg -n "On[A-Za-z]+|Area(Enter|Exit)|ModuleLoad|Tick" "$MODULE_DIR"
```

### Stage 3 — routing

**Goal:** убедиться, что entrypoints маршрутизируют вызовы через единый core include/handler слой.

```bash
MODULE_DIR="src/modules/npc" # replace with src/modules/<module_name> for NPC Bhvr
rg -n "#include \".*core\"|#include \"<module_name>_core\"" "$MODULE_DIR"/*.nss
rg -n "(NpcBehavior|<ModuleName>)On|(NpcBehavior|<ModuleName>)Area(Activate|Pause|Resume)|(NpcBehavior|<ModuleName>)Bootstrap" "$MODULE_DIR"/*.nss
```

### Stage 4 — smoke

**Goal:** выполнить базовый статический smoke по ключевым событиям и, при наличии стенда, логовый smoke.

```bash
MODULE_DIR="src/modules/npc" # replace with src/modules/<module_name> for NPC Bhvr
rg -n "OnSpawn|OnPerception|OnDamaged|OnDeath|OnDialogue|On[A-Za-z]+" "$MODULE_DIR"
# tail -f /path/to/server.log | rg "<module_name>|spawn|perception|damaged|death|dialogue|defer|dropped"
```

### Stage 5 — perf-gate

**Goal:** проверить, что изменение не ухудшает SLO/perf-gate относительно актуального baseline.

```bash
# RUNS должен быть целым числом >= 1 (например, RUNS=3).
RUNS=3 bash scripts/run_npc_bench.sh scenario_a_nominal
```


## Контрактные проверки lifecycle

Для валидации связки `core <-> lifecycle_controller` используйте универсальный скрипт:

```bash
bash scripts/check_lifecycle_contract.sh \
  src/modules/npc/npc_core.nss \
  src/controllers/lifecycle_controller.nss \
  npc_behavior
```

Подробности и примеры для NPC Bhvr: `docs/testing_contracts.md`.

## Быстрый итог перед merge

- [x] **Blocking:** структура и entrypoints валидны.
- [x] **Blocking:** все On\* маршрутизируются через core.
- [x] **Blocking:** статический smoke по spawn/perception/damaged/death/dialogue.
- [ ] **Informational:** runtime-лог smoke на стенде (если доступен).
- [ ] **Blocking для perf-изменений:** SLO/perf-gate не нарушены.

## Статус последней валидации

- **Дата:** 2026-02-20
- **Ветка:** `work`
- **Результат:** статические merge-gate проверки пройдены; runtime/perf-пункты остаются в статусе pending до прогона на стенде.

```bash
rg --files src/modules/npc
rg -n "void main\(" src/modules/npc/npc_behavior_*.nss
rg -n "NpcBehaviorOn(Spawn|Perception|Damaged|Death|Dialogue|PhysicalAttacked|SpellCastAt|Heartbeat)|NpcBehaviorOnAreaTick" src/modules/npc
# RUNS должен быть целым числом >= 1 (например, RUNS=3).
RUNS=3 bash scripts/run_npc_bench.sh scenario_a_nominal
```
