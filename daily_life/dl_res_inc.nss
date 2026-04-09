#ifndef DL_RES_INC_NSS
#define DL_RES_INC_NSS

// Step 05: resolver/materialization skeleton.
// Scope is intentionally narrow: EARLY_WORKER sleep window only.

const string DL_L_NPC_DIRECTIVE = "dl_npc_directive";
const string DL_L_NPC_MAT_REQ = "dl_npc_mat_req";
const string DL_L_NPC_MAT_TAG = "dl_npc_mat_tag";

const int DL_DIR_NONE = 0;
const int DL_DIR_SLEEP = 1;

int DL_NormalizeHour(int nHour)
{
    while (nHour < 0)
    {
        nHour = nHour + 24;
    }
    while (nHour > 23)
    {
        nHour = nHour - 24;
    }
    return nHour;
}

int DL_IsEarlyWorkerSleepHour(int nHour)
{
    nHour = DL_NormalizeHour(nHour);
    return nHour >= 22 || nHour < 6;
}

int DL_ResolveNpcDirectiveAtHour(object oNpc, int nHour)
{
    if (!GetIsObjectValid(oNpc))
    {
        return DL_DIR_NONE;
    }

    if (GetLocalString(oNpc, "dl_profile_id") == "early_worker")
    {
        if (DL_IsEarlyWorkerSleepHour(nHour))
        {
            return DL_DIR_SLEEP;
        }
    }

    return DL_DIR_NONE;
}

int DL_ResolveNpcDirective(object oNpc)
{
    return DL_ResolveNpcDirectiveAtHour(oNpc, GetTimeHour());
}

void DL_ApplyMaterializationSkeleton(object oNpc, int nDirective)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    if (nDirective == DL_DIR_SLEEP)
    {
        SetLocalInt(oNpc, DL_L_NPC_MAT_REQ, TRUE);
        SetLocalString(oNpc, DL_L_NPC_MAT_TAG, "sleep");
        return;
    }

    DeleteLocalInt(oNpc, DL_L_NPC_MAT_REQ);
    DeleteLocalString(oNpc, DL_L_NPC_MAT_TAG);
}

void DL_ApplyDirectiveSkeleton(object oNpc, int nDirective)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    SetLocalInt(oNpc, DL_L_NPC_DIRECTIVE, nDirective);

    if (nDirective == DL_DIR_SLEEP)
    {
        SetLocalString(oNpc, "dl_state", "sleep");
    }
    else if (GetLocalString(oNpc, "dl_state") == "")
    {
        SetLocalString(oNpc, "dl_state", "idle");
    }

    DL_ApplyMaterializationSkeleton(oNpc, nDirective);
}

#endif
