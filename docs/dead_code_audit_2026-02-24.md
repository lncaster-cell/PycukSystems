# Аудит мусорного/мёртвого кода (2026-02-24)

## Область аудита
- Проверены каталоги `src/`, `scripts/`, `benchmarks/`, `docs/`.
- **Исключены из анализа**: весь `third_party/` и любые артефакты компилятора/toolchain внутри него.

## Методика
1. Быстрый статический прогон Python-линтера на неиспользуемые импорты/переменные/имена:
   - `ruff check scripts benchmarks --select F401,F841,F821`
2. Дополнительный прогон общих smell-правил для скриптов:
   - `ruff check scripts benchmarks --select F,ARG,B,UP,SIM`
3. Эвристический поиск кандидатов в мёртвые функции в `.nss`:
   - сбор сигнатур функций;
   - проверка наличия внешних ссылок на имя функции в `src/`, `scripts/`, `docs/`, `benchmarks/`.

> Важно: шаг (3) даёт **кандидатов** и может содержать ложноположительные срабатывания для приватных helper-функций, вызываемых только в том же include-файле, либо функций, используемых неявно рантаймом/контрактом.

## Результаты

### 1) Python и shell-скрипты
- Не найдено неиспользуемых импортов/переменных/необъявленных имён в `scripts/` и `benchmarks/` по правилам `F401/F841/F821`.
- Найдены 3 code-smell замечания (не про dead code):
  - `B904` в `scripts/analyze_npc_fairness.py` (2 места);
  - `SIM102` в `scripts/bench/analyze_single_run.py` (1 место).

### 2) Кандидаты в мёртвый код в NWScript (`.nss`)
Ниже — функции, у которых не обнаружено внешних ссылок (кроме определения) в рамках репозитория:

- `NpcBhvrQueueIndexKey` — `src/modules/npc/npc_queue_index_inc.nss`
- `NpcBhvrSafeId` — `src/modules/npc/npc_activity_migration_inc.nss`
- `NpcBhvrActivityRouteCountKey` — `src/modules/npc/npc_activity_migration_inc.nss`
- `NpcBhvrActivityRouteLoopKey` — `src/modules/npc/npc_activity_migration_inc.nss`
- `NpcBhvrActivityRouteTagKey` — `src/modules/npc/npc_activity_migration_inc.nss`
- `NpcBhvrActivityRoutePauseTicksKey` — `src/modules/npc/npc_activity_migration_inc.nss`
- `NpcBhvrActivityRouteMigratedFlagKey` — `src/modules/npc/npc_activity_migration_inc.nss`
- `NpcBhvrQueuePickPriority` — `src/modules/npc/npc_tick_inc.nss`
- `NpcBhvrGetTickMaxEvents` — `src/modules/npc/npc_tick_inc.nss`
- `NpcBhvrGetTickSoftBudgetMs` — `src/modules/npc/npc_tick_inc.nss`
- `NpcBhvrQueueCountDeferred` — `src/modules/npc/npc_queue_deferred_inc.nss`
- `NpcBhvrQueueDeferredLooksDesynced` — `src/modules/npc/npc_queue_deferred_inc.nss`
- `NpcBhvrActivityTryResolveScheduledSlot` — `src/modules/npc/npc_activity_schedule_inc.nss`

## Рекомендации
1. Для списка кандидатов выше: подтвердить необходимость через runtime-smoke и контрактные тесты (`scripts/test_npc_smoke.sh`, `scripts/test_npc_activity_contract.sh`, профильные контрактные проверки).
2. Если функция действительно не нужна:
   - удалить определение;
   - прогнать контрактные/smoke тесты;
   - зафиксировать изменение в `src/modules/npc/README.md`.
3. Если функция нужна, но неявно используется:
   - добавить явный вызов/контрактный тест на использование;
   - либо пометить в комментарии, почему функция оставлена.
