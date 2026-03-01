// NPC registry + player-count cache internals.

string NpcBhvrPendingSubjectTag(object oSubject);
string NpcBhvrPendingLegacySubjectTag(object oSubject);

string NpcBhvrRegistrySlotKey(int nIndex)
{
    return NPC_BHVR_VAR_REGISTRY_PREFIX + IntToString(nIndex);
}

string NpcBhvrRegistryIndexKey(object oNpc)
{
    return NPC_BHVR_VAR_REGISTRY_INDEX_PREFIX + NpcBhvrPendingSubjectTag(oNpc);
}

string NpcBhvrRegistryLegacyIndexKey(object oNpc)
{
    return NPC_BHVR_VAR_REGISTRY_INDEX_PREFIX + NpcBhvrPendingLegacySubjectTag(oNpc);
}

int NpcBhvrRegistryIsRuntimeNpcCandidate(object oNpc)
{
    if (!GetIsObjectValid(oNpc) || GetIsPC(oNpc) || GetObjectType(oNpc) != OBJECT_TYPE_CREATURE)
    {
        return FALSE;
    }

    if (GetLocalString(oNpc, "npc_cfg_role") != "" ||
        GetLocalString(oNpc, "npc_cfg_identity_type") != "" ||
        GetLocalString(oNpc, "npc_cfg_schedule") != "" ||
        GetLocalString(oNpc, "npc_cfg_work_route") != "" ||
        GetLocalString(oNpc, "npc_cfg_home_route") != "" ||
        GetLocalString(oNpc, "npc_cfg_leisure_route") != "" ||
        GetLocalString(oNpc, "npc_cfg_slot_dawn_route") != "" ||
        GetLocalString(oNpc, "npc_cfg_slot_morning_route") != "" ||
        GetLocalString(oNpc, "npc_cfg_slot_afternoon_route") != "" ||
        GetLocalString(oNpc, "npc_cfg_slot_evening_route") != "" ||
        GetLocalString(oNpc, "npc_cfg_slot_night_route") != "" ||
        GetLocalString(oNpc, "npc_cfg_alert_route") != "" ||
        GetLocalInt(oNpc, "npc_cfg_force_reactive") == TRUE ||
        GetLocalInt(oNpc, "npc_cfg_allow_physical_hide") == TRUE)
    {
        return TRUE;
    }

    // Runtime continuity path for already-initialized NPCs.
    return GetLocalString(oNpc, "npc_cfg_derived_role") != "" ||
           GetLocalString(oNpc, "npc_activity_route_effective") != "" ||
           GetLocalString(oNpc, "npc_route_profile_default") != "";
}

void NpcBhvrRegistryResetIdleCursor(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    SetLocalInt(oArea, NPC_BHVR_VAR_IDLE_CURSOR, 1);
}

void NpcBhvrRegistryClampIdleCursor(object oArea, int nCount)
{
    int nCursor;

    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    if (nCount <= 0)
    {
        NpcBhvrRegistryResetIdleCursor(oArea);
        return;
    }

    nCursor = GetLocalInt(oArea, NPC_BHVR_VAR_IDLE_CURSOR);
    if (nCursor <= 0 || nCursor > nCount)
    {
        SetLocalInt(oArea, NPC_BHVR_VAR_IDLE_CURSOR, 1);
    }
}

int NpcBhvrRegistryGetIndex(object oArea, object oNpc)
{
    int nIndex;

    nIndex = GetLocalInt(oArea, NpcBhvrRegistryIndexKey(oNpc));
    if (nIndex > 0)
    {
        return nIndex;
    }

    nIndex = GetLocalInt(oArea, NpcBhvrRegistryLegacyIndexKey(oNpc));
    if (nIndex > 0)
    {
        SetLocalInt(oArea, NpcBhvrRegistryIndexKey(oNpc), nIndex);
        DeleteLocalInt(oArea, NpcBhvrRegistryLegacyIndexKey(oNpc));
    }

    return nIndex;
}

int NpcBhvrRegistryInsert(object oArea, object oNpc)
{
    int nCount;
    int nIndex;

    if (!GetIsObjectValid(oArea) || !NpcBhvrRegistryIsRuntimeNpcCandidate(oNpc))
    {
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_REGISTRY_REJECT_TOTAL);
        return FALSE;
    }

    if (GetArea(oNpc) != oArea)
    {
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_REGISTRY_REJECT_TOTAL);
        return FALSE;
    }

    nIndex = NpcBhvrRegistryGetIndex(oArea, oNpc);
    if (nIndex > 0 && GetLocalObject(oArea, NpcBhvrRegistrySlotKey(nIndex)) == oNpc)
    {
        return TRUE;
    }

    nCount = GetLocalInt(oArea, NPC_BHVR_VAR_REGISTRY_COUNT);
    if (nCount >= NPC_BHVR_REGISTRY_MAX)
    {
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_REGISTRY_OVERFLOW_TOTAL);
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_REGISTRY_REJECT_TOTAL);
        return FALSE;
    }

    nCount = nCount + 1;
    SetLocalObject(oArea, NpcBhvrRegistrySlotKey(nCount), oNpc);
    SetLocalInt(oArea, NpcBhvrRegistryIndexKey(oNpc), nCount);
    SetLocalInt(oArea, NPC_BHVR_VAR_REGISTRY_COUNT, nCount);
    NpcBhvrRegistryClampIdleCursor(oArea, nCount);
    return TRUE;
}

int NpcBhvrRegistryRemove(object oArea, object oNpc)
{
    int nCount;
    int nIndex;
    object oTail;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oNpc))
    {
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_REGISTRY_REJECT_TOTAL);
        return FALSE;
    }

    nIndex = NpcBhvrRegistryGetIndex(oArea, oNpc);
    nCount = GetLocalInt(oArea, NPC_BHVR_VAR_REGISTRY_COUNT);
    if (nIndex <= 0 || nIndex > nCount)
    {
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_REGISTRY_REJECT_TOTAL);
        return FALSE;
    }

    oTail = GetLocalObject(oArea, NpcBhvrRegistrySlotKey(nCount));
    if (nIndex != nCount)
    {
        SetLocalObject(oArea, NpcBhvrRegistrySlotKey(nIndex), oTail);
        if (GetIsObjectValid(oTail))
        {
            SetLocalInt(oArea, NpcBhvrRegistryIndexKey(oTail), nIndex);
        }
    }

    DeleteLocalObject(oArea, NpcBhvrRegistrySlotKey(nCount));
    DeleteLocalInt(oArea, NpcBhvrRegistryIndexKey(oNpc));
    nCount = nCount - 1;
    SetLocalInt(oArea, NPC_BHVR_VAR_REGISTRY_COUNT, nCount);
    NpcBhvrRegistryClampIdleCursor(oArea, nCount);
    return TRUE;
}

int NpcBhvrRegistryCompactInvalidEntries(object oArea, int nBatchCap)
{
    int nCount;
    int nIndex;
    int nRemoved;
    object oNpc;
    object oTail;

    if (!GetIsObjectValid(oArea))
    {
        return 0;
    }

    NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_REGISTRY_COMPACTION_RUNS_TOTAL);

    nCount = GetLocalInt(oArea, NPC_BHVR_VAR_REGISTRY_COUNT);
    if (nCount <= 0)
    {
        NpcBhvrRegistryResetIdleCursor(oArea);
        return 0;
    }

    if (nBatchCap <= 0)
    {
        nBatchCap = nCount;
    }

    nIndex = 1;
    nRemoved = 0;

    while (nIndex <= nCount && nRemoved < nBatchCap)
    {
        oNpc = GetLocalObject(oArea, NpcBhvrRegistrySlotKey(nIndex));
        if (!GetIsObjectValid(oNpc) || GetArea(oNpc) != oArea || !NpcBhvrRegistryIsRuntimeNpcCandidate(oNpc))
        {
            if (GetIsObjectValid(oNpc))
            {
                DeleteLocalInt(oArea, NpcBhvrRegistryIndexKey(oNpc));
            }

            oTail = GetLocalObject(oArea, NpcBhvrRegistrySlotKey(nCount));
            if (nIndex != nCount)
            {
                SetLocalObject(oArea, NpcBhvrRegistrySlotKey(nIndex), oTail);
                if (GetIsObjectValid(oTail))
                {
                    SetLocalInt(oArea, NpcBhvrRegistryIndexKey(oTail), nIndex);
                }
            }

            DeleteLocalObject(oArea, NpcBhvrRegistrySlotKey(nCount));
            nCount = nCount - 1;
            nRemoved = nRemoved + 1;
            continue;
        }

        nIndex = nIndex + 1;
    }

    SetLocalInt(oArea, NPC_BHVR_VAR_REGISTRY_COUNT, nCount);
    NpcBhvrRegistryClampIdleCursor(oArea, nCount);

    if (nRemoved > 0)
    {
        NpcBhvrMetricAdd(oArea, NPC_BHVR_METRIC_REGISTRY_COMPACTION_REMOVED_TOTAL, nRemoved);
    }
    return nRemoved;
}

void NpcBhvrRegistryBroadcastIdleTickBudgeted(object oArea, int nMaxNpcPerTick)
{
    int nIndex;
    int nCount;
    int nProcessed;
    int nScanned;
    object oNpc;

    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    nCount = GetLocalInt(oArea, NPC_BHVR_VAR_REGISTRY_COUNT);
    if (nCount <= 0)
    {
        NpcBhvrRegistryResetIdleCursor(oArea);
        NpcBhvrMetricSet(oArea, NPC_BHVR_METRIC_IDLE_PROCESSED_PER_TICK, 0);
        NpcBhvrMetricSet(oArea, NPC_BHVR_METRIC_IDLE_REMAINING, 0);
        return;
    }

    if (nMaxNpcPerTick <= 0)
    {
        nMaxNpcPerTick = nCount;
    }

    NpcBhvrRegistryClampIdleCursor(oArea, nCount);
    nIndex = GetLocalInt(oArea, NPC_BHVR_VAR_IDLE_CURSOR);
    nProcessed = 0;
    nScanned = 0;

    while (nCount > 0 && nProcessed < nMaxNpcPerTick && nScanned < nCount)
    {
        if (nIndex > nCount)
        {
            nIndex = 1;
        }

        oNpc = GetLocalObject(oArea, NpcBhvrRegistrySlotKey(nIndex));
        nScanned = nScanned + 1;
        if (!GetIsObjectValid(oNpc) || GetArea(oNpc) != oArea)
        {
            nIndex = nIndex + 1;
            continue;
        }

        NpcBhvrActivityOnIdleTick(oNpc);
        nProcessed = nProcessed + 1;
        nIndex = nIndex + 1;
    }

    NpcBhvrRegistryClampIdleCursor(oArea, nCount);
    if (nCount > 0)
    {
        if (nIndex > nCount)
        {
            nIndex = 1;
        }
        SetLocalInt(oArea, NPC_BHVR_VAR_IDLE_CURSOR, nIndex);
    }

    NpcBhvrMetricSet(oArea, NPC_BHVR_METRIC_IDLE_PROCESSED_PER_TICK, nProcessed);
    if (nCount > nProcessed)
    {
        NpcBhvrMetricSet(oArea, NPC_BHVR_METRIC_IDLE_REMAINING, nCount - nProcessed);
    }
    else
    {
        NpcBhvrMetricSet(oArea, NPC_BHVR_METRIC_IDLE_REMAINING, 0);
    }
}
