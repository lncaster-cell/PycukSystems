// Route state application helpers.

string NpcBhvrActivityResolveSlotEmote(object oNpc, string sSlot);
string NpcBhvrActivityResolveMode(object oNpc);
int NpcBhvrActivityResolveRouteCount(object oNpc, string sRouteId);
int NpcBhvrActivityResolveRouteLoop(object oNpc, string sRouteId);
int NpcBhvrActivityNormalizeWaypointIndex(int nIndex, int nCount, int bLoop);
int NpcBhvrActivityResolveRoutePauseTicks(object oNpc, string sRouteId);
int NpcBhvrActivityResolveRoutePointActivity(object oNpc, string sRouteId, int nWpIndex);
string NpcBhvrActivityResolveRouteTag(object oNpc, string sRouteId);
string NpcBhvrActivityComposeWaypointState(string sBaseState, string sRouteTag, int nWpIndex, int nWpCount);
string NpcBhvrActivityGetCustomAnims(int nActivityId);
string NpcBhvrActivityGetNumericAnims(int nActivityId);
string NpcBhvrActivityGetWaypointTagRequirement(int nActivityId);
int NpcBhvrPendingNow();
int NpcBhvrActivityRequiresTrainingPartner(int nActivityId);
int NpcBhvrActivityRequiresBarPair(int nActivityId);
void NpcBhvrActivitySetCooldownTicks(object oNpc, int nTicks, int nNow);

string NpcBhvrActivityResolveAction(object oNpc, string sMode, string sSlot, int nWpIndex, int nWpCount)
{
    string sEmote;

    if (!GetIsObjectValid(oNpc))
    {
        return "idle";
    }

    if (sMode == NPC_BHVR_ACTIVITY_MODE_ALERT)
    {
        return "guard_hold";
    }

    if (sSlot == NPC_BHVR_ACTIVITY_SLOT_MORNING)
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

void NpcBhvrActivitySetTransitionState(object oNpc, string sState)
{
    string sCurrentState;

    sCurrentState = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_STATE);
    if (sCurrentState == sState)
    {
        return;
    }

    // Canonical split: activity_state is current state, activity_last stores
    // previous state observed before transition.
    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_LAST, sCurrentState);
    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_STATE, sState);
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
    string sMode;
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
    sMode = NpcBhvrActivityResolveMode(oNpc);
    sSlot = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT_EFFECTIVE);
    sEmote = NpcBhvrActivityResolveSlotEmote(oNpc, sSlot);
    sAction = NpcBhvrActivityResolveAction(oNpc, sMode, sSlot, nWpIndex, nWpCount);
    sCustomAnims = NpcBhvrActivityGetCustomAnims(nActivityId);
    sNumericAnims = NpcBhvrActivityGetNumericAnims(nActivityId);
    sWaypointRequirement = NpcBhvrActivityGetWaypointTagRequirement(nActivityId);
    nNow = NpcBhvrPendingNow();

    NpcBhvrActivitySetTransitionState(oNpc, sState);
    NpcBhvrActivitySetCooldownTicks(oNpc, nCooldown + nPauseTicks, nNow);
    NpcBhvrSetLocalIntIfChanged(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_COUNT, nWpCount);
    NpcBhvrSetLocalIntIfChanged(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_LOOP, bLoop);
    NpcBhvrSetLocalIntIfChanged(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_INDEX, NpcBhvrActivityNormalizeWaypointIndex(nWpIndex + 1, nWpCount, bLoop));
    NpcBhvrSetLocalStringIfChanged(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_TAG, sRouteTag);
    NpcBhvrSetLocalStringIfChanged(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT_EMOTE, sEmote);
    NpcBhvrSetLocalStringIfChanged(oNpc, NPC_BHVR_VAR_ACTIVITY_ACTION, sAction);
    NpcBhvrSetLocalIntIfChanged(oNpc, NPC_BHVR_VAR_ACTIVITY_ID, nActivityId);
    NpcBhvrSetLocalStringIfChanged(oNpc, NPC_BHVR_VAR_ACTIVITY_CUSTOM_ANIMS, sCustomAnims);
    NpcBhvrSetLocalStringIfChanged(oNpc, NPC_BHVR_VAR_ACTIVITY_NUMERIC_ANIMS, sNumericAnims);
    NpcBhvrSetLocalStringIfChanged(oNpc, NPC_BHVR_VAR_ACTIVITY_WAYPOINT_TAG, sWaypointRequirement);
    NpcBhvrSetLocalIntIfChanged(oNpc, NPC_BHVR_VAR_ACTIVITY_REQUIRES_TRAINING_PARTNER, NpcBhvrActivityRequiresTrainingPartner(nActivityId));
    NpcBhvrSetLocalIntIfChanged(oNpc, NPC_BHVR_VAR_ACTIVITY_REQUIRES_BAR_PAIR, NpcBhvrActivityRequiresBarPair(nActivityId));
}
