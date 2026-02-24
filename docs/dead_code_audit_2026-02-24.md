# Аудит мусорного/мёртвого кода (2026-02-24)

## Область аудита
- Проверены каталоги `src/`, `scripts/`, `benchmarks/`, `docs/`.
- **Исключены из анализа**: весь `third_party/` и любые артефакты компилятора/toolchain внутри него.
- Также при аудитах/инспекциях не анализируются и не изменяются сторонние инструменты (third-party tooling и встроенный в них компилятор).

## Методика
1. Быстрый статический прогон Python-линтера на неиспользуемые импорты/переменные/имена:
   - `ruff check scripts benchmarks --select F401,F841,F821`
2. Дополнительный прогон общих smell-правил для скриптов:
   - `ruff check scripts benchmarks --select F,ARG,B,UP,SIM`
3. Эвристический поиск кандидатов в мёртвые функции в `.nss`:
   - сбор сигнатур функций;
   - проверка наличия ссылок на имя функции в `src/`, `scripts/`, `docs/`, `benchmarks/`, включая:
     - внешние ссылки из других файлов/модулей;
     - внутримодульные вызовы в том же include-файле.

> Важно: шаг (3) даёт **кандидатов**. Функции, используемые только внутри собственного include-файла, классифицируются как локальные helper'ы и не считаются dead code.

## Результаты

### 1) Python и shell-скрипты
- Не найдено неиспользуемых импортов/переменных/необъявленных имён в `scripts/` и `benchmarks/` по правилам `F401/F841/F821`.
- Найдены 3 code-smell замечания (не про dead code):
  - `B904` в `scripts/analyze_npc_fairness.py` (2 места);
  - `SIM102` в `scripts/bench/analyze_single_run.py` (1 место).

### 2) Кандидаты в мёртвый код в NWScript (`.nss`)
#### 2.1 Не используется вообще
- Кандидаты не обнаружены по текущей эвристике (с учётом внешних и внутримодульных ссылок).

#### 2.2 Используется только внутри собственного include-файла
Ниже — локальные helper-функции. Это **не dead code**:

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

### Risk of false positive
- Не удалять кандидатов только по факту отсутствия внешних ссылок.
- Перед удалением обязательно проверить вызовы в том же include-файле/модуле.
- Учитывать неявные точки входа (runtime-контракты, include-цепочки, сценарные соглашения).

## Рекомендации
1. Для потенциальных кандидатов из категории «не используется вообще»: подтвердить необходимость через runtime-smoke и контрактные тесты (`scripts/test_npc_smoke.sh`, `scripts/test_npc_activity_contract.sh`, профильные контрактные проверки).
2. Если функция действительно не нужна:
   - удалить определение;
   - прогнать контрактные/smoke тесты;
   - зафиксировать изменение в `src/modules/npc/README.md`.
3. Если функция нужна, но неявно используется:
   - добавить явный вызов/контрактный тест на использование;
   - либо пометить в комментарии, почему функция оставлена.
