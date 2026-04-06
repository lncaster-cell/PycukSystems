#pragma once

#include "daily_life/dl_const_inc"

int DL_IsValidCreature(object oNPC)
{
    return GetIsObjectValid(oNPC) && GetObjectType(oNPC) == OBJECT_TYPE_CREATURE;
}

int DL_IsAreaHot(object oArea)
{
    return GetLocalInt(oArea, DL_L_AREA_TIER) == DL_AREA_HOT;
}

int DL_IsAreaWarm(object oArea)
{
    return GetLocalInt(oArea, DL_L_AREA_TIER) == DL_AREA_WARM;
}

int DL_IsAreaFrozen(object oArea)
{
    return GetLocalInt(oArea, DL_L_AREA_TIER) == DL_AREA_FROZEN;
}

int DL_IsDirectiveVisible(int nDirective)
{
    return nDirective != DL_DIR_ABSENT
        && nDirective != DL_DIR_HIDE_SAFE
        && nDirective != DL_DIR_UNASSIGNED;
}

int DL_HasAnyPlayers(object oArea)
{
    object oObject = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oObject))
    {
        if (GetIsPC(oObject) && !GetIsDM(oObject))
        {
            return TRUE;
        }
        oObject = GetNextObjectInArea(oArea);
    }
    return FALSE;
}

int DL_HasAnyPlayersExcept(object oArea, object oIgnored)
{
    object oObject = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oObject))
    {
        if (oObject != oIgnored && GetIsPC(oObject) && !GetIsDM(oObject))
        {
            return TRUE;
        }
        oObject = GetNextObjectInArea(oArea);
    }
    return FALSE;
}

int DL_IsAreaAnchor(object oPoint, object oArea)
{
    return GetIsObjectValid(oPoint) && GetArea(oPoint) == oArea;
}

string DL_GetAnchorGroupToken(int nAnchorGroup)
{
    if (nAnchorGroup == DL_AG_SLEEP)
    {
        return "sleep";
    }
    if (nAnchorGroup == DL_AG_WORK)
    {
        return "work";
    }
    if (nAnchorGroup == DL_AG_SERVICE)
    {
        return "service";
    }
    if (nAnchorGroup == DL_AG_SOCIAL)
    {
        return "social";
    }
    if (nAnchorGroup == DL_AG_DUTY)
    {
        return "duty";
    }
    if (nAnchorGroup == DL_AG_GATE)
    {
        return "gate";
    }
    if (nAnchorGroup == DL_AG_PATROL_POINT)
    {
        return "patrol";
    }
    if (nAnchorGroup == DL_AG_STREET_NEAR_BASE)
    {
        return "street";
    }
    if (nAnchorGroup == DL_AG_WAIT)
    {
        return "wait";
    }
    if (nAnchorGroup == DL_AG_HIDE)
    {
        return "hide";
    }
    return "none";
}

string DL_GetSubtypeAnchorToken(object oNPC, int nAnchorGroup)
{
    int nSubtype = GetLocalInt(oNPC, DL_L_NPC_SUBTYPE);

    if (nSubtype == DL_SUBTYPE_BLACKSMITH)
    {
        if (nAnchorGroup == DL_AG_WORK)
        {
            return "forge";
        }
        if (nAnchorGroup == DL_AG_SLEEP)
        {
            return "bed";
        }
        if (nAnchorGroup == DL_AG_SOCIAL)
        {
            return "tavern";
        }
    }
    if (nSubtype == DL_SUBTYPE_ARTISAN || nSubtype == DL_SUBTYPE_LABORER)
    {
        if (nAnchorGroup == DL_AG_WORK)
        {
            return "workbench";
        }
    }
    if (nSubtype == DL_SUBTYPE_SHOPKEEPER)
    {
        if (nAnchorGroup == DL_AG_SERVICE)
        {
            return "counter";
        }
    }
    if (nSubtype == DL_SUBTYPE_INNKEEPER)
    {
        if (nAnchorGroup == DL_AG_SERVICE)
        {
            return "bar";
        }
        if (nAnchorGroup == DL_AG_SOCIAL)
        {
            return "tavern";
        }
    }
    if (nSubtype == DL_SUBTYPE_GATE_POST)
    {
        if (nAnchorGroup == DL_AG_DUTY || nAnchorGroup == DL_AG_GATE)
        {
            return "gate_post";
        }
        if (nAnchorGroup == DL_AG_SLEEP)
        {
            return "barracks_bed";
        }
    }
    if (nSubtype == DL_SUBTYPE_PATROL)
    {
        if (nAnchorGroup == DL_AG_DUTY || nAnchorGroup == DL_AG_PATROL_POINT)
        {
            return "patrol_point";
        }
    }
    if (nAnchorGroup == DL_AG_STREET_NEAR_BASE)
    {
        return "street";
    }
    if (nAnchorGroup == DL_AG_HIDE)
    {
        return "inside";
    }
    return DL_GetAnchorGroupToken(nAnchorGroup);
}

string DL_GetAnchorTagCandidate(object oNPC, int nAnchorGroup, int nIndex)
{
    string sNpcTag = GetTag(oNPC);
    string sGroup = DL_GetAnchorGroupToken(nAnchorGroup);
    return sNpcTag + "_" + sGroup + "_" + IntToString(nIndex);
}

string DL_GetBaseAnchorTagCandidate(object oNPC, int nAnchorGroup, int nIndex)
{
    object oBase = GetLocalObject(oNPC, DL_L_NPC_BASE);
    if (!GetIsObjectValid(oBase))
    {
        return "";
    }
    return GetTag(oBase) + "_" + DL_GetAnchorGroupToken(nAnchorGroup) + "_" + IntToString(nIndex);
}

string DL_GetSpecializedAnchorTagCandidate(object oNPC, int nAnchorGroup, int nIndex)
{
    object oBase = GetLocalObject(oNPC, DL_L_NPC_BASE);
    string sToken = DL_GetSubtypeAnchorToken(oNPC, nAnchorGroup);
    if (sToken == "")
    {
        return "";
    }
    if (GetIsObjectValid(oBase))
    {
        return GetTag(oBase) + "_" + sToken + "_" + IntToString(nIndex);
    }
    return sToken + "_" + IntToString(nIndex);
}

string DL_GetAreaAnchorTagCandidate(object oNPC, object oArea, int nAnchorGroup, int nIndex)
{
    if (!GetIsObjectValid(oArea))
    {
        return "";
    }
    return GetTag(oArea) + "_" + DL_GetSubtypeAnchorToken(oNPC, nAnchorGroup) + "_" + IntToString(nIndex);
}
