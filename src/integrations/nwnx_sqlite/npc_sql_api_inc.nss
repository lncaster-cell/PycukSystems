// NWNX SQLite integration: base runtime API.
// Контракт: единая точка инициализации/healthcheck, безопасные read/write wrappers,
// нормализованные коды ошибок и централизованное логирование DB-ошибок.

const int NPC_SQLITE_OK = 0;
const int NPC_SQLITE_ERR_NOT_READY = 1001;
const int NPC_SQLITE_ERR_LOCKED = 1002;
const int NPC_SQLITE_ERR_BUSY = 1003;
const int NPC_SQLITE_ERR_MALFORMED = 1004;
const int NPC_SQLITE_ERR_CONSTRAINT = 1005;
const int NPC_SQLITE_ERR_IO = 1006;
const int NPC_SQLITE_ERR_UNKNOWN = 1999;

const string NPC_SQLITE_VAR_READY = "npc_sqlite_ready";
const string NPC_SQLITE_VAR_LAST_ERROR = "npc_sqlite_last_error";
const string NPC_SQLITE_VAR_LAST_ERROR_CODE = "npc_sqlite_last_error_code";
const string NPC_SQLITE_VAR_LAST_QUERY = "npc_sqlite_last_query";
const string NPC_SQLITE_VAR_LAST_RESULT = "npc_sqlite_last_result";
const string NPC_SQLITE_VAR_LAST_OPERATION = "npc_sqlite_last_operation";

const string NPC_SQLITE_OP_READ = "read";
const string NPC_SQLITE_OP_WRITE = "write";

int NpcSqliteNormalizeError(string sErrorRaw)
{
    string sError;

    sError = GetStringLowerCase(sErrorRaw);
    if (sError == "")
    {
        return NPC_SQLITE_OK;
    }

    if (FindSubString(sError, "locked") >= 0)
    {
        return NPC_SQLITE_ERR_LOCKED;
    }
    if (FindSubString(sError, "busy") >= 0)
    {
        return NPC_SQLITE_ERR_BUSY;
    }
    if (FindSubString(sError, "malformed") >= 0)
    {
        return NPC_SQLITE_ERR_MALFORMED;
    }
    if (FindSubString(sError, "constraint") >= 0)
    {
        return NPC_SQLITE_ERR_CONSTRAINT;
    }
    if (FindSubString(sError, "disk") >= 0 || FindSubString(sError, "i/o") >= 0)
    {
        return NPC_SQLITE_ERR_IO;
    }

    return NPC_SQLITE_ERR_UNKNOWN;
}

void NpcSqliteLogDbError(string sOperation, int nCode, string sErrorRaw, string sQuery)
{
    object oModule;

    oModule = GetModule();
    SetLocalString(oModule, NPC_SQLITE_VAR_LAST_ERROR, sErrorRaw);
    SetLocalInt(oModule, NPC_SQLITE_VAR_LAST_ERROR_CODE, nCode);
    SetLocalString(oModule, NPC_SQLITE_VAR_LAST_QUERY, sQuery);
    SetLocalString(oModule, NPC_SQLITE_VAR_LAST_OPERATION, sOperation);

    // Унифицированный runtime-лог для всех DB ошибок.
    WriteTimestampedLogEntry(
        "[npc.sqlite] op=" + sOperation
        + " code=" + IntToString(nCode)
        + " err='" + sErrorRaw + "'"
    );
}

int NpcSqliteInit()
{
    // В текущем контракте инициализация помечает готовность runtime API.
    // Реальный open/connect выполняется NWNX-слоем на старте сервера.
    SetLocalInt(GetModule(), NPC_SQLITE_VAR_READY, TRUE);
    return NPC_SQLITE_OK;
}

int NpcSqliteHealthcheck()
{
    // Smoke-инвариант: healthcheck обязан использовать SELECT 1.
    return NpcSqliteSafeRead("SELECT 1;");
}

int NpcSqliteSafeRead(string sQuery)
{
    object oModule;
    string sErrorRaw;
    int nCode;

    oModule = GetModule();
    if (GetLocalInt(oModule, NPC_SQLITE_VAR_READY) != TRUE)
    {
        NpcSqliteLogDbError(NPC_SQLITE_OP_READ, NPC_SQLITE_ERR_NOT_READY, "sqlite api is not ready", sQuery);
        return NPC_SQLITE_ERR_NOT_READY;
    }

    // Adapter hook:
    // В production здесь вызывается NWNX_SQLITE read API.
    // Для контрактного слоя используем инъекцию ошибки через module local.
    sErrorRaw = GetLocalString(oModule, "npc_sqlite_injected_read_error");
    nCode = NpcSqliteNormalizeError(sErrorRaw);

    SetLocalString(oModule, NPC_SQLITE_VAR_LAST_QUERY, sQuery);
    if (nCode == NPC_SQLITE_OK)
    {
        SetLocalString(oModule, NPC_SQLITE_VAR_LAST_RESULT, "ok");
    }
    else
    {
        SetLocalString(oModule, NPC_SQLITE_VAR_LAST_RESULT, "error:" + IntToString(nCode));
    }

    if (nCode != NPC_SQLITE_OK)
    {
        NpcSqliteLogDbError(NPC_SQLITE_OP_READ, nCode, sErrorRaw, sQuery);
    }

    return nCode;
}

int NpcSqliteSafeWrite(string sQuery)
{
    object oModule;
    string sErrorRaw;
    int nCode;

    oModule = GetModule();
    if (GetLocalInt(oModule, NPC_SQLITE_VAR_READY) != TRUE)
    {
        NpcSqliteLogDbError(NPC_SQLITE_OP_WRITE, NPC_SQLITE_ERR_NOT_READY, "sqlite api is not ready", sQuery);
        return NPC_SQLITE_ERR_NOT_READY;
    }

    sErrorRaw = GetLocalString(oModule, "npc_sqlite_injected_write_error");
    nCode = NpcSqliteNormalizeError(sErrorRaw);

    SetLocalString(oModule, NPC_SQLITE_VAR_LAST_QUERY, sQuery);
    if (nCode == NPC_SQLITE_OK)
    {
        SetLocalString(oModule, NPC_SQLITE_VAR_LAST_RESULT, "ok");
    }
    else
    {
        SetLocalString(oModule, NPC_SQLITE_VAR_LAST_RESULT, "error:" + IntToString(nCode));
    }

    if (nCode != NPC_SQLITE_OK)
    {
        NpcSqliteLogDbError(NPC_SQLITE_OP_WRITE, nCode, sErrorRaw, sQuery);
    }

    return nCode;
}
