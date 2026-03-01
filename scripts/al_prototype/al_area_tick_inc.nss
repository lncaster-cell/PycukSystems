#include "al_constants_inc"
#include "al_area_constants_inc"
#include "al_npc_reg_inc"
#include "al_debug_inc"

// Shared Area tick helper: scheduled every 45s while players are present.
// NPC registry synchronization is handled here at the area level only.

const int AL_AREA_ROUTE_INDEX_MAX = 1023;

void AL_AreaDebugLog(object oArea, string sMessage)
{
    if (!GetIsObjectValid(oArea) || GetLocalInt(oArea, "al_debug") != 1)
    {
        return;
    }

    AL_SendDebugMessageToAreaPCs(oArea, sMessage);
}

void AL_ClearAreaRouteCacheByTag(object oArea, string sTag)
{
    if (!GetIsObjectValid(oArea) || sTag == "")
    {
        return;
    }

    string sResetPrefix = "al_route_" + sTag + "_";
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
    DeleteLocalInt(oArea, sResetPrefix + "count");
    DeleteLocalInt(oArea, sResetPrefix + "count_reset");
    DeleteLocalInt(oArea, sResetPrefix + "gap_logged");
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

    // NOTE: Clearing "al_routes_cached" is safe and forces a full rebuild
    // of the cached route data on the next call.
    if (GetLocalInt(oArea, "al_routes_cached"))
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
                string sTagSeenKey = "al_route_scan_seen_" + sTag;
                if (!GetLocalInt(oArea, sTagSeenKey))
                {
                    SetLocalInt(oArea, sTagSeenKey, TRUE);
                    SetLocalString(oArea, "al_route_scan_tag_" + IntToString(iTagCount), sTag);
                    SetLocalInt(oArea, "al_route_rebuild_seen_" + sTag, TRUE);
                    SetLocalString(oArea, "al_route_rebuild_tag_" + IntToString(iTagCount), sTag);
                    iTagCount++;

                    // Reset previous cache for the tag once before rebuilding.
                    AL_ClearAreaRouteCacheByTag(oArea, sTag);
                }

                string sTmpPrefix = "al_route_scan_tmp_" + sTag + "_";
                int nTmpCount = GetLocalInt(oArea, sTmpPrefix + "n");
                SetLocalObject(oArea, sTmpPrefix + IntToString(nTmpCount), oObj);
                SetLocalInt(oArea, sTmpPrefix + "n", nTmpCount + 1);

                if (GetLocalInt(oObj, "al_route_index_set"))
                {
                    SetLocalInt(oArea, "al_route_" + sTag + "_has_index", TRUE);
                }
            }
        }

        oObj = GetNextObjectInArea(oArea);
    }

    int iTagIndex = 0;
    while (iTagIndex < iTagCount)
    {
        string sTag = GetLocalString(oArea, "al_route_scan_tag_" + IntToString(iTagIndex));
        if (sTag != "")
        {
            string sAreaPrefix = "al_route_" + sTag + "_";
            string sTmpPrefix = "al_route_scan_tmp_" + sTag + "_";
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

                if (bRequiresIndex && !GetLocalInt(oWp, "al_route_index_set"))
                {
                    string sMissingIndexLoggedKey = sAreaPrefix + "missing_index_logged";
                    if (!GetLocalInt(oArea, sMissingIndexLoggedKey))
                    {
                        AL_AreaDebugLog(oArea, "AL: waypoint " + sTag + " missing al_route_index; skipped.");
                        SetLocalInt(oArea, sMissingIndexLoggedKey, TRUE);
                    }
                    continue;
                }

                int nIndex = nCount;
                if (bRequiresIndex)
                {
                    nIndex = GetLocalInt(oWp, "al_route_index");
                    if (nIndex < 0 || nIndex > AL_AREA_ROUTE_INDEX_MAX)
                    {
                        AL_AreaDebugLog(oArea, "AL: waypoint " + sTag + " has invalid al_route_index " + IntToString(nIndex) + " (allowed 0.." + IntToString(AL_AREA_ROUTE_INDEX_MAX) + "); skipped.");
                        continue;
                    }
                }

                string sIndex = sAreaPrefix + IntToString(nIndex);
                string sIndexMarker = sIndex + "_set";
                if (GetLocalInt(oArea, sIndexMarker))
                {
                    AL_AreaDebugLog(oArea, "AL: duplicate route index " + IntToString(nIndex) + " for tag " + sTag + "; skipped.");
                    continue;
                }

                SetLocalInt(oArea, sIndexMarker, TRUE);
                nCount++;

                SetLocalInt(oArea, sAreaPrefix + "seen_" + IntToString(nSeenCount), nIndex);
                nSeenCount++;

                SetLocalLocation(oArea, sIndex, GetLocation(oWp));
                int nActivity = GetLocalInt(oWp, "al_activity");
                if (nActivity > 0)
                {
                    SetLocalInt(oArea, sIndex + "_activity", nActivity);
                }
                else
                {
                    DeleteLocalInt(oArea, sIndex + "_activity");
                }

                DeleteLocalLocation(oArea, sIndex + "_jump");
                // Transition setup is pre-seeded via toolset/bootstrap:
                // - Preferred: set a local location on the waypoint: "al_transition_location".
                // - Alternative: set a local object area: "al_transition_area" + x/y/z/facing.
                // Avoid tag lookups in runtime hot paths.
                location lJump = GetLocalLocation(oWp, "al_transition_location");
                object oJumpArea = GetAreaFromLocation(lJump);
                if (GetIsObjectValid(oJumpArea))
                {
                    SetLocalLocation(oArea, sIndex + "_jump", lJump);
                }
                else
                {
                    object oTargetArea = GetLocalObject(oWp, "al_transition_area");
                    if (GetIsObjectValid(oTargetArea))
                    {
                        float fX = GetLocalFloat(oWp, "al_transition_x");
                        float fY = GetLocalFloat(oWp, "al_transition_y");
                        float fZ = GetLocalFloat(oWp, "al_transition_z");
                        float fFacing = GetLocalFloat(oWp, "al_transition_facing");
                        location lResolvedJump = Location(oTargetArea, Vector(fX, fY, fZ), fFacing);
                        SetLocalLocation(oArea, sIndex + "_jump", lResolvedJump);
                    }
                }
            }
            DeleteLocalInt(oArea, sTmpPrefix + "n");

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

            SetLocalInt(oArea, sAreaPrefix + "count", nCount);
            SetLocalInt(oArea, sAreaPrefix + "seen_n", nSeenCount);
            SetLocalInt(oArea, sAreaPrefix + "n", nDenseCount);
            SetLocalInt(oArea, sAreaPrefix + "idx_built", TRUE);
            SetLocalInt(oArea, sAreaPrefix + "gap_logged", TRUE);
            if (nCount > 0 && nCount != nDenseCount)
            {
                AL_AreaDebugLog(oArea, "AL: route tag " + sTag + " has gaps in al_route_index; using dense list.");
            }

            DeleteLocalInt(oArea, sAreaPrefix + "count_reset");
        }

        DeleteLocalString(oArea, "al_route_scan_tag_" + IntToString(iTagIndex));
        DeleteLocalInt(oArea, "al_route_scan_seen_" + sTag);
        iTagIndex++;
    }

    int iKnownTagCount = GetLocalInt(oArea, "al_route_known_n");
    int iKnownTagIndex = 0;
    while (iKnownTagIndex < iKnownTagCount)
    {
        string sKnownTag = GetLocalString(oArea, "al_route_known_tag_" + IntToString(iKnownTagIndex));
        if (sKnownTag != "" && !GetLocalInt(oArea, "al_route_rebuild_seen_" + sKnownTag))
        {
            AL_ClearAreaRouteCacheByTag(oArea, sKnownTag);
            AL_AreaDebugLog(oArea, "AL: cleared stale route tag cache " + sKnownTag + ".");
        }

        DeleteLocalString(oArea, "al_route_known_tag_" + IntToString(iKnownTagIndex));
        iKnownTagIndex++;
    }

    int iRebuildTagIndex = 0;
    while (iRebuildTagIndex < iTagCount)
    {
        string sRebuildTag = GetLocalString(oArea, "al_route_rebuild_tag_" + IntToString(iRebuildTagIndex));
        if (sRebuildTag != "")
        {
            SetLocalString(oArea, "al_route_known_tag_" + IntToString(iRebuildTagIndex), sRebuildTag);
            DeleteLocalInt(oArea, "al_route_rebuild_seen_" + sRebuildTag);
        }

        DeleteLocalString(oArea, "al_route_rebuild_tag_" + IntToString(iRebuildTagIndex));
        iRebuildTagIndex++;
    }
    SetLocalInt(oArea, "al_route_known_n", iTagCount);

    SetLocalInt(oArea, "al_routes_cached", TRUE);
}

int AL_ComputeTimeSlot()
{
    // GetTimeHour() is expected to be in the 0..23 range.
    int iSlot = GetTimeHour() / 4;
    if (iSlot > AL_SLOT_MAX)
    {
        iSlot = AL_SLOT_MAX;
    }

    return iSlot;
}

void AreaTick(object oArea, int nToken)
{
    if (GetLocalInt(oArea, "al_player_count") <= 0)
    {
        return;
    }

    if (nToken != GetLocalInt(oArea, "al_tick_token"))
    {
        return;
    }

    int iSyncTick = GetLocalInt(oArea, "al_sync_tick") + 1;
    int bSynced = FALSE;
    if (iSyncTick >= AL_SYNC_TICK_INTERVAL)
    {
        iSyncTick = 0;
        AL_SyncAreaNPCRegistry(oArea);
        bSynced = TRUE;
    }
    SetLocalInt(oArea, "al_sync_tick", iSyncTick);

    int iSlot = AL_ComputeTimeSlot();

    if (iSlot == GetLocalInt(oArea, "al_slot"))
    {
        DelayCommand(AL_TICK_PERIOD, AreaTick(oArea, nToken));
        return;
    }

    if (!bSynced)
    {
        AL_SyncAreaNPCRegistry(oArea);
    }
    SetLocalInt(oArea, "al_slot", iSlot);
    AL_BroadcastUserEvent(oArea, AL_EVT_SLOT_0 + iSlot);
    DelayCommand(AL_TICK_PERIOD, AreaTick(oArea, nToken));
}
