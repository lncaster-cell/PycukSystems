#ifndef DL_ANCHOR_INC_NSS
#define DL_ANCHOR_INC_NSS

#include "dl_const_inc"
#include "dl_util_inc"
#include "dl_types_inc"

// Legacy compatibility include.
// New runtime entry scripts should prefer the compile-safe aggregation path via dl_all_inc.

const int DL_ANCHOR_SEARCH_MAX_INDEX = 4;

int DL_IsAnchorMarkerType(int nObjType)
{
    return nObjType == OBJECT_TYPE_WAYPOINT || nObjType == OBJECT_TYPE_PLACEABLE;
}

int DL_IsAnchorContextAllowed(object oNPC, object oPoint)
{
    // Anchor context is local-only:
    // anchor must be in the same area as NPC.
    //
    // Cross-area anchors are never allowed here (even if "close" by world coords).
    // Any explicit long-range relocation must be handled by dedicated jump/teleport flow.

    if (!GetIsObjectValid(oPoint))
    {
        return FALSE;
    }
    if (!GetIsObjectValid(oNPC))
    {
        return FALSE;
    }

    return GetArea(oNPC) == GetArea(oPoint);
}

object DL_FindAnchorByTag(object oArea, string sTag)
{
    object oObj;
    int nObjType;

    if (!GetIsObjectValid(oArea) || sTag == "")
    {
        return OBJECT_INVALID;
    }

    oObj = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oObj))
    {
        // Anchors are expected to be world markers.
        nObjType = GetObjectType(oObj);
        if (DL_IsAnchorMarkerType(nObjType) && GetTag(oObj) == sTag)
        {
            return oObj;
        }

        oObj = GetNextObjectInArea(oArea);
    }

    return OBJECT_INVALID;
}

object DL_FindFallbackAnchorPoint(object oNPC, object oArea, int nAnchorGroup)
{
    object oBase = DL_GetNpcBase(oNPC);
    object oPoint;

    if (DL_IsAreaAnchor(oBase, oArea) && DL_IsAnchorContextAllowed(oNPC, oBase))
    {
        return oBase;
    }

    oPoint = DL_FindAnchorByTag(oArea, DL_GetSpecializedAnchorTagCandidate(oNPC, DL_AG_WAIT, 1));
    if (GetIsObjectValid(oPoint) && DL_IsAnchorContextAllowed(oNPC, oPoint))
    {
        return oPoint;
    }

    oPoint = DL_FindAnchorByTag(oArea, DL_GetAreaAnchorTagCandidate(oNPC, oArea, nAnchorGroup, 1));
    if (GetIsObjectValid(oPoint) && DL_IsAnchorContextAllowed(oNPC, oPoint))
    {
        return oPoint;
    }

    return OBJECT_INVALID;
}

object DL_FindFallbackAnchorPointIgnoringPolicy(object oNPC, object oArea, int nAnchorGroup)
{
    object oBase = DL_GetNpcBase(oNPC);
    object oPoint;

    if (DL_IsAreaAnchor(oBase, oArea))
    {
        return oBase;
    }

    oPoint = DL_FindAnchorByTag(oArea, DL_GetSpecializedAnchorTagCandidate(oNPC, DL_AG_WAIT, 1));
    if (GetIsObjectValid(oPoint))
    {
        return oPoint;
    }

    oPoint = DL_FindAnchorByTag(oArea, DL_GetAreaAnchorTagCandidate(oNPC, oArea, nAnchorGroup, 1));
    if (GetIsObjectValid(oPoint))
    {
        return oPoint;
    }

    return OBJECT_INVALID;
}

object DL_FindAnchorPoint(object oNPC, object oArea, int nAnchorGroup)
{
    int i = 1;
    object oPoint;

    while (i <= DL_ANCHOR_SEARCH_MAX_INDEX)
    {
        oPoint = DL_FindAnchorByTag(oArea, DL_GetAnchorTagCandidate(oNPC, nAnchorGroup, i));
        if (GetIsObjectValid(oPoint) && DL_IsAnchorContextAllowed(oNPC, oPoint))
        {
            return oPoint;
        }

        oPoint = DL_FindAnchorByTag(oArea, DL_GetBaseAnchorTagCandidate(oNPC, nAnchorGroup, i));
        if (GetIsObjectValid(oPoint) && DL_IsAnchorContextAllowed(oNPC, oPoint))
        {
            return oPoint;
        }

        oPoint = DL_FindAnchorByTag(oArea, DL_GetSpecializedAnchorTagCandidate(oNPC, nAnchorGroup, i));
        if (GetIsObjectValid(oPoint) && DL_IsAnchorContextAllowed(oNPC, oPoint))
        {
            return oPoint;
        }

        oPoint = DL_FindAnchorByTag(oArea, DL_GetAreaAnchorTagCandidate(oNPC, oArea, nAnchorGroup, i));
        if (GetIsObjectValid(oPoint) && DL_IsAnchorContextAllowed(oNPC, oPoint))
        {
            return oPoint;
        }
        i += 1;
    }

    return DL_FindFallbackAnchorPoint(oNPC, oArea, nAnchorGroup);
}

object DL_FindAnchorPointIgnoringPolicy(object oNPC, object oArea, int nAnchorGroup)
{
    int i = 1;
    object oPoint;

    while (i <= DL_ANCHOR_SEARCH_MAX_INDEX)
    {
        oPoint = DL_FindAnchorByTag(oArea, DL_GetAnchorTagCandidate(oNPC, nAnchorGroup, i));
        if (GetIsObjectValid(oPoint))
        {
            return oPoint;
        }

        oPoint = DL_FindAnchorByTag(oArea, DL_GetBaseAnchorTagCandidate(oNPC, nAnchorGroup, i));
        if (GetIsObjectValid(oPoint))
        {
            return oPoint;
        }

        oPoint = DL_FindAnchorByTag(oArea, DL_GetSpecializedAnchorTagCandidate(oNPC, nAnchorGroup, i));
        if (GetIsObjectValid(oPoint))
        {
            return oPoint;
        }

        oPoint = DL_FindAnchorByTag(oArea, DL_GetAreaAnchorTagCandidate(oNPC, oArea, nAnchorGroup, i));
        if (GetIsObjectValid(oPoint))
        {
            return oPoint;
        }
        i += 1;
    }

    return DL_FindFallbackAnchorPointIgnoringPolicy(oNPC, oArea, nAnchorGroup);
}

#endif
