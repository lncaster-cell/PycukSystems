// NPC OnUserDefined: attach to NPC OnUserDefined in the toolset.

#include "al_npc_activity_apply_inc"
#include "al_npc_sleep_inc"
#include "al_npc_pair_revalidate_inc"
#include "al_npc_pair_inc"
#include "al_area_mode_contract_inc"

void AL_ResetRouteIndex(object oNpc)
{
    SetLocalInt(oNpc, "r_idx", 0);
}

int AL_ActivityUsesRoute(int nSlot)
{
    return AL_GetRouteCount(OBJECT_SELF, nSlot) > 0;
}

int AL_GetRepeatAnimIntervalSeconds()
{
    return 15 + Random(16);
}

int AL_ResolveSlot(object oNpc, int nEvent)
{
    if (nEvent == AL_EVT_RESYNC)
    {
        object oArea = GetArea(oNpc);
        if (GetIsObjectValid(oArea))
        {
            return GetLocalInt(oArea, "al_slot");
        }

        return -1;
    }

    if (nEvent >= AL_EVT_SLOT_BASE && nEvent <= AL_EVT_SLOT_5)
    {
        return nEvent - AL_EVT_SLOT_BASE;
    }

    if (nEvent == AL_EVT_ROUTE_REPEAT)
    {
        return GetLocalInt(oNpc, "r_slot");
    }

    return -1;
}

void AL_SyncRouteForSlot(object oNpc, int nSlot)
{
    string sDesiredTag = AL_GetDesiredRouteTag(oNpc, nSlot);
    string sCurrentTag = AL_GetRouteTag(oNpc, nSlot);

    if (sDesiredTag == "")
    {
        AL_ClearRoute(oNpc, nSlot);
    }
    else
    {
        if (sCurrentTag != "" && sCurrentTag != sDesiredTag)
        {
            AL_ClearRoute(oNpc, nSlot);
        }

        AL_CacheRouteFromTag(oNpc, nSlot, sDesiredTag);
    }

    AL_ResetRouteIndex(oNpc);
}


int AL_GetRepeatRequeueMinGapSeconds(object oNpc)
{
    object oArea = GetArea(oNpc);
    if (!GetIsObjectValid(oArea))
    {
        return 0;
    }

    if (AL_IsAreaModeWarm(oArea))
    {
        return AL_ROUTE_REPEAT_MIN_GAP_SECONDS_WARM;
    }

    if (AL_IsAreaModeHot(oArea))
    {
        return AL_ROUTE_REPEAT_MIN_GAP_SECONDS_HOT;
    }

    return 0;
}

int AL_IsDaySecondsCooldownActive(object oObj, string sKey)
{
    int nNextStored = GetLocalInt(oObj, sKey);
    if (nNextStored == 0)
    {
        return FALSE;
    }

    int nNow = AL_GetAmbientLifeDaySeconds();
    int nNext = nNextStored - 1;
    int nDelta = (nNext - nNow + 86400) % 86400;
    return nDelta > 0 && nDelta < 43200;
}

void AL_MarkDaySecondsCooldown(object oObj, string sKey, int nDelaySeconds)
{
    int nNow = AL_GetAmbientLifeDaySeconds();
    int nNext = (nNow + nDelaySeconds) % 86400;
    SetLocalInt(oObj, sKey, nNext + 1);
}

void AL_ResetRepeatRequeueCooldown(object oNpc)
{
    DeleteLocalInt(oNpc, "al_repeat_next");
}

int AL_IsRepeatRequeueCoolingDownByMode(object oNpc)
{
    int nMinGap = AL_GetRepeatRequeueMinGapSeconds(oNpc);
    if (nMinGap <= 0)
    {
        return FALSE;
    }

    return AL_IsDaySecondsCooldownActive(oNpc, "al_repeat_next");
}

void AL_MarkRepeatRequeueScheduled(object oNpc, int nDelaySeconds)
{
    AL_MarkDaySecondsCooldown(oNpc, "al_repeat_next", nDelaySeconds);
}

int AL_IsRepeatAnimCoolingDown(object oNpc)
{
    return AL_IsDaySecondsCooldownActive(oNpc, "al_anim_next");
}

void AL_MarkAnimationApplied(object oNpc, int nIntervalSeconds)
{
    AL_MarkDaySecondsCooldown(oNpc, "al_anim_next", nIntervalSeconds);
}

void AL_ClearRouteAndRepeatState(object oNpc, int bStopSleep)
{
    if (bStopSleep)
    {
        AL_StopSleepAtBed(oNpc);
    }

    AL_ResetRepeatRequeueCooldown(oNpc);
    AL_ClearActiveRoute(oNpc, /*bClearActions=*/ TRUE);
}

void AL_QueueRepeatRequeue(object oNpc, object oArea)
{
    AL_DebugLogL2(oArea, oNpc, "AL: repeat requeue in warm area.");
    int nQueuedDelaySeconds = 5 + Random(8);

    int nModeMinGap = AL_GetRepeatRequeueMinGapSeconds(oNpc);
    if (nModeMinGap > nQueuedDelaySeconds)
    {
        nQueuedDelaySeconds = nModeMinGap;
    }

    float fRepeatDelay = IntToFloat(nQueuedDelaySeconds);

    AssignCommand(oNpc, ActionWait(fRepeatDelay));
    AssignCommand(oNpc, ActionDoCommand(SignalEvent(oNpc, EventUserDefined(AL_EVT_ROUTE_REPEAT))));

    // Keep queued ActionWait delay and stored cooldown strictly identical.
    AL_MarkRepeatRequeueScheduled(oNpc, nQueuedDelaySeconds);
}

int AL_ShouldIgnoreRepeatEvent(object oNpc, object oArea, int nSlot)
{
    if (GetLocalInt(oNpc, "r_active") == FALSE || AL_GetRouteCount(oNpc, nSlot) <= 0)
    {
        AL_DebugLogL2(oArea, oNpc, "AL: repeat ignored (inactive route). slot=" + IntToString(nSlot) + ".");
        return TRUE;
    }

    if (GetLocalInt(oNpc, "al_last_slot") != nSlot)
    {
        AL_DebugLogL2(oArea, oNpc, "AL: repeat ignored (stale slot). slot=" + IntToString(nSlot) + ".");
        return TRUE;
    }

    return FALSE;
}

int AL_ShouldStopAfterGuardCleanup(object oNpc, int nEvent, int bCanUseRoute, int nActivity)
{
    if (nActivity == AL_ACT_NPC_HIDDEN)
    {
        AL_ClearRouteAndRepeatState(oNpc, TRUE);
        return TRUE;
    }

    if (nEvent == AL_EVT_ROUTE_REPEAT && !bCanUseRoute)
    {
        AL_ClearRouteAndRepeatState(oNpc, TRUE);
        return TRUE;
    }

    return FALSE;
}


void AL_LogPairFallbackOnResync(object oNpc, int nEvent, int nActivity)
{
    if (nEvent != AL_EVT_RESYNC)
    {
        return;
    }

    object oArea = GetArea(oNpc);
    if (!GetIsObjectValid(oArea) || !AL_IsDebugLevelEnabled(oArea, OBJECT_INVALID, AL_DEBUG_LEVEL_L1))
    {
        return;
    }

    int bNeedsTrainingPartner = AL_ActivityRequiresTrainingPartner(nActivity);
    int bNeedsBarPair = AL_ActivityRequiresBarPair(nActivity);
    if (!bNeedsTrainingPartner && !bNeedsBarPair)
    {
        return;
    }

    object oTrainingPartner = GetLocalObject(oNpc, "al_training_partner");
    object oBarPair = GetLocalObject(oNpc, "al_bar_pair");
    int bTrainingPartnerValid = GetIsObjectValid(oTrainingPartner)
        && GetArea(oTrainingPartner) == oArea;
    int bBarPairValid = GetIsObjectValid(oBarPair)
        && GetArea(oBarPair) == oArea;

    if ((bNeedsTrainingPartner && !bTrainingPartnerValid)
        || (bNeedsBarPair && !bBarPairValid))
    {
        AL_DebugLogL1(oArea, oNpc,
            "AL: resync fallback to ACT_ONE for " + GetName(oNpc)
            + " (invalid training/bar pair after wake)."
        );
    }
}

void main()
{
    object oNpc = OBJECT_SELF;
    int nEvent = GetUserDefinedEventNumber();
    object oArea = GetArea(oNpc);
    if (!GetIsObjectValid(oArea) || AL_IsAreaModeOff(oArea) || AL_IsAreaModeCold(oArea))
    {
        return;
    }

    int nSlot = AL_ResolveSlot(oNpc, nEvent);

    if (nSlot < 0 || nSlot > AL_SLOT_MAX)
    {
        return;
    }

    if (nEvent == AL_EVT_ROUTE_REPEAT)
    {
        if (AL_ShouldIgnoreRepeatEvent(oNpc, oArea, nSlot))
        {
            return;
        }
    }
    else if (nEvent != AL_EVT_RESYNC && GetLocalInt(oNpc, "al_last_slot") == nSlot)
    {
        return;
    }

    if (nEvent != AL_EVT_ROUTE_REPEAT)
    {
        AL_ResetRepeatRequeueCooldown(oNpc);
    }

    if (nEvent == AL_EVT_RESYNC)
    {
        AL_DebugLogL1(oArea, oNpc, "AL: RESYNC started for " + GetName(oNpc) + ".");
        // Wake/resync contract: pair subsystem must be validated before
        // evaluating route/activity requirements for this slot.
        AL_InitTrainingPartner(oNpc);
        AL_InitBarPair(oNpc);
        SetLocalInt(oNpc, "al_last_slot", -1);
    }

    AL_RevalidateAreaPairLinksForWake(oNpc);

    if (nEvent != AL_EVT_ROUTE_REPEAT)
    {
        AL_SyncRouteForSlot(oNpc, nSlot);
    }

    SetLocalInt(oNpc, "al_last_slot", nSlot);
    int nActivity = AL_GetWaypointActivityForSlot(oNpc, nSlot);
    int bUsesRoute = AL_ActivityUsesRoute(nSlot);
    int bHasRequiredRoute = AL_ActivityHasRequiredRoute(oNpc, nSlot, nActivity);
    int bCanUseRoute = bUsesRoute && bHasRequiredRoute;
    AL_LogPairFallbackOnResync(oNpc, nEvent, nActivity);
    if (AL_ShouldStopAfterGuardCleanup(oNpc, nEvent, bCanUseRoute, nActivity))
    {
        return;
    }

    int bSleepActivity = AL_ShouldLoopCustomAnimation(nActivity);
    if (!bSleepActivity)
    {
        AL_StopSleepAtBed(oNpc);
    }

    if (!bCanUseRoute)
    {
        AL_ClearRouteAndRepeatState(oNpc, FALSE);
    }

    int bSkipMoveRepeat = bCanUseRoute
        && nEvent == AL_EVT_ROUTE_REPEAT
        && AL_GetRouteCount(oNpc, nSlot) == 1;

    int bRepeatRequeueWarmCooldown = FALSE;
    if (bSkipMoveRepeat)
    {
        bRepeatRequeueWarmCooldown = AL_IsRepeatRequeueCoolingDownByMode(oNpc);
    }

    if (bCanUseRoute && !bSleepActivity)
    {
        if (bSkipMoveRepeat)
        {
            if (!bRepeatRequeueWarmCooldown)
            {
                AL_QueueRepeatRequeue(oNpc, oArea);
            }
            else
            {
                AL_DebugLogL2(oArea, oNpc, "AL: repeat requeue suppressed by cooldown.");
            }
        }
        else
        {
            AL_QueueRoute(oNpc, nSlot, nEvent != AL_EVT_ROUTE_REPEAT);
        }
    }
    else if (bSleepActivity)
    {
        // Sleep does not need movement repeat loops: keep NPC docked and avoid
        // extra AL_EVT_ROUTE_REPEAT scheduling/load while sleeping.
        AL_ClearRouteAndRepeatState(oNpc, FALSE);
    }

    int bAllowAnimation = nEvent != AL_EVT_ROUTE_REPEAT || !AL_IsRepeatAnimCoolingDown(oNpc);

    int bShouldPlay = bAllowAnimation && (bSleepActivity || !(bCanUseRoute && nEvent != AL_EVT_ROUTE_REPEAT));

    if (bShouldPlay)
    {
        int nIntervalSeconds = AL_GetRepeatAnimIntervalSeconds();
        if (bSleepActivity)
        {
            object oSleepWp = AL_FindSleepWaypointForSlot(oNpc, nSlot);
            // Source of truth for sleep animation fallback:
            // AL_StartSleepAtBed only docks + starts sleep when bed config is valid.
            // If docking fails, we run a single fallback via AL_ApplyActivityForSlot here.
            if (!AL_StartSleepAtBed(oNpc, oSleepWp))
            {
                AL_ApplyActivityForSlot(oNpc, nSlot);
            }
        }
        else
        {
            AL_ApplyActivityForSlot(oNpc, nSlot);
        }
        AL_MarkAnimationApplied(oNpc, nIntervalSeconds);
    }
}
