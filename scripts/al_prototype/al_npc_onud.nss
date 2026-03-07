// NPC OnUserDefined: attach to NPC OnUserDefined in the toolset.

#include "al_npc_acts_inc"
#include "al_npc_pair_inc"

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


int AL_IsWarmArea(object oNpc)
{
    object oArea = GetArea(oNpc);
    return GetIsObjectValid(oArea) && GetLocalInt(oArea, "al_player_count") > 0;
}

void AL_RecordEventNoise(object oNpc, int nEvent)
{
    object oArea = GetArea(oNpc);
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    int nTotal = GetLocalInt(oArea, "al_event_noise_total") + 1;
    SetLocalInt(oArea, "al_event_noise_total", nTotal);

    if (nEvent == AL_EVT_ROUTE_REPEAT)
    {
        int nRepeat = GetLocalInt(oArea, "al_event_noise_route_repeat") + 1;
        SetLocalInt(oArea, "al_event_noise_route_repeat", nRepeat);
    }
}

int AL_IsRepeatRequeueCoolingDownInWarm(object oNpc)
{
    if (!AL_IsWarmArea(oNpc))
    {
        return FALSE;
    }

    int nNextStored = GetLocalInt(oNpc, "al_repeat_next");
    if (nNextStored == 0)
    {
        return FALSE;
    }

    int nNow = AL_GetAmbientLifeDaySeconds();
    int nNext = nNextStored - 1;
    int nDelta = (nNext - nNow + 86400) % 86400;
    return nDelta > 0 && nDelta < 43200;
}

void AL_MarkRepeatRequeueScheduled(object oNpc, int nDelaySeconds)
{
    int nNow = AL_GetAmbientLifeDaySeconds();
    int nNext = (nNow + nDelaySeconds) % 86400;
    SetLocalInt(oNpc, "al_repeat_next", nNext + 1);
}

int AL_IsRepeatAnimCoolingDown(object oNpc)
{
    int nNextStored = GetLocalInt(oNpc, "al_anim_next");
    if (nNextStored == 0)
    {
        return FALSE;
    }

    int nNext = nNextStored - 1;
    int nNow = AL_GetAmbientLifeDaySeconds();
    int nDelta = (nNext - nNow + 86400) % 86400;
    return nDelta > 0 && nDelta < 43200;
}

void AL_MarkAnimationApplied(object oNpc, int nIntervalSeconds)
{
    int nNow = AL_GetAmbientLifeDaySeconds();
    int nNext = (nNow + nIntervalSeconds) % 86400;
    SetLocalInt(oNpc, "al_anim_next", nNext + 1);
}


void AL_LogPairFallbackOnResync(object oNpc, int nEvent, int nActivity)
{
    if (nEvent != AL_EVT_RESYNC)
    {
        return;
    }

    object oArea = GetArea(oNpc);
    if (!GetIsObjectValid(oArea) || GetLocalInt(oArea, "al_debug") != 1)
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
        AL_SendDebugMessageToAreaPCs(oArea,
            "AL: resync fallback to ACT_ONE for " + GetName(oNpc)
            + " (invalid training/bar pair after wake)."
        );
    }
}

void main()
{
    object oNpc = OBJECT_SELF;
    int nEvent = GetUserDefinedEventNumber();
    int nSlot = AL_ResolveSlot(oNpc, nEvent);

    if (nSlot < 0 || nSlot > AL_SLOT_MAX)
    {
        return;
    }

    AL_RecordEventNoise(oNpc, nEvent);

    if (nEvent == AL_EVT_ROUTE_REPEAT)
    {
        int nRouteActive = GetLocalInt(oNpc, "r_active");
        if (nRouteActive == FALSE || AL_GetRouteCount(oNpc, nSlot) <= 0)
        {
            return;
        }

        if (GetLocalInt(oNpc, "al_last_slot") != nSlot)
        {
            return;
        }
    }
    else if (nEvent != AL_EVT_RESYNC && GetLocalInt(oNpc, "al_last_slot") == nSlot)
    {
        return;
    }

    if (nEvent == AL_EVT_RESYNC)
    {
        // Wake/resync contract: pair subsystem must be validated before
        // evaluating route/activity requirements for this slot.
        AL_InitTrainingPartner(oNpc);
        AL_InitBarPair(oNpc);
        SetLocalInt(oNpc, "al_last_slot", -1);
    }

    if (nEvent != AL_EVT_ROUTE_REPEAT)
    {
        AL_SyncRouteForSlot(oNpc, nSlot);
    }

    SetLocalInt(oNpc, "al_last_slot", nSlot);
    int nActivity = AL_GetWaypointActivityForSlot(oNpc, nSlot);
    int bUsesRoute = AL_ActivityUsesRoute(nSlot);
    int bRequiresRouteTag = AL_GetActivityWaypointTag(nActivity) != "";
    int bHasRequiredRoute = AL_ActivityHasRequiredRoute(oNpc, nSlot, nActivity);
    int bCanUseRoute = bUsesRoute && bHasRequiredRoute;
    AL_LogPairFallbackOnResync(oNpc, nEvent, nActivity);
    if (nActivity == AL_ACT_NPC_HIDDEN)
    {
        AL_StopSleepAtBed(oNpc);
        AL_ClearActiveRoute(oNpc, /*bClearActions=*/ TRUE);
        return;
    }
    if (nEvent == AL_EVT_ROUTE_REPEAT && !bCanUseRoute)
    {
        AL_StopSleepAtBed(oNpc);
        AL_ClearActiveRoute(oNpc, /*bClearActions=*/ TRUE);
        return;
    }

    int bSleepActivity = AL_ShouldLoopCustomAnimation(nActivity);
    if (!bSleepActivity)
    {
        AL_StopSleepAtBed(oNpc);
    }

    if (!bCanUseRoute)
    {
        AL_ClearActiveRoute(oNpc, /*bClearActions=*/ TRUE);
    }

    int bSkipMoveRepeat = FALSE;
    if (bCanUseRoute && nEvent == AL_EVT_ROUTE_REPEAT && AL_GetRouteCount(oNpc, nSlot) == 1)
    {
        bSkipMoveRepeat = TRUE;
    }

    int bRepeatRequeueWarmCooldown = FALSE;
    if (bSkipMoveRepeat)
    {
        bRepeatRequeueWarmCooldown = AL_IsRepeatRequeueCoolingDownInWarm(oNpc);
    }

    if (bCanUseRoute && !bSleepActivity)
    {
        if (bSkipMoveRepeat)
        {
            if (!bRepeatRequeueWarmCooldown)
            {
                int nRepeatDelaySeconds = 5 + Random(8);
                float fRepeatDelay = IntToFloat(nRepeatDelaySeconds);

                AssignCommand(oNpc, ActionWait(fRepeatDelay));
                AssignCommand(oNpc, ActionDoCommand(SignalEvent(oNpc, EventUserDefined(AL_EVT_ROUTE_REPEAT))));

                int nWarmDelay = nRepeatDelaySeconds;
                if (nWarmDelay < AL_EVT_ROUTE_REPEAT_WARM_MIN_GAP_SECONDS)
                {
                    nWarmDelay = AL_EVT_ROUTE_REPEAT_WARM_MIN_GAP_SECONDS;
                }

                AL_MarkRepeatRequeueScheduled(oNpc, nWarmDelay);
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
        AL_ClearActiveRoute(oNpc, /*bClearActions=*/ TRUE);
    }

    int bAllowAnimation = TRUE;
    if (nEvent == AL_EVT_ROUTE_REPEAT)
    {
        if (AL_IsRepeatAnimCoolingDown(oNpc))
        {
            bAllowAnimation = FALSE;
        }
    }

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
