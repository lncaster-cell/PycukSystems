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
const string NPC_BHVR_VAR_ACTIVITY_SLOT_EFFECTIVE = "npc_activity_slot_effective";
const string NPC_BHVR_VAR_ACTIVITY_RESOLVED_HOUR = "npc_activity_resolved_hour";
const string NPC_BHVR_VAR_ACTIVITY_AREA_EFFECTIVE = "npc_activity_area_effective";
const string NPC_BHVR_VAR_ACTIVITY_INVALID_SLOT_LAST = "npc_activity_invalid_slot_last";
const string NPC_BHVR_VAR_ACTIVITY_ROUTE_CONFIG_EFFECTIVE = "npc_activity_route_config_effective";
const string NPC_BHVR_VAR_ACTIVITY_PRECHECK_STAMP = "npc_activity_precheck_stamp";

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
const string NPC_BHVR_VAR_ROUTE_RUNTIME_ROUTE_ID = "npc_route_runtime_route_id";
const string NPC_BHVR_VAR_ROUTE_RUNTIME_COUNT_KEY = "npc_route_runtime_count_key";
const string NPC_BHVR_VAR_ROUTE_RUNTIME_LOOP_KEY = "npc_route_runtime_loop_key";
const string NPC_BHVR_VAR_ROUTE_RUNTIME_TAG_KEY = "npc_route_runtime_tag_key";
const string NPC_BHVR_VAR_ROUTE_RUNTIME_PAUSE_KEY = "npc_route_runtime_pause_key";

const int NPC_BHVR_LOCAL_KEY_MAX_LENGTH = 64;
const int NPC_BHVR_LOCAL_KEY_HASH_LENGTH = 6;

const string NPC_BHVR_ACTIVITY_SLOT_DEFAULT = "default";
const string NPC_BHVR_ACTIVITY_SLOT_PRIORITY = "priority";
const string NPC_BHVR_ACTIVITY_SLOT_CRITICAL = "critical";

const string NPC_BHVR_ACTIVITY_ROUTE_DEFAULT = "default_route";
const string NPC_BHVR_ACTIVITY_ROUTE_PRIORITY = "priority_patrol";
const string NPC_BHVR_ACTIVITY_ROUTE_CRITICAL_SAFE = "critical_safe";
const string NPC_BHVR_ACTIVITY_ROUTE_TAG_DEFAULT = "default";

const int NPC_BHVR_ACTIVITY_ROUTE_ID_MIN_LEN = 1;
const int NPC_BHVR_ACTIVITY_ROUTE_ID_MAX_LEN = 32;
const int NPC_BHVR_ACTIVITY_ROUTE_TAG_MIN_LEN = 1;
const int NPC_BHVR_ACTIVITY_ROUTE_TAG_MAX_LEN = 24;

const int NPC_BHVR_ACTIVITY_HINT_IDLE = 1;
const int NPC_BHVR_ACTIVITY_HINT_PATROL = 2;
const int NPC_BHVR_ACTIVITY_HINT_CRITICAL_SAFE = 3;

// AmbientLiveV2 activity IDs (ported from legacy AL data layer).
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

int NpcBhvrActivityIsValidIdentifierValue(string sValue, int nMinLen, int nMaxLen);
string NpcBhvrActivityAdapterNormalizeRoute(string sRouteId);
string NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(string sRouteId, object oMetricScope);
string NpcBhvrActivityNormalizeRouteIdOrDefault(string sRouteId, object oMetricScope);
string NpcBhvrActivityNormalizeRouteTagOrDefault(string sRouteTag, object oMetricScope);

#include "npc_activity_migration_inc"

#include "npc_activity_route_resolution_inc"
#include "npc_activity_schedule_inc"
#include "npc_activity_state_apply_inc"

string NpcBhvrActivitySlotRouteProfileKey(string sSlot)
{
    return NPC_BHVR_VAR_ROUTE_PROFILE_SLOT_PREFIX + sSlot;
}

string NpcBhvrActivityScheduleStartKey(string sSlot)
{
    return NPC_BHVR_VAR_ACTIVITY_SCHEDULE_START_PREFIX + sSlot;
}

string NpcBhvrActivityScheduleEndKey(string sSlot)
{
    return NPC_BHVR_VAR_ACTIVITY_SCHEDULE_END_PREFIX + sSlot;
}

string NpcBhvrActivityRouteCacheSlotKey(string sSlot)
{
    return NPC_BHVR_VAR_ROUTE_CACHE_SLOT_PREFIX + sSlot;
}

string NpcBhvrActivityRouteCacheResolveForSlot(object oArea, string sSlot)
{
    string sRoute;

    if (!GetIsObjectValid(oArea))
    {
        return "";
    }

    sRoute = NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(
        GetLocalString(oArea, NpcBhvrActivityRouteCacheSlotKey(sSlot)),
        oArea
    );
    if (sRoute != "")
    {
        return sRoute;
    }

    return NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(
        GetLocalString(oArea, NPC_BHVR_VAR_ROUTE_CACHE_DEFAULT),
        oArea
    );
}

int NpcBhvrActivityIsScheduleEnabled(object oNpc, object oArea)
{
    if (GetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_SCHEDULE_ENABLED))
    {
        return TRUE;
    }

    if (GetIsObjectValid(oArea) && GetLocalInt(oArea, NPC_BHVR_VAR_ACTIVITY_SCHEDULE_ENABLED))
    {
        return TRUE;
    }

    return FALSE;
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


string NpcBhvrActivityComposePrecheckStamp(int nResolvedHour, string sAreaTag, string sRouteConfiguredRaw, string sSlotRaw, int bScheduleEnabled)
{
    string sAreaHash;
    string sRouteHash;
    string sStamp;

    sAreaHash = NpcBhvrSafeHash(sAreaTag, NPC_BHVR_LOCAL_KEY_HASH_LENGTH);
    sRouteHash = NpcBhvrSafeHash(sRouteConfiguredRaw, NPC_BHVR_LOCAL_KEY_HASH_LENGTH);
    sStamp = IntToString(nResolvedHour) + "|" + sAreaHash + "|" + sRouteHash;

    if (!bScheduleEnabled)
    {
        sStamp = sStamp + "|" + NpcBhvrSafeHash(sSlotRaw, NPC_BHVR_LOCAL_KEY_HASH_LENGTH);
    }

    return sStamp;
}

int NpcBhvrActivityNeedsHeavyRefresh(object oNpc, string sPrecheckStamp)
{
    string sPrecheckCached;

    sPrecheckCached = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_PRECHECK_STAMP);
    return sPrecheckCached == "" || sPrecheckCached != sPrecheckStamp;
}

void NpcBhvrActivityRunHeavyRefreshForIdle(object oNpc, int nResolvedHour, object oArea, string sAreaTag)
{
    string sSlotRaw;
    string sSlot;
    string sSlotCached;
    string sRouteConfigured;
    string sRouteConfiguredCached;

    sSlotRaw = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT);
    sSlot = NpcBhvrActivityResolveScheduledSlotForContext(
        oNpc,
        NpcBhvrActivityAdapterNormalizeSlot(sSlotRaw),
        NpcBhvrActivityIsScheduleEnabled(oNpc, oArea),
        nResolvedHour
    );
    sSlotCached = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT_EFFECTIVE);

    sRouteConfigured = NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(
        GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE),
        oNpc
    );
    sRouteConfiguredCached = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_CONFIG_EFFECTIVE);

    if (GetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_RESOLVED_HOUR) != nResolvedHour
        || sSlotCached == ""
        || sSlotCached != sSlot
        || sRouteConfiguredCached != sRouteConfigured
        || GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_AREA_EFFECTIVE) != sAreaTag)
    {
        NpcBhvrActivityRefreshProfileState(oNpc);
    }
}

int NpcBhvrActivityIsSupportedRoute(string sRouteId)
{
    return sRouteId == NPC_BHVR_ACTIVITY_ROUTE_DEFAULT
        || sRouteId == NPC_BHVR_ACTIVITY_ROUTE_PRIORITY
        || sRouteId == NPC_BHVR_ACTIVITY_ROUTE_CRITICAL_SAFE;
}

int NpcBhvrActivityIsValidIdentifierValue(string sValue, int nMinLen, int nMaxLen)
{
    int nLength;
    int nIndex;
    string sChar;

    nLength = GetStringLength(sValue);
    if (nLength < nMinLen || nLength > nMaxLen)
    {
        return FALSE;
    }

    nIndex = 0;
    while (nIndex < nLength)
    {
        sChar = GetSubString(sValue, nIndex, 1);
        if (FindSubString("abcdefghijklmnopqrstuvwxyz0123456789_", sChar) < 0)
        {
            return FALSE;
        }

        nIndex = nIndex + 1;
    }

    return TRUE;
}


int NpcBhvrActivityAdapterWasSlotFallback(string sSlot)
{
    return sSlot != NPC_BHVR_ACTIVITY_SLOT_DEFAULT
        && sSlot != NPC_BHVR_ACTIVITY_SLOT_PRIORITY
        && sSlot != NPC_BHVR_ACTIVITY_SLOT_CRITICAL;
}

string NpcBhvrActivityAdapterNormalizeSlot(string sSlot)
{
    // Adapter-layer: normalize slot-group semantics into npc namespace.
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

int NpcBhvrActivityMapRouteHint(string sRouteId)
{
    // Adapter-layer: map resolved npc route profile to runtime activity hint.
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
    string sKey;
    string sRouteIdNormalized;

    if (!GetIsObjectValid(oNpc))
    {
        return 0;
    }

    sRouteIdNormalized = NpcBhvrActivityNormalizeRouteIdOrDefault(sRouteId, oNpc);
    sKey = NpcBhvrActivityGetPrewarmedRuntimeKey(oNpc, sRouteIdNormalized, NPC_BHVR_VAR_ROUTE_RUNTIME_COUNT_KEY, "nb_rc_", oNpc);
    nCount = NpcBhvrActivityReadMigratedRouteInt(oNpc, sRouteIdNormalized, sKey, NPC_BHVR_VAR_ROUTE_COUNT_PREFIX);
    if (nCount > 0)
    {
        return nCount;
    }

    oArea = GetArea(oNpc);
    if (GetIsObjectValid(oArea))
    {
        sKey = NpcBhvrActivityGetPrewarmedRuntimeKey(oArea, sRouteIdNormalized, NPC_BHVR_VAR_ROUTE_RUNTIME_COUNT_KEY, "nb_rc_", oArea);
        nCount = NpcBhvrActivityReadMigratedRouteInt(oArea, sRouteIdNormalized, sKey, NPC_BHVR_VAR_ROUTE_COUNT_PREFIX);
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
    string sKey;
    string sRouteIdNormalized;

    if (!GetIsObjectValid(oNpc))
    {
        return TRUE;
    }

    sRouteIdNormalized = NpcBhvrActivityNormalizeRouteIdOrDefault(sRouteId, oNpc);
    sKey = NpcBhvrActivityGetPrewarmedRuntimeKey(oNpc, sRouteIdNormalized, NPC_BHVR_VAR_ROUTE_RUNTIME_LOOP_KEY, "nb_rl_", oNpc);
    nLoopFlag = NpcBhvrActivityReadMigratedRouteInt(oNpc, sRouteIdNormalized, sKey, NPC_BHVR_VAR_ROUTE_LOOP_PREFIX);
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

    sKey = NpcBhvrActivityGetPrewarmedRuntimeKey(oArea, sRouteIdNormalized, NPC_BHVR_VAR_ROUTE_RUNTIME_LOOP_KEY, "nb_rl_", oArea);
    nLoopFlag = NpcBhvrActivityReadMigratedRouteInt(oArea, sRouteIdNormalized, sKey, NPC_BHVR_VAR_ROUTE_LOOP_PREFIX);
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
    string sKey;
    string sRouteIdNormalized;

    if (!GetIsObjectValid(oNpc))
    {
        return NPC_BHVR_ACTIVITY_ROUTE_TAG_DEFAULT;
    }

    sRouteIdNormalized = NpcBhvrActivityNormalizeRouteIdOrDefault(sRouteId, oNpc);
    sKey = NpcBhvrActivityGetPrewarmedRuntimeKey(oNpc, sRouteIdNormalized, NPC_BHVR_VAR_ROUTE_RUNTIME_TAG_KEY, "nb_rt_", oNpc);
    sTag = NpcBhvrActivityReadMigratedRouteString(oNpc, sRouteIdNormalized, sKey, NPC_BHVR_VAR_ROUTE_TAG_PREFIX);
    if (sTag != "")
    {
        return NpcBhvrActivityNormalizeRouteTagOrDefault(sTag, oNpc);
    }

    oArea = GetArea(oNpc);
    if (GetIsObjectValid(oArea))
    {
        sKey = NpcBhvrActivityGetPrewarmedRuntimeKey(oArea, sRouteIdNormalized, NPC_BHVR_VAR_ROUTE_RUNTIME_TAG_KEY, "nb_rt_", oArea);
        sTag = NpcBhvrActivityReadMigratedRouteString(oArea, sRouteIdNormalized, sKey, NPC_BHVR_VAR_ROUTE_TAG_PREFIX);
        return NpcBhvrActivityNormalizeRouteTagOrDefault(sTag, oNpc);
    }

    return NpcBhvrActivityNormalizeRouteTagOrDefault("", oNpc);
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
    sRouteTag = NpcBhvrActivityNormalizeRouteTagOrDefault(sRouteTag, OBJECT_INVALID);

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
    string sRouteIdNormalized;

    if (!GetIsObjectValid(oNpc) || nWpIndex < 0)
    {
        return 0;
    }

    sRouteIdNormalized = NpcBhvrActivityNormalizeRouteIdOrDefault(sRouteId, oNpc);
    nActivity = NpcBhvrActivityReadMigratedRouteInt(
        oNpc,
        sRouteIdNormalized,
        NpcBhvrActivityRoutePointActivityKey(sRouteIdNormalized, nWpIndex),
        NPC_BHVR_VAR_ROUTE_ACTIVITY_PREFIX
    );
    if (nActivity > 0)
    {
        return nActivity;
    }

    oArea = GetArea(oNpc);
    if (!GetIsObjectValid(oArea))
    {
        return 0;
    }

    nActivity = NpcBhvrActivityReadMigratedRouteInt(
        oArea,
        sRouteIdNormalized,
        NpcBhvrActivityRoutePointActivityKey(sRouteIdNormalized, nWpIndex),
        NPC_BHVR_VAR_ROUTE_ACTIVITY_PREFIX
    );
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
    string sKey;
    string sRouteIdNormalized;

    if (!GetIsObjectValid(oNpc))
    {
        return 0;
    }

    sRouteIdNormalized = NpcBhvrActivityNormalizeRouteIdOrDefault(sRouteId, oNpc);
    sKey = NpcBhvrActivityGetPrewarmedRuntimeKey(oNpc, sRouteIdNormalized, NPC_BHVR_VAR_ROUTE_RUNTIME_PAUSE_KEY, "nb_rp_", oNpc);
    nPause = NpcBhvrActivityReadMigratedRouteInt(oNpc, sRouteIdNormalized, sKey, NPC_BHVR_VAR_ROUTE_PAUSE_TICKS_PREFIX);
    if (nPause > 0)
    {
        return nPause;
    }

    oArea = GetArea(oNpc);
    if (!GetIsObjectValid(oArea))
    {
        return 0;
    }

    sKey = NpcBhvrActivityGetPrewarmedRuntimeKey(oArea, sRouteIdNormalized, NPC_BHVR_VAR_ROUTE_RUNTIME_PAUSE_KEY, "nb_rp_", oArea);
    nPause = NpcBhvrActivityReadMigratedRouteInt(oArea, sRouteIdNormalized, sKey, NPC_BHVR_VAR_ROUTE_PAUSE_TICKS_PREFIX);
    if (nPause > 0)
    {
        return nPause;
    }

    return 0;
}


int NpcBhvrActivityAdapterIsCriticalSafe(string sSlot, int nRouteHint)
{
    return sSlot == NPC_BHVR_ACTIVITY_SLOT_CRITICAL || nRouteHint == NPC_BHVR_ACTIVITY_HINT_CRITICAL_SAFE;
}

int NpcBhvrActivityAdapterIsPriority(string sSlot, int nRouteHint)
{
    return sSlot == NPC_BHVR_ACTIVITY_SLOT_PRIORITY || nRouteHint == NPC_BHVR_ACTIVITY_HINT_PATROL;
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

void NpcBhvrActivityOnAreaActivate(object oArea)
{
    NpcBhvrActivityPrewarmAreaRuntime(oArea);
}

void NpcBhvrActivityRefreshProfileState(object oNpc)
{
    object oArea;
    string sSlot;
    string sSlotRaw;
    string sRouteConfigured;
    string sRoute;
    string sAreaTag;
    int nSlotFallback;
    int nResolvedHour;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    oArea = GetArea(oNpc);
    sSlotRaw = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT);
    nSlotFallback = NpcBhvrActivityAdapterWasSlotFallback(sSlotRaw);
    sSlot = NpcBhvrActivityAdapterNormalizeSlot(sSlotRaw);
    nResolvedHour = GetTimeHour();
    if (GetIsObjectValid(oArea))
    {
        sAreaTag = GetTag(oArea);
    }
    else
    {
        sAreaTag = "";
    }
    sSlot = NpcBhvrActivityResolveScheduledSlotForContext(
        oNpc,
        sSlot,
        NpcBhvrActivityIsScheduleEnabled(oNpc, oArea),
        nResolvedHour
    );
    sRouteConfigured = NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(
        GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE),
        oNpc
    );
    sRoute = NpcBhvrActivityResolveRouteProfile(oNpc, sSlot);
    NpcBhvrActivityPrewarmRouteRuntime(oNpc, sRoute, oNpc);

    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT, sSlot);
    if (sRouteConfigured != "")
    {
        SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE, sRouteConfigured);
    }
    else
    {
        DeleteLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE);
    }

    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT_EFFECTIVE, sSlot);
    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_EFFECTIVE, sRoute);
    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_RESOLVED_HOUR, nResolvedHour);
    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_AREA_EFFECTIVE, sAreaTag);
    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_CONFIG_EFFECTIVE, sRouteConfigured);
    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT_FALLBACK, nSlotFallback);

    if (nSlotFallback)
    {
        if (GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_INVALID_SLOT_LAST) != sSlotRaw)
        {
            NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_ACTIVITY_INVALID_SLOT_TOTAL);
            SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_INVALID_SLOT_LAST, sSlotRaw);
        }
    }
    else
    {
        DeleteLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_INVALID_SLOT_LAST);
    }
}

void NpcBhvrActivityInitRuntimeState(object oNpc)
{
    string sSlot;
    string sRoute;
    int nWpCount;
    int bWpLoop;
    int nWpIndex;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    sSlot = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT_EFFECTIVE);
    sRoute = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_EFFECTIVE);

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

}

void NpcBhvrActivityOnSpawn(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    // Spawn order: profile refresh -> runtime init -> transition stamp.
    NpcBhvrActivityRefreshProfileState(oNpc);
    NpcBhvrActivityInitRuntimeState(oNpc);
    NpcBhvrActivityAdapterStampTransition(oNpc, "spawn_ready");
}

void NpcBhvrActivityOnIdleTick(object oNpc)
{
    object oArea;
    string sPrecheckStamp;
    string sRoute;
    string sRouteConfiguredRaw;
    string sAreaTag;
    int nRouteHint;
    int nResolvedHour;
    int bScheduleEnabled;

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

    oArea = GetArea(oNpc);
    nResolvedHour = GetTimeHour();
    sRouteConfiguredRaw = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE);
    bScheduleEnabled = NpcBhvrActivityIsScheduleEnabled(oNpc, oArea);

    if (GetIsObjectValid(oArea))
    {
        sAreaTag = GetTag(oArea);
    }
    else
    {
        sAreaTag = "";
    }

    sPrecheckStamp = NpcBhvrActivityComposePrecheckStamp(
        nResolvedHour,
        sAreaTag,
        sRouteConfiguredRaw,
        GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT),
        bScheduleEnabled
    );

    if (NpcBhvrActivityNeedsHeavyRefresh(oNpc, sPrecheckStamp))
    {
        NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_ACTIVITY_REFRESH_TOTAL);
        NpcBhvrActivityRunHeavyRefreshForIdle(oNpc, nResolvedHour, oArea, sAreaTag);
        SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_PRECHECK_STAMP, sPrecheckStamp);
    }
    else
    {
        NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_ACTIVITY_REFRESH_SKIPPED_TOTAL);
    }

    string sSlot = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT_EFFECTIVE);
    sRoute = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_EFFECTIVE);

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
