#include "al_constants_inc"
#include "al_acts_inc"

const int ALV_SEV_CRITICAL = 0;
const int ALV_SEV_WARNING = 1;
const int ALV_SEV_INFO = 2;
const int ALV_ROUTE_INDEX_MAX = 1023;

string ALV_SeverityName(int nSeverity)
{
    if (nSeverity == ALV_SEV_CRITICAL)
    {
        return "critical";
    }

    if (nSeverity == ALV_SEV_WARNING)
    {
        return "warning";
    }

    return "info";
}

string ALV_AreaTag(object oArea)
{
    string sTag = GetTag(oArea);
    if (sTag == "")
    {
        return "<no-area-tag>";
    }

    return sTag;
}

string ALV_ObjectTag(object oObject)
{
    string sTag = GetTag(oObject);
    if (sTag == "")
    {
        return "<no-tag>";
    }

    return sTag;
}

int ALV_IsKnownActivity(int nActivity)
{
    switch (nActivity)
    {
        case AL_ACT_NPC_HIDDEN:
        case AL_ACT_NPC_ACT_ONE:
        case AL_ACT_NPC_ACT_TWO:
        case AL_ACT_NPC_DINNER:
        case AL_ACT_NPC_MIDNIGHT_BED:
        case AL_ACT_NPC_SLEEP_BED:
        case AL_ACT_NPC_WAKE:
        case AL_ACT_NPC_AGREE:
        case AL_ACT_NPC_ANGRY:
        case AL_ACT_NPC_SAD:
        case AL_ACT_NPC_COOK:
        case AL_ACT_NPC_DANCE_FEMALE:
        case AL_ACT_NPC_DANCE_MALE:
        case AL_ACT_NPC_DRUM:
        case AL_ACT_NPC_FLUTE:
        case AL_ACT_NPC_FORGE:
        case AL_ACT_NPC_GUITAR:
        case AL_ACT_NPC_WOODSMAN:
        case AL_ACT_NPC_MEDITATE:
        case AL_ACT_NPC_POST:
        case AL_ACT_NPC_READ:
        case AL_ACT_NPC_SIT:
        case AL_ACT_NPC_SIT_DINNER:
        case AL_ACT_NPC_STAND_CHAT:
        case AL_ACT_NPC_TRAINING_ONE:
        case AL_ACT_NPC_TRAINING_TWO:
        case AL_ACT_NPC_TRAINER_PACE:
        case AL_ACT_NPC_WWP:
        case AL_ACT_NPC_CHEER:
        case AL_ACT_NPC_COOK_MULTI:
        case AL_ACT_NPC_FORGE_MULTI:
        case AL_ACT_NPC_MIDNIGHT_90:
        case AL_ACT_NPC_SLEEP_90:
        case AL_ACT_NPC_THIEF:
        case AL_ACT_NPC_THIEF2:
        case AL_ACT_NPC_ASSASSIN:
        case AL_ACT_NPC_MERCHANT_MULTI:
        case AL_ACT_NPC_KNEEL_TALK:
        case AL_ACT_NPC_BARMAID:
        case AL_ACT_NPC_BARTENDER:
        case AL_ACT_NPC_GUARD:
        case AL_ACT_LOCATE_LOOK:
        case AL_ACT_LOCATE_IDLE:
        case AL_ACT_LOCATE_SIT:
        case AL_ACT_LOCATE_KNEEL:
        case AL_ACT_LOCATE_TALK:
        case AL_ACT_LOCATE_CRAFT:
        case AL_ACT_LOCATE_MEDITATE:
        case AL_ACT_LOCATE_STEALTH:
            return TRUE;
    }

    return FALSE;
}

object ALV_FindAreaByTag(string sAreaTag)
{
    object oArea = GetFirstArea();
    while (GetIsObjectValid(oArea))
    {
        if (GetTag(oArea) == sAreaTag)
        {
            return oArea;
        }

        oArea = GetNextArea();
    }

    return OBJECT_INVALID;
}

object ALV_FindWaypointByTagInArea(object oArea, string sWaypointTag)
{
    int iNth = 0;
    object oWaypoint = GetObjectByTag(sWaypointTag, iNth);
    while (GetIsObjectValid(oWaypoint))
    {
        if (GetObjectType(oWaypoint) == OBJECT_TYPE_WAYPOINT && GetArea(oWaypoint) == oArea)
        {
            return oWaypoint;
        }

        iNth++;
        oWaypoint = GetObjectByTag(sWaypointTag, iNth);
    }

    return OBJECT_INVALID;
}

void ALV_Report(object oModule, int nSeverity, string sAreaTag, string sObjectTag, string sReason)
{
    int nCount = GetLocalInt(oModule, "alv_count_" + ALV_SeverityName(nSeverity));
    SetLocalInt(oModule, "alv_count_" + ALV_SeverityName(nSeverity), nCount + 1);

    string sLine = "[AL-VALIDATOR][" + ALV_SeverityName(nSeverity) + "] area='" + sAreaTag
        + "' object='" + sObjectTag + "' reason='" + sReason + "'";

    WriteTimestampedLogEntry(sLine);

    object oPc = GetFirstPC(FALSE);
    if (GetIsObjectValid(oPc))
    {
        SendMessageToPC(oPc, sLine);
    }
}

void ALV_ValidateNpc(object oModule, object oArea, object oNpc)
{
    int bEnabled = GetLocalInt(oNpc, AL_L_ENABLED) == 1;

    int bHasRouteSlots = FALSE;
    int nSlot = 0;
    while (nSlot <= AL_SLOT_MAX)
    {
        if (GetLocalString(oNpc, AL_LocalWaypointTag(nSlot)) != "")
        {
            bHasRouteSlots = TRUE;
            break;
        }

        nSlot++;
    }

    if (!bEnabled && !bHasRouteSlots)
    {
        return;
    }

    if (bEnabled && !bHasRouteSlots)
    {
        ALV_Report(oModule, ALV_SEV_WARNING, ALV_AreaTag(oArea), ALV_ObjectTag(oNpc),
            "al_enabled=1 set without any alwp0..alwp5 route slots");
        return;
    }

    ALV_Report(oModule, ALV_SEV_INFO, ALV_AreaTag(oArea), ALV_ObjectTag(oNpc),
        "AL-NPC marker check passed (alwp*/al_enabled contract satisfied)");
}

void ALV_ValidateWaypoint(object oModule, object oArea, object oWaypoint)
{
    string sAreaTag = ALV_AreaTag(oArea);
    string sWaypointTag = ALV_ObjectTag(oWaypoint);

    int nActivity = GetLocalInt(oWaypoint, AL_L_ACTIVITY);
    if (nActivity <= 0)
    {
        ALV_Report(oModule, ALV_SEV_CRITICAL, sAreaTag, sWaypointTag,
            "missing or non-positive al_activity on route-waypoint");
    }
    else if (!ALV_IsKnownActivity(nActivity))
    {
        ALV_Report(oModule, ALV_SEV_CRITICAL, sAreaTag, sWaypointTag,
            "unknown al_activity=" + IntToString(nActivity));
    }

    string sTransitionAreaTag = GetLocalString(oWaypoint, AL_L_TRANSITION_AREA_TAG);
    string sTransitionWaypointTag = GetLocalString(oWaypoint, AL_L_TRANSITION_WAYPOINT_TAG);
    if (sTransitionAreaTag != "")
    {
        object oTargetArea = ALV_FindAreaByTag(sTransitionAreaTag);
        if (!GetIsObjectValid(oTargetArea))
        {
            ALV_Report(oModule, ALV_SEV_CRITICAL, sAreaTag, sWaypointTag,
                "al_transition_area_tag points to missing area '" + sTransitionAreaTag + "'");
            return;
        }

        if (sTransitionWaypointTag == "")
        {
            sTransitionWaypointTag = GetTag(oWaypoint);
        }

        if (sTransitionWaypointTag == "")
        {
            ALV_Report(oModule, ALV_SEV_CRITICAL, sAreaTag, sWaypointTag,
                "transition fallback waypoint tag is empty (source waypoint has no tag)");
            return;
        }

        if (!GetIsObjectValid(ALV_FindWaypointByTagInArea(oTargetArea, sTransitionWaypointTag)))
        {
            ALV_Report(oModule, ALV_SEV_CRITICAL, sAreaTag, sWaypointTag,
                "transition target waypoint '" + sTransitionWaypointTag + "' not found in area '" + sTransitionAreaTag + "'");
        }
    }
    else if (sTransitionWaypointTag != "")
    {
        ALV_Report(oModule, ALV_SEV_WARNING, sAreaTag, sWaypointTag,
            "al_transition_waypoint_tag set without al_transition_area_tag");
    }
}

void ALV_CollectIndexedRouteData(object oModule, object oArea, object oWaypoint, int nTagListIndex)
{
    string sTag = GetTag(oWaypoint);
    if (sTag == "")
    {
        return;
    }

    string sTagSeenKey = "alv_seen_" + sTag;
    if (!GetLocalInt(oArea, sTagSeenKey))
    {
        SetLocalInt(oArea, sTagSeenKey, TRUE);
        SetLocalString(oArea, "alv_route_tag_" + IntToString(nTagListIndex), sTag);
        SetLocalInt(oArea, "alv_route_tag_n", nTagListIndex + 1);
    }

    int bHasPresenceFlag = GetLocalInt(oWaypoint, AL_L_ROUTE_INDEX_PRESENT)
        || GetLocalInt(oWaypoint, AL_L_ROUTE_INDEX_SET);
    int nRouteIndex = GetLocalInt(oWaypoint, AL_L_WP_ROUTE_INDEX);
    int bValidRouteIndex = bHasPresenceFlag && nRouteIndex >= 0 && nRouteIndex <= ALV_ROUTE_INDEX_MAX;

    if (bHasPresenceFlag && !bValidRouteIndex)
    {
        ALV_Report(oModule, ALV_SEV_CRITICAL, ALV_AreaTag(oArea), ALV_ObjectTag(oWaypoint),
            "route index presence flag set but al_route_index is outside 0..1023");
    }

    if (!bHasPresenceFlag && nRouteIndex != 0)
    {
        ALV_Report(oModule, ALV_SEV_WARNING, ALV_AreaTag(oArea), ALV_ObjectTag(oWaypoint),
            "al_route_index has non-zero value but presence flag (al_route_index_present/al_route_index_set) is missing");
    }

    string sCountKey = "alv_route_cnt_" + sTag;
    int nCount = GetLocalInt(oArea, sCountKey);
    SetLocalObject(oArea, "alv_route_obj_" + sTag + "_" + IntToString(nCount), oWaypoint);
    SetLocalInt(oArea, sCountKey, nCount + 1);

    if (bValidRouteIndex)
    {
        SetLocalInt(oArea, "alv_route_indexed_" + sTag, TRUE);
    }
}

void ALV_ValidateIndexedRoutes(object oModule, object oArea)
{
    int nTagCount = GetLocalInt(oArea, "alv_route_tag_n");
    int iTag = 0;

    while (iTag < nTagCount)
    {
        string sTag = GetLocalString(oArea, "alv_route_tag_" + IntToString(iTag));
        int bIndexedRoute = GetLocalInt(oArea, "alv_route_indexed_" + sTag);
        int nRoutePointCount = GetLocalInt(oArea, "alv_route_cnt_" + sTag);

        int iPoint = 0;
        while (iPoint < nRoutePointCount)
        {
            string sObjectKey = "alv_route_obj_" + sTag + "_" + IntToString(iPoint);
            object oWaypoint = GetLocalObject(oArea, sObjectKey);

            if (GetIsObjectValid(oWaypoint) && bIndexedRoute)
            {
                int bHasPresenceFlag = GetLocalInt(oWaypoint, AL_L_ROUTE_INDEX_PRESENT)
                    || GetLocalInt(oWaypoint, AL_L_ROUTE_INDEX_SET);
                int nRouteIndex = GetLocalInt(oWaypoint, AL_L_WP_ROUTE_INDEX);
                int bValidRouteIndex = bHasPresenceFlag && nRouteIndex >= 0 && nRouteIndex <= ALV_ROUTE_INDEX_MAX;

                if (!bValidRouteIndex)
                {
                    ALV_Report(oModule, ALV_SEV_WARNING, ALV_AreaTag(oArea), ALV_ObjectTag(oWaypoint),
                        "indexed-route is enabled for this waypoint tag, but this point has no valid index + presence flag");
                }
            }

            DeleteLocalObject(oArea, sObjectKey);
            iPoint++;
        }

        DeleteLocalString(oArea, "alv_route_tag_" + IntToString(iTag));
        DeleteLocalInt(oArea, "alv_seen_" + sTag);
        DeleteLocalInt(oArea, "alv_route_cnt_" + sTag);
        DeleteLocalInt(oArea, "alv_route_indexed_" + sTag);

        iTag++;
    }

    DeleteLocalInt(oArea, "alv_route_tag_n");
}

void ALV_ValidateArea(object oModule, object oArea)
{
    object oObject = GetFirstObjectInArea(oArea);
    int nTagListIndex = 0;

    while (GetIsObjectValid(oObject))
    {
        int nObjectType = GetObjectType(oObject);

        if (nObjectType == OBJECT_TYPE_CREATURE)
        {
            ALV_ValidateNpc(oModule, oArea, oObject);
        }
        else if (nObjectType == OBJECT_TYPE_WAYPOINT)
        {
            ALV_ValidateWaypoint(oModule, oArea, oObject);
            ALV_CollectIndexedRouteData(oModule, oArea, oObject, nTagListIndex);
            nTagListIndex = GetLocalInt(oArea, "alv_route_tag_n");
        }

        oObject = GetNextObjectInArea(oArea);
    }

    ALV_ValidateIndexedRoutes(oModule, oArea);
}

void main()
{
    object oModule = GetModule();

    DeleteLocalInt(oModule, "alv_count_critical");
    DeleteLocalInt(oModule, "alv_count_warning");
    DeleteLocalInt(oModule, "alv_count_info");

    WriteTimestampedLogEntry("[AL-VALIDATOR] Start validation");

    object oArea = GetFirstArea();
    while (GetIsObjectValid(oArea))
    {
        ALV_ValidateArea(oModule, oArea);
        oArea = GetNextArea();
    }

    int nCritical = GetLocalInt(oModule, "alv_count_critical");
    int nWarning = GetLocalInt(oModule, "alv_count_warning");
    int nInfo = GetLocalInt(oModule, "alv_count_info");
    string sSummary = "[AL-VALIDATOR] Summary: critical=" + IntToString(nCritical)
        + ", warning=" + IntToString(nWarning)
        + ", info=" + IntToString(nInfo);

    WriteTimestampedLogEntry(sSummary);

    object oPc = GetFirstPC(FALSE);
    if (GetIsObjectValid(oPc))
    {
        SendMessageToPC(oPc, sSummary);
    }
}
