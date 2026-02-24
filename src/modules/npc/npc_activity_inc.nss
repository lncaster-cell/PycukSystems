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
const string NPC_BHVR_VAR_ACTIVITY_ACTION = "npc_activity_action";
const string NPC_BHVR_VAR_ACTIVITY_ID = "npc_activity_id";
const string NPC_BHVR_VAR_ACTIVITY_CUSTOM_ANIMS = "npc_activity_custom_anims";
const string NPC_BHVR_VAR_ACTIVITY_NUMERIC_ANIMS = "npc_activity_numeric_anims";
const string NPC_BHVR_VAR_ACTIVITY_WAYPOINT_TAG = "npc_activity_waypoint_tag";
const string NPC_BHVR_VAR_ACTIVITY_REQUIRES_TRAINING_PARTNER = "npc_activity_requires_training_partner";
const string NPC_BHVR_VAR_ACTIVITY_REQUIRES_BAR_PAIR = "npc_activity_requires_bar_pair";
const string NPC_BHVR_VAR_ACTIVITY_SCHEDULE_ENABLED = "npc_activity_schedule_enabled";

const string NPC_BHVR_VAR_ACTIVITY_SCHEDULE_START_PREFIX = "npc_schedule_start_";
const string NPC_BHVR_VAR_ACTIVITY_SCHEDULE_END_PREFIX = "npc_schedule_end_";

const string NPC_BHVR_VAR_ROUTE_PAUSE_TICKS_PREFIX = "npc_route_pause_ticks_";

const string NPC_BHVR_VAR_ROUTE_COUNT_PREFIX = "npc_route_count_";
const string NPC_BHVR_VAR_ROUTE_LOOP_PREFIX = "npc_route_loop_";
const string NPC_BHVR_VAR_ROUTE_TAG_PREFIX = "npc_route_tag_";
const string NPC_BHVR_VAR_ROUTE_ACTIVITY_PREFIX = "npc_route_activity_";

const string NPC_BHVR_ACTIVITY_SLOT_DEFAULT = "default";
const string NPC_BHVR_ACTIVITY_SLOT_PRIORITY = "priority";
const string NPC_BHVR_ACTIVITY_SLOT_CRITICAL = "critical";

const string NPC_BHVR_ACTIVITY_ROUTE_DEFAULT = "default_route";
const string NPC_BHVR_ACTIVITY_ROUTE_PRIORITY = "priority_patrol";
const string NPC_BHVR_ACTIVITY_ROUTE_CRITICAL_SAFE = "critical_safe";

const int NPC_BHVR_ACTIVITY_HINT_IDLE = 1;
const int NPC_BHVR_ACTIVITY_HINT_PATROL = 2;
const int NPC_BHVR_ACTIVITY_HINT_CRITICAL_SAFE = 3;

// AmbientLiveV2 activity IDs (ported from legacy AL data layer).
const int NPC_BHVR_ACTIVITY_ID_HIDDEN = 0;
const int NPC_BHVR_ACTIVITY_ID_ACT_ONE = 1;
const int NPC_BHVR_ACTIVITY_ID_ACT_TWO = 2;
const int NPC_BHVR_ACTIVITY_ID_DINNER = 3;
const int NPC_BHVR_ACTIVITY_ID_MIDNIGHT_BED = 4;
const int NPC_BHVR_ACTIVITY_ID_SLEEP_BED = 5;
const int NPC_BHVR_ACTIVITY_ID_WAKE = 6;
const int NPC_BHVR_ACTIVITY_ID_AGREE = 7;
const int NPC_BHVR_ACTIVITY_ID_ANGRY = 8;
const int NPC_BHVR_ACTIVITY_ID_SAD = 9;
const int NPC_BHVR_ACTIVITY_ID_COOK = 10;
const int NPC_BHVR_ACTIVITY_ID_DANCE_FEMALE = 11;
const int NPC_BHVR_ACTIVITY_ID_DANCE_MALE = 12;
const int NPC_BHVR_ACTIVITY_ID_DRUM = 13;
const int NPC_BHVR_ACTIVITY_ID_FLUTE = 14;
const int NPC_BHVR_ACTIVITY_ID_FORGE = 15;
const int NPC_BHVR_ACTIVITY_ID_GUITAR = 16;
const int NPC_BHVR_ACTIVITY_ID_WOODSMAN = 17;
const int NPC_BHVR_ACTIVITY_ID_MEDITATE = 18;
const int NPC_BHVR_ACTIVITY_ID_POST = 19;
const int NPC_BHVR_ACTIVITY_ID_READ = 20;
const int NPC_BHVR_ACTIVITY_ID_SIT = 21;
const int NPC_BHVR_ACTIVITY_ID_SIT_DINNER = 22;
const int NPC_BHVR_ACTIVITY_ID_STAND_CHAT = 23;
const int NPC_BHVR_ACTIVITY_ID_TRAINING_ONE = 24;
const int NPC_BHVR_ACTIVITY_ID_TRAINING_TWO = 25;
const int NPC_BHVR_ACTIVITY_ID_TRAINER_PACE = 26;
const int NPC_BHVR_ACTIVITY_ID_WWP = 27;
const int NPC_BHVR_ACTIVITY_ID_CHEER = 28;
const int NPC_BHVR_ACTIVITY_ID_COOK_MULTI = 29;
const int NPC_BHVR_ACTIVITY_ID_FORGE_MULTI = 30;
const int NPC_BHVR_ACTIVITY_ID_MIDNIGHT_90 = 31;
const int NPC_BHVR_ACTIVITY_ID_SLEEP_90 = 32;
const int NPC_BHVR_ACTIVITY_ID_THIEF = 33;
const int NPC_BHVR_ACTIVITY_ID_THIEF2 = 36;
const int NPC_BHVR_ACTIVITY_ID_ASSASSIN = 37;
const int NPC_BHVR_ACTIVITY_ID_MERCHANT_MULTI = 38;
const int NPC_BHVR_ACTIVITY_ID_KNEEL_TALK = 39;
const int NPC_BHVR_ACTIVITY_ID_BARMAID = 41;
const int NPC_BHVR_ACTIVITY_ID_BARTENDER = 42;
const int NPC_BHVR_ACTIVITY_ID_GUARD = 43;
const int NPC_BHVR_ACTIVITY_ID_LOCATE_WRAPPER_MIN = 91;
const int NPC_BHVR_ACTIVITY_ID_LOCATE_WRAPPER_MAX = 98;

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

string NpcBhvrActivityRoutePointActivityKey(string sRouteId, int nIndex)
{
    return NPC_BHVR_VAR_ROUTE_ACTIVITY_PREFIX + sRouteId + "_" + IntToString(nIndex);
}

string NpcBhvrActivityScheduleStartKey(string sSlot)
{
    return NPC_BHVR_VAR_ACTIVITY_SCHEDULE_START_PREFIX + sSlot;
}

string NpcBhvrActivityScheduleEndKey(string sSlot)
{
    return NPC_BHVR_VAR_ACTIVITY_SCHEDULE_END_PREFIX + sSlot;
}

// Contract: see schedule-aware slot section in src/modules/npc/README.md.
int NpcBhvrActivityIsHourInWindow(int nHour, int nStart, int nEnd)
{
    if (nStart < 0 || nStart > 23 || nEnd < 0 || nEnd > 23)
    {
        return FALSE;
    }

    if (nStart == nEnd)
    {
        // Защита от неявного always-on при незаполненных/неполных окнах расписания
        // (GetLocalInt по отсутствующему ключу возвращает 0).
        return FALSE;
    }

    // Non-wrapping window.
    if (nStart < nEnd)
    {
        return nHour >= nStart && nHour < nEnd;
    }

    // Wrapping window (например, 22 -> 6).
    return nHour >= nStart || nHour < nEnd;
}

int NpcBhvrActivityTryResolveScheduledSlot(object oNpc, int nHour, string sSlot)
{
    int nStart;
    int nEnd;
    int bStartPresent;
    int bEndPresent;

    bStartPresent = GetLocalString(oNpc, NpcBhvrActivityScheduleStartKey(sSlot)) != "";
    bEndPresent = GetLocalString(oNpc, NpcBhvrActivityScheduleEndKey(sSlot)) != "";

    if (!bStartPresent || !bEndPresent)
    {
        if (bStartPresent != bEndPresent)
        {
            NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_ACTIVITY_SCHEDULE_WINDOW_INVALID_TOTAL);
        }
        return FALSE;
    }

    nStart = GetLocalInt(oNpc, NpcBhvrActivityScheduleStartKey(sSlot));
    nEnd = GetLocalInt(oNpc, NpcBhvrActivityScheduleEndKey(sSlot));

    if (!NpcBhvrActivityIsHourInWindow(nHour, nStart, nEnd))
    {
        if (nStart < 0 || nStart > 23 || nEnd < 0 || nEnd > 23 || nStart == nEnd)
        {
            NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_ACTIVITY_SCHEDULE_WINDOW_INVALID_TOTAL);
        }
        return FALSE;
    }

    return TRUE;
}

string NpcBhvrActivityResolveScheduledSlot(object oNpc, string sCurrentSlot)
{
    object oArea;
    int bEnabled;
    int nHour;

    if (!GetIsObjectValid(oNpc))
    {
        return sCurrentSlot;
    }

    oArea = GetArea(oNpc);

    bEnabled = GetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_SCHEDULE_ENABLED);
    if (!bEnabled && GetIsObjectValid(oArea))
    {
        bEnabled = GetLocalInt(oArea, NPC_BHVR_VAR_ACTIVITY_SCHEDULE_ENABLED);
    }
    if (!bEnabled)
    {
        return sCurrentSlot;
    }

    nHour = GetTimeHour();

    if (NpcBhvrActivityTryResolveScheduledSlot(oNpc, nHour, NPC_BHVR_ACTIVITY_SLOT_CRITICAL))
    {
        return NPC_BHVR_ACTIVITY_SLOT_CRITICAL;
    }

    if (NpcBhvrActivityTryResolveScheduledSlot(oNpc, nHour, NPC_BHVR_ACTIVITY_SLOT_PRIORITY))
    {
        return NPC_BHVR_ACTIVITY_SLOT_PRIORITY;
    }

    return NPC_BHVR_ACTIVITY_SLOT_DEFAULT;
}

int NpcBhvrActivityIsSupportedRoute(string sRouteId)
{
    return sRouteId == NPC_BHVR_ACTIVITY_ROUTE_DEFAULT
        || sRouteId == NPC_BHVR_ACTIVITY_ROUTE_PRIORITY
        || sRouteId == NPC_BHVR_ACTIVITY_ROUTE_CRITICAL_SAFE;
}

string NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(string sRouteId, object oMetricScope)
{
    if (sRouteId == "")
    {
        return "";
    }

    if (!NpcBhvrActivityIsSupportedRoute(sRouteId))
    {
        NpcBhvrMetricInc(oMetricScope, NPC_BHVR_METRIC_ACTIVITY_INVALID_ROUTE_TOTAL);
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
        oNpc
    );
    if (sRoute != "")
    {
        return sRoute;
    }

    sRoute = NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(
        GetLocalString(oNpc, NpcBhvrActivitySlotRouteProfileKey(sSlot)),
        oNpc
    );
    if (sRoute != "")
    {
        return sRoute;
    }

    sRoute = NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(
        GetLocalString(oNpc, NPC_BHVR_VAR_ROUTE_PROFILE_DEFAULT),
        oNpc
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

int NpcBhvrActivityIsLocateWrapperActivity(int nActivity)
{
    return nActivity >= NPC_BHVR_ACTIVITY_ID_LOCATE_WRAPPER_MIN
        && nActivity <= NPC_BHVR_ACTIVITY_ID_LOCATE_WRAPPER_MAX;
}

int NpcBhvrActivityResolveRoutePointActivity(object oNpc, string sRouteId, int nWpIndex)
{
    int nActivity;
    object oArea;

    if (!GetIsObjectValid(oNpc) || nWpIndex < 0)
    {
        return 0;
    }

    nActivity = GetLocalInt(oNpc, NpcBhvrActivityRoutePointActivityKey(sRouteId, nWpIndex));
    if (nActivity > 0)
    {
        return nActivity;
    }

    oArea = GetArea(oNpc);
    if (!GetIsObjectValid(oArea))
    {
        return 0;
    }

    nActivity = GetLocalInt(oArea, NpcBhvrActivityRoutePointActivityKey(sRouteId, nWpIndex));
    if (nActivity > 0)
    {
        return nActivity;
    }

    return 0;
}

string NpcBhvrActivityGetLocateWrapperCustomAnims(int nActivity)
{
    switch (nActivity)
    {
        case 91: return "lookleft, lookright, shrug";
        case 92: return "bored, scratchhead, yawn";
        case 93: return "sitfidget, sitidle, sittalk, sittalk01, sittalk02";
        case 94: return "kneelidle, kneeltalk";
        case 95: return "chuckle, nodno, nodyes, talk01, talk02, talklaugh";
        case 96: return "craft01, dustoff, forge01, openlock";
        case 97: return "meditate";
        case 98: return "disableground, sleightofhand, sneak";
    }

    return "";
}

string NpcBhvrActivityGetCustomAnims(int nActivity)
{
    if (NpcBhvrActivityIsLocateWrapperActivity(nActivity))
    {
        return NpcBhvrActivityGetLocateWrapperCustomAnims(nActivity);
    }

    switch (nActivity)
    {
        case NPC_BHVR_ACTIVITY_ID_ACT_ONE: return "lookleft, lookright";
        case NPC_BHVR_ACTIVITY_ID_ACT_TWO: return "lookleft, lookright";
        case NPC_BHVR_ACTIVITY_ID_DINNER: return "sitdrink, siteat, sitidle";
        case NPC_BHVR_ACTIVITY_ID_MIDNIGHT_BED: return "laydownB, proneB";
        case NPC_BHVR_ACTIVITY_ID_SLEEP_BED: return "laydownB, proneB";
        case NPC_BHVR_ACTIVITY_ID_WAKE: return "sitdrink, siteat, sitidle";
        case NPC_BHVR_ACTIVITY_ID_AGREE: return "chuckle, flirt, nodyes";
        case NPC_BHVR_ACTIVITY_ID_ANGRY: return "intimidate, nodno, talkshout";
        case NPC_BHVR_ACTIVITY_ID_SAD: return "talksad, tired";
        case NPC_BHVR_ACTIVITY_ID_COOK: return "cooking02, disablefront";
        case NPC_BHVR_ACTIVITY_ID_DANCE_FEMALE: return "curtsey, dance01";
        case NPC_BHVR_ACTIVITY_ID_DANCE_MALE: return "bow, dance01, dance02";
        case NPC_BHVR_ACTIVITY_ID_DRUM: return "bow, playdrum";
        case NPC_BHVR_ACTIVITY_ID_FLUTE: return "curtsey, playflute";
        case NPC_BHVR_ACTIVITY_ID_FORGE: return "craft01, dustoff, forge01";
        case NPC_BHVR_ACTIVITY_ID_GUITAR: return "bow, playguitar";
        case NPC_BHVR_ACTIVITY_ID_WOODSMAN: return "*1attack01, kneelidle";
        case NPC_BHVR_ACTIVITY_ID_MEDITATE: return "meditate";
        case NPC_BHVR_ACTIVITY_ID_POST: return "lookleft, lookright";
        case NPC_BHVR_ACTIVITY_ID_READ: return "sitidle, sitread, sitteat";
        case NPC_BHVR_ACTIVITY_ID_SIT: return "sitfidget, sitidle, sittalk, sittalk01, sittalk02";
        case NPC_BHVR_ACTIVITY_ID_SIT_DINNER:
            return "sitdrink, siteat, sitidle, sittalk, sittalk01, sittalk02";
        case NPC_BHVR_ACTIVITY_ID_STAND_CHAT:
            return "chuckle, lookleft, lookright, shrug, talk01, talk02, talklaugh";
        case NPC_BHVR_ACTIVITY_ID_TRAINING_ONE: return "lookleft, lookright";
        case NPC_BHVR_ACTIVITY_ID_TRAINING_TWO: return "lookleft, lookright";
        case NPC_BHVR_ACTIVITY_ID_TRAINER_PACE: return "lookleft, lookright";
        case NPC_BHVR_ACTIVITY_ID_WWP: return "kneelidle, lookleft, lookright";
        case NPC_BHVR_ACTIVITY_ID_CHEER: return "chuckle, clapping, talklaugh, victory";
        case NPC_BHVR_ACTIVITY_ID_COOK_MULTI:
            return "cooking01, cooking02, craft01, disablefront, dustoff, forge01, gettable, kneelidle, kneelup, openlock, scratchhead";
        case NPC_BHVR_ACTIVITY_ID_FORGE_MULTI:
            return "craft01, dustoff, forge01, forge02, gettable, kneeldown, kneelidle, kneelup, openlock";
        case NPC_BHVR_ACTIVITY_ID_MIDNIGHT_90: return "laydownB, proneB";
        case NPC_BHVR_ACTIVITY_ID_SLEEP_90: return "laydownB, proneB";
        case NPC_BHVR_ACTIVITY_ID_THIEF: return "chuckle, getground, gettable, openlock";
        case NPC_BHVR_ACTIVITY_ID_THIEF2: return "disableground, sleightofhand, sneak";
        case NPC_BHVR_ACTIVITY_ID_ASSASSIN: return "sneak";
        case NPC_BHVR_ACTIVITY_ID_MERCHANT_MULTI:
            return "bored, getground, gettable, openlock, sleightofhand, yawn";
        case NPC_BHVR_ACTIVITY_ID_KNEEL_TALK: return "kneelidle, kneeltalk";
        case NPC_BHVR_ACTIVITY_ID_BARMAID: return "gettable, lookright, openlock, yawn";
        case NPC_BHVR_ACTIVITY_ID_BARTENDER: return "gettable, lookright, openlock, yawn";
        case NPC_BHVR_ACTIVITY_ID_GUARD: return "bored, lookleft, lookright, sigh";
    }

    return "";
}

string NpcBhvrActivityGetNumericAnims(int nActivity)
{
    switch (nActivity)
    {
        case NPC_BHVR_ACTIVITY_ID_ANGRY: return "10";
        case NPC_BHVR_ACTIVITY_ID_SAD: return "9";
        case NPC_BHVR_ACTIVITY_ID_COOK: return "35, 36";
        case NPC_BHVR_ACTIVITY_ID_DANCE_FEMALE: return "27";
    }

    return "";
}

string NpcBhvrActivityGetWaypointTagRequirement(int nActivity)
{
    switch (nActivity)
    {
        case NPC_BHVR_ACTIVITY_ID_TRAINER_PACE: return "AL_WP_PACE";
        case NPC_BHVR_ACTIVITY_ID_WWP: return "AL_WP_WWP";
    }

    return "";
}

int NpcBhvrActivityRequiresTrainingPartner(int nActivity)
{
    return nActivity == NPC_BHVR_ACTIVITY_ID_TRAINING_ONE || nActivity == NPC_BHVR_ACTIVITY_ID_TRAINING_TWO;
}

int NpcBhvrActivityRequiresBarPair(int nActivity)
{
    return nActivity == NPC_BHVR_ACTIVITY_ID_BARMAID;
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
    int nActivityId;
    string sRouteTag;
    string sState;
    string sSlot;
    string sEmote;
    string sAction;
    string sCustomAnims;
    string sNumericAnims;
    string sWaypointRequirement;

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

    NpcBhvrActivityAdapterStampTransition(oNpc, sState);
    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_COOLDOWN, nCooldown + nPauseTicks);
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
    sSlot = NpcBhvrActivityResolveScheduledSlot(oNpc, sSlot);
    sRouteConfigured = NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(
        GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE),
        oNpc
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
    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_ID, 0);
    DeleteLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_CUSTOM_ANIMS);
    DeleteLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_NUMERIC_ANIMS);
    DeleteLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_WAYPOINT_TAG);
    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_REQUIRES_TRAINING_PARTNER, FALSE);
    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_REQUIRES_BAR_PAIR, FALSE);

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
    sSlot = NpcBhvrActivityResolveScheduledSlot(oNpc, sSlot);
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
