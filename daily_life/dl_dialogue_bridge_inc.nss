#ifndef DL_DIALOGUE_BRIDGE_INC_NSS
#define DL_DIALOGUE_BRIDGE_INC_NSS

#include "dl_const_inc"
#include "dl_util_inc"
#include "dl_types_inc"
#include "dl_interact_inc"
#include "dl_log_inc"

const string DL_L_CONV_STORE_OBJECT = "dl_conv_store_object";
const string DL_L_CONV_STORE_TAG = "dl_conv_store_tag";
const string DL_L_CONV_STORE_AREA_TAGS = "dl_conv_store_area_tags";
const string DL_L_CONV_STORE_MARKUP = "dl_conv_store_markup";
const string DL_L_CONV_STORE_MARKDOWN = "dl_conv_store_markdown";

int DL_ShouldSkipConversationPrepare(object oNPC)
{
    int nDirective;

    if (!DL_IsValidCreature(oNPC) || !DL_IsDailyLifeNpc(oNPC))
    {
        return TRUE;
    }

    nDirective = GetLocalInt(oNPC, DL_L_DIRECTIVE);
    return nDirective == DL_DIR_ABSENT || nDirective == DL_DIR_UNASSIGNED;
}

int DL_PrepareConversationState(object oNPC)
{
    object oArea;

    if (DL_ShouldSkipConversationPrepare(oNPC))
    {
        return FALSE;
    }

    oArea = GetArea(oNPC);
    if (!GetIsObjectValid(oArea))
    {
        return FALSE;
    }

    DL_RefreshInteractionState(oNPC, oArea);
    return TRUE;
}

void DL_FinalizeConversationState(object oNPC)
{
    if (DL_ShouldSkipConversationPrepare(oNPC))
    {
        return;
    }

    if (GetIsObjectValid(GetArea(oNPC)))
    {
        DL_RefreshInteractionState(oNPC, GetArea(oNPC));
    }
}

int DL_IsConversationAvailable(object oNPC)
{
    int nDirective;

    if (!DL_IsValidCreature(oNPC))
    {
        return FALSE;
    }
    if (!DL_IsDailyLifeNpc(oNPC))
    {
        return TRUE;
    }

    nDirective = GetLocalInt(oNPC, DL_L_DIRECTIVE);
    return nDirective != DL_DIR_ABSENT && nDirective != DL_DIR_UNASSIGNED;
}

int DL_HasDialogueMode(object oNPC, int nDialogueMode)
{
    if (!DL_IsValidCreature(oNPC) || !DL_IsDailyLifeNpc(oNPC))
    {
        return FALSE;
    }
    return GetLocalInt(oNPC, DL_L_DIALOGUE_MODE) == nDialogueMode;
}

int DL_HasServiceMode(object oNPC, int nServiceMode)
{
    if (!DL_IsValidCreature(oNPC) || !DL_IsDailyLifeNpc(oNPC))
    {
        return FALSE;
    }
    return GetLocalInt(oNPC, DL_L_SERVICE_MODE) == nServiceMode;
}

int DL_CanOpenConversationStore(object oNPC)
{
    int nServiceMode;

    if (!DL_IsValidCreature(oNPC) || !DL_IsDailyLifeNpc(oNPC))
    {
        return FALSE;
    }

    nServiceMode = GetLocalInt(oNPC, DL_L_SERVICE_MODE);
    return nServiceMode == DL_SERVICE_AVAILABLE || nServiceMode == DL_SERVICE_LIMITED;
}

int DL_IsConversationStoreCandidate(object oStore, string sStoreTag)
{
    if (!GetIsObjectValid(oStore))
    {
        return FALSE;
    }
    if (GetObjectType(oStore) != OBJECT_TYPE_STORE)
    {
        return FALSE;
    }
    return GetTag(oStore) == sStoreTag;
}

int DL_IsConversationStoreSearchArea(object oArea)
{
    return GetIsObjectValid(oArea);
}

void DL_LogConversationStoreAreaConflict(object oNPC, object oArea, string sStoreTag)
{
    DL_LogNpc(
        oNPC,
        DL_DEBUG_BASIC,
        "conversation store tag conflict in area: area_tag=" + GetTag(oArea) + ", store_tag=" + sStoreTag
    );
}

void DL_LogConversationStoreSearchConflict(object oNPC, string sStoreTag)
{
    DL_LogNpc(
        oNPC,
        DL_DEBUG_BASIC,
        "conversation store tag conflict across search context: store_tag=" + sStoreTag
    );
}

void DL_LogConversationStoreCacheTagMismatch(object oNPC, object oStore, string sStoreTag)
{
    DL_LogNpc(
        oNPC,
        DL_DEBUG_BASIC,
        "conversation store cache rejected due to tag mismatch: expected_tag=" + sStoreTag + ", cached_store_tag=" + GetTag(oStore)
    );
}

int DL_CountConversationStoresInArea(object oArea, string sStoreTag)
{
    object oObject;
    int nMatchCount = 0;

    if (!DL_IsConversationStoreSearchArea(oArea))
    {
        return 0;
    }

    oObject = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oObject))
    {
        if (DL_IsConversationStoreCandidate(oObject, sStoreTag))
        {
            nMatchCount += 1;
        }

        oObject = GetNextObjectInArea(oArea);
    }

    return nMatchCount;
}

object DL_FindConversationStoreInArea(object oArea, string sStoreTag)
{
    object oObject;

    if (!DL_IsConversationStoreSearchArea(oArea))
    {
        return OBJECT_INVALID;
    }

    oObject = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oObject))
    {
        if (DL_IsConversationStoreCandidate(oObject, sStoreTag))
        {
            return oObject;
        }
        oObject = GetNextObjectInArea(oArea);
    }

    return OBJECT_INVALID;
}

object DL_GetConversationStore(object oNPC)
{
    object oStore = GetLocalObject(oNPC, DL_L_CONV_STORE_OBJECT);
    object oArea;
    object oNpcArea;
    object oCandidate;
    string sAreaTags;
    string sStoreTag;
    string sAreaTag;
    int nOffset = 0;
    int nSepPos;
    int nListLen;
    int nAreaIndex;
    int nAreaMatches;
    int nTotalMatches = 0;

    sStoreTag = GetLocalString(oNPC, DL_L_CONV_STORE_TAG);
    if (sStoreTag == "")
    {
        return OBJECT_INVALID;
    }

    if (DL_IsConversationStoreCandidate(oStore, sStoreTag))
    {
        return oStore;
    }
    if (GetIsObjectValid(oStore) && GetObjectType(oStore) == OBJECT_TYPE_STORE)
    {
        DL_LogConversationStoreCacheTagMismatch(oNPC, oStore, sStoreTag);
    }

    oNpcArea = GetArea(oNPC);
    nAreaMatches = DL_CountConversationStoresInArea(oNpcArea, sStoreTag);
    if (nAreaMatches > 1)
    {
        DL_LogConversationStoreAreaConflict(oNPC, oNpcArea, sStoreTag);
        return OBJECT_INVALID;
    }
    if (nAreaMatches == 1)
    {
        oCandidate = DL_FindConversationStoreInArea(oNpcArea, sStoreTag);
        nTotalMatches += 1;
    }

    sAreaTags = GetLocalString(oNPC, DL_L_CONV_STORE_AREA_TAGS);
    nListLen = GetStringLength(sAreaTags);
    while (nOffset < nListLen)
    {
        nSepPos = FindSubString(sAreaTags, ";", nOffset);
        if (nSepPos < 0)
        {
            sAreaTag = GetSubString(sAreaTags, nOffset, nListLen - nOffset);
            nOffset = nListLen;
        }
        else
        {
            sAreaTag = GetSubString(sAreaTags, nOffset, nSepPos - nOffset);
            nOffset = nSepPos + 1;
        }

        if (sAreaTag == "")
        {
            continue;
        }

        nAreaIndex = 0;
        oArea = GetObjectByTag(sAreaTag, nAreaIndex);
        while (GetIsObjectValid(oArea))
        {
            if (oArea == oNpcArea)
            {
                nAreaIndex += 1;
                oArea = GetObjectByTag(sAreaTag, nAreaIndex);
                continue;
            }

            if (DL_IsConversationStoreSearchArea(oArea))
            {
                nAreaMatches = DL_CountConversationStoresInArea(oArea, sStoreTag);
                if (nAreaMatches > 1)
                {
                    DL_LogConversationStoreAreaConflict(oNPC, oArea, sStoreTag);
                    return OBJECT_INVALID;
                }
                if (nAreaMatches == 1)
                {
                    oCandidate = DL_FindConversationStoreInArea(oArea, sStoreTag);
                    nTotalMatches += 1;
                }
            }

            nAreaIndex += 1;
            oArea = GetObjectByTag(sAreaTag, nAreaIndex);
        }
    }

    if (nTotalMatches > 1)
    {
        DL_LogConversationStoreSearchConflict(oNPC, sStoreTag);
        return OBJECT_INVALID;
    }

    if (nTotalMatches == 1 && GetIsObjectValid(oCandidate))
    {
        return oCandidate;
    }

    return OBJECT_INVALID;
}

int DL_OpenConversationStore(object oNPC, object oPC)
{
    object oStore;
    int nMarkup;
    int nMarkdown;
    string sStoreTag;
    string sResolvedStoreTag;

    if (!GetIsObjectValid(oPC) || !DL_CanOpenConversationStore(oNPC))
    {
        return FALSE;
    }

    oStore = DL_GetConversationStore(oNPC);
    sStoreTag = GetLocalString(oNPC, DL_L_CONV_STORE_TAG);
    if (!GetIsObjectValid(oStore))
    {
        DL_LogNpc(oNPC, DL_DEBUG_BASIC, "conversation store missing or invalid");
        return FALSE;
    }

    sResolvedStoreTag = GetTag(oStore);
    DL_LogNpc(
        oNPC,
        DL_DEBUG_BASIC,
        "open conversation store: npc_tag=" + GetTag(oNPC) + ", store_tag=" + sStoreTag + ", resolved_store_tag=" + sResolvedStoreTag
    );

    nMarkup = GetLocalInt(oNPC, DL_L_CONV_STORE_MARKUP);
    nMarkdown = GetLocalInt(oNPC, DL_L_CONV_STORE_MARKDOWN);
    OpenStore(oStore, oPC, nMarkup, nMarkdown);
    return TRUE;
}

#endif
