const string DL_L_MODULE_WORKER_SEQ = "dl_module_worker_seq";
const string DL_L_MODULE_WORKER_TICKS = "dl_module_worker_ticks";
const string DL_L_MODULE_WORKER_LAST_PROCESSED = "dl_module_worker_last_processed";
const string DL_L_MODULE_RESYNC_LAST_PROCESSED = "dl_module_resync_last_processed";
const string DL_L_AREA_WORKER_LAST_PROCESSED = "dl_area_worker_last_processed";
const string DL_L_AREA_RESYNC_LAST_PROCESSED = "dl_area_resync_last_processed";
const string DL_L_NPC_LAST_TOUCH_TICK = "dl_npc_last_touch_tick";

const int DL_AREA_PASS_MODE_WORKER = 1;
const int DL_AREA_PASS_MODE_RESYNC = 2;
const string DL_L_AREA_REG_BOOTSTRAP_TICK = "dl_area_reg_bootstrap_tick";
const int DL_REG_BOOTSTRAP_INTERVAL_TICKS = 30;

void DL_WorkerTouchNpc(object oNpc);

int DL_MaybeBootstrapAreaRegistry(object oArea, int nTickStamp, int nScanBudget)
{
    int nLastBootstrapTick = GetLocalInt(oArea, DL_L_AREA_REG_BOOTSTRAP_TICK);
    if (nTickStamp >= nLastBootstrapTick && (nTickStamp - nLastBootstrapTick) < DL_REG_BOOTSTRAP_INTERVAL_TICKS)
    {
        return GetLocalInt(oArea, DL_L_AREA_REG_COUNT);
    }

    SetLocalInt(oArea, DL_L_AREA_REG_BOOTSTRAP_TICK, nTickStamp);

    if (nScanBudget < DL_WORKER_BUDGET_MIN)
    {
        nScanBudget = DL_WORKER_BUDGET_MIN;
    }

    object oObj = GetFirstObjectInArea(oArea);
    int nScannedActive = 0;

    while (GetIsObjectValid(oObj) && nScannedActive < nScanBudget)
    {
        if (GetObjectType(oObj) == OBJECT_TYPE_CREATURE && DL_IsActivePipelineNpc(oObj))
        {
            nScannedActive = nScannedActive + 1;
            if (GetLocalInt(oObj, DL_L_NPC_REG_ON) != TRUE)
            {
                DL_RegisterNpc(oObj);
            }
        }

        oObj = GetNextObjectInArea(oArea);
    }

    return GetLocalInt(oArea, DL_L_AREA_REG_COUNT);
}

int DL_ProcessAreaNpcByPassMode(object oNpc, int nPassMode, int nTickStamp)
{
    if (nPassMode == DL_AREA_PASS_MODE_WORKER &&
        GetLocalInt(oNpc, DL_L_NPC_LAST_TOUCH_TICK) == nTickStamp)
    {
        return FALSE;
    }

    if (nPassMode == DL_AREA_PASS_MODE_RESYNC)
    {
        DL_RequestResync(oNpc, DL_RESYNC_AREA_ENTER);
        DL_ProcessResync(oNpc);
        SetLocalInt(oNpc, DL_L_NPC_LAST_TOUCH_TICK, nTickStamp);
        return TRUE;
    }

    DL_WorkerTouchNpc(oNpc);
    SetLocalInt(oNpc, DL_L_NPC_LAST_TOUCH_TICK, nTickStamp);
    return TRUE;
}

int DL_RunAreaNpcRoundRobinPass(object oArea, int nCursor, int nBudget, int nPassMode, int nTickStamp)
{
    if (nCursor < 0)
    {
        nCursor = 0;
    }

    if (nBudget < DL_WORKER_BUDGET_MIN)
    {
        nBudget = DL_WORKER_BUDGET_MIN;
    }

    int nNpcProcessed = 0;
    int nNpcSeen = 0;
    int nNpcRegistered = GetLocalInt(oArea, DL_L_AREA_REG_COUNT);
    if (nNpcRegistered < 0)
    {
        nNpcRegistered = 0;
    }

    // Registry reconciliation: if area registry is empty, run throttled bounded scan
    // to recover from missed spawn/registration edges.
    if (nNpcRegistered == 0)
    {
        nNpcRegistered = DL_MaybeBootstrapAreaRegistry(oArea, nTickStamp, nBudget);
        if (nNpcRegistered == 0)
        {
            SetLocalInt(oArea, DL_L_AREA_PASS_LAST_SEEN, 0);
            return 0;
        }
    }

    if (nCursor >= nNpcRegistered)
    {
        nCursor = nCursor % nNpcRegistered;
    }

    object oObj = GetFirstObjectInArea(oArea);

    while (GetIsObjectValid(oObj))
    {
        if (GetObjectType(oObj) == OBJECT_TYPE_CREATURE && DL_IsActivePipelineNpc(oObj))
        {
            if (nNpcProcessed < nBudget && nNpcSeen >= nCursor)
            {
                if (DL_ProcessAreaNpcByPassMode(oObj, nPassMode, nTickStamp))
                {
                    nNpcProcessed = nNpcProcessed + 1;
                }
            }
            nNpcSeen = nNpcSeen + 1;

            // Fast-path: once we reached budget and a full logical window in front of cursor,
            // avoid scanning the rest of the area.
            if (nNpcProcessed >= nBudget && nNpcSeen >= (nCursor + nBudget))
            {
                break;
            }
        }

        oObj = GetNextObjectInArea(oArea);
    }

    if (nNpcProcessed < nBudget && nCursor > 0)
    {
        oObj = GetFirstObjectInArea(oArea);
        int nWrapSeen = 0;

        while (GetIsObjectValid(oObj) && nNpcProcessed < nBudget)
        {
            if (GetObjectType(oObj) == OBJECT_TYPE_CREATURE && DL_IsActivePipelineNpc(oObj))
            {
                if (nWrapSeen < nCursor)
                {
                    if (DL_ProcessAreaNpcByPassMode(oObj, nPassMode, nTickStamp))
                    {
                        nNpcProcessed = nNpcProcessed + 1;
                    }
                }
                nWrapSeen = nWrapSeen + 1;
            }

            oObj = GetNextObjectInArea(oArea);
        }
    }

    // Registry-backed source of truth: cheaper than full creature scans each tick.
    SetLocalInt(oArea, DL_L_AREA_PASS_LAST_SEEN, nNpcRegistered);
    return nNpcProcessed;
}

void DL_WorkerTouchNpc(object oNpc)
{
    if (!DL_IsActivePipelineNpc(oNpc))
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

    if (DL_GetNpcProblemSummary(oNpc) != "ok")
    {
        DL_MaybeLogNpcDiagnostic(oNpc, "worker", FALSE);
    }
    else
    {
        DeleteLocalString(oNpc, DL_L_NPC_DIAG_LAST_SIG);
    }
}

void DL_RunAreaEnterResyncTick(object oArea)
{
    if (!DL_IsAreaObject(oArea))
    {
        return;
    }

    if (!DL_IsRuntimeEnabled())
    {
        return;
    }

    if (DL_GetAreaTier(oArea) != DL_TIER_HOT)
    {
        return;
    }

    if (GetLocalInt(oArea, DL_L_AREA_ENTER_RESYNC_PENDING) != TRUE)
    {
        return;
    }

    int nBudget = DL_GetAreaResyncBudget(oArea);
    nBudget = DL_ConsumeModuleNpcBudget(nBudget);
    if (nBudget <= 0)
    {
        SetLocalInt(oArea, DL_L_AREA_RESYNC_LAST_PROCESSED, 0);
        object oModuleNoBudget = GetModule();
        SetLocalInt(oModuleNoBudget, DL_L_MODULE_RESYNC_LAST_PROCESSED, 0);
        return;
    }

    int nCursor = GetLocalInt(oArea, DL_L_AREA_ENTER_RESYNC_CURSOR);
    int nTickStamp = GetLocalInt(oArea, DL_L_AREA_WORKER_TICK);
    int nNpcProcessed = DL_RunAreaNpcRoundRobinPass(oArea, nCursor, nBudget, DL_AREA_PASS_MODE_RESYNC, nTickStamp);
    int nNpcSeen = GetLocalInt(oArea, DL_L_AREA_PASS_LAST_SEEN);

    SetLocalInt(oArea, DL_L_AREA_ENTER_RESYNC_TOUCHED, nNpcProcessed);
    SetLocalInt(oArea, DL_L_AREA_RESYNC_LAST_PROCESSED, nNpcProcessed);
    object oModule = GetModule();
    SetLocalInt(oModule, DL_L_MODULE_RESYNC_LAST_PROCESSED, nNpcProcessed);

    if (nNpcSeen <= 0)
    {
        SetLocalInt(oArea, DL_L_AREA_ENTER_RESYNC_CURSOR, 0);
        SetLocalInt(oArea, DL_L_AREA_ENTER_RESYNC_PENDING, FALSE);
        SetLocalInt(oArea, DL_L_AREA_ENTER_RESYNC_DONE, GetLocalInt(oArea, DL_L_AREA_ENTER_RESYNC_DONE) + 1);
        return;
    }

    int nNextCursor = (nCursor + nNpcProcessed) % nNpcSeen;
    SetLocalInt(oArea, DL_L_AREA_ENTER_RESYNC_CURSOR, nNextCursor);

    if (nNextCursor == 0)
    {
        SetLocalInt(oArea, DL_L_AREA_ENTER_RESYNC_PENDING, FALSE);
        SetLocalInt(oArea, DL_L_AREA_ENTER_RESYNC_DONE, GetLocalInt(oArea, DL_L_AREA_ENTER_RESYNC_DONE) + 1);
    }
}

void DL_RunAreaWorkerTick(object oArea)
{
    if (!DL_IsAreaObject(oArea))
    {
        return;
    }

    if (!DL_IsRuntimeEnabled())
    {
        return;
    }

    DL_BootstrapAreaTier(oArea);
    DL_MaybeReconcileAreaPlayerCount(oArea);
    if (DL_GetAreaTier(oArea) != DL_TIER_HOT)
    {
        return;
    }

    DL_RunAreaEnterResyncTick(oArea);

    int nBudget = DL_GetAreaWorkerBudget(oArea);
    nBudget = DL_ConsumeModuleNpcBudget(nBudget);
    if (nBudget <= 0)
    {
        SetLocalInt(oArea, DL_L_AREA_WORKER_TICK, GetLocalInt(oArea, DL_L_AREA_WORKER_TICK) + 1);
        object oModuleNoBudget = GetModule();
        SetLocalInt(oModuleNoBudget, DL_L_MODULE_WORKER_TICKS, GetLocalInt(oModuleNoBudget, DL_L_MODULE_WORKER_TICKS) + 1);
        SetLocalInt(oArea, DL_L_AREA_WORKER_LAST_PROCESSED, 0);
        SetLocalInt(oModuleNoBudget, DL_L_MODULE_WORKER_LAST_PROCESSED, 0);
        return;
    }

    int nCursor = DL_GetAreaWorkerCursor(oArea);
    int nTickStamp = GetLocalInt(oArea, DL_L_AREA_WORKER_TICK);
    int nNpcProcessed = DL_RunAreaNpcRoundRobinPass(oArea, nCursor, nBudget, DL_AREA_PASS_MODE_WORKER, nTickStamp);
    int nNpcSeen = GetLocalInt(oArea, DL_L_AREA_PASS_LAST_SEEN);

    if (nNpcSeen <= 0)
    {
        DL_SetAreaWorkerCursor(oArea, 0);
    }
    else
    {
        DL_SetAreaWorkerCursor(oArea, (nCursor + nNpcProcessed) % nNpcSeen);
    }

    SetLocalInt(oArea, DL_L_AREA_WORKER_TICK, GetLocalInt(oArea, DL_L_AREA_WORKER_TICK) + 1);
    object oModule = GetModule();
    SetLocalInt(oModule, DL_L_MODULE_WORKER_TICKS, GetLocalInt(oModule, DL_L_MODULE_WORKER_TICKS) + 1);
    SetLocalInt(oArea, DL_L_AREA_WORKER_LAST_PROCESSED, nNpcProcessed);
    SetLocalInt(oModule, DL_L_MODULE_WORKER_LAST_PROCESSED, nNpcProcessed);
}
