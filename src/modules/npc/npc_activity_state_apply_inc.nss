// Route state application helpers.

string NpcBhvrActivityResolveAction(object oNpc, string sSlot, string sRouteId, int nWpIndex, int nWpCount)
{
    string sEmote;

    if (!GetIsObjectValid(oNpc))
    {
        return "idle";
    }

    if (sRouteId == NPC_BHVR_ACTIVITY_ROUTE_CRITICAL_SAFE || sSlot == NPC_BHVR_ACTIVITY_SLOT_CRITICAL)
    {
        return "guard_hold";
    }

    if (sRouteId == NPC_BHVR_ACTIVITY_ROUTE_PRIORITY || sSlot == NPC_BHVR_ACTIVITY_SLOT_PRIORITY)
    {
        if (nWpCount > 0)
        {
            if ((nWpIndex % 2) == 0)
            {
                return "patrol_move";
            }

            return "patrol_scan";
        }

        return "patrol_ready";
    }

    sEmote = NpcBhvrActivityResolveSlotEmote(oNpc, sSlot);
    if (sEmote != "")
    {
        return "ambient_" + sEmote;
    }

    return "ambient_idle";
}

void NpcBhvrActivityAdapterStampTransition(object oNpc, string sState)
{
    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_STATE, sState);
    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_LAST, sState);
    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_LAST_TS, GetTimeHour() * 3600 + GetTimeMinute() * 60 + GetTimeSecond());
}

void NpcBhvrActivityApplyRouteState(object oNpc, string sRouteId, string sBaseState, int nCooldown)
{
    int nWpCount;
    int bLoop;
    int nWpIndex;
    int nPauseTicks;
    int nActivityId;
    string sRouteTag;
    string sState;
    string sSlot;
    string sEmote;
    string sAction;
    string sCustomAnims;
    string sNumericAnims;
    string sWaypointRequirement;
    int nNow;

    nWpCount = NpcBhvrActivityResolveRouteCount(oNpc, sRouteId);
    bLoop = NpcBhvrActivityResolveRouteLoop(oNpc, sRouteId);
    nWpIndex = NpcBhvrActivityNormalizeWaypointIndex(GetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_INDEX), nWpCount, bLoop);
    nPauseTicks = NpcBhvrActivityResolveRoutePauseTicks(oNpc, sRouteId);
    nActivityId = NpcBhvrActivityResolveRoutePointActivity(oNpc, sRouteId, nWpIndex);
    sRouteTag = NpcBhvrActivityResolveRouteTag(oNpc, sRouteId);
    sState = NpcBhvrActivityComposeWaypointState(sBaseState, sRouteTag, nWpIndex, nWpCount);
    sSlot = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT);
    sEmote = NpcBhvrActivityResolveSlotEmote(oNpc, sSlot);
    sAction = NpcBhvrActivityResolveAction(oNpc, sSlot, sRouteId, nWpIndex, nWpCount);
    sCustomAnims = NpcBhvrActivityGetCustomAnims(nActivityId);
    sNumericAnims = NpcBhvrActivityGetNumericAnims(nActivityId);
    sWaypointRequirement = NpcBhvrActivityGetWaypointTagRequirement(nActivityId);
    nNow = NpcBhvrPendingNow();

    NpcBhvrActivityAdapterStampTransition(oNpc, sState);
    NpcBhvrActivitySetCooldownTicks(oNpc, nCooldown + nPauseTicks, nNow);
    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_COUNT, nWpCount);
    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_LOOP, bLoop);
    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_INDEX, NpcBhvrActivityNormalizeWaypointIndex(nWpIndex + 1, nWpCount, bLoop));
    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_TAG, sRouteTag);
    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT_EMOTE, sEmote);
    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ACTION, sAction);
    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_ID, nActivityId);
    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_CUSTOM_ANIMS, sCustomAnims);
    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_NUMERIC_ANIMS, sNumericAnims);
    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_WAYPOINT_TAG, sWaypointRequirement);
    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_REQUIRES_TRAINING_PARTNER, NpcBhvrActivityRequiresTrainingPartner(nActivityId));
    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_REQUIRES_BAR_PAIR, NpcBhvrActivityRequiresBarPair(nActivityId));
}
