#include "al_constants_inc"
#include "al_npc_reg_inc"

// Shared Area tick helper: scheduled every 45s while players are present.
// NPC registry synchronization is handled here at the area level only.

const float AL_TICK_PERIOD = 45.0;
const int AL_SYNC_TICK_INTERVAL = 4;

void AL_AreaDebugLog(object oArea, string sMessage)
{
    if (!GetIsObjectValid(oArea) || GetLocalInt(oArea, "al_debug") != 1)
    {
        return;
    }

    object oPc = GetFirstPC();
    while (GetIsObjectValid(oPc))
    {
        if (GetArea(oPc) == oArea)
        {
            SendMessageToPC(oPc, sMessage);
        }

        oPc = GetNextPC();
    }
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

    object oResetObj = GetFirstObjectInArea(oArea);
    int iResetCount = 0;
    while (GetIsObjectValid(oResetObj))
    {
        if (GetObjectType(oResetObj) == OBJECT_TYPE_WAYPOINT)
        {
            string sResetTag = GetTag(oResetObj);
            if (sResetTag != "")
            {
                string sResetFlag = "al_route_reset_" + sResetTag;
                if (!GetLocalInt(oArea, sResetFlag))
                {
                    SetLocalInt(oArea, sResetFlag, TRUE);
                    SetLocalString(oArea, "al_route_reset_tag_" + IntToString(iResetCount), sResetTag);
                    iResetCount++;

                    string sResetPrefix = "al_route_" + sResetTag + "_";
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
                    DeleteLocalInt(oArea, sResetPrefix + "idx_built");
                    DeleteLocalInt(oArea, sResetPrefix + "has_index");
                }

                if (GetLocalInt(oResetObj, "al_route_index_set"))
                {
                    SetLocalInt(oArea, "al_route_" + sResetTag + "_has_index", TRUE);
                }
            }
        }

        oResetObj = GetNextObjectInArea(oArea);
    }

    object oObj = GetFirstObjectInArea(oArea);

    while (GetIsObjectValid(oObj))
    {
        if (GetObjectType(oObj) == OBJECT_TYPE_WAYPOINT)
        {
            string sTag = GetTag(oObj);
            if (sTag != "")
            {
                string sAreaPrefix = "al_route_" + sTag + "_";
                string sCountResetKey = sAreaPrefix + "count_reset";
                int bRequiresIndex = GetLocalInt(oArea, sAreaPrefix + "has_index");
                if (!GetLocalInt(oArea, sCountResetKey))
                {
                    SetLocalInt(oArea, sAreaPrefix + "count", 0);
                    SetLocalInt(oArea, sCountResetKey, TRUE);
                }

                if (bRequiresIndex && !GetLocalInt(oObj, "al_route_index_set"))
                {
                    AL_AreaDebugLog(oArea, "AL: waypoint " + sTag + " missing al_route_index; skipped.");
                    oObj = GetNextObjectInArea(oArea);
                    continue;
                }

                int nIndex = GetLocalInt(oArea, sAreaPrefix + "count");
                if (bRequiresIndex)
                {
                    nIndex = GetLocalInt(oObj, "al_route_index");
                }
                string sIndex = sAreaPrefix + IntToString(nIndex);
                string sIndexMarker = sIndex + "_set";
                if (GetLocalInt(oArea, sIndexMarker))
                {
                    AL_AreaDebugLog(oArea, "AL: duplicate route index " + IntToString(nIndex) + " for tag " + sTag + "; skipped.");
                    oObj = GetNextObjectInArea(oArea);
                    continue;
                }
                SetLocalInt(oArea, sIndexMarker, TRUE);
                SetLocalInt(oArea, sAreaPrefix + "count", GetLocalInt(oArea, sAreaPrefix + "count") + 1);

                int nSeenCount = GetLocalInt(oArea, sAreaPrefix + "seen_n");
                SetLocalInt(oArea, sAreaPrefix + "seen_" + IntToString(nSeenCount), nIndex);
                SetLocalInt(oArea, sAreaPrefix + "seen_n", nSeenCount + 1);

                SetLocalLocation(oArea, sIndex, GetLocation(oObj));
                int nActivity = GetLocalInt(oObj, "al_activity");
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
                location lJump = GetLocalLocation(oObj, "al_transition_location");
                object oJumpArea = GetAreaFromLocation(lJump);
                if (GetIsObjectValid(oJumpArea))
                {
                    SetLocalLocation(oArea, sIndex + "_jump", lJump);
                }
                else
                {
                    object oTargetArea = GetLocalObject(oObj, "al_transition_area");
                    if (GetIsObjectValid(oTargetArea))
                    {
                        float fX = GetLocalFloat(oObj, "al_transition_x");
                        float fY = GetLocalFloat(oObj, "al_transition_y");
                        float fZ = GetLocalFloat(oObj, "al_transition_z");
                        float fFacing = GetLocalFloat(oObj, "al_transition_facing");
                        location lResolvedJump = Location(oTargetArea, Vector(fX, fY, fZ), fFacing);
                        SetLocalLocation(oArea, sIndex + "_jump", lResolvedJump);
                    }
                }

            }
        }

        oObj = GetNextObjectInArea(oArea);
    }

    oObj = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oObj))
    {
        if (GetObjectType(oObj) == OBJECT_TYPE_WAYPOINT)
        {
            string sTag = GetTag(oObj);
            if (sTag != "")
            {
                string sAreaPrefix = "al_route_" + sTag + "_";
                string sGapLoggedKey = sAreaPrefix + "gap_logged";
                if (!GetLocalInt(oArea, sGapLoggedKey))
                {
                    int nCount = GetLocalInt(oArea, sAreaPrefix + "count");
                    int nDenseCount = 0;
                    int nSeenCount = GetLocalInt(oArea, sAreaPrefix + "seen_n");
                    int iSeen = 0;
                    // Dense index follows waypoint discovery order from the area scan.
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
                    SetLocalInt(oArea, sAreaPrefix + "n", nDenseCount);
                    SetLocalInt(oArea, sAreaPrefix + "idx_built", TRUE);
                    if (nCount > 0 && nCount != nDenseCount)
                    {
                        AL_AreaDebugLog(oArea, "AL: route tag " + sTag + " has gaps in al_route_index; using dense list.");
                    }
                    SetLocalInt(oArea, sGapLoggedKey, TRUE);
                }
                DeleteLocalInt(oArea, sAreaPrefix + "count_reset");
            }
        }

        oObj = GetNextObjectInArea(oArea);
    }

    int iResetCleanupIndex = 0;
    while (iResetCleanupIndex < iResetCount)
    {
        string sCleanupTag = GetLocalString(oArea, "al_route_reset_tag_" + IntToString(iResetCleanupIndex));
        if (sCleanupTag != "")
        {
            DeleteLocalInt(oArea, "al_route_reset_" + sCleanupTag);
        }
        DeleteLocalString(oArea, "al_route_reset_tag_" + IntToString(iResetCleanupIndex));
        iResetCleanupIndex++;
    }

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
