#include "al_constants_inc"
#include "al_debug_inc"

// Include layering contract (one-way):
// - al_route_cache_inc -> {al_constants_inc, al_debug_inc}
// - al_area_tick_inc  -> {al_area_constants_inc, al_npc_reg_inc, al_route_cache_inc}
// - al_npc_routes     -> {al_constants_inc, al_npc_reg_inc, al_route_cache_inc}
// Entrypoints should include only the highest-level include they need.

const int AL_AREA_ROUTE_INDEX_MAX = 1023;

int AL_HasRouteIndexFlag(object oWp)
{
    // Dual-key contract for explicit index presence:
    // 1) Preferred key: al_route_index_present
    // 2) Legacy fallback: al_route_index_set
    // This allows al_route_index == 0 to be treated as a valid, set value.
    int bHasIndexPresent = GetLocalInt(oWp, AL_L_ROUTE_INDEX_PRESENT);
    if (bHasIndexPresent)
    {
        return TRUE;
    }

    return GetLocalInt(oWp, AL_L_ROUTE_INDEX_SET);
}

int AL_HasRouteIndex(object oWp)
{
    // Backward-compatible wrapper for callers using old helper name.
    return AL_HasRouteIndexFlag(oWp);
}

int AL_HasValidRouteIndex(object oWp)
{
    if (!AL_HasRouteIndexFlag(oWp))
    {
        return FALSE;
    }

    int nIndex = GetLocalInt(oWp, AL_L_WP_ROUTE_INDEX);
    return nIndex >= 0 && nIndex <= AL_AREA_ROUTE_INDEX_MAX;
}

void AL_AreaDebugLog(object oArea, int nLevel, string sMessage)
{
    AL_DebugLog(oArea, OBJECT_INVALID, nLevel, sMessage);
}

object AL_FindWaypointInAreaByTag(object oArea, string sTag)
{
    if (!GetIsObjectValid(oArea) || sTag == "")
    {
        return OBJECT_INVALID;
    }

    int iNth = 0;
    object oCandidate = GetObjectByTag(sTag, iNth);
    while (GetIsObjectValid(oCandidate))
    {
        if (GetObjectType(oCandidate) == OBJECT_TYPE_WAYPOINT && GetArea(oCandidate) == oArea)
        {
            return oCandidate;
        }

        iNth++;
        oCandidate = GetObjectByTag(sTag, iNth);
    }

    return OBJECT_INVALID;
}

void AL_ClearAreaRouteCacheByTag(object oArea, string sTag)
{
    if (!GetIsObjectValid(oArea) || sTag == "")
    {
        return;
    }

    // Runtime route-cache locals per tag:
    // - points:   al_route_<tag>_<idx>, _activity, _jump
    // - dense map: al_route_<tag>_idx_<dense> + idx_built
    // - counters:  n (dense points), seen_n + seen_* (for exact cleanup)
    // - integrity: has_index, missing_index_logged
    string sResetPrefix = AL_LocalRouteTagPrefix(sTag);
    int iExistingCount = GetLocalInt(oArea, sResetPrefix + "n");
    int iResetIndex = 0;
    int iSeenCount = GetLocalInt(oArea, sResetPrefix + "seen_n");
    if (iSeenCount > 0)
    {
        while (iResetIndex < iSeenCount)
        {
            int iSeenIndex = GetLocalInt(oArea, sResetPrefix + "seen_" + IntToString(iResetIndex));
            string sResetIndex = sResetPrefix + IntToString(iSeenIndex);
            DeleteLocalLocation(oArea, sResetIndex);
            DeleteLocalInt(oArea, sResetIndex + "_activity");
            DeleteLocalInt(oArea, sResetIndex + "_set");
            DeleteLocalLocation(oArea, sResetIndex + "_jump");
            DeleteLocalInt(oArea, sResetPrefix + "seen_" + IntToString(iResetIndex));
            iResetIndex++;
        }
    }
    else
    {
        // Legacy fallback for old caches that do not have seen_* yet.
        while (iResetIndex < iExistingCount)
        {
            string sResetIndex = sResetPrefix + IntToString(iResetIndex);
            DeleteLocalLocation(oArea, sResetIndex);
            DeleteLocalInt(oArea, sResetIndex + "_activity");
            DeleteLocalInt(oArea, sResetIndex + "_set");
            DeleteLocalLocation(oArea, sResetIndex + "_jump");
            iResetIndex++;
        }
    }

    iResetIndex = 0;
    while (iResetIndex < iExistingCount)
    {
        DeleteLocalInt(oArea, sResetPrefix + "idx_" + IntToString(iResetIndex));
        iResetIndex++;
    }
    DeleteLocalInt(oArea, sResetPrefix + "n");
    DeleteLocalInt(oArea, sResetPrefix + "seen_n");
    DeleteLocalInt(oArea, sResetPrefix + "missing_index_logged");
    DeleteLocalInt(oArea, sResetPrefix + "idx_built");
    DeleteLocalInt(oArea, sResetPrefix + "has_index");
}

void AL_CacheAreaRoutes(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    // NOTE: Clearing AL_L_ROUTES_CACHED is safe and forces a full rebuild
    // of the cached route data on the next call.
    if (GetLocalInt(oArea, AL_L_ROUTES_CACHED))
    {
        return;
    }

    object oObj = GetFirstObjectInArea(oArea);
    int iTagCount = 0;

    // Main discovery pass over waypoints.
    while (GetIsObjectValid(oObj))
    {
        if (GetObjectType(oObj) == OBJECT_TYPE_WAYPOINT)
        {
            string sTag = GetTag(oObj);
            if (sTag != "")
            {
                string sTagSeenKey = AL_LocalRouteScanSeenKey(sTag);
                if (!GetLocalInt(oArea, sTagSeenKey))
                {
                    SetLocalInt(oArea, sTagSeenKey, TRUE);
                    SetLocalString(oArea, AL_LocalRouteScanTagKey(iTagCount), sTag);
                    SetLocalInt(oArea, AL_LocalRouteRebuildSeenKey(sTag), TRUE);
                    SetLocalString(oArea, AL_LocalRouteRebuildTagKey(iTagCount), sTag);
                    iTagCount++;

                    // Reset previous cache for the tag once before rebuilding.
                    AL_ClearAreaRouteCacheByTag(oArea, sTag);
                }

                string sTmpPrefix = AL_LocalRouteScanTmpPrefix(sTag);
                int nTmpCount = GetLocalInt(oArea, sTmpPrefix + "n");
                SetLocalObject(oArea, sTmpPrefix + IntToString(nTmpCount), oObj);
                SetLocalInt(oArea, sTmpPrefix + "n", nTmpCount + 1);

                if (AL_HasValidRouteIndex(oObj))
                {
                    SetLocalInt(oArea, AL_LocalRouteTagPrefix(sTag) + "has_index", TRUE);
                }
            }
        }

        oObj = GetNextObjectInArea(oArea);
    }

    int iTagIndex = 0;
    while (iTagIndex < iTagCount)
    {
        string sTag = GetLocalString(oArea, AL_LocalRouteScanTagKey(iTagIndex));
        if (sTag != "")
        {
            string sAreaPrefix = AL_LocalRouteTagPrefix(sTag);
            string sTmpPrefix = AL_LocalRouteScanTmpPrefix(sTag);
            int bRequiresIndex = GetLocalInt(oArea, sAreaPrefix + "has_index");
            int nCount = 0;
            int nDenseCount = 0;
            int nSeenCount = 0;

            int iTmp = 0;
            int nTmpCount = GetLocalInt(oArea, sTmpPrefix + "n");
            while (iTmp < nTmpCount)
            {
                object oWp = GetLocalObject(oArea, sTmpPrefix + IntToString(iTmp));
                DeleteLocalObject(oArea, sTmpPrefix + IntToString(iTmp));
                iTmp++;

                if (!GetIsObjectValid(oWp))
                {
                    continue;
                }

                if (bRequiresIndex && !AL_HasValidRouteIndex(oWp))
                {
                    string sMissingIndexLoggedKey = sAreaPrefix + "missing_index_logged";
                    if (!GetLocalInt(oArea, sMissingIndexLoggedKey))
                    {
                        AL_AreaDebugLog(oArea, AL_DEBUG_LEVEL_L1, "AL: waypoint " + sTag + " has missing/invalid al_route_index; skipped.");
                        SetLocalInt(oArea, sMissingIndexLoggedKey, TRUE);
                    }
                    continue;
                }

                int nIndex = nCount;
                if (bRequiresIndex)
                {
                    nIndex = GetLocalInt(oWp, AL_L_WP_ROUTE_INDEX);
                    if (nIndex < 0 || nIndex > AL_AREA_ROUTE_INDEX_MAX)
                    {
                        AL_AreaDebugLog(oArea, AL_DEBUG_LEVEL_L1, "AL: waypoint " + sTag + " has invalid al_route_index " + IntToString(nIndex) + " (allowed 0.." + IntToString(AL_AREA_ROUTE_INDEX_MAX) + "); skipped.");
                        continue;
                    }
                }

                string sIndex = sAreaPrefix + IntToString(nIndex);
                string sIndexMarker = sIndex + "_set";
                if (GetLocalInt(oArea, sIndexMarker))
                {
                    AL_AreaDebugLog(oArea, AL_DEBUG_LEVEL_L1, "AL: duplicate route index " + IntToString(nIndex) + " for tag " + sTag + "; skipped.");
                    continue;
                }

                SetLocalInt(oArea, sIndexMarker, TRUE);
                nCount++;

                SetLocalInt(oArea, sAreaPrefix + "seen_" + IntToString(nSeenCount), nIndex);
                nSeenCount++;

                SetLocalLocation(oArea, sIndex, GetLocation(oWp));
                int nActivity = GetLocalInt(oWp, AL_L_ACTIVITY);
                if (nActivity > 0)
                {
                    SetLocalInt(oArea, sIndex + "_activity", nActivity);
                }
                else
                {
                    DeleteLocalInt(oArea, sIndex + "_activity");
                }

                DeleteLocalLocation(oArea, sIndex + "_jump");
                // Transition setup contract (simplified):
                // - source waypoint local AL_L_TRANSITION_AREA_TAG points to target area tag.
                // - optional source waypoint local AL_L_TRANSITION_WAYPOINT_TAG points to
                //   destination waypoint tag in target area.
                // - when AL_L_TRANSITION_WAYPOINT_TAG is missing, current waypoint tag is used.
                string sTargetAreaTag = GetLocalString(oWp, AL_L_TRANSITION_AREA_TAG);
                if (sTargetAreaTag != "")
                {
                    object oTargetArea = OBJECT_INVALID;
                    int iTagIndex = 0;
                    while (TRUE)
                    {
                        object oTagCandidate = GetObjectByTag(sTargetAreaTag, iTagIndex);
                        if (!GetIsObjectValid(oTagCandidate))
                        {
                            break;
                        }

                        if (GetObjectType(oTagCandidate) == OBJECT_TYPE_AREA)
                        {
                            oTargetArea = oTagCandidate;
                            break;
                        }

                        AL_AreaDebugLog(oArea, AL_DEBUG_LEVEL_L2, "AL: transition area tag '" + sTargetAreaTag
                            + "' resolved to non-area object; skipped candidate.");
                        iTagIndex++;
                    }

                    if (GetIsObjectValid(oTargetArea))
                    {
                        string sTargetWpTag = GetLocalString(oWp, AL_L_TRANSITION_WAYPOINT_TAG);
                        if (sTargetWpTag == "")
                        {
                            sTargetWpTag = sTag;
                        }

                        object oTargetWp = AL_FindWaypointInAreaByTag(oTargetArea, sTargetWpTag);
                        if (GetIsObjectValid(oTargetWp))
                        {
                            SetLocalLocation(oArea, sIndex + "_jump", GetLocation(oTargetWp));
                        }
                        else
                        {
                            AL_AreaDebugLog(oArea, AL_DEBUG_LEVEL_L1, "AL: transition target waypoint '" + sTargetWpTag
                                + "' not found in area '" + sTargetAreaTag + "' for source waypoint '" + sTag + "'.");
                        }
                    }
                    else
                    {
                        AL_AreaDebugLog(oArea, AL_DEBUG_LEVEL_L1, "AL: transition area tag '" + sTargetAreaTag
                            + "' is missing or invalid for source waypoint '" + sTag + "'.");
                    }
                }
            }
            DeleteLocalInt(oArea, sTmpPrefix + "n");

            if (bRequiresIndex)
            {
                // Indexed routes must expose idx_* in ascending al_route_index order.
                // Keep sparse indexes (for example, 0/10/20) and build a dense map
                // by scanning set markers in index order.
                int iIndex = 0;
                while (iIndex <= AL_AREA_ROUTE_INDEX_MAX)
                {
                    string sIndex = sAreaPrefix + IntToString(iIndex);
                    if (GetLocalInt(oArea, sIndex + "_set"))
                    {
                        SetLocalInt(oArea, sAreaPrefix + "idx_" + IntToString(nDenseCount), iIndex);
                        nDenseCount++;
                    }
                    iIndex++;
                }
            }
            else
            {
                // Legacy fallback: keep discovery order for non-indexed routes.
                int iSeen = 0;
                while (iSeen < nSeenCount)
                {
                    int iIndex = GetLocalInt(oArea, sAreaPrefix + "seen_" + IntToString(iSeen));
                    string sIndex = sAreaPrefix + IntToString(iIndex);
                    if (GetLocalInt(oArea, sIndex + "_set"))
                    {
                        SetLocalInt(oArea, sAreaPrefix + "idx_" + IntToString(nDenseCount), iIndex);
                        nDenseCount++;
                    }
                    iSeen++;
                }
            }

            // Keep only runtime keys:
            // - n/seen_n describe stored points and cleanup domain
            // - idx_* + idx_built provide dense traversal for NPC route copy
            // - missing_index_logged throttles integrity warnings
            SetLocalInt(oArea, sAreaPrefix + "seen_n", nSeenCount);
            SetLocalInt(oArea, sAreaPrefix + "n", nDenseCount);
            SetLocalInt(oArea, sAreaPrefix + "idx_built", TRUE);
            if (nCount > 0 && nCount != nDenseCount)
            {
                AL_AreaDebugLog(oArea, AL_DEBUG_LEVEL_L2, "AL: route adjacency tag " + sTag + " has index gaps; using dense list.");
            }
        }

        DeleteLocalString(oArea, AL_LocalRouteScanTagKey(iTagIndex));
        DeleteLocalInt(oArea, AL_LocalRouteScanSeenKey(sTag));
        iTagIndex++;
    }

    int iKnownTagCount = GetLocalInt(oArea, AL_L_ROUTE_KNOWN_N);
    int iKnownTagIndex = 0;
    while (iKnownTagIndex < iKnownTagCount)
    {
        string sKnownTag = GetLocalString(oArea, AL_LocalRouteKnownTagKey(iKnownTagIndex));
        if (sKnownTag != "" && !GetLocalInt(oArea, AL_LocalRouteRebuildSeenKey(sKnownTag)))
        {
            AL_ClearAreaRouteCacheByTag(oArea, sKnownTag);
            AL_AreaDebugLog(oArea, AL_DEBUG_LEVEL_L2, "AL: route adjacency stale cache cleared for tag " + sKnownTag + ".");
        }

        DeleteLocalString(oArea, AL_LocalRouteKnownTagKey(iKnownTagIndex));
        iKnownTagIndex++;
    }

    int iRebuildTagIndex = 0;
    while (iRebuildTagIndex < iTagCount)
    {
        string sRebuildTag = GetLocalString(oArea, AL_LocalRouteRebuildTagKey(iRebuildTagIndex));
        if (sRebuildTag != "")
        {
            SetLocalString(oArea, AL_LocalRouteKnownTagKey(iRebuildTagIndex), sRebuildTag);
            DeleteLocalInt(oArea, AL_LocalRouteRebuildSeenKey(sRebuildTag));
        }

        DeleteLocalString(oArea, AL_LocalRouteRebuildTagKey(iRebuildTagIndex));
        iRebuildTagIndex++;
    }
    SetLocalInt(oArea, AL_L_ROUTE_KNOWN_N, iTagCount);

    SetLocalInt(oArea, AL_L_ROUTES_CACHED, TRUE);
}
