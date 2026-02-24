# `src/integrations/nwnx_sqlite` — runtime API и контракты

Каталог содержит рабочие include-модули интеграции NPC runtime с NWNX/SQLite.

> Источник истины для SQLite API-обёртки: `npc_sql_api_inc.nss`.
> `npc_sqlite_api_inc.nss` оставлен только как compatibility shim и не должен использоваться для изменений логики.

## Include-модули

- `npc_sql_api_inc.nss` — базовый DB API:
  - `NpcSqliteInit()`;
  - `NpcSqliteHealthcheck()` (обязательный smoke `SELECT 1;`);
  - `NpcSqliteSafeRead(string sQuery)` / `NpcSqliteSafeWrite(string sQuery)`;
  - `NpcSqliteNormalizeError(string sErrorRaw)`;
  - `NpcSqliteLogDbError(string sOperation, int nCode, string sErrorRaw, string sQuery)`.
- `npc_repo_inc.nss` — repository-слой с SQL-константами и thin-функциями:
  - `NpcRepoUpsertNpcState()`;
  - `NpcRepoFetchUnprocessedEvents()`;
  - `NpcRepoMarkEventProcessed()`;
  - `NpcRepoFetchDueSchedules()`.

> ⚠️ Статус подключения к runtime: сейчас в рабочем тике используется только
> `NpcRepoUpsertNpcState()` (через write-behind flush). Функции
> `NpcRepoFetchUnprocessedEvents()`, `NpcRepoMarkEventProcessed()` и
> `NpcRepoFetchDueSchedules()` пока являются **contract-only** (API + SQL в repo,
> без вызовов из lifecycle/worker NPC).
- `npc_wb_inc.nss` — минимальный write-behind контракт:
  - dirty-очередь: `NpcSqliteWriteBehindMarkDirty()`, `NpcSqliteWriteBehindDirtyCount()`;
  - flush-trigger: `NpcSqliteWriteBehindShouldFlush(int nNowTs, int nBatchSize, int nFlushIntervalSec)`;
  - flush: `NpcSqliteWriteBehindFlush(int nNowTs, int nBatchSize)`;
  - graceful degradation: `NpcSqliteWriteBehindApplyWriteResult(int nWriteResult)` + `npc_sqlite_wb_degraded_mode`.


## Compatibility aliases

В каталоге сохранены два shim-include для обратной совместимости со старыми путями include:

- `npc_sqlite_api_inc.nss` -> `npc_sql_api_inc.nss`;
- `npc_writebehind_inc.nss` -> `npc_wb_inc.nss`.

Причина существования: дать существующим скриптам время на миграцию без немедленного breaking change.
Политика поддержки: **deprecated**, удаление запланировано на **2026-06-30**.
Новые изменения и новые include должны использовать только канонические файлы.

## Нормализованные коды ошибок

- `NPC_SQLITE_OK = 0`
- `NPC_SQLITE_ERR_NOT_READY = 1001`
- `NPC_SQLITE_ERR_LOCKED = 1002`
- `NPC_SQLITE_ERR_BUSY = 1003`
- `NPC_SQLITE_ERR_MALFORMED = 1004`
- `NPC_SQLITE_ERR_CONSTRAINT = 1005`
- `NPC_SQLITE_ERR_IO = 1006`
- `NPC_SQLITE_ERR_UNKNOWN = 1999`

## Инварианты runtime

1. Любой read/write в SQLite выполняется только через `NpcSqliteSafeRead/Write`.
2. Любая DB-ошибка логируется только через `NpcSqliteLogDbError`.
3. Healthcheck обязан использовать `SELECT 1;` через `NpcSqliteHealthcheck()`.
4. При серии write-ошибок (`>=3`) write-behind переводится в degraded-mode (`npc_sqlite_wb_degraded_mode=TRUE`).
5. SQL-строки для NPC persistence хранятся в repository include (`npc_repo_inc.nss`), а не в `npc_core.nss`.

## Точки интеграции с NPC runtime

- `src/modules/npc/npc_core.nss`:
  - включает `npc_sql_api_inc` и `npc_wb_inc`;
  - на `NpcBhvrOnModuleLoad()` вызывает `NpcSqliteInit()` + `NpcSqliteHealthcheck()`;
  - на enqueue-событиях помечает dirty через `NpcSqliteWriteBehindMarkDirty()`;
  - в area tick запускает flush по таймеру/батчу через `NpcSqliteWriteBehindShouldFlush(...)`.
