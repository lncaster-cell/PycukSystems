// Route config resolution helpers.

int NpcBhvrActivityIsSupportedRoute(string sRouteId);
string NpcBhvrActivitySlotRouteProfileKey(string sSlot);
string NpcBhvrActivityRouteCacheResolveForSlot(object oArea, string sSlot);

string NpcBhvrActivityAdapterNormalizeRoute(string sRouteId)
{
    if (NpcBhvrActivityIsValidIdentifierValue(
        sRouteId,
        NPC_BHVR_ACTIVITY_ROUTE_ID_MIN_LEN,
        NPC_BHVR_ACTIVITY_ROUTE_ID_MAX_LEN
    ))
    {
        return sRouteId;
    }

    return NPC_BHVR_ACTIVITY_ROUTE_DEFAULT;
}

string NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(string sRouteId, object oMetricScope)
{
    if (sRouteId == "")
    {
        return "";
    }

    if (!NpcBhvrActivityIsValidIdentifierValue(
        sRouteId,
        NPC_BHVR_ACTIVITY_ROUTE_ID_MIN_LEN,
        NPC_BHVR_ACTIVITY_ROUTE_ID_MAX_LEN
    ))
    {
        NpcBhvrMetricInc(oMetricScope, NPC_BHVR_METRIC_ACTIVITY_INVALID_ROUTE_TOTAL);
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
        return NpcBhvrActivityAdapterNormalizeRoute("");
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
        return NpcBhvrActivityAdapterNormalizeRoute("");
    }

    sRoute = NpcBhvrActivityRouteCacheResolveForSlot(oArea, sSlot);
    if (sRoute != "")
    {
        return sRoute;
    }

    return NpcBhvrActivityAdapterNormalizeRoute("");
}

string NpcBhvrActivityNormalizeRouteIdOrDefault(string sRouteId, object oMetricScope)
{
    string sNormalized;

    sNormalized = NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(sRouteId, oMetricScope);
    if (sNormalized != "")
    {
        return sNormalized;
    }

    return NPC_BHVR_ACTIVITY_ROUTE_DEFAULT;
}

string NpcBhvrActivityNormalizeRouteTagOrDefault(string sRouteTag, object oMetricScope)
{
    if (NpcBhvrActivityIsValidIdentifierValue(
        sRouteTag,
        NPC_BHVR_ACTIVITY_ROUTE_TAG_MIN_LEN,
        NPC_BHVR_ACTIVITY_ROUTE_TAG_MAX_LEN
    ))
    {
        return sRouteTag;
    }

    if (oMetricScope != OBJECT_INVALID)
    {
        NpcBhvrMetricInc(oMetricScope, NPC_BHVR_METRIC_ACTIVITY_INVALID_ROUTE_TOTAL);
    }

    return NPC_BHVR_ACTIVITY_ROUTE_TAG_DEFAULT;
}
