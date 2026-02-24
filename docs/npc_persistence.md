# Персистентность NPC (SQLite / NWNX)


Документ фиксирует целевую схему хранения состояния NPC, рабочие индексы, политику миграций и правила write-behind для первой итерации модуля поведения.

## 1. Таблицы и ключи

### 1.1 `npc_states`
Текущее состояние NPC и служебные поля для синхронизации.

Рекомендуемые поля:
- `npc_id TEXT PRIMARY KEY` — стабильный уникальный идентификатор NPC.
- `area_id TEXT NOT NULL` — текущая область.
- `state TEXT NOT NULL` — текущее FSM-состояние (idle, patrol, combat, return и т.д.).
- `state_updated_at INTEGER NOT NULL` — unix-time последнего изменения состояния.
- `version INTEGER NOT NULL DEFAULT 0` — версия записи для optimistic-update.

Ключи:
- `PRIMARY KEY (npc_id)`.

### 1.2 `npc_goals`
Очередь/набор целей NPC (краткосрочных и среднесрочных).

Рекомендуемые поля:
- `goal_id INTEGER PRIMARY KEY AUTOINCREMENT`.
- `npc_id TEXT NOT NULL` — владелец цели.
- `goal_type TEXT NOT NULL`.
- `status TEXT NOT NULL` — active, paused, done, failed.
- `priority INTEGER NOT NULL` — приоритет выполнения (чем выше, тем раньше обработка).
- `payload_json TEXT` — сериализованные параметры.
- `updated_at INTEGER NOT NULL`.

Ключи:
- `PRIMARY KEY (goal_id)`.
- `FOREIGN KEY (npc_id) REFERENCES npc_states(npc_id) ON DELETE CASCADE`.

### 1.3 `relationships`
Социальные/фракционные связи между парами сущностей.

Рекомендуемые поля:
- `source_npc_id TEXT NOT NULL`.
- `target_npc_id TEXT NOT NULL`.
- `relation_kind TEXT NOT NULL` — ally, neutral, hostile, leader, follower и т.п.
- `score INTEGER NOT NULL` — численная оценка связи.
- `updated_at INTEGER NOT NULL`.

Ключи:
- `PRIMARY KEY (source_npc_id, target_npc_id, relation_kind)`.
- `FOREIGN KEY (source_npc_id) REFERENCES npc_states(npc_id) ON DELETE CASCADE`.
- `FOREIGN KEY (target_npc_id) REFERENCES npc_states(npc_id) ON DELETE CASCADE`.

### 1.4 `npc_events`
Персистентная очередь событий для отложенной/гарантированной обработки.

Рекомендуемые поля:
- `event_id INTEGER PRIMARY KEY AUTOINCREMENT`.
- `npc_id TEXT NOT NULL`.
- `event_type TEXT NOT NULL`.
- `payload_json TEXT`.
- `processed INTEGER NOT NULL DEFAULT 0` — 0/1 флаг обработки.
- `created_at INTEGER NOT NULL`.
- `processed_at INTEGER`.

Ключи:
- `PRIMARY KEY (event_id)`.
- `FOREIGN KEY (npc_id) REFERENCES npc_states(npc_id) ON DELETE CASCADE`.

### 1.5 `schedules`
Планировщик отложенных задач NPC.

Рекомендуемые поля:
- `schedule_id INTEGER PRIMARY KEY AUTOINCREMENT`.
- `npc_id TEXT NOT NULL`.
- `task_type TEXT NOT NULL`.
- `run_at INTEGER NOT NULL` — unix-time ближайшего запуска.
- `status TEXT NOT NULL` — pending, running, done, canceled.
- `priority INTEGER NOT NULL DEFAULT 0`.
- `last_error TEXT`.

Ключи:
- `PRIMARY KEY (schedule_id)`.
- `FOREIGN KEY (npc_id) REFERENCES npc_states(npc_id) ON DELETE CASCADE`.

---

## 2. Индексы под рабочие запросы

Ниже — минимальный набор индексов для типичных «горячих» чтений.

### 2.1 Фильтрация по area
- `CREATE INDEX idx_npc_states_area ON npc_states(area_id);`

Сценарий: быстрый выбор NPC в конкретной области для area-tick обработки.

### 2.2 Фильтрация по status / priority
- `CREATE INDEX idx_npc_goals_status_priority ON npc_goals(status, priority DESC);`
- `CREATE INDEX idx_schedules_status_priority ON schedules(status, priority DESC);`

Сценарий: выборка активных элементов очередей в порядке приоритета.

### 2.3 Фильтрация по processed / run_at
- `CREATE INDEX idx_npc_events_processed_created ON npc_events(processed, created_at);`
- `CREATE INDEX idx_schedules_run_at ON schedules(run_at);`
- `CREATE INDEX idx_schedules_status_run_at ON schedules(status, run_at);`

Сценарий:
- поиск необработанных событий (`processed = 0`);
- поиск «просроченных» задач (`run_at <= now`) и ближайших запусков.

Примечание: состав индексов уточняется по профилированию (`EXPLAIN QUERY PLAN` + runtime-метрики).

---

## 3. Версионирование схемы через `PRAGMA user_version`

Используется целочисленная версия схемы SQLite:
- текущая версия читается через `PRAGMA user_version;`
- при старте модуля выполняется последовательность миграций `N -> N+1`;
- после успешной миграции фиксируется новая версия: `PRAGMA user_version = <N>;`.

Правила:
1. Миграции идемпотентны (где возможно: `IF NOT EXISTS`, проверка существования колонок/индексов).
2. Каждая миграция атомарна (в транзакции), кроме операций, которые SQLite выполняет вне транзакции по ограничениям DDL.
3. Код модуля проверяет минимально поддерживаемую версию и отказывается стартовать при несовместимости.
4. Версия схемы повышается только вместе с изменениями в репозитории (без «ручных» hotfix в проде).

---

## 4. Обязательные PRAGMA и назначение

### `PRAGMA journal_mode = WAL;`
- Включает WAL-режим.
- Даёт лучшую конкурентность: чтения не блокируются записью так агрессивно, как в rollback journal.
- Предпочтительный режим для write-behind и частых коротких транзакций.

### `PRAGMA busy_timeout = <ms>;`
- Задаёт время ожидания при блокировке БД.
- Снижает вероятность мгновенных ошибок `database is locked` в пиковых фазах.
- Рекомендуется стартовое окно 1000–5000 мс (подбирается по нагрузке).

### `PRAGMA foreign_keys = ON;`
- Принудительно включает проверку внешних ключей.
- Защищает от «осиротевших» записей в `npc_goals`, `npc_events`, `schedules`, `relationships`.

### `PRAGMA optimize;`
- Вызывается после изменения индексов/схемы и периодически в low-load окне.
- Позволяет SQLite обновлять внутренние статистики и улучшать планирование запросов.

---

## 5. Правила write-behind

Write-behind применяется для операций, не требующих немедленной синхронной фиксации в рамках текущего тика.

### 5.1 Когда выполнять flush
Flush dirty-очереди выполняется при любом из условий:
1. По таймеру (например, каждые 100–250 мс).
2. По размеру батча (достигнут лимит dirty-элементов).
3. Перед критическими lifecycle-событиями (`module_stop`, `reload`, `shutdown`).
4. При переходе в «опасный» режим (рост очереди/ошибки записи).

### 5.2 Допустимый размер dirty-очереди
Рекомендуемые пороги (базовый профиль):
- **Нормальный режим:** до 1_000 записей.
- **Мягкий лимит:** 1_001–5_000 (форсировать более частый flush, уменьшать размер игровых батчей).
- **Жёсткий лимит:** > 5_000 (включать деградацию: временно отключать не-критичные записи/агрегацию).

Конкретные значения должны калиброваться бенчмарками под целевой online.

### 5.3 Что считается аварийным состоянием
Система считает состояние аварийным, если выполняется хотя бы одно условие:
- dirty-очередь превышает жёсткий лимит дольше заданного окна (например, > 10 секунд);
- серия ошибок записи в БД подряд (например, 3+ неуспешных flush);
- flush-латентность стабильно выходит за бюджет тика и вызывает заметную деградацию runtime;
- БД недоступна/повреждена (`database disk image is malformed`, постоянный `database is locked` после таймаута).

В аварийном состоянии:
1. логируется health-событие высокого приоритета;
2. включается режим graceful degradation (только критичные записи);
3. предпринимается безопасный повтор flush с backoff;
4. при невозможности стабилизации — модуль переводится в fail-safe режим с минимальным влиянием на игровой тик.


---

## 6. Трассировка “документ → функции/файлы”

### 6.0 Контракт safe read/write (`NpcSqliteSafeRead` / `NpcSqliteSafeWrite`)
- После нормализации кода ошибки `nCode` функции всегда обновляют `npc_sqlite_last_query` текущим SQL.
- `npc_sqlite_last_result` выставляется по итоговому коду операции:
  - `"ok"`, если `nCode == NPC_SQLITE_OK`;
  - `"error:<code>"`, если `nCode != NPC_SQLITE_OK`.
- `NpcSqliteLogDbError(...)` вызывается только при ошибке (`nCode != NPC_SQLITE_OK`), при этом `npc_sqlite_last_result` уже содержит ошибочный итог.

### 6.1 Базовый NWNX/SQLite API
- Инициализация: `NpcSqliteInit` — `src/integrations/nwnx_sqlite/npc_sql_api_inc.nss`.
- Healthcheck (`SELECT 1`): `NpcSqliteHealthcheck` — `src/integrations/nwnx_sqlite/npc_sql_api_inc.nss`.
- Безопасный доступ read/write: `NpcSqliteSafeRead`, `NpcSqliteSafeWrite` — `src/integrations/nwnx_sqlite/npc_sql_api_inc.nss`.
- Нормализация ошибок: `NpcSqliteNormalizeError` — `src/integrations/nwnx_sqlite/npc_sql_api_inc.nss`.
- Единое runtime-логирование DB ошибок: `NpcSqliteLogDbError` — `src/integrations/nwnx_sqlite/npc_sql_api_inc.nss`.

### 6.2 Repository-слой (SQL вне NPC core)
- SQL-константы и repository-функции:
  - `NPC_SQL_STATE_UPSERT`, `NpcRepoUpsertNpcState`;
  - `NPC_SQL_EVENTS_FETCH_UNPROCESSED`, `NpcRepoFetchUnprocessedEvents`;
  - `NPC_SQL_EVENT_MARK_PROCESSED`, `NpcRepoMarkEventProcessed`;
  - `NPC_SQL_SCHEDULES_FETCH_DUE`, `NpcRepoFetchDueSchedules`.
- Файл: `src/integrations/nwnx_sqlite/npc_repo_inc.nss`.
- Инвариант: `src/modules/npc/npc_core.nss` не содержит прямых SQL-строк.

### 6.3 Минимальный write-behind контракт
- Dirty-очередь: `NpcSqliteWriteBehindMarkDirty`, `NpcSqliteWriteBehindDirtyCount`.
- Flush-trigger (таймер/батч): `NpcSqliteWriteBehindShouldFlush`.
- Flush-операция: `NpcSqliteWriteBehindFlush`.
- Graceful degradation при сериях ошибок: `NpcSqliteWriteBehindApplyWriteResult` + `npc_sqlite_wb_degraded_mode`.
- Файл: `src/integrations/nwnx_sqlite/npc_wb_inc.nss`.

### 6.4 Встраивание в NPC runtime
- Модульная инициализация и healthcheck: `NpcBhvrOnModuleLoad` — `src/modules/npc/npc_core.nss`.
- Dirty-mark на enqueue: `NpcBhvrQueueEnqueue` — `src/modules/npc/npc_core.nss`.
- Flush-trigger в area tick: `NpcBhvrOnAreaTick` — `src/modules/npc/npc_core.nss`.
