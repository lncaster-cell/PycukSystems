// Legacy pending migration key/runtime helpers.

string NpcBhvrPendingPriorityKey(string sNpcKey)
{
    return NpcBhvrLocalKey("nb_pp_", sNpcKey);
}

string NpcBhvrPendingReasonCodeKey(string sNpcKey)
{
    return NpcBhvrLocalKey("nb_pr_", sNpcKey);
}

string NpcBhvrPendingStatusKey(string sNpcKey)
{
    return NpcBhvrLocalKey("nb_ps_", sNpcKey);
}

string NpcBhvrPendingUpdatedAtKey(string sNpcKey)
{
    return NpcBhvrLocalKey("nb_pu_", sNpcKey);
}

string NpcBhvrPendingPriorityLegacyKey(string sNpcKey)
{
    return "npc_queue_pending_priority_" + sNpcKey;
}

string NpcBhvrPendingReasonCodeLegacyKey(string sNpcKey)
{
    return "npc_queue_pending_reason_" + sNpcKey;
}

string NpcBhvrPendingStatusLegacyKey(string sNpcKey)
{
    return "npc_queue_pending_status_" + sNpcKey;
}

string NpcBhvrPendingUpdatedAtLegacyKey(string sNpcKey)
{
    return "npc_queue_pending_updated_ts_" + sNpcKey;
}

string NpcBhvrPendingLegacySubjectTag(object oSubject)
{
    string sTag;

    sTag = GetTag(oSubject);
    if (sTag == "")
    {
        sTag = "npc_" + GetName(oSubject);
    }

    return sTag;
}

string NpcBhvrPendingSubjectTag(object oSubject)
{
    object oModule;
    int nCounter;
    string sUid;

    if (!GetIsObjectValid(oSubject))
    {
        return "";
    }

    sUid = GetLocalString(oSubject, NPC_BHVR_VAR_NPC_UID);
    if (sUid != "")
    {
        return sUid;
    }

    // Tag/Name aren't stable unique IDs: cloned NPCs in one area/module can share both values.
    oModule = GetModule();
    nCounter = GetLocalInt(oModule, NPC_BHVR_VAR_NPC_UID_COUNTER) + 1;
    SetLocalInt(oModule, NPC_BHVR_VAR_NPC_UID_COUNTER, nCounter);
    sUid = "npc_uid_" + IntToString(nCounter);
    SetLocalString(oSubject, NPC_BHVR_VAR_NPC_UID, sUid);
    return sUid;
}

void NpcBhvrPendingAreaMigrateLegacy(object oArea, object oSubject, string sNpcKey)
{
    string sLegacyKey;
    string sStatus;
    int nValue;

    sLegacyKey = NpcBhvrPendingLegacySubjectTag(oSubject);
    if (sLegacyKey == sNpcKey)
    {
        return;
    }

    nValue = GetLocalInt(oArea, NpcBhvrPendingPriorityKey(sNpcKey));
    if (nValue == 0)
    {
        nValue = GetLocalInt(oArea, NpcBhvrPendingPriorityLegacyKey(sLegacyKey));
        if (nValue != 0)
        {
            SetLocalInt(oArea, NpcBhvrPendingPriorityKey(sNpcKey), nValue);
            DeleteLocalInt(oArea, NpcBhvrPendingPriorityLegacyKey(sLegacyKey));
        }
    }

    nValue = GetLocalInt(oArea, NpcBhvrPendingReasonCodeKey(sNpcKey));
    if (nValue == 0)
    {
        nValue = GetLocalInt(oArea, NpcBhvrPendingReasonCodeLegacyKey(sLegacyKey));
        if (nValue != 0)
        {
            SetLocalInt(oArea, NpcBhvrPendingReasonCodeKey(sNpcKey), nValue);
            DeleteLocalInt(oArea, NpcBhvrPendingReasonCodeLegacyKey(sLegacyKey));
        }
    }

    sStatus = GetLocalString(oArea, NpcBhvrPendingStatusKey(sNpcKey));
    if (sStatus == "")
    {
        sStatus = GetLocalString(oArea, NpcBhvrPendingStatusLegacyKey(sLegacyKey));
        if (sStatus != "")
        {
            SetLocalString(oArea, NpcBhvrPendingStatusKey(sNpcKey), sStatus);
            DeleteLocalString(oArea, NpcBhvrPendingStatusLegacyKey(sLegacyKey));
        }
    }

    nValue = GetLocalInt(oArea, NpcBhvrPendingUpdatedAtKey(sNpcKey));
    if (nValue == 0)
    {
        nValue = GetLocalInt(oArea, NpcBhvrPendingUpdatedAtLegacyKey(sLegacyKey));
        if (nValue != 0)
        {
            SetLocalInt(oArea, NpcBhvrPendingUpdatedAtKey(sNpcKey), nValue);
            DeleteLocalInt(oArea, NpcBhvrPendingUpdatedAtLegacyKey(sLegacyKey));
        }
    }
}

