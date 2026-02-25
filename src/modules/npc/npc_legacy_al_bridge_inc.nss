// Legacy Ambient Life (al_*) migration bridge.
// Canonical runtime remains npc_*; this file only normalizes legacy content once.

const int NPC_BHVR_LEGACY_BRIDGE_VERSION = 1;
const string NPC_BHVR_VAR_LEGACY_BRIDGE_NPC_VERSION = "npc_legacy_bridge_npc_version";
const string NPC_BHVR_VAR_LEGACY_BRIDGE_AREA_VERSION = "npc_legacy_bridge_area_version";

// Legacy AL keys (supported subset for controlled migration).
const string NPC_BHVR_LEGACY_VAR_SLOT = "al_slot";
const string NPC_BHVR_LEGACY_VAR_ROUTE = "al_route";
const string NPC_BHVR_LEGACY_VAR_SCHEDULE_ENABLED = "al_schedule_enabled";
const string NPC_BHVR_LEGACY_VAR_SLOT_CRITICAL_START = "al_schedule_critical_start";
const string NPC_BHVR_LEGACY_VAR_SLOT_CRITICAL_END = "al_schedule_critical_end";
const string NPC_BHVR_LEGACY_VAR_SLOT_PRIORITY_START = "al_schedule_priority_start";
const string NPC_BHVR_LEGACY_VAR_SLOT_PRIORITY_END = "al_schedule_priority_end";

const string NPC_BHVR_LEGACY_VAR_AREA_ROUTE_DEFAULT = "al_route_default";
const string NPC_BHVR_LEGACY_VAR_AREA_ROUTE_PRIORITY = "al_route_priority";
const string NPC_BHVR_LEGACY_VAR_AREA_ROUTE_CRITICAL = "al_route_critical";

const string NPC_BHVR_LEGACY_VAR_ROUTE_COUNT_PREFIX = "al_route_count_";
const string NPC_BHVR_LEGACY_VAR_ROUTE_LOOP_PREFIX = "al_route_loop_";
const string NPC_BHVR_LEGACY_VAR_ROUTE_TAG_PREFIX = "al_route_tag_";
const string NPC_BHVR_LEGACY_VAR_ROUTE_PAUSE_PREFIX = "al_route_pause_";
const string NPC_BHVR_LEGACY_VAR_ROUTE_ACTIVITY_PREFIX = "al_route_activity_";

int NpcBhvrActivityIsSupportedRoute(string sRouteId);
string NpcBhvrActivityAdapterNormalizeRoute(string sRouteId);
string NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(string sRouteId, object oMetricScope);
string NpcBhvrActivityNormalizeRouteTagOrDefault(string sRouteTag, object oMetricScope);
string NpcBhvrActivityScheduleStartKey(string sSlot);
string NpcBhvrActivityScheduleEndKey(string sSlot);

void NpcBhvrLegacyBridgeMetric(object oScope, string sMetric, int nDelta)
{
    if (!GetIsObjectValid(oScope) || nDelta <= 0)
    {
        return;
    }

    NpcBhvrMetricAdd(oScope, sMetric, nDelta);
}

void NpcBhvrLegacyBridgeMigrateRouteProfileKey(object oOwner, object oMetricScope, string sLegacyKey, string sTargetKey)
{
    string sLegacy;
    string sNormalized;

    sLegacy = GetLocalString(oOwner, sLegacyKey);
    if (sLegacy == "")
    {
        return;
    }

    sNormalized = NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(sLegacy, oMetricScope);
    if (sNormalized == "")
    {
        NpcBhvrMetricInc(oMetricScope, NPC_BHVR_METRIC_LEGACY_UNSUPPORTED_KEYS_TOTAL);
        NpcBhvrMetricInc(oMetricScope, NPC_BHVR_METRIC_LEGACY_FALLBACK_TOTAL);
        return;
    }

    if (GetLocalString(oOwner, sTargetKey) == "")
    {
        SetLocalString(oOwner, sTargetKey, sNormalized);
        NpcBhvrMetricInc(oMetricScope, NPC_BHVR_METRIC_LEGACY_NORMALIZED_KEYS_TOTAL);
    }
}

void NpcBhvrLegacyBridgeMigrateRouteDataForId(object oNpc, string sRouteId)
{
    int nIndex;
    int nCount;
    int nValue;
    string sRoute;
    string sTag;
    string sActivityKey;

    sRoute = NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(sRouteId, oNpc);
    if (sRoute == "")
    {
        NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LEGACY_UNSUPPORTED_KEYS_TOTAL);
        return;
    }

    nCount = GetLocalInt(oNpc, NPC_BHVR_LEGACY_VAR_ROUTE_COUNT_PREFIX + sRoute);
    if (nCount > 0 && GetLocalInt(oNpc, NPC_BHVR_VAR_ROUTE_COUNT_PREFIX + sRoute) <= 0)
    {
        SetLocalInt(oNpc, NPC_BHVR_VAR_ROUTE_COUNT_PREFIX + sRoute, nCount);
        NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LEGACY_NORMALIZED_KEYS_TOTAL);
    }

    nValue = GetLocalInt(oNpc, NPC_BHVR_LEGACY_VAR_ROUTE_LOOP_PREFIX + sRoute);
    if (GetLocalInt(oNpc, NPC_BHVR_VAR_ROUTE_LOOP_PREFIX + sRoute) == 0 && nValue != 0)
    {
        SetLocalInt(oNpc, NPC_BHVR_VAR_ROUTE_LOOP_PREFIX + sRoute, nValue);
        NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LEGACY_NORMALIZED_KEYS_TOTAL);
    }

    sTag = GetLocalString(oNpc, NPC_BHVR_LEGACY_VAR_ROUTE_TAG_PREFIX + sRoute);
    if (sTag != "" && GetLocalString(oNpc, NPC_BHVR_VAR_ROUTE_TAG_PREFIX + sRoute) == "")
    {
        SetLocalString(oNpc, NPC_BHVR_VAR_ROUTE_TAG_PREFIX + sRoute, NpcBhvrActivityNormalizeRouteTagOrDefault(sTag, oNpc));
        NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LEGACY_NORMALIZED_KEYS_TOTAL);
    }

    nValue = GetLocalInt(oNpc, NPC_BHVR_LEGACY_VAR_ROUTE_PAUSE_PREFIX + sRoute);
    if (GetLocalInt(oNpc, NPC_BHVR_VAR_ROUTE_PAUSE_TICKS_PREFIX + sRoute) == 0 && nValue > 0)
    {
        SetLocalInt(oNpc, NPC_BHVR_VAR_ROUTE_PAUSE_TICKS_PREFIX + sRoute, nValue);
        NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LEGACY_NORMALIZED_KEYS_TOTAL);
    }

    if (nCount <= 0)
    {
        return;
    }

    nIndex = 0;
    while (nIndex < nCount)
    {
        sActivityKey = NPC_BHVR_LEGACY_VAR_ROUTE_ACTIVITY_PREFIX + sRoute + "_" + IntToString(nIndex);
        nValue = GetLocalInt(oNpc, sActivityKey);
        if (nValue > 0 && GetLocalInt(oNpc, NPC_BHVR_VAR_ROUTE_ACTIVITY_PREFIX + sRoute + "_" + IntToString(nIndex)) <= 0)
        {
            SetLocalInt(oNpc, NPC_BHVR_VAR_ROUTE_ACTIVITY_PREFIX + sRoute + "_" + IntToString(nIndex), nValue);
            NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LEGACY_NORMALIZED_KEYS_TOTAL);
        }
        nIndex = nIndex + 1;
    }
}

void NpcBhvrLegacyBridgeMigrateNpc(object oNpc)
{
    object oArea;
    string sLegacy;
    string sNormalized;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    if (GetLocalInt(oNpc, NPC_BHVR_VAR_LEGACY_BRIDGE_NPC_VERSION) == NPC_BHVR_LEGACY_BRIDGE_VERSION)
    {
        return;
    }

    oArea = GetArea(oNpc);

    sLegacy = GetLocalString(oNpc, NPC_BHVR_LEGACY_VAR_SLOT);
    if (sLegacy != "")
    {
        if (GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT) == "")
        {
            SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT, sLegacy);
            NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LEGACY_NORMALIZED_KEYS_TOTAL);
        }
    }

    sLegacy = GetLocalString(oNpc, NPC_BHVR_LEGACY_VAR_ROUTE);
    if (sLegacy != "")
    {
        sNormalized = NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(sLegacy, oNpc);
        if (sNormalized != "")
        {
            if (GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE) == "")
            {
                SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE, sNormalized);
                NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LEGACY_NORMALIZED_KEYS_TOTAL);
            }
        }
        else
        {
            NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LEGACY_UNSUPPORTED_KEYS_TOTAL);
            NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LEGACY_FALLBACK_TOTAL);
        }
    }

    if (GetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_SCHEDULE_ENABLED) == 0 && GetLocalInt(oNpc, NPC_BHVR_LEGACY_VAR_SCHEDULE_ENABLED) != 0)
    {
        SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_SCHEDULE_ENABLED, TRUE);
        NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LEGACY_NORMALIZED_KEYS_TOTAL);
    }

    if (GetLocalString(oNpc, NpcBhvrActivityScheduleStartKey(NPC_BHVR_ACTIVITY_SLOT_CRITICAL)) == "" &&
        GetLocalString(oNpc, NPC_BHVR_LEGACY_VAR_SLOT_CRITICAL_START) != "")
    {
        SetLocalInt(oNpc, NpcBhvrActivityScheduleStartKey(NPC_BHVR_ACTIVITY_SLOT_CRITICAL), GetLocalInt(oNpc, NPC_BHVR_LEGACY_VAR_SLOT_CRITICAL_START));
        SetLocalInt(oNpc, NpcBhvrActivityScheduleEndKey(NPC_BHVR_ACTIVITY_SLOT_CRITICAL), GetLocalInt(oNpc, NPC_BHVR_LEGACY_VAR_SLOT_CRITICAL_END));
        NpcBhvrMetricAdd(oNpc, NPC_BHVR_METRIC_LEGACY_NORMALIZED_KEYS_TOTAL, 2);
    }

    if (GetLocalString(oNpc, NpcBhvrActivityScheduleStartKey(NPC_BHVR_ACTIVITY_SLOT_PRIORITY)) == "" &&
        GetLocalString(oNpc, NPC_BHVR_LEGACY_VAR_SLOT_PRIORITY_START) != "")
    {
        SetLocalInt(oNpc, NpcBhvrActivityScheduleStartKey(NPC_BHVR_ACTIVITY_SLOT_PRIORITY), GetLocalInt(oNpc, NPC_BHVR_LEGACY_VAR_SLOT_PRIORITY_START));
        SetLocalInt(oNpc, NpcBhvrActivityScheduleEndKey(NPC_BHVR_ACTIVITY_SLOT_PRIORITY), GetLocalInt(oNpc, NPC_BHVR_LEGACY_VAR_SLOT_PRIORITY_END));
        NpcBhvrMetricAdd(oNpc, NPC_BHVR_METRIC_LEGACY_NORMALIZED_KEYS_TOTAL, 2);
    }

    NpcBhvrLegacyBridgeMigrateRouteDataForId(oNpc, NPC_BHVR_ACTIVITY_ROUTE_DEFAULT);
    NpcBhvrLegacyBridgeMigrateRouteDataForId(oNpc, NPC_BHVR_ACTIVITY_ROUTE_PRIORITY);
    NpcBhvrLegacyBridgeMigrateRouteDataForId(oNpc, NPC_BHVR_ACTIVITY_ROUTE_CRITICAL_SAFE);

    SetLocalInt(oNpc, NPC_BHVR_VAR_LEGACY_BRIDGE_NPC_VERSION, NPC_BHVR_LEGACY_BRIDGE_VERSION);
    NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LEGACY_MIGRATED_NPC_TOTAL);

    if (GetIsObjectValid(oArea))
    {
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_LEGACY_MIGRATED_NPC_TOTAL);
    }
}

void NpcBhvrLegacyBridgeMigrateAreaDefaults(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    if (GetLocalInt(oArea, NPC_BHVR_VAR_LEGACY_BRIDGE_AREA_VERSION) == NPC_BHVR_LEGACY_BRIDGE_VERSION)
    {
        return;
    }

    NpcBhvrLegacyBridgeMigrateRouteProfileKey(oArea, oArea, NPC_BHVR_LEGACY_VAR_AREA_ROUTE_DEFAULT, NPC_BHVR_VAR_ROUTE_PROFILE_DEFAULT);
    NpcBhvrLegacyBridgeMigrateRouteProfileKey(oArea, oArea, NPC_BHVR_LEGACY_VAR_AREA_ROUTE_PRIORITY, NpcBhvrActivitySlotRouteProfileKey(NPC_BHVR_ACTIVITY_SLOT_PRIORITY));
    NpcBhvrLegacyBridgeMigrateRouteProfileKey(oArea, oArea, NPC_BHVR_LEGACY_VAR_AREA_ROUTE_CRITICAL, NpcBhvrActivitySlotRouteProfileKey(NPC_BHVR_ACTIVITY_SLOT_CRITICAL));

    SetLocalInt(oArea, NPC_BHVR_VAR_LEGACY_BRIDGE_AREA_VERSION, NPC_BHVR_LEGACY_BRIDGE_VERSION);
    NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_LEGACY_MIGRATED_AREA_TOTAL);
}
