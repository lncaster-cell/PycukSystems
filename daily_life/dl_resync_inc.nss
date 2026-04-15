const string DL_L_NPC_RESYNC_PENDING = "dl_npc_resync_pending";
const string DL_L_NPC_RESYNC_REASON = "dl_npc_resync_reason";

const string DL_L_MODULE_RESYNC_REQ = "dl_module_resync_req";
const string DL_L_MODULE_CLEANUP_CNT = "dl_module_cleanup_cnt";

const int DL_RESYNC_NONE = 0;
const int DL_RESYNC_SPAWN = 1;
const int DL_RESYNC_USER = 2;
const int DL_RESYNC_AREA_ENTER = 3;

void DL_RequestResync(object oNpc, int nReason)
{
    if (!DL_IsPipelineNpc(oNpc))
    {
        return;
    }

    if (nReason < DL_RESYNC_NONE || nReason > DL_RESYNC_AREA_ENTER)
    {
        nReason = DL_RESYNC_USER;
    }

    SetLocalInt(oNpc, DL_L_NPC_RESYNC_PENDING, TRUE);
    SetLocalInt(oNpc, DL_L_NPC_RESYNC_REASON, nReason);

    object oModule = GetModule();
    SetLocalInt(oModule, DL_L_MODULE_RESYNC_REQ, GetLocalInt(oModule, DL_L_MODULE_RESYNC_REQ) + 1);
}

void DL_ProcessResync(object oNpc)
{
    if (!DL_IsActivePipelineNpc(oNpc))
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

    int nReason = GetLocalInt(oNpc, DL_L_NPC_RESYNC_REASON);
    if (nReason == DL_RESYNC_SPAWN || nReason == DL_RESYNC_USER || nReason == DL_RESYNC_AREA_ENTER)
    {
        int nDirective = DL_ResolveNpcDirective(oNpc);
        DL_ApplyDirectiveSkeleton(oNpc, nDirective);
        DL_MaybeLogNpcDiagnostic(oNpc, "resync", TRUE);
    }

    SetLocalInt(oNpc, DL_L_NPC_RESYNC_PENDING, FALSE);
}

void DL_CleanupNpcRuntimeState(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
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
