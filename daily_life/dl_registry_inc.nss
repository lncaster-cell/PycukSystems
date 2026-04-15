const string DL_L_AREA_TIER = "dl_area_tier";
const string DL_L_AREA_REG_COUNT = "dl_reg_count";
const string DL_L_AREA_REG_SEQ = "dl_reg_seq";
const string DL_L_AREA_WORKER_TICK = "dl_worker_tick";

const int DL_TIER_FROZEN = 0;
const int DL_TIER_WARM = 1;
const int DL_TIER_HOT = 2;

const string DL_L_AREA_WORKER_CURSOR = "dl_worker_cursor";
const string DL_L_AREA_WORKER_BUDGET = "dl_worker_budget";
const string DL_L_AREA_RESYNC_BUDGET = "dl_area_resync_budget";
const string DL_L_AREA_PLAYER_COUNT = "dl_area_player_count";
const string DL_L_AREA_PLAYER_COUNT_INIT = "dl_area_player_count_init";
const string DL_L_AREA_PLAYER_COUNT_RECONCILE_TICK = "dl_area_player_count_reconcile_tick";
const string DL_L_AREA_ENTER_RESYNC_PENDING = "dl_area_enter_resync_pending";
const string DL_L_AREA_ENTER_RESYNC_CURSOR = "dl_area_enter_resync_cursor";
const string DL_L_AREA_ENTER_RESYNC_TOUCHED = "dl_area_enter_resync_touched";
const string DL_L_AREA_ENTER_RESYNC_DONE = "dl_area_enter_resync_done";

const string DL_L_NPC_REG_ON = "dl_reg_on";
const string DL_L_NPC_WORKER_SEQ = "dl_npc_worker_seq";
const string DL_L_NPC_REG_AREA = "dl_npc_reg_area";

const int DL_WORKER_BUDGET_MIN = 1;
const int DL_WORKER_BUDGET_WARM = 2;
const int DL_WORKER_BUDGET_HOT = 4;
const int DL_WORKER_BUDGET_MAX = 12;
const int DL_RESYNC_BUDGET_MIN = 1;
const int DL_RESYNC_BUDGET_WARM = 1;
const int DL_RESYNC_BUDGET_HOT = 2;
const int DL_RESYNC_BUDGET_MAX = 6;
const int DL_PLAYER_COUNT_RECONCILE_INTERVAL_TICKS = 30;

const string DL_L_AREA_PASS_LAST_SEEN = "dl_area_pass_last_seen";
const string DL_L_MODULE_NPC_BUDGET_PER_MINUTE = "dl_module_npc_budget_per_minute";
const string DL_L_MODULE_NPC_BUDGET_MINUTE_KEY = "dl_module_npc_budget_minute_key";
const string DL_L_MODULE_NPC_BUDGET_LEFT = "dl_module_npc_budget_left";
const string DL_L_MODULE_NPC_BUDGET_WINDOW_INIT = "dl_module_npc_budget_window_init";

const int DL_MODULE_NPC_BUDGET_MIN = 1;
const int DL_MODULE_NPC_BUDGET_DEFAULT = 24;
const int DL_MODULE_NPC_BUDGET_MAX = 128;

int DL_CountPlayersInArea(object oArea)
{
    int nCount = 0;
    object oObj = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oObj))
    {
        if (GetObjectType(oObj) == OBJECT_TYPE_CREATURE && DL_IsRuntimePlayer(oObj))
        {
            nCount = nCount + 1;
        }
        oObj = GetNextObjectInArea(oArea);
    }
    return nCount;
}

int DL_GetAreaPlayerCount(object oArea)
{
    int nCount = GetLocalInt(oArea, DL_L_AREA_PLAYER_COUNT);
    if (nCount < 0)
    {
        nCount = 0;
        SetLocalInt(oArea, DL_L_AREA_PLAYER_COUNT, nCount);
    }
    return nCount;
}

void DL_RefreshAreaPlayerCount(object oArea)
{
    int nCount = DL_CountPlayersInArea(oArea);
    SetLocalInt(oArea, DL_L_AREA_PLAYER_COUNT, nCount);
    SetLocalInt(oArea, DL_L_AREA_PLAYER_COUNT_INIT, TRUE);
}

void DL_EnsureAreaPlayerCountSeeded(object oArea)
{
    if (GetLocalInt(oArea, DL_L_AREA_PLAYER_COUNT_INIT) == TRUE)
    {
        return;
    }

    DL_RefreshAreaPlayerCount(oArea);
}

void DL_MaybeReconcileAreaPlayerCount(object oArea)
{
    if (!DL_IsAreaObject(oArea))
    {
        return;
    }

    if (GetLocalInt(oArea, DL_L_AREA_PLAYER_COUNT_INIT) != TRUE)
    {
        DL_RefreshAreaPlayerCount(oArea);
        SetLocalInt(oArea, DL_L_AREA_PLAYER_COUNT_RECONCILE_TICK, GetLocalInt(oArea, DL_L_AREA_WORKER_TICK));
        return;
    }

    int nNowTick = GetLocalInt(oArea, DL_L_AREA_WORKER_TICK);
    int nLastTick = GetLocalInt(oArea, DL_L_AREA_PLAYER_COUNT_RECONCILE_TICK);
    if (nNowTick >= nLastTick && (nNowTick - nLastTick) < DL_PLAYER_COUNT_RECONCILE_INTERVAL_TICKS)
    {
        return;
    }

    SetLocalInt(oArea, DL_L_AREA_PLAYER_COUNT_RECONCILE_TICK, nNowTick);
    DL_RefreshAreaPlayerCount(oArea);
}

int DL_GetAreaTier(object oArea)
{
    int nTier = GetLocalInt(oArea, DL_L_AREA_TIER);
    if (nTier < DL_TIER_FROZEN || nTier > DL_TIER_HOT)
    {
        return DL_TIER_WARM;
    }
    return nTier;
}

void DL_SetAreaTier(object oArea, int nTier)
{
    if (nTier < DL_TIER_FROZEN)
    {
        nTier = DL_TIER_FROZEN;
    }
    if (nTier > DL_TIER_HOT)
    {
        nTier = DL_TIER_HOT;
    }
    SetLocalInt(oArea, DL_L_AREA_TIER, nTier);
}

int DL_GetAreaWorkerBudget(object oArea)
{
    int nBudget = GetLocalInt(oArea, DL_L_AREA_WORKER_BUDGET);
    if (nBudget < DL_WORKER_BUDGET_MIN || nBudget > DL_WORKER_BUDGET_MAX)
    {
        int nTier = DL_GetAreaTier(oArea);
        if (nTier == DL_TIER_HOT)
        {
            return DL_WORKER_BUDGET_HOT;
        }
        return DL_WORKER_BUDGET_WARM;
    }
    return nBudget;
}

int DL_GetAreaResyncBudget(object oArea)
{
    int nBudget = GetLocalInt(oArea, DL_L_AREA_RESYNC_BUDGET);
    if (nBudget < DL_RESYNC_BUDGET_MIN || nBudget > DL_RESYNC_BUDGET_MAX)
    {
        int nTier = DL_GetAreaTier(oArea);
        if (nTier == DL_TIER_HOT)
        {
            return DL_RESYNC_BUDGET_HOT;
        }
        return DL_RESYNC_BUDGET_WARM;
    }
    return nBudget;
}

void DL_SetAreaResyncBudget(object oArea, int nBudget)
{
    if (nBudget < DL_RESYNC_BUDGET_MIN)
    {
        nBudget = DL_RESYNC_BUDGET_MIN;
    }
    if (nBudget > DL_RESYNC_BUDGET_MAX)
    {
        nBudget = DL_RESYNC_BUDGET_MAX;
    }
    SetLocalInt(oArea, DL_L_AREA_RESYNC_BUDGET, nBudget);
}

int DL_GetModuleNpcBudgetPerMinute()
{
    object oModule = GetModule();
    int nBudget = GetLocalInt(oModule, DL_L_MODULE_NPC_BUDGET_PER_MINUTE);
    if (nBudget < DL_MODULE_NPC_BUDGET_MIN || nBudget > DL_MODULE_NPC_BUDGET_MAX)
    {
        return DL_MODULE_NPC_BUDGET_DEFAULT;
    }
    return nBudget;
}

void DL_SetModuleNpcBudgetPerMinute(int nBudget)
{
    if (nBudget < DL_MODULE_NPC_BUDGET_MIN)
    {
        nBudget = DL_MODULE_NPC_BUDGET_MIN;
    }
    if (nBudget > DL_MODULE_NPC_BUDGET_MAX)
    {
        nBudget = DL_MODULE_NPC_BUDGET_MAX;
    }

    object oModule = GetModule();
    SetLocalInt(oModule, DL_L_MODULE_NPC_BUDGET_PER_MINUTE, nBudget);
}

int DL_GetCurrentMinuteKey()
{
    return GetTimeHour() * 60 + GetTimeMinute();
}

void DL_EnsureModuleNpcBudgetWindow()
{
    object oModule = GetModule();
    int nNowKey = DL_GetCurrentMinuteKey();
    int nStoredKey = GetLocalInt(oModule, DL_L_MODULE_NPC_BUDGET_MINUTE_KEY);
    if (GetLocalInt(oModule, DL_L_MODULE_NPC_BUDGET_WINDOW_INIT) == TRUE && nNowKey == nStoredKey)
    {
        return;
    }

    SetLocalInt(oModule, DL_L_MODULE_NPC_BUDGET_WINDOW_INIT, TRUE);
    SetLocalInt(oModule, DL_L_MODULE_NPC_BUDGET_MINUTE_KEY, nNowKey);
    SetLocalInt(oModule, DL_L_MODULE_NPC_BUDGET_LEFT, DL_GetModuleNpcBudgetPerMinute());
}

int DL_ConsumeModuleNpcBudget(int nRequested)
{
    if (nRequested <= 0)
    {
        return 0;
    }

    DL_EnsureModuleNpcBudgetWindow();

    object oModule = GetModule();
    int nLeft = GetLocalInt(oModule, DL_L_MODULE_NPC_BUDGET_LEFT);
    if (nLeft <= 0)
    {
        return 0;
    }

    if (nRequested > nLeft)
    {
        nRequested = nLeft;
    }

    SetLocalInt(oModule, DL_L_MODULE_NPC_BUDGET_LEFT, nLeft - nRequested);
    return nRequested;
}

void DL_SetAreaWorkerBudget(object oArea, int nBudget)
{
    if (nBudget < DL_WORKER_BUDGET_MIN)
    {
        nBudget = DL_WORKER_BUDGET_MIN;
    }
    if (nBudget > DL_WORKER_BUDGET_MAX)
    {
        nBudget = DL_WORKER_BUDGET_MAX;
    }
    SetLocalInt(oArea, DL_L_AREA_WORKER_BUDGET, nBudget);
}

int DL_GetAreaWorkerCursor(object oArea)
{
    int nCursor = GetLocalInt(oArea, DL_L_AREA_WORKER_CURSOR);
    if (nCursor < 0)
    {
        return 0;
    }
    return nCursor;
}

void DL_SetAreaWorkerCursor(object oArea, int nCursor)
{
    if (nCursor < 0)
    {
        nCursor = 0;
    }
    SetLocalInt(oArea, DL_L_AREA_WORKER_CURSOR, nCursor);
}

void DL_BootstrapAreaTier(object oArea)
{
    if (!DL_IsAreaObject(oArea))
    {
        return;
    }

    DL_EnsureAreaPlayerCountSeeded(oArea);

    int nTier = DL_GetAreaTier(oArea);
    if (nTier != DL_TIER_HOT && DL_GetAreaPlayerCount(oArea) > 0)
    {
        nTier = DL_TIER_HOT;
    }
    else if (nTier < DL_TIER_WARM)
    {
        nTier = DL_TIER_WARM;
    }

    DL_SetAreaTier(oArea, nTier);

    if (GetLocalInt(oArea, DL_L_AREA_WORKER_CURSOR) < 0)
    {
        DL_SetAreaWorkerCursor(oArea, 0);
    }
    if (GetLocalInt(oArea, DL_L_AREA_WORKER_BUDGET) < DL_WORKER_BUDGET_MIN)
    {
        DL_SetAreaWorkerBudget(oArea, DL_GetAreaTier(oArea) == DL_TIER_HOT ? DL_WORKER_BUDGET_HOT : DL_WORKER_BUDGET_WARM);
    }
    if (GetLocalInt(oArea, DL_L_AREA_RESYNC_BUDGET) < DL_RESYNC_BUDGET_MIN)
    {
        DL_SetAreaResyncBudget(oArea, DL_GetAreaTier(oArea) == DL_TIER_HOT ? DL_RESYNC_BUDGET_HOT : DL_RESYNC_BUDGET_WARM);
    }
}

void DL_OnAreaEnterBootstrap(object oArea, object oEnter)
{
    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oEnter))
    {
        return;
    }

    if (DL_IsRuntimePlayer(oEnter))
    {
        // Runtime-safe refresh: OnEnter timing differs by engine/version; recompute exact count.
        DL_RefreshAreaPlayerCount(oArea);
        DL_SetAreaTier(oArea, DL_TIER_HOT);
        SetLocalInt(oArea, DL_L_AREA_ENTER_RESYNC_PENDING, TRUE);
        return;
    }

    DL_BootstrapAreaTier(oArea);
}

void DL_OnAreaExitBootstrap(object oArea, object oExit)
{
    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oExit))
    {
        return;
    }

    if (DL_IsRuntimePlayer(oExit))
    {
        // Runtime-safe refresh: avoid counter drift from event ordering edge-cases.
        DL_RefreshAreaPlayerCount(oArea);
        if (DL_GetAreaPlayerCount(oArea) <= 0)
        {
            DL_SetAreaTier(oArea, DL_TIER_WARM);
        }
        return;
    }

    DL_BootstrapAreaTier(oArea);
}

void DL_RegisterNpc(object oNpc)
{
    if (!DL_IsActivePipelineNpc(oNpc))
    {
        return;
    }

    if (GetLocalInt(oNpc, DL_L_NPC_REG_ON) == TRUE)
    {
        return;
    }

    SetLocalInt(oNpc, DL_L_NPC_REG_ON, TRUE);

    if (GetLocalString(oNpc, DL_L_NPC_PROFILE_ID) == "")
    {
        SetLocalString(oNpc, DL_L_NPC_PROFILE_ID, "default");
    }
    if (GetLocalString(oNpc, DL_L_NPC_STATE) == "")
    {
        SetLocalString(oNpc, DL_L_NPC_STATE, "idle");
    }

    object oArea = GetArea(oNpc);
    if (GetIsObjectValid(oArea))
    {
        SetLocalObject(oNpc, DL_L_NPC_REG_AREA, oArea);
        SetLocalInt(oArea, DL_L_AREA_REG_COUNT, GetLocalInt(oArea, DL_L_AREA_REG_COUNT) + 1);
        SetLocalInt(oArea, DL_L_AREA_REG_SEQ, GetLocalInt(oArea, DL_L_AREA_REG_SEQ) + 1);
    }
}

void DL_UnregisterNpc(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    if (GetObjectType(oNpc) != OBJECT_TYPE_CREATURE)
    {
        return;
    }

    if (GetIsPC(oNpc))
    {
        return;
    }

    if (GetIsDM(oNpc))
    {
        return;
    }

    if (GetLocalInt(oNpc, DL_L_NPC_REG_ON) != TRUE)
    {
        return;
    }

    DeleteLocalInt(oNpc, DL_L_NPC_REG_ON);

    object oArea = GetArea(oNpc);
    if (!GetIsObjectValid(oArea))
    {
        oArea = GetLocalObject(oNpc, DL_L_NPC_REG_AREA);
    }

    if (GetIsObjectValid(oArea))
    {
        int nCount = GetLocalInt(oArea, DL_L_AREA_REG_COUNT);
        if (nCount > 0)
        {
            SetLocalInt(oArea, DL_L_AREA_REG_COUNT, nCount - 1);
        }
        SetLocalInt(oArea, DL_L_AREA_REG_SEQ, GetLocalInt(oArea, DL_L_AREA_REG_SEQ) + 1);
    }

    DeleteLocalObject(oNpc, DL_L_NPC_REG_AREA);
    DeleteLocalString(oNpc, DL_L_NPC_DIAG_LAST_SIG);
}
