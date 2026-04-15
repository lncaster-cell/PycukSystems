// Valid runtime lifecycle events start at 1.
const int DL_NPC_EVENT_SPAWN = 1;
const int DL_NPC_EVENT_DEATH = 2;
const int DL_NPC_EVENT_BLOCKED = 3;

// 3000+ range chosen for project-defined user events (avoid BioWare 1000..1011, 1510, 1511).
const int DL_UD_PIPELINE_NPC_EVENT = 3001;

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

int DL_IsNpcLifecycleEventKind(int nEventKind)
{
    return nEventKind == DL_NPC_EVENT_SPAWN || nEventKind == DL_NPC_EVENT_DEATH;
}

void DL_HandleNpcUserDefined(object oNpc, int nUserDefined)
{
    if (nUserDefined != DL_UD_PIPELINE_NPC_EVENT)
    {
        return;
    }

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    int nEventKind = GetLocalInt(oNpc, DL_L_NPC_EVENT_KIND);
    if (!DL_IsNpcLifecycleEventKind(nEventKind))
    {
        return;
    }

    // Death cleanup is an invariant: runtime state must be cleaned even if runtime is disabled.
    if (nEventKind == DL_NPC_EVENT_DEATH)
    {
        DL_CleanupNpcRuntimeState(oNpc);
        if (!DL_IsRuntimeEnabled())
        {
            return;
        }
    }
    else if (!DL_IsRuntimeEnabled())
    {
        // Spawn processing remains runtime-gated by design.
        return;
    }

    DL_RecordNpcLifecycleEvent(oNpc, nEventKind);

    if (nEventKind == DL_NPC_EVENT_SPAWN)
    {
        if (!DL_IsActivePipelineNpc(oNpc))
        {
            return;
        }

        DL_RegisterNpc(oNpc);
        DL_RequestResync(oNpc, DL_RESYNC_SPAWN);
        DL_ProcessResync(oNpc);
        return;
    }
}
