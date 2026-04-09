#include "dl_res_inc"

// Daily Life core event ingress (clean-room).
// Ingress scope: OnSpawn/OnDeath -> OnUserDefined bridge.

const string DL_L_MODULE_ENABLED = "dl_enabled";
const string DL_L_MODULE_CONTRACT_VERSION = "dl_contract_version";
const string DL_CONTRACT_VERSION_A0 = "a0";

const string DL_L_NPC_EVENT_KIND = "dl_npc_event_kind";
const string DL_L_NPC_EVENT_SEQ = "dl_npc_event_seq";

const string DL_L_MODULE_EVENT_SEQ = "dl_module_event_seq";
const string DL_L_MODULE_LAST_EVENT_KIND = "dl_module_last_event_kind";
const string DL_L_MODULE_LAST_EVENT_ACTOR = "dl_module_last_event_actor";
const string DL_L_MODULE_SPAWN_COUNT = "dl_module_spawn_count";
const string DL_L_MODULE_DEATH_COUNT = "dl_module_death_count";

const string DL_L_NPC_RESYNC_PENDING = "dl_npc_resync_pending";
const string DL_L_NPC_RESYNC_REASON = "dl_npc_resync_reason";

const string DL_L_MODULE_RESYNC_REQ = "dl_module_resync_req";
const string DL_L_MODULE_CLEANUP_CNT = "dl_module_cleanup_cnt";

const int DL_RESYNC_NONE = 0;
const int DL_RESYNC_SPAWN = 1;
const int DL_RESYNC_DEATH = 2;
const int DL_RESYNC_USER = 3;


const string DL_L_AREA_TIER = "dl_area_tier";
const string DL_L_AREA_REG_COUNT = "dl_reg_count";
const string DL_L_AREA_REG_SEQ = "dl_reg_seq";
const string DL_L_AREA_WORKER_TICK = "dl_worker_tick";

const int DL_TIER_FROZEN = 0;
const int DL_TIER_WARM = 1;
const int DL_TIER_HOT = 2;

const string DL_L_AREA_WORKER_CURSOR = "dl_worker_cursor";
const string DL_L_AREA_WORKER_BUDGET = "dl_worker_budget";

const string DL_L_NPC_REG_ON = "dl_reg_on";
const string DL_L_NPC_PROFILE_ID = "dl_profile_id";
const string DL_L_NPC_STATE = "dl_state";
const string DL_L_NPC_WORKER_SEQ = "dl_npc_worker_seq";

const string DL_L_MODULE_WORKER_SEQ = "dl_module_worker_seq";
const string DL_L_MODULE_WORKER_TICKS = "dl_module_worker_ticks";

const int DL_NPC_EVENT_NONE = 0;
const int DL_NPC_EVENT_SPAWN = 1;
const int DL_NPC_EVENT_DEATH = 2;

// 3000+ range chosen for project-defined user events (avoid BioWare 1000..1011, 1510, 1511).
const int DL_UD_PIPELINE_NPC_EVENT = 3001;

const int DL_WORKER_BUDGET_MIN = 1;
const int DL_WORKER_BUDGET_WARM = 2;
const int DL_WORKER_BUDGET_HOT = 4;
const int DL_WORKER_BUDGET_MAX = 12;
const int DL_WORKER_SCAN_CAP = 128;

int DL_IsRuntimeEnabled()
{
    object oModule = GetModule();
    if (GetLocalInt(oModule, DL_L_MODULE_ENABLED) != TRUE)
    {
        return FALSE;
    }

    return GetLocalString(oModule, DL_L_MODULE_CONTRACT_VERSION) == DL_CONTRACT_VERSION_A0;
}

void DL_InitModuleContract()
{
    object oModule = GetModule();
    int nEnabled = GetLocalInt(oModule, DL_L_MODULE_ENABLED) == TRUE ? TRUE : FALSE;

    SetLocalString(oModule, DL_L_MODULE_CONTRACT_VERSION, DL_CONTRACT_VERSION_A0);
    SetLocalInt(oModule, DL_L_MODULE_ENABLED, nEnabled);

    if (GetLocalInt(oModule, DL_L_MODULE_EVENT_SEQ) < 0)
    {
        SetLocalInt(oModule, DL_L_MODULE_EVENT_SEQ, 0);
    }
}


int DL_AreaHasPlayer(object oArea)
{
    object oObj = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oObj))
    {
        if (GetIsPC(oObj) && !GetIsDM(oObj))
        {
            return TRUE;
        }
        oObj = GetNextObjectInArea(oArea);
    }
    return FALSE;
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
    if (!GetIsObjectValid(oArea) || GetObjectType(oArea) != OBJECT_TYPE_AREA)
    {
        return;
    }

    int nTier = DL_GetAreaTier(oArea);
    if (DL_AreaHasPlayer(oArea))
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
}

void DL_OnAreaEnterBootstrap(object oArea, object oEnter)
{
    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oEnter))
    {
        return;
    }

    if (GetIsPC(oEnter) && !GetIsDM(oEnter))
    {
        DL_SetAreaTier(oArea, DL_TIER_HOT);
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

    if (GetIsPC(oExit) && !GetIsDM(oExit) && !DL_AreaHasPlayer(oArea))
    {
        DL_SetAreaTier(oArea, DL_TIER_WARM);
        return;
    }

    DL_BootstrapAreaTier(oArea);
}

void DL_RequestResync(object oNpc, int nReason)
{
    if (!DL_IsPipelineNpc(oNpc))
    {
        return;
    }

    if (nReason < DL_RESYNC_NONE || nReason > DL_RESYNC_USER)
    {
        nReason = DL_RESYNC_USER;
    }

    SetLocalInt(oNpc, DL_L_NPC_RESYNC_PENDING, TRUE);
    SetLocalInt(oNpc, DL_L_NPC_RESYNC_REASON, nReason);

    object oModule = GetModule();
    SetLocalInt(oModule, DL_L_MODULE_RESYNC_REQ, GetLocalInt(oModule, DL_L_MODULE_RESYNC_REQ) + 1);
}

void DL_RegisterNpc(object oNpc)
{
    if (!DL_IsPipelineNpc(oNpc))
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
        SetLocalInt(oArea, DL_L_AREA_REG_COUNT, GetLocalInt(oArea, DL_L_AREA_REG_COUNT) + 1);
        SetLocalInt(oArea, DL_L_AREA_REG_SEQ, GetLocalInt(oArea, DL_L_AREA_REG_SEQ) + 1);
    }
}

void DL_UnregisterNpc(object oNpc)
{
    if (!DL_IsPipelineNpc(oNpc))
    {
        return;
    }

    if (GetLocalInt(oNpc, DL_L_NPC_REG_ON) != TRUE)
    {
        return;
    }

    DeleteLocalInt(oNpc, DL_L_NPC_REG_ON);

    object oArea = GetArea(oNpc);
    if (GetIsObjectValid(oArea))
    {
        int nCount = GetLocalInt(oArea, DL_L_AREA_REG_COUNT);
        if (nCount > 0)
        {
            SetLocalInt(oArea, DL_L_AREA_REG_COUNT, nCount - 1);
        }
        SetLocalInt(oArea, DL_L_AREA_REG_SEQ, GetLocalInt(oArea, DL_L_AREA_REG_SEQ) + 1);
    }
}

void DL_ProcessResync(object oNpc)
{
    if (!DL_IsPipelineNpc(oNpc))
    {
        return;
    }

    if (!DL_IsRuntimeEnabled())
    {
        return;
    }

    if (GetLocalInt(oNpc, DL_L_NPC_RESYNC_PENDING) != TRUE)
    {
        return;
    }

    SetLocalInt(oNpc, DL_L_NPC_RESYNC_PENDING, FALSE);
}

void DL_CleanupNpcRuntimeState(object oNpc)
{
    if (!DL_IsPipelineNpc(oNpc))
    {
        return;
    }

    DL_UnregisterNpc(oNpc);

    DeleteLocalInt(oNpc, DL_L_NPC_EVENT_KIND);
    DeleteLocalInt(oNpc, DL_L_NPC_EVENT_SEQ);
    DeleteLocalInt(oNpc, DL_L_NPC_RESYNC_PENDING);
    DeleteLocalInt(oNpc, DL_L_NPC_RESYNC_REASON);
    DeleteLocalInt(oNpc, DL_L_NPC_WORKER_SEQ);

    object oModule = GetModule();
    SetLocalInt(oModule, DL_L_MODULE_CLEANUP_CNT, GetLocalInt(oModule, DL_L_MODULE_CLEANUP_CNT) + 1);
}

void DL_WorkerTouchNpc(object oNpc)
{
    if (!DL_IsPipelineNpc(oNpc))
    {
        return;
    }

    if (GetLocalInt(oNpc, DL_L_NPC_REG_ON) != TRUE)
    {
        DL_RegisterNpc(oNpc);
    }

    object oModule = GetModule();
    int nWorkerSeq = GetLocalInt(oModule, DL_L_MODULE_WORKER_SEQ) + 1;
    SetLocalInt(oModule, DL_L_MODULE_WORKER_SEQ, nWorkerSeq);
    SetLocalInt(oNpc, DL_L_NPC_WORKER_SEQ, nWorkerSeq);

    int nDirective = DL_ResolveNpcDirective(oNpc);
    DL_ApplyDirectiveSkeleton(oNpc, nDirective);
}

void DL_RunAreaWorkerTick(object oArea)
{
    if (!GetIsObjectValid(oArea) || GetObjectType(oArea) != OBJECT_TYPE_AREA)
    {
        return;
    }

    if (!DL_IsRuntimeEnabled())
    {
        return;
    }

    DL_BootstrapAreaTier(oArea);
    if (DL_GetAreaTier(oArea) == DL_TIER_FROZEN)
    {
        return;
    }

    int nBudget = DL_GetAreaWorkerBudget(oArea);
    int nCursor = DL_GetAreaWorkerCursor(oArea);
    int nTouched = 0;
    int nScanned = 0;
    int nIndex = 0;
    object oObj = GetFirstObjectInArea(oArea);

    while (GetIsObjectValid(oObj) && nTouched < nBudget && nScanned < DL_WORKER_SCAN_CAP)
    {
        if (DL_IsPipelineNpc(oObj))
        {
            if (nIndex >= nCursor)
            {
                DL_WorkerTouchNpc(oObj);
                nTouched = nTouched + 1;
            }
            nIndex = nIndex + 1;
        }
        oObj = GetNextObjectInArea(oArea);
        nScanned = nScanned + 1;
    }

    if (nTouched < nBudget && nCursor > 0)
    {
        oObj = GetFirstObjectInArea(oArea);
        nScanned = 0;
        nIndex = 0;

        while (GetIsObjectValid(oObj) && nTouched < nBudget && nScanned < DL_WORKER_SCAN_CAP)
        {
            if (DL_IsPipelineNpc(oObj))
            {
                if (nIndex < nCursor)
                {
                    DL_WorkerTouchNpc(oObj);
                    nTouched = nTouched + 1;
                }
                nIndex = nIndex + 1;
            }
            oObj = GetNextObjectInArea(oArea);
            nScanned = nScanned + 1;
        }
    }

    if (nIndex <= 0)
    {
        DL_SetAreaWorkerCursor(oArea, 0);
    }
    else
    {
        DL_SetAreaWorkerCursor(oArea, (nCursor + nTouched) % nIndex);
    }

    SetLocalInt(oArea, DL_L_AREA_WORKER_TICK, GetLocalInt(oArea, DL_L_AREA_WORKER_TICK) + 1);
    object oModule = GetModule();
    SetLocalInt(oModule, DL_L_MODULE_WORKER_TICKS, GetLocalInt(oModule, DL_L_MODULE_WORKER_TICKS) + 1);
}

int DL_IsPipelineNpc(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return FALSE;
    }

    if (GetObjectType(oNpc) != OBJECT_TYPE_CREATURE)
    {
        return FALSE;
    }

    if (GetIsDM(oNpc))
    {
        return FALSE;
    }

    return TRUE;
}

void DL_RequestNpcLifecycleSignal(object oNpc, int nEventKind)
{
    if (!DL_IsPipelineNpc(oNpc))
    {
        return;
    }

    SetLocalInt(oNpc, DL_L_NPC_EVENT_KIND, nEventKind);
    SetLocalInt(oNpc, DL_L_NPC_EVENT_SEQ, GetLocalInt(oNpc, DL_L_NPC_EVENT_SEQ) + 1);

    SignalEvent(oNpc, EventUserDefined(DL_UD_PIPELINE_NPC_EVENT));
}

void DL_RecordNpcLifecycleEvent(object oNpc, int nEventKind)
{
    object oModule = GetModule();
    int nSeq = GetLocalInt(oModule, DL_L_MODULE_EVENT_SEQ) + 1;

    SetLocalInt(oModule, DL_L_MODULE_EVENT_SEQ, nSeq);
    SetLocalInt(oModule, DL_L_MODULE_LAST_EVENT_KIND, nEventKind);
    SetLocalObject(oModule, DL_L_MODULE_LAST_EVENT_ACTOR, oNpc);

    if (nEventKind == DL_NPC_EVENT_SPAWN)
    {
        SetLocalInt(oModule, DL_L_MODULE_SPAWN_COUNT, GetLocalInt(oModule, DL_L_MODULE_SPAWN_COUNT) + 1);
        return;
    }

    if (nEventKind == DL_NPC_EVENT_DEATH)
    {
        SetLocalInt(oModule, DL_L_MODULE_DEATH_COUNT, GetLocalInt(oModule, DL_L_MODULE_DEATH_COUNT) + 1);
    }
}

void DL_HandleNpcUserDefined(object oNpc, int nUserDefined)
{
    if (nUserDefined != DL_UD_PIPELINE_NPC_EVENT)
    {
        return;
    }

    if (!DL_IsPipelineNpc(oNpc))
    {
        return;
    }

    if (!DL_IsRuntimeEnabled())
    {
        return;
    }

    int nEventKind = GetLocalInt(oNpc, DL_L_NPC_EVENT_KIND);
    if (nEventKind != DL_NPC_EVENT_SPAWN && nEventKind != DL_NPC_EVENT_DEATH)
    {
        return;
    }

    DL_RecordNpcLifecycleEvent(oNpc, nEventKind);

    if (nEventKind == DL_NPC_EVENT_SPAWN)
    {
        DL_RegisterNpc(oNpc);
        DL_RequestResync(oNpc, DL_RESYNC_SPAWN);
        DL_ProcessResync(oNpc);
        return;
    }

    if (nEventKind == DL_NPC_EVENT_DEATH)
    {
        DL_RequestResync(oNpc, DL_RESYNC_DEATH);
        DL_CleanupNpcRuntimeState(oNpc);
    }
}

