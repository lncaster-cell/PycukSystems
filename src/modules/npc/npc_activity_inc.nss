// NPC Bhvr activity include.
// Здесь размещается адаптированный контентный слой активностей (AL primitives -> npc namespace).

const string NPC_BHVR_VAR_ACTIVITY_SLOT = "npc_activity_slot";
const string NPC_BHVR_VAR_ACTIVITY_ROUTE = "npc_activity_route";
const string NPC_BHVR_VAR_ACTIVITY_STATE = "npc_activity_state";
const string NPC_BHVR_VAR_ACTIVITY_COOLDOWN = "npc_activity_cooldown";
const string NPC_BHVR_VAR_ACTIVITY_LAST = "npc_activity_last";
const string NPC_BHVR_VAR_ACTIVITY_LAST_TS = "npc_activity_last_ts";
const string NPC_BHVR_VAR_ACTIVITY_ROUTE_EFFECTIVE = "npc_activity_route_effective";
const string NPC_BHVR_VAR_ACTIVITY_SLOT_FALLBACK = "npc_activity_slot_fallback";

const string NPC_BHVR_VAR_ROUTE_PROFILE_SLOT_PREFIX = "npc_route_profile_slot_";
const string NPC_BHVR_VAR_ROUTE_PROFILE_DEFAULT = "npc_route_profile_default";
const string NPC_BHVR_VAR_ROUTE_CACHE_SLOT_PREFIX = "npc_route_cache_slot_";
const string NPC_BHVR_VAR_ROUTE_CACHE_DEFAULT = "npc_route_cache_default";

// Waypoint/ambient activity runtime locals.
const string NPC_BHVR_VAR_ACTIVITY_WP_INDEX = "npc_activity_wp_index";
const string NPC_BHVR_VAR_ACTIVITY_WP_COUNT = "npc_activity_wp_count";
const string NPC_BHVR_VAR_ACTIVITY_WP_LOOP = "npc_activity_wp_loop";
const string NPC_BHVR_VAR_ACTIVITY_ROUTE_TAG = "npc_activity_route_tag";
const string NPC_BHVR_VAR_ACTIVITY_SLOT_EMOTE = "npc_activity_slot_emote";

const string NPC_BHVR_VAR_ROUTE_COUNT_PREFIX = "npc_route_count_";
const string NPC_BHVR_VAR_ROUTE_LOOP_PREFIX = "npc_route_loop_";
const string NPC_BHVR_VAR_ROUTE_TAG_PREFIX = "npc_route_tag_";

// Waypoint/ambient activity runtime locals.
const string NPC_BHVR_VAR_ACTIVITY_WP_INDEX = "npc_activity_wp_index";
const string NPC_BHVR_VAR_ACTIVITY_WP_COUNT = "npc_activity_wp_count";
const string NPC_BHVR_VAR_ACTIVITY_WP_LOOP = "npc_activity_wp_loop";
const string NPC_BHVR_VAR_ACTIVITY_ROUTE_TAG = "npc_activity_route_tag";
const string NPC_BHVR_VAR_ACTIVITY_SLOT_EMOTE = "npc_activity_slot_emote";

const string NPC_BHVR_VAR_ROUTE_COUNT_PREFIX = "npc_route_count_";
const string NPC_BHVR_VAR_ROUTE_LOOP_PREFIX = "npc_route_loop_";
const string NPC_BHVR_VAR_ROUTE_TAG_PREFIX = "npc_route_tag_";

// Waypoint/ambient activity runtime locals.
const string NPC_BHVR_VAR_ACTIVITY_WP_INDEX = "npc_activity_wp_index";
const string NPC_BHVR_VAR_ACTIVITY_WP_COUNT = "npc_activity_wp_count";
const string NPC_BHVR_VAR_ACTIVITY_WP_LOOP = "npc_activity_wp_loop";
const string NPC_BHVR_VAR_ACTIVITY_ROUTE_TAG = "npc_activity_route_tag";
const string NPC_BHVR_VAR_ACTIVITY_SLOT_EMOTE = "npc_activity_slot_emote";

const string NPC_BHVR_VAR_ROUTE_COUNT_PREFIX = "npc_route_count_";
const string NPC_BHVR_VAR_ROUTE_LOOP_PREFIX = "npc_route_loop_";
const string NPC_BHVR_VAR_ROUTE_TAG_PREFIX = "npc_route_tag_";

// Waypoint/ambient activity runtime locals.
const string NPC_BHVR_VAR_ACTIVITY_WP_INDEX = "npc_activity_wp_index";
const string NPC_BHVR_VAR_ACTIVITY_WP_COUNT = "npc_activity_wp_count";
const string NPC_BHVR_VAR_ACTIVITY_WP_LOOP = "npc_activity_wp_loop";
const string NPC_BHVR_VAR_ACTIVITY_ROUTE_TAG = "npc_activity_route_tag";
const string NPC_BHVR_VAR_ACTIVITY_SLOT_EMOTE = "npc_activity_slot_emote";
const string NPC_BHVR_VAR_ACTIVITY_ACTION = "npc_activity_action";

const string NPC_BHVR_VAR_ROUTE_PAUSE_TICKS_PREFIX = "npc_route_pause_ticks_";

const string NPC_BHVR_VAR_ROUTE_COUNT_PREFIX = "npc_route_count_";
const string NPC_BHVR_VAR_ROUTE_LOOP_PREFIX = "npc_route_loop_";
const string NPC_BHVR_VAR_ROUTE_TAG_PREFIX = "npc_route_tag_";

const string NPC_BHVR_ACTIVITY_SLOT_DEFAULT = "default";
const string NPC_BHVR_ACTIVITY_SLOT_PRIORITY = "priority";
const string NPC_BHVR_ACTIVITY_SLOT_CRITICAL = "critical";

const string NPC_BHVR_ACTIVITY_ROUTE_DEFAULT = "default_route";
const string NPC_BHVR_ACTIVITY_ROUTE_PRIORITY = "priority_patrol";
const string NPC_BHVR_ACTIVITY_ROUTE_CRITICAL_SAFE = "critical_safe";

const int NPC_BHVR_ACTIVITY_HINT_IDLE = 1;
const int NPC_BHVR_ACTIVITY_HINT_PATROL = 2;
const int NPC_BHVR_ACTIVITY_HINT_CRITICAL_SAFE = 3;

const int NPC_BHVR_ACTIVITY_ROUTE_SOURCE_NPC_LOCAL = 1;
const int NPC_BHVR_ACTIVITY_ROUTE_SOURCE_AREA_LOCAL = 2;

string NpcBhvrActivityAreaRouteCacheSlotKey(string sSlot)
{
    return NPC_BHVR_VAR_ROUTE_CACHE_SLOT_PREFIX + sSlot;
}

void NpcBhvrActivityRouteCacheWarmup(object oArea)
{
    string sDefault;
    string sPriority;
    string sCritical;

    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    if (GetLocalInt(oArea, "routes_cached") == TRUE)
    {
        NpcBhvrMetricRouteCacheRecordHit(oArea);
        return;
    }

    NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_ROUTE_CACHE_WARMUP_TOTAL);
    NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_ROUTE_CACHE_RESCAN_TOTAL);
    NpcBhvrMetricRouteCacheRecordMiss(oArea);

    sDefault = NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(
        GetLocalString(oArea, NpcBhvrActivitySlotRouteProfileKey(NPC_BHVR_ACTIVITY_SLOT_DEFAULT)),
        oArea,
        NPC_BHVR_ACTIVITY_ROUTE_SOURCE_AREA_LOCAL
    );
    if (sDefault == "")
    {
        sDefault = NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(
            GetLocalString(oArea, NPC_BHVR_VAR_ROUTE_PROFILE_DEFAULT),
            oArea,
            NPC_BHVR_ACTIVITY_ROUTE_SOURCE_AREA_LOCAL
        );
    }
    if (sDefault == "")
    {
        sDefault = NPC_BHVR_ACTIVITY_ROUTE_DEFAULT;
    }

    sPriority = NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(
        GetLocalString(oArea, NpcBhvrActivitySlotRouteProfileKey(NPC_BHVR_ACTIVITY_SLOT_PRIORITY)),
        oArea,
        NPC_BHVR_ACTIVITY_ROUTE_SOURCE_AREA_LOCAL
    );
    if (sPriority == "")
    {
        sPriority = sDefault;
    }

    sCritical = NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(
        GetLocalString(oArea, NpcBhvrActivitySlotRouteProfileKey(NPC_BHVR_ACTIVITY_SLOT_CRITICAL)),
        oArea,
        NPC_BHVR_ACTIVITY_ROUTE_SOURCE_AREA_LOCAL
    );
    if (sCritical == "")
    {
        sCritical = sDefault;
    }

    SetLocalString(oArea, NPC_BHVR_VAR_ROUTE_CACHE_DEFAULT, sDefault);
    SetLocalString(oArea, NpcBhvrActivityAreaRouteCacheSlotKey(NPC_BHVR_ACTIVITY_SLOT_DEFAULT), sDefault);
    SetLocalString(oArea, NpcBhvrActivityAreaRouteCacheSlotKey(NPC_BHVR_ACTIVITY_SLOT_PRIORITY), sPriority);
    SetLocalString(oArea, NpcBhvrActivityAreaRouteCacheSlotKey(NPC_BHVR_ACTIVITY_SLOT_CRITICAL), sCritical);
    SetLocalInt(oArea, "routes_cached", TRUE);
    SetLocalInt(oArea, "routes_cache_version", GetLocalInt(oArea, "routes_cache_version") + 1);
}

void NpcBhvrActivityRouteCacheInvalidate(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    DeleteLocalString(oArea, NPC_BHVR_VAR_ROUTE_CACHE_DEFAULT);
    DeleteLocalString(oArea, NpcBhvrActivityAreaRouteCacheSlotKey(NPC_BHVR_ACTIVITY_SLOT_DEFAULT));
    DeleteLocalString(oArea, NpcBhvrActivityAreaRouteCacheSlotKey(NPC_BHVR_ACTIVITY_SLOT_PRIORITY));
    DeleteLocalString(oArea, NpcBhvrActivityAreaRouteCacheSlotKey(NPC_BHVR_ACTIVITY_SLOT_CRITICAL));
    SetLocalInt(oArea, "routes_cached", FALSE);
}

string NpcBhvrActivityRouteCacheResolveForSlot(object oArea, string sSlot)
{
    string sRoute;

    if (!GetIsObjectValid(oArea))
    {
        return "";
    }

    NpcBhvrActivityRouteCacheWarmup(oArea);

    sRoute = GetLocalString(oArea, NpcBhvrActivityAreaRouteCacheSlotKey(sSlot));
    if (sRoute == "")
    {
        sRoute = GetLocalString(oArea, NPC_BHVR_VAR_ROUTE_CACHE_DEFAULT);
    }

    if (sRoute == "")
    {
        sRoute = NPC_BHVR_ACTIVITY_ROUTE_DEFAULT;
    }

    return sRoute;
}

string NpcBhvrActivitySlotRouteProfileKey(string sSlot)
{
    return NPC_BHVR_VAR_ROUTE_PROFILE_SLOT_PREFIX + sSlot;
}

string NpcBhvrActivityRouteCountKey(string sRouteId)
{
    return NPC_BHVR_VAR_ROUTE_COUNT_PREFIX + sRouteId;
}

string NpcBhvrActivityRouteLoopKey(string sRouteId)
{
    return NPC_BHVR_VAR_ROUTE_LOOP_PREFIX + sRouteId;
}

string NpcBhvrActivityRouteTagKey(string sRouteId)
{
    return NPC_BHVR_VAR_ROUTE_TAG_PREFIX + sRouteId;
}

string NpcBhvrActivityRoutePauseTicksKey(string sRouteId)
{
    return NPC_BHVR_VAR_ROUTE_PAUSE_TICKS_PREFIX + sRouteId;
}

int NpcBhvrActivityIsSupportedRoute(string sRouteId)
{
    return sRouteId == NPC_BHVR_ACTIVITY_ROUTE_DEFAULT
        || sRouteId == NPC_BHVR_ACTIVITY_ROUTE_PRIORITY
        || sRouteId == NPC_BHVR_ACTIVITY_ROUTE_CRITICAL_SAFE;
}

string NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(string sRouteId, object oMetricScope, int nSource)
{
    if (sRouteId == "")
    {
        return "";
    }

    if (!NpcBhvrActivityIsSupportedRoute(sRouteId))
    {
        NpcBhvrMetricInc(oMetricScope, NPC_BHVR_METRIC_ACTIVITY_INVALID_ROUTE_TOTAL);
        if (nSource == NPC_BHVR_ACTIVITY_ROUTE_SOURCE_NPC_LOCAL)
        {
            NpcBhvrMetricInc(oMetricScope, NPC_BHVR_METRIC_ACTIVITY_INVALID_ROUTE_NPC_LOCAL_TOTAL);
        }
        else if (nSource == NPC_BHVR_ACTIVITY_ROUTE_SOURCE_AREA_LOCAL)
        {
            NpcBhvrMetricInc(oMetricScope, NPC_BHVR_METRIC_ACTIVITY_INVALID_ROUTE_AREA_LOCAL_TOTAL);
        }

        return "";
    }

    return NpcBhvrActivityAdapterNormalizeRoute(sRouteId);
}

string NpcBhvrActivityResolveRouteProfile(object oNpc, string sSlot)
{
    object oArea;
    string sRoute;

    if (!GetIsObjectValid(oNpc))
    {
        return NPC_BHVR_ACTIVITY_ROUTE_DEFAULT;
    }

    sRoute = NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(
        GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE),
        oNpc,
        NPC_BHVR_ACTIVITY_ROUTE_SOURCE_NPC_LOCAL
    );
    if (sRoute != "")
    {
        return sRoute;
    }

    sRoute = NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(
        GetLocalString(oNpc, NpcBhvrActivitySlotRouteProfileKey(sSlot)),
        oNpc,
        NPC_BHVR_ACTIVITY_ROUTE_SOURCE_NPC_LOCAL
    );
    if (sRoute != "")
    {
        return sRoute;
    }

    sRoute = NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(
        GetLocalString(oNpc, NPC_BHVR_VAR_ROUTE_PROFILE_DEFAULT),
        oNpc,
        NPC_BHVR_ACTIVITY_ROUTE_SOURCE_NPC_LOCAL
    );
    if (sRoute != "")
    {
        return sRoute;
    }

    oArea = GetArea(oNpc);
    if (!GetIsObjectValid(oArea))
    {
        return NPC_BHVR_ACTIVITY_ROUTE_DEFAULT;
    }

    sRoute = NpcBhvrActivityRouteCacheResolveForSlot(oArea, sSlot);
    if (sRoute != "")
    {
        return sRoute;
    }

    return NPC_BHVR_ACTIVITY_ROUTE_DEFAULT;
}

int NpcBhvrActivityAdapterWasSlotFallback(string sSlot)
{
    return sSlot != NPC_BHVR_ACTIVITY_SLOT_DEFAULT
        && sSlot != NPC_BHVR_ACTIVITY_SLOT_PRIORITY
        && sSlot != NPC_BHVR_ACTIVITY_SLOT_CRITICAL;
}

string NpcBhvrActivityAdapterNormalizeSlot(string sSlot)
{
    // AL-concept adapter: slot-group normalization in npc namespace.
    if (sSlot == NPC_BHVR_ACTIVITY_SLOT_PRIORITY)
    {
        return NPC_BHVR_ACTIVITY_SLOT_PRIORITY;
    }

    if (sSlot == NPC_BHVR_ACTIVITY_SLOT_CRITICAL)
    {
        return NPC_BHVR_ACTIVITY_SLOT_CRITICAL;
    }

    return NPC_BHVR_ACTIVITY_SLOT_DEFAULT;
}

string NpcBhvrActivityAdapterNormalizeRoute(string sRouteId)
{
    // AL-concept adapter: route-id normalization in npc namespace.
    if (sRouteId == NPC_BHVR_ACTIVITY_ROUTE_PRIORITY)
    {
        return NPC_BHVR_ACTIVITY_ROUTE_PRIORITY;
    }

    if (sRouteId == NPC_BHVR_ACTIVITY_ROUTE_CRITICAL_SAFE)
    {
        return NPC_BHVR_ACTIVITY_ROUTE_CRITICAL_SAFE;
    }

    return NPC_BHVR_ACTIVITY_ROUTE_DEFAULT;
}

int NpcBhvrActivityMapRouteHint(string sRouteId)
{
    // Adapter mapping: npc_* profile -> AL-like activity semantics.
    if (sRouteId == NPC_BHVR_ACTIVITY_ROUTE_CRITICAL_SAFE)
    {
        return NPC_BHVR_ACTIVITY_HINT_CRITICAL_SAFE;
    }

    if (sRouteId == NPC_BHVR_ACTIVITY_ROUTE_PRIORITY)
    {
        return NPC_BHVR_ACTIVITY_HINT_PATROL;
    }

    return NPC_BHVR_ACTIVITY_HINT_IDLE;
}

int NpcBhvrActivityResolveRouteCount(object oNpc, string sRouteId)
{
    int nCount;
    object oArea;

    if (!GetIsObjectValid(oNpc))
    {
        return 0;
    }

    nCount = GetLocalInt(oNpc, NpcBhvrActivityRouteCountKey(sRouteId));
    if (nCount > 0)
    {
        return nCount;
    }

    oArea = GetArea(oNpc);
    if (GetIsObjectValid(oArea))
    {
        nCount = GetLocalInt(oArea, NpcBhvrActivityRouteCountKey(sRouteId));
        if (nCount > 0)
        {
            return nCount;
        }
    }

    return 0;
}

int NpcBhvrActivityResolveRouteLoop(object oNpc, string sRouteId)
{
    object oArea;
    int nLoopFlag;

    if (!GetIsObjectValid(oNpc))
    {
        return TRUE;
    }

    nLoopFlag = GetLocalInt(oNpc, NpcBhvrActivityRouteLoopKey(sRouteId));
    if (nLoopFlag > 0)
    {
        return TRUE;
    }

    if (nLoopFlag < 0)
    {
        return FALSE;
    }

    oArea = GetArea(oNpc);
    if (!GetIsObjectValid(oArea))
    {
        return TRUE;
    }

    nLoopFlag = GetLocalInt(oArea, NpcBhvrActivityRouteLoopKey(sRouteId));
    if (nLoopFlag > 0)
    {
        return TRUE;
    }

    if (nLoopFlag < 0)
    {
        return FALSE;
    }

    return TRUE;
}

string NpcBhvrActivityResolveRouteTag(object oNpc, string sRouteId)
{
    object oArea;
    string sTag;

    if (!GetIsObjectValid(oNpc))
    {
        return "";
    }

    sTag = GetLocalString(oNpc, NpcBhvrActivityRouteTagKey(sRouteId));
    if (sTag != "")
    {
        return sTag;
    }

    oArea = GetArea(oNpc);
    if (!GetIsObjectValid(oArea))
    {
        return "";
    }

    return GetLocalString(oArea, NpcBhvrActivityRouteTagKey(sRouteId));
}

int NpcBhvrActivityNormalizeWaypointIndex(int nIndex, int nCount, int bLoop)
{
    if (nCount <= 0)
    {
        return 0;
    }

    if (nIndex < 0)
    {
        return 0;
    }

    if (nIndex < nCount)
    {
        return nIndex;
    }

    if (bLoop)
    {
        return nIndex % nCount;
    }

    return nCount - 1;
}

string NpcBhvrActivityComposeWaypointState(string sBaseState, string sRouteTag, int nWpIndex, int nWpCount)
{
    if (sRouteTag == "" || nWpCount <= 0)
    {
        return sBaseState;
    }

    return sBaseState + "_" + sRouteTag + "_" + IntToString(nWpIndex + 1) + "_of_" + IntToString(nWpCount);
}

string NpcBhvrActivityResolveSlotEmote(object oNpc, string sSlot)
{
    string sEmote;
    object oArea;

    if (!GetIsObjectValid(oNpc))
    {
        return "";
    }

    sEmote = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT_EMOTE + "_" + sSlot);
    if (sEmote != "")
    {
        return sEmote;
    }

    oArea = GetArea(oNpc);
    if (GetIsObjectValid(oArea))
    {
        sEmote = GetLocalString(oArea, NPC_BHVR_VAR_ACTIVITY_SLOT_EMOTE + "_" + sSlot);
        if (sEmote != "")
        {
            return sEmote;
        }

        sEmote = GetLocalString(oArea, NPC_BHVR_VAR_ACTIVITY_SLOT_EMOTE);
        if (sEmote != "")
        {
            return sEmote;
        }
    }

    return GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT_EMOTE);
}

int NpcBhvrActivityResolveRoutePauseTicks(object oNpc, string sRouteId)
{
    int nPause;
    object oArea;

    if (!GetIsObjectValid(oNpc))
    {
        return 0;
    }

    nPause = GetLocalInt(oNpc, NpcBhvrActivityRoutePauseTicksKey(sRouteId));
    if (nPause > 0)
    {
        return nPause;
    }

    oArea = GetArea(oNpc);
    if (!GetIsObjectValid(oArea))
    {
        return 0;
    }

    nPause = GetLocalInt(oArea, NpcBhvrActivityRoutePauseTicksKey(sRouteId));
    if (nPause > 0)
    {
        return nPause;
    }

    return 0;
}

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

int NpcBhvrActivityAdapterIsCriticalSafe(string sSlot, int nRouteHint)
{
    return sSlot == NPC_BHVR_ACTIVITY_SLOT_CRITICAL || nRouteHint == NPC_BHVR_ACTIVITY_HINT_CRITICAL_SAFE;
}

int NpcBhvrActivityAdapterIsPriority(string sSlot, int nRouteHint)
{
    return sSlot == NPC_BHVR_ACTIVITY_SLOT_PRIORITY || nRouteHint == NPC_BHVR_ACTIVITY_HINT_PATROL;
}

void NpcBhvrActivityApplyRouteState(object oNpc, string sRouteId, string sBaseState, int nCooldown)
{
    int nWpCount;
    int bLoop;
    int nWpIndex;
    int nPauseTicks;
    string sRouteTag;
    string sState;
    string sSlot;
    string sEmote;
    string sAction;

    nWpCount = NpcBhvrActivityResolveRouteCount(oNpc, sRouteId);
    bLoop = NpcBhvrActivityResolveRouteLoop(oNpc, sRouteId);
    nWpIndex = NpcBhvrActivityNormalizeWaypointIndex(GetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_INDEX), nWpCount, bLoop);
    nPauseTicks = NpcBhvrActivityResolveRoutePauseTicks(oNpc, sRouteId);
    sRouteTag = NpcBhvrActivityResolveRouteTag(oNpc, sRouteId);
    sState = NpcBhvrActivityComposeWaypointState(sBaseState, sRouteTag, nWpIndex, nWpCount);
    sSlot = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT);
    sEmote = NpcBhvrActivityResolveSlotEmote(oNpc, sSlot);
    sAction = NpcBhvrActivityResolveAction(oNpc, sSlot, sRouteId, nWpIndex, nWpCount);

    NpcBhvrActivityAdapterStampTransition(oNpc, sState);
    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_COOLDOWN, nCooldown + nPauseTicks);
    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_COUNT, nWpCount);
    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_LOOP, bLoop);
    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_INDEX, NpcBhvrActivityNormalizeWaypointIndex(nWpIndex + 1, nWpCount, bLoop));
    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_TAG, sRouteTag);
    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT_EMOTE, sEmote);
    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ACTION, sAction);
}

void NpcBhvrActivityApplyCriticalSafeRoute(object oNpc)
{
    NpcBhvrActivityApplyRouteState(oNpc, NPC_BHVR_ACTIVITY_ROUTE_CRITICAL_SAFE, "idle_critical_safe", 1);
}

void NpcBhvrActivityApplyDefaultRoute(object oNpc)
{
    NpcBhvrActivityApplyRouteState(oNpc, NPC_BHVR_ACTIVITY_ROUTE_DEFAULT, "idle_default", 1);
}

void NpcBhvrActivityApplyPriorityRoute(object oNpc)
{
    NpcBhvrActivityApplyRouteState(oNpc, NPC_BHVR_ACTIVITY_ROUTE_PRIORITY, "idle_priority_patrol", 2);
}

void NpcBhvrActivityOnSpawn(object oNpc)
{
    string sSlot;
    string sRouteConfigured;
    string sRoute;
    int nWpCount;
    int bWpLoop;
    int nWpIndex;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    // Обязательная spawn-инициализация profile-state в npc_* namespace.
    string sSlotRaw = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT);
    int nSlotFallback = NpcBhvrActivityAdapterWasSlotFallback(sSlotRaw);

    sSlot = NpcBhvrActivityAdapterNormalizeSlot(sSlotRaw);
    sRouteConfigured = NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(
        GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE),
        oNpc,
        NPC_BHVR_ACTIVITY_ROUTE_SOURCE_NPC_LOCAL
    );

    sRoute = NpcBhvrActivityResolveRouteProfile(oNpc, sSlot);

    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT, sSlot);
    if (sRouteConfigured != "")
    {
        SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE, sRouteConfigured);
    }
    else
    {
        DeleteLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE);
    }

    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_EFFECTIVE, sRoute);
    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT_FALLBACK, nSlotFallback);
    if (nSlotFallback)
    {
        NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_ACTIVITY_INVALID_SLOT_TOTAL);
    }

    if (GetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_COOLDOWN) < 0)
    {
        SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_COOLDOWN, 0);
    }

    nWpCount = NpcBhvrActivityResolveRouteCount(oNpc, sRoute);
    bWpLoop = NpcBhvrActivityResolveRouteLoop(oNpc, sRoute);
    nWpIndex = NpcBhvrActivityNormalizeWaypointIndex(GetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_INDEX), nWpCount, bWpLoop);

    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_INDEX, nWpIndex);
    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_COUNT, nWpCount);
    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_LOOP, bWpLoop);
    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_TAG, NpcBhvrActivityResolveRouteTag(oNpc, sRoute));
    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT_EMOTE, NpcBhvrActivityResolveSlotEmote(oNpc, sSlot));
    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ACTION, "spawn_init");

    NpcBhvrActivityAdapterStampTransition(oNpc, "spawn_ready");
}

void NpcBhvrActivityOnIdleTick(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    int nCooldown = GetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_COOLDOWN);
    if (nCooldown > 0)
    {
        SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_COOLDOWN, nCooldown - 1);
        return;
    }

    string sSlot = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT);
    string sSlotRaw = sSlot;
    string sRoute = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE);
    int nRouteHint;
    int nSlotFallback = NpcBhvrActivityAdapterWasSlotFallback(sSlotRaw);

    sSlot = NpcBhvrActivityAdapterNormalizeSlot(sSlotRaw);
    sRoute = NpcBhvrActivityResolveRouteProfile(oNpc, sSlot);
    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT, sSlot);
    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_EFFECTIVE, sRoute);
    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT_FALLBACK, nSlotFallback);
    if (nSlotFallback)
    {
        NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_ACTIVITY_INVALID_SLOT_TOTAL);
    }

    nRouteHint = NpcBhvrActivityMapRouteHint(sRoute);

    // Dispatcher: CRITICAL-safe -> priority -> default fallback.
    if (NpcBhvrActivityAdapterIsCriticalSafe(sSlot, nRouteHint))
    {
        NpcBhvrActivityApplyCriticalSafeRoute(oNpc);
        return;
    }

    if (NpcBhvrActivityAdapterIsPriority(sSlot, nRouteHint))
    {
        NpcBhvrActivityApplyPriorityRoute(oNpc);
        return;
    }

    NpcBhvrActivityApplyDefaultRoute(oNpc);
}
