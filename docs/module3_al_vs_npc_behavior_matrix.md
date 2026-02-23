# Формализованная матрица: «лучшее из AL» vs «лучшее из npc_behavior»

## Контекст

Матрица нужна как опорный артефакт для подготовки **третьего модуля**: что переиспользовать из исторической Ambient Life (AL) системы и что брать как стандарт из текущего `npc_behavior` runtime.

Источники: `tools/al_system/*`, `tools/npc_behavior_system/*`, а также проектные ограничения из `docs/design.md`.

## Легенда оценки

- **A (готово к прямому переносу)** — зрелый паттерн, подходит без серьёзной переработки.
- **B (перенос с адаптацией)** — использовать как основу, но нормализовать под module API.
- **C (не переносить как есть)** — либо устаревший подход, либо конфликт с текущими guardrails.

## Матрица решений

| Направление | Лучшее из AL | Лучшее из `npc_behavior` | Решение для Module 3 | Оценка |
| --- | --- | --- | --- | --- |
| **Area-local orchestration** | Простая area-модель с периодическим tick (`AL_TICK_PERIOD`) и синхронизацией реестра NPC на уровне области. | Формальный lifecycle `RUNNING/PAUSED/STOPPED`, один area-loop, auto-start policy, idle-stop окно и resume-path. | Брать runtime-контур из `npc_behavior`; из AL оставить только идею area-local ownership. | **A (npc_behavior)** |
| **Обработка нагрузки** | Равномерный периодический обход; практически без приоритизации и деградации. | Bounded queue, coalescing, priority buckets (`CRITICAL/HIGH/NORMAL/LOW`), deferred/eviction guardrails, fairness-сценарии. | Полностью наследовать queue/priority контракт `npc_behavior`; AL-подход не использовать как baseline. | **A (npc_behavior)** |
| **NPC registry / адресация** | Плотный реестр `al_npc_count`, `al_npc_<idx>` с prune/swap-компакцией, broadcast по области без tag-search. | Область в `npc_behavior` ориентирована на event-intake и фильтрацию существ; отдельный dense registry как API не выделен. | В Module 3 взять из AL паттерн dense area-registry как optional helper (для массовых сигналов/обходов). | **B (AL с адаптацией)** |
| **Инициализация runtime параметров** | Преимущественно локальные ad-hoc значения и fallback'и в хелперах активностей. | Стандартизированный `OnSpawn`: template locals, валидация defaults, init-once, disable guard. | Использовать `npc_behavior` как эталон spawn defaults + валидации для нового модуля. | **A (npc_behavior)** |
| **State machine и боевые переходы** | AL сфокусирован на ambient-активностях, без строгого combat-state контракта. | Явные состояния `IDLE/ALERT/COMBAT`, hostile-trigger, decay `ALERT -> IDLE`, единые handlers. | Брать state-модель из `npc_behavior`; AL-активности подключать как слой поведения поверх состояния. | **A (npc_behavior)** |
| **Наблюдаемость/метрики** | Локальные debug-флаги и сообщения (`al_debug`) для ручной диагностики. | Единый контракт метрик `NpcBehaviorMetricInc/Add`, whitelist ключей для write-behind. | Основа observability — только `npc_behavior` стиль; AL debug оставить только как dev-only diagnostics. | **A (npc_behavior)** |
| **Hook-архитектура** | Исторически функциональные include/скрипты, но без явного thin-entrypoint стандарта по всей системе. | Централизация в core include + thin-entrypoint runtime hooks, debug вынесен в отдельные скрипты. | Утвердить thin-entrypoint как обязательный стандарт Module 3. | **A (npc_behavior)** |
| **Маршруты/активности и контентные паттерны** | Богатый слой активностей NPC (slot activity, route-point activity, custom/numeric animations, training/bar pair constraints). | Сильный runtime-контур, но контентный слой (анимационные ambient-паттерны) менее развит. | Перенести AL activity primitives как библиотеку контентной оркестрации поверх нового runtime. | **B (AL с адаптацией)** |
| **Безопасное выключение и cleanup** | Есть hide/unhide + resync подходы на area events. | Формальные cleanup-инварианты для pending/queue, death cleanup и lifecycle stop/pause semantics. | Для критичных инвариантов брать `npc_behavior`; AL hide/unhide применять как дополнительный UX-инструмент. | **A (npc_behavior)** |

## Норматив для подготовки Module 3

Отдельный документ с performance gate для гибридного модуля: `docs/perf/module3_perf_gate.md` (применяется отдельно от Phase 1 NPC).

1. **Runtime-контракт (обязательный):**
   - lifecycle, queue guardrails, intake-policy, observability — наследуются из `npc_behavior` без упрощений;
   - любые отклонения фиксируются отдельным ADR/диздоком до начала реализации.

2. **Контентный слой (селективный перенос из AL):**
   - маршруты, slot activities, activity constraints, групповые ambient-сценарии;
   - перенос выполняется через адаптеры к текущему module API (без прямого копирования legacy keyspace).

3. **Запрещённые anti-patterns для Module 3:**
   - отсутствие приоритизации событий в area-loop;
   - entrypoint-скрипты с бизнес-логикой (вместо thin-wrapper + core);
   - разрозненная метрика через прямые `SetLocalInt` в hooks.

## Минимальный backlog на внедрение матрицы

- [ ] Создать `module3_core.nss` с заимствованием lifecycle/queue паттернов `npc_behavior`.
- [ ] Выделить `module3_activity_inc.nss` и портировать туда AL activity primitives через новый namespace.
- [ ] Ввести `module3_metrics_inc.nss` с единым API инкремента метрик.
- [ ] Подготовить perf-сценарии Module 3 по аналогии с fairness/overflow проверками `npc_behavior`.

