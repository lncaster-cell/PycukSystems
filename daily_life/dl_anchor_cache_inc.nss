object DL_GetNpcCachedWaypointByTag(object oNpc, string sCacheLocal, string sTag)
{
    if (!GetIsObjectValid(oNpc) || sTag == "")
    {
        return OBJECT_INVALID;
    }

    object oCached = GetLocalObject(oNpc, sCacheLocal);
    if (GetIsObjectValid(oCached) && GetTag(oCached) == sTag)
    {
        return oCached;
    }

    object oWp = GetWaypointByTag(sTag);
    if (!GetIsObjectValid(oWp))
    {
        return OBJECT_INVALID;
    }

    SetLocalObject(oNpc, sCacheLocal, oWp);
    return oWp;
}
object DL_ResolveEffectiveWaypointForNpc(object oNpc, object oWp)
{
    if (!GetIsObjectValid(oNpc) || !GetIsObjectValid(oWp))
    {
        return OBJECT_INVALID;
    }

    if (GetArea(oWp) == GetArea(oNpc))
    {
        return oWp;
    }

    if (DL_WaypointHasTransition(oWp))
    {
        object oExitWp = DL_ResolveTransitionExitWaypointFromEntry(oWp);
        if (GetIsObjectValid(oExitWp) && GetArea(oExitWp) == GetArea(oNpc))
        {
            return oExitWp;
        }
    }

    return OBJECT_INVALID;
}
object DL_ResolveNpcWaypointWithFallbackTag(
    object oNpc,
    string sCacheLocal,
    string sPersonalPrefix,
    string sPersonalSuffix,
    string sFallbackTag
)
{
    if (!GetIsObjectValid(oNpc))
    {
        return OBJECT_INVALID;
    }

    string sNpcTag = GetTag(oNpc);
    object oWp = DL_ResolveEffectiveWaypointForNpc(
        oNpc,
        DL_GetNpcCachedWaypointByTag(oNpc, sCacheLocal, sPersonalPrefix + sNpcTag + sPersonalSuffix)
    );
    if (GetIsObjectValid(oWp))
    {
        return oWp;
    }

    return DL_ResolveEffectiveWaypointForNpc(
        oNpc,
        DL_GetNpcCachedWaypointByTag(oNpc, sCacheLocal, sFallbackTag)
    );
}
object DL_GetNpcAreaByTagCached(object oNpc, string sAreaTagLocal, string sAreaCacheLocal)
{
    if (!GetIsObjectValid(oNpc))
    {
        return OBJECT_INVALID;
    }

    string sAreaTag = GetLocalString(oNpc, sAreaTagLocal);
    if (sAreaTag == "")
    {
        return OBJECT_INVALID;
    }

    object oCached = GetLocalObject(oNpc, sAreaCacheLocal);
    if (GetIsObjectValid(oCached) && GetTag(oCached) == sAreaTag)
    {
        return oCached;
    }

    object oArea = GetObjectByTag(sAreaTag);
    if (!GetIsObjectValid(oArea) || !DL_IsAreaObject(oArea))
    {
        DL_LogMarkupIssueOnce(
            oNpc,
            "invalid_area_" + sAreaTagLocal + "_" + sAreaTag,
            "NPC " + GetTag(oNpc) + ": area tag '" + sAreaTag + "' is invalid for local '" + sAreaTagLocal + "'."
        );
        return OBJECT_INVALID;
    }

    SetLocalObject(oNpc, sAreaCacheLocal, oArea);
    return oArea;
}
object DL_GetAreaAnchorWaypoint(object oNpc, object oArea, string sAnchorLocal, string sCacheLocal, int bRequired)
{
    if (!GetIsObjectValid(oNpc) || !GetIsObjectValid(oArea))
    {
        return OBJECT_INVALID;
    }

    string sWpTag = GetLocalString(oArea, sAnchorLocal);
    if (sWpTag == "")
    {
        if (bRequired)
        {
            DL_LogMarkupIssueOnce(
                oNpc,
                "missing_anchor_" + GetTag(oArea) + "_" + sAnchorLocal,
                "Area " + GetTag(oArea) + " misses required anchor '" + sAnchorLocal + "' for NPC " + GetTag(oNpc) + "."
            );
        }
        return OBJECT_INVALID;
    }

    object oWp = DL_GetNpcCachedWaypointByTag(oNpc, sCacheLocal, sWpTag);
    if (!GetIsObjectValid(oWp))
    {
        DL_LogMarkupIssueOnce(
            oNpc,
            "missing_wp_" + GetTag(oArea) + "_" + sAnchorLocal + "_" + sWpTag,
            "Area " + GetTag(oArea) + " anchor '" + sAnchorLocal + "' points to missing waypoint '" + sWpTag + "'."
        );
        return OBJECT_INVALID;
    }
    return oWp;
}
object DL_GetHomeArea(object oNpc)
{
    object oHome = DL_GetNpcAreaByTagCached(oNpc, DL_L_NPC_HOME_AREA_TAG, DL_L_NPC_CACHE_HOME_AREA);
    if (!GetIsObjectValid(oHome))
    {
        DL_LogMarkupIssueOnce(
            oNpc,
            "missing_home_area",
            "NPC " + GetTag(oNpc) + " has no valid home area (dl_home_area_tag)."
        );
    }
    return oHome;
}
object DL_GetWorkArea(object oNpc)
{
    return DL_GetNpcAreaByTagCached(oNpc, DL_L_NPC_WORK_AREA_TAG, DL_L_NPC_CACHE_WORK_AREA);
}
object DL_GetMealArea(object oNpc)
{
    return DL_GetNpcAreaByTagCached(oNpc, DL_L_NPC_MEAL_AREA_TAG, DL_L_NPC_CACHE_MEAL_AREA);
}
object DL_GetSocialArea(object oNpc)
{
    return DL_GetNpcAreaByTagCached(oNpc, DL_L_NPC_SOCIAL_AREA_TAG, DL_L_NPC_CACHE_SOCIAL_AREA);
}
object DL_GetPublicArea(object oNpc)
{
    return DL_GetNpcAreaByTagCached(oNpc, DL_L_NPC_PUBLIC_AREA_TAG, DL_L_NPC_CACHE_PUBLIC_AREA);
}
