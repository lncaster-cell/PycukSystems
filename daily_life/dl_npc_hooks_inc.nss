#ifndef DL_NPC_HOOKS_INC_NSS
#define DL_NPC_HOOKS_INC_NSS

#include "dl_const_inc"
#include "dl_log_inc"
#include "dl_types_inc"
#include "dl_area_inc"
#include "dl_resync_inc"
#include "dl_slot_handoff_inc"

const int DL_UD_BOOTSTRAP = 12001;
const int DL_UD_RESYNC = 12002;
const int DL_UD_FORCE_RESYNC = 12003;
const int DL_UD_CLEANUP = 12004;
const int DL_UD_PERCEPTION = 12005;
const int DL_UD_PHYSICAL_ATTACKED = 12006;
const int DL_UD_DISTURBED = 12007;
const int DL_UD_DAMAGED = 12008;
const int DL_UD_SPELL_CAST_AT = 12009;

const string DL_L_UD_LAST_PERCEPTION_TICK = "dl_ud_last_perception_tick";
const string DL_L_UD_LAST_ATTACK_TICK = "dl_ud_last_attack_tick";
const string DL_L_UD_LAST_DISTURBED_TICK = "dl_ud_last_disturbed_tick";
const string DL_L_UD_LAST_DAMAGED_TICK = "dl_ud_last_damaged_tick";
const string DL_L_UD_LAST_SPELL_TICK = "dl_ud_last_spell_tick";
const string DL_L_UD_COOLDOWN_INIT_SUFFIX = "_init";

const int DL_UD_PERCEPTION_COOLDOWN_SEC = 3;
const int DL_UD_ATTACK_COOLDOWN_SEC = 1;
const int DL_UD_DISTURBED_COOLDOWN_SEC = 2;
const int DL_UD_DAMAGED_COOLDOWN_SEC = 1;
const int DL_UD_SPELL_COOLDOWN_SEC = 2;

int DL_GetHookClockSeconds()
{
    return (GetTimeHour() * 3600) + (GetTimeMinute() * 60) + GetTimeSecond();
}

int DL_HasHookCooldownElapsed(object oNPC, string sKey, int nCooldownSec)
{
    string sInitKey = sKey + DL_L_UD_COOLDOWN_INIT_SUFFIX;
    int nNow = DL_GetHookClockSeconds();
    int bInitialized = GetLocalInt(oNPC, sInitKey);
    int nLast;
    int nElapsed;

    if (!bInitialized)
    {
        return TRUE;
    }

    nLast = GetLocalInt(oNPC, sKey);
    nElapsed = nNow - nLast;
    if (nElapsed < 0)
    {
        nElapsed += 86400;
    }
    return nElapsed >= nCooldownSec;
}

void DL_MarkHookCooldown(object oNPC, string sKey)
{
    string sInitKey = sKey + DL_L_UD_COOLDOWN_INIT_SUFFIX;

    SetLocalInt(oNPC, sKey, DL_GetHookClockSeconds());
    SetLocalInt(oNPC, sInitKey, TRUE);
}

int DL_IsNpcLifecycleSubject(object oNPC)
{
    if (!GetIsObjectValid(oNPC))
    {
        return FALSE;
    }
    if (GetObjectType(oNPC) != OBJECT_TYPE_CREATURE)
    {
        return FALSE;
    }
    if (GetIsPC(oNPC))
    {
        return FALSE;
    }
    return TRUE;
}

string DL_GetPendingBootstrapSlotId(object oNPC)
{
    string sPendingSlotId;
    string sFunctionSlotId;
    string sBootstrapSlotId;
    object oBootstrapNpc;

    if (!DL_IsNpcLifecycleSubject(oNPC))
    {
        return "";
    }

    sPendingSlotId = GetLocalString(oNPC, DL_L_PENDING_SLOT_ID);
    if (sPendingSlotId != "")
    {
        return sPendingSlotId;
    }

    sFunctionSlotId = DL_GetFunctionSlotId(oNPC);
    if (sFunctionSlotId != "")
    {
        return sFunctionSlotId;
    }

    sBootstrapSlotId = DL_GetSlotAssignedBootstrapSlotForNpc(oNPC);
    oBootstrapNpc = DL_GetSlotAssignedBootstrapNpcForSlot(sBootstrapSlotId);
    if (sBootstrapSlotId != "" && oBootstrapNpc == oNPC)
    {
        DL_LogNpc(oNPC, DL_DEBUG_VERBOSE, "pending bootstrap slot fallback from per-slot mapping: " + sBootstrapSlotId);
        return sBootstrapSlotId;
    }

    return "";
}

int DL_TryBootstrapNpcProfile(object oNPC)
{
    string sFunctionSlotId;

    if (!DL_IsNpcLifecycleSubject(oNPC))
    {
        return FALSE;
    }
    if (DL_IsDailyLifeNpc(oNPC))
    {
        return TRUE;
    }

    sFunctionSlotId = DL_GetPendingBootstrapSlotId(oNPC);
    if (sFunctionSlotId == "")
    {
        return FALSE;
    }

    if (DL_GetFunctionSlotId(oNPC) == "")
    {
        SetLocalString(oNPC, DL_L_FUNCTION_SLOT_ID, sFunctionSlotId);
    }
    if (DL_HasStagedFunctionSlotProfile(sFunctionSlotId))
    {
        DL_ApplyAssignedSlotProfile(oNPC, sFunctionSlotId);
        DL_ClearFunctionSlotProfile(sFunctionSlotId);
    }

    if (DL_IsDailyLifeNpc(oNPC))
    {
        DL_ClearSlotAssignedBootstrapForNpcOrSlot(oNPC, sFunctionSlotId);
        DeleteLocalString(oNPC, DL_L_PENDING_SLOT_ID);
        return TRUE;
    }

    return FALSE;
}

int DL_CanEmitNpcHookEvent(object oNPC)
{
    if (!DL_IsNpcLifecycleSubject(oNPC))
    {
        return FALSE;
    }
    if (DL_IsDailyLifeNpc(oNPC))
    {
        return TRUE;
    }
    return DL_GetPendingBootstrapSlotId(oNPC) != "";
}

void DL_SignalNpcUserDefined(object oNPC, int nEvent)
{
    if (!GetIsObjectValid(oNPC))
    {
        return;
    }
    SignalEvent(oNPC, EventUserDefined(nEvent));
}

int DL_RequestNpcHookResync(object oNPC, int nReason, int bForceNow)
{
    object oArea;

    if (!DL_IsNpcLifecycleSubject(oNPC))
    {
        return FALSE;
    }
    if (!DL_TryBootstrapNpcProfile(oNPC))
    {
        return FALSE;
    }

    oArea = GetArea(oNPC);
    if (bForceNow && GetIsObjectValid(oArea) && DL_ShouldRunDailyLife(oArea))
    {
        DL_RunForcedResync(oNPC, oArea, nReason);
        return TRUE;
    }

    DL_RequestResync(oNPC, nReason);
    return TRUE;
}

int DL_RequestNpcWorkerHookResync(object oNPC, int bForceNow)
{
    return DL_RequestNpcHookResync(oNPC, DL_RESYNC_WORKER, bForceNow);
}

int DL_IsNpcProducerEvent(int nEvent)
{
    return nEvent == DL_UD_PERCEPTION
        || nEvent == DL_UD_PHYSICAL_ATTACKED
        || nEvent == DL_UD_DISTURBED
        || nEvent == DL_UD_DAMAGED
        || nEvent == DL_UD_SPELL_CAST_AT;
}

int DL_IsPlayablePerceptionSource(object oSeen)
{
    return GetIsObjectValid(oSeen) && GetIsPC(oSeen) && !GetIsDM(oSeen);
}

int DL_ShouldEmitHookEventWithCooldown(object oNPC, string sKey, int nCooldownSec)
{
    if (!DL_CanEmitNpcHookEvent(oNPC))
    {
        return FALSE;
    }
    if (!DL_HasHookCooldownElapsed(oNPC, sKey, nCooldownSec))
    {
        return FALSE;
    }

    DL_MarkHookCooldown(oNPC, sKey);
    return TRUE;
}

void DL_OnNpcSpawnHook(object oNPC)
{
    if (!DL_RequestNpcWorkerHookResync(oNPC, FALSE))
    {
        DL_LogNpc(oNPC, DL_DEBUG_VERBOSE, "npc spawn hook ignored: bootstrap not ready");
        return;
    }

    DL_LogNpc(oNPC, DL_DEBUG_VERBOSE, "npc spawn hook -> worker resync requested");
}

void DL_OnNpcDeathHook(object oNPC)
{
    string sFunctionSlotId;

    if (!GetIsObjectValid(oNPC))
    {
        return;
    }

    sFunctionSlotId = DL_GetFunctionSlotId(oNPC);
    if (sFunctionSlotId != "")
    {
        DL_RecordBaseLostEvent(oNPC, sFunctionSlotId, DL_DIR_ABSENT);
        DL_ClearBaseLostEventForNpcOrSlot(oNPC, sFunctionSlotId);
        DL_RequestFunctionSlotReview(sFunctionSlotId, DL_RESYNC_BASE_LOST);
    }

    DeleteLocalString(oNPC, DL_L_PENDING_SLOT_ID);
    DeleteLocalInt(oNPC, DL_L_RESYNC_PENDING);
    DeleteLocalInt(oNPC, DL_L_RESYNC_REASON);
    DeleteLocalInt(oNPC, DL_L_ACTIVITY_KIND);
    DeleteLocalInt(oNPC, DL_L_DIALOGUE_MODE);
    DeleteLocalInt(oNPC, DL_L_SERVICE_MODE);
    DeleteLocalInt(oNPC, DL_L_ANCHOR_GROUP);
    // Keep cooldown cleanup suffix in sync with DL_L_UD_COOLDOWN_INIT_SUFFIX.
    DeleteLocalInt(oNPC, DL_L_UD_LAST_PERCEPTION_TICK);
    DeleteLocalInt(oNPC, DL_L_UD_LAST_PERCEPTION_TICK + DL_L_UD_COOLDOWN_INIT_SUFFIX);
    DeleteLocalInt(oNPC, DL_L_UD_LAST_ATTACK_TICK);
    DeleteLocalInt(oNPC, DL_L_UD_LAST_ATTACK_TICK + DL_L_UD_COOLDOWN_INIT_SUFFIX);
    DeleteLocalInt(oNPC, DL_L_UD_LAST_DISTURBED_TICK);
    DeleteLocalInt(oNPC, DL_L_UD_LAST_DISTURBED_TICK + DL_L_UD_COOLDOWN_INIT_SUFFIX);
    DeleteLocalInt(oNPC, DL_L_UD_LAST_DAMAGED_TICK);
    DeleteLocalInt(oNPC, DL_L_UD_LAST_DAMAGED_TICK + DL_L_UD_COOLDOWN_INIT_SUFFIX);
    DeleteLocalInt(oNPC, DL_L_UD_LAST_SPELL_TICK);
    DeleteLocalInt(oNPC, DL_L_UD_LAST_SPELL_TICK + DL_L_UD_COOLDOWN_INIT_SUFFIX);

    DL_LogNpc(oNPC, DL_DEBUG_BASIC, "npc death hook -> runtime cleanup complete");
}

void DL_OnNpcUserDefinedHook(object oNPC, int nEvent)
{
    if (!DL_IsNpcLifecycleSubject(oNPC) && nEvent != DL_UD_CLEANUP)
    {
        return;
    }

    if (nEvent == DL_UD_BOOTSTRAP)
    {
        DL_OnNpcSpawnHook(oNPC);
        return;
    }

    if (nEvent == DL_UD_CLEANUP)
    {
        DL_OnNpcDeathHook(oNPC);
        return;
    }

    if (nEvent == DL_UD_RESYNC || nEvent == DL_UD_FORCE_RESYNC)
    {
        DL_RequestNpcWorkerHookResync(oNPC, nEvent == DL_UD_FORCE_RESYNC);
        return;
    }

    if (DL_IsNpcProducerEvent(nEvent))
    {
        DL_RequestNpcWorkerHookResync(oNPC, FALSE);
        return;
    }
}

int DL_ShouldEmitPerceptionEvent(object oNPC, object oSeen)
{
    if (!DL_IsPlayablePerceptionSource(oSeen))
    {
        return FALSE;
    }
    return DL_ShouldEmitHookEventWithCooldown(oNPC, DL_L_UD_LAST_PERCEPTION_TICK, DL_UD_PERCEPTION_COOLDOWN_SEC);
}

int DL_ShouldEmitAttackEvent(object oNPC)
{
    return DL_ShouldEmitHookEventWithCooldown(oNPC, DL_L_UD_LAST_ATTACK_TICK, DL_UD_ATTACK_COOLDOWN_SEC);
}

int DL_ShouldEmitDisturbedEvent(object oNPC)
{
    return DL_ShouldEmitHookEventWithCooldown(oNPC, DL_L_UD_LAST_DISTURBED_TICK, DL_UD_DISTURBED_COOLDOWN_SEC);
}

int DL_ShouldEmitDamagedEvent(object oNPC)
{
    return DL_ShouldEmitHookEventWithCooldown(oNPC, DL_L_UD_LAST_DAMAGED_TICK, DL_UD_DAMAGED_COOLDOWN_SEC);
}

int DL_ShouldEmitSpellEvent(object oNPC)
{
    return DL_ShouldEmitHookEventWithCooldown(oNPC, DL_L_UD_LAST_SPELL_TICK, DL_UD_SPELL_COOLDOWN_SEC);
}

#endif
