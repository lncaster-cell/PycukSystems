#include "dl_all_inc"

const string DL_L_BINDING_PREFLIGHT_ERRORS = "dl_binding_preflight_errors";
const string DL_L_BINDING_PREFLIGHT_WARNINGS = "dl_binding_preflight_warnings";
const string DL_L_BINDING_PREFLIGHT_CHECKED = "dl_binding_preflight_checked";

void DL_LogBindingPreflightIssue(object oNPC, string sField, string sValue, string sExpected)
{
    DL_Log(
        DL_DEBUG_BASIC,
        "Runtime binding preflight issue npc=" + GetTag(oNPC)
        + " field=" + sField
        + " value=" + sValue
        + " expected=" + sExpected
    );
}

void DL_RestoreBindingProbeResyncState(object oNPC, int bHadPending, int nPreviousReason)
{
    if (bHadPending)
    {
        SetLocalInt(oNPC, DL_L_RESYNC_PENDING, TRUE);
    }
    else
    {
        DeleteLocalInt(oNPC, DL_L_RESYNC_PENDING);
    }

    SetLocalInt(oNPC, DL_L_RESYNC_REASON, nPreviousReason);
}

int DL_ProbeOnUserDefinedBinding(object oNPC)
{
    int bHadPending;
    int nPreviousReason;
    int bObserved;

    if (!GetIsObjectValid(oNPC) || !DL_IsDailyLifeNpc(oNPC))
    {
        return FALSE;
    }

    bHadPending = GetLocalInt(oNPC, DL_L_RESYNC_PENDING);
    nPreviousReason = GetLocalInt(oNPC, DL_L_RESYNC_REASON);

    DeleteLocalInt(oNPC, DL_L_RESYNC_PENDING);
    SetLocalInt(oNPC, DL_L_RESYNC_REASON, DL_RESYNC_NONE);

    DL_SignalNpcUserDefined(oNPC, DL_UD_RESYNC);

    bObserved =
        GetLocalInt(oNPC, DL_L_RESYNC_PENDING) == TRUE
        && GetLocalInt(oNPC, DL_L_RESYNC_REASON) == DL_RESYNC_WORKER;

    DL_RestoreBindingProbeResyncState(oNPC, bHadPending, nPreviousReason);
    return bObserved;
}

void main()
{
    object oArea = GetFirstArea();
    int nChecked = 0;
    int nWarnings = 0;
    int nErrors = 0;

    while (GetIsObjectValid(oArea))
    {
        object oObject = GetFirstObjectInArea(oArea);

        while (GetIsObjectValid(oObject))
        {
            if (GetObjectType(oObject) == OBJECT_TYPE_CREATURE && !GetIsPC(oObject) && DL_IsDailyLifeNpc(oObject))
            {
                nChecked += 1;

                if (!DL_ProbeOnUserDefinedBinding(oObject))
                {
                    DL_LogBindingPreflightIssue(
                        oObject,
                        "OnUserDefined",
                        "probe_failed",
                        "scripts/daily_life/dl_npc_onud handles DL_UD_RESYNC"
                    );
                    nErrors += 1;
                }
            }

            oObject = GetNextObjectInArea(oArea);
        }

        oArea = GetNextArea();
    }

    if (nChecked == 0)
    {
        DL_Log(DL_DEBUG_BASIC, "Runtime binding preflight issue no Daily Life NPC found");
        nErrors += 1;
    }

    DL_Log(
        DL_DEBUG_BASIC,
        "Runtime binding preflight manual checklist OnSpawn=scripts/daily_life/dl_npc_onspawn OnDeath=scripts/daily_life/dl_npc_ondeath"
    );

    DL_Log(
        DL_DEBUG_BASIC,
        "Runtime binding preflight summary checked=" + IntToString(nChecked)
        + " warnings=" + IntToString(nWarnings)
        + " errors=" + IntToString(nErrors)
    );

    SetLocalInt(GetModule(), DL_L_BINDING_PREFLIGHT_CHECKED, nChecked);
    SetLocalInt(GetModule(), DL_L_BINDING_PREFLIGHT_WARNINGS, nWarnings);
    SetLocalInt(GetModule(), DL_L_BINDING_PREFLIGHT_ERRORS, nErrors);
}
