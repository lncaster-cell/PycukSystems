#ifndef DL_MATERIALIZE_INC_NSS
#define DL_MATERIALIZE_INC_NSS

#include "dl_const_inc"
#include "dl_log_inc"
#include "dl_util_inc"
#include "dl_override_inc"
#include "dl_resolver_inc"
#include "dl_anchor_inc"
#include "dl_activity_inc"
#include "dl_interact_inc"
#include "dl_slot_handoff_inc"

int DL_ShouldInstantPlace(object oNPC, object oArea, object oPoint)
{
    if (!GetIsObjectValid(oPoint))
    {
        return FALSE;
    }
    if (GetArea(oNPC) != GetArea(oPoint))
    {
        return TRUE;
    }
    if (DL_IsAreaHot(oArea))
    {
        return GetDistanceBetween(oNPC, oPoint) > 20.0;
    }
    return TRUE;
}

void DL_ApplyInstantPlacement(object oNPC, object oPoint)
{
    if (!GetIsObjectValid(oPoint))
    {
        return;
    }
    AssignCommand(oNPC, ClearAllActions());
    AssignCommand(oNPC, ActionJumpToObject(oPoint));
}

void DL_ApplyLocalWalk(object oNPC, object oPoint)
{
    if (!GetIsObjectValid(oPoint))
    {
        return;
    }
    AssignCommand(oNPC, ClearAllActions());
    AssignCommand(oNPC, ActionMoveToObject(oPoint, TRUE));
}

void DL_ApplyPlotModeByDirective(object oNPC, int nDirective)
{
    int bShouldBePlot;
    int bWasPlot;

    bShouldBePlot = (nDirective != DL_DIR_ABSENT);
    bWasPlot = GetPlotFlag(oNPC);

    if (bWasPlot == bShouldBePlot)
    {
        return;
    }

    SetPlotFlag(oNPC, bShouldBePlot);
    if (bShouldBePlot)
    {
        DL_LogNpc(oNPC, DL_DEBUG_BASIC, "plot mode restored");
    }
    else
    {
        DL_LogNpc(oNPC, DL_DEBUG_BASIC, "plot mode disabled for ABSENT");
    }
}

void DL_HideOrMarkAbsent(object oNPC, int nDirective)
{
    SetLocalInt(oNPC, DL_L_DIRECTIVE, nDirective);
    SetLocalInt(oNPC, DL_L_ANCHOR_GROUP, DL_AG_NONE);
    DL_ApplyPlotModeByDirective(oNPC, nDirective);
}

void DL_HandleUnassignedNpc(object oNPC)
{
    string sFunctionSlotId = DL_GetFunctionSlotId(oNPC);

    AssignCommand(oNPC, ClearAllActions());
    SetLocalInt(oNPC, DL_L_DIRECTIVE, DL_DIR_UNASSIGNED);
    SetLocalInt(oNPC, DL_L_ACTIVITY_KIND, DL_ACT_NONE);
    SetLocalInt(oNPC, DL_L_ANCHOR_GROUP, DL_AG_NONE);
    DL_ApplyPlotModeByDirective(oNPC, DL_DIR_UNASSIGNED);
    DL_SetInteractionStateExplicit(oNPC, DL_DIR_UNASSIGNED, DL_DLG_UNAVAILABLE, DL_SERVICE_NONE);
    DL_RecordBaseLostEvent(oNPC, sFunctionSlotId, DL_DIR_UNASSIGNED);

    if (sFunctionSlotId != "")
    {
        DL_RequestFunctionSlotReview(sFunctionSlotId, DL_RESYNC_BASE_LOST);
    }
    else
    {
        DL_LogNpc(oNPC, DL_DEBUG_BASIC, "base lost without function slot id");
    }
}

int DL_TryRecoverBaseFromFunctionSlot(object oNPC)
{
    string sFunctionSlotId = DL_GetFunctionSlotId(oNPC);

    if (sFunctionSlotId == "")
    {
        return FALSE;
    }
    if (!DL_HasStagedFunctionSlotProfile(sFunctionSlotId))
    {
        return FALSE;
    }

    DL_ApplyAssignedSlotProfile(oNPC, sFunctionSlotId);

    if (!DL_HasBase(oNPC))
    {
        return FALSE;
    }

    DL_ClearFunctionSlotProfile(sFunctionSlotId);
    DL_LogNpc(oNPC, DL_DEBUG_BASIC, "base recovered from staged function slot profile: " + sFunctionSlotId);
    return TRUE;
}

int DL_GetPrimaryBaseAnchorGroup(object oNPC)
{
    int nFamily = DL_GetNpcFamily(oNPC);

    if (nFamily == DL_FAMILY_CRAFT)
    {
        return DL_AG_WORK;
    }
    if (nFamily == DL_FAMILY_TRADE_SERVICE)
    {
        return DL_AG_SERVICE;
    }
    if (nFamily == DL_FAMILY_LAW)
    {
        return DL_AG_DUTY;
    }
    return DL_AG_SLEEP;
}

object DL_FindProvisionalBaseAnchor(object oNPC, object oArea)
{
    int i = 1;
    int nPrimaryGroup = DL_GetPrimaryBaseAnchorGroup(oNPC);
    object oPoint;

    while (i <= 4)
    {
        oPoint = DL_FindAnchorByTag(oArea, DL_GetAreaAnchorTagCandidate(oNPC, oArea, nPrimaryGroup, i));
        if (GetIsObjectValid(oPoint))
        {
            return oPoint;
        }

        oPoint = DL_FindAnchorByTag(oArea, DL_GetAreaAnchorTagCandidate(oNPC, oArea, DL_AG_SLEEP, i));
        if (GetIsObjectValid(oPoint))
        {
            return oPoint;
        }

        oPoint = DL_FindAnchorByTag(oArea, DL_GetAreaAnchorTagCandidate(oNPC, oArea, DL_AG_WAIT, i));
        if (GetIsObjectValid(oPoint))
        {
            return oPoint;
        }
        i += 1;
    }

    return OBJECT_INVALID;
}

int DL_TryAssignProvisionalBase(object oNPC, object oArea)
{
    object oBase;

    if (!GetIsObjectValid(oArea))
    {
        return FALSE;
    }

    oBase = DL_FindProvisionalBaseAnchor(oNPC, oArea);
    if (!GetIsObjectValid(oBase))
    {
        return FALSE;
    }

    SetLocalObject(oNPC, DL_L_NPC_BASE, oBase);
    DL_LogNpc(oNPC, DL_DEBUG_BASIC, "provisional base assigned from area anchors: " + GetTag(oBase));
    return TRUE;
}

int DL_HandleBaseLost(object oNPC, object oArea)
{
    string sFunctionSlotId;

    if (DL_HasBase(oNPC))
    {
        return FALSE;
    }

    sFunctionSlotId = DL_GetFunctionSlotId(oNPC);
    if (DL_TryRecoverBaseFromFunctionSlot(oNPC))
    {
        object oModule = GetModule();
        object oLastBaseLostNpc = GetLocalObject(oModule, DL_L_LAST_BASE_LOST_NPC);
        string sLastBaseLostSlot = GetLocalString(oModule, DL_L_LAST_BASE_LOST_SLOT);

        DL_ClearBaseLostEventForNpcOrSlot(oNPC, sFunctionSlotId);

        if (oLastBaseLostNpc == oNPC || (sFunctionSlotId != "" && sLastBaseLostSlot == sFunctionSlotId))
        {
            DeleteLocalString(oModule, DL_L_LAST_BASE_LOST_SLOT);
            DeleteLocalObject(oModule, DL_L_LAST_BASE_LOST_NPC);
            DeleteLocalInt(oModule, DL_L_LAST_BASE_LOST_KIND);
        }
        return FALSE;
    }
    if (DL_TryAssignProvisionalBase(oNPC, oArea))
    {
        return FALSE;
    }

    DL_LogNpc(oNPC, DL_DEBUG_BASIC, "base lost, applying handoff fallback");
    if (DL_IsNamed(oNPC) || DL_IsPersistent(oNPC))
    {
        if (sFunctionSlotId != "")
        {
            DL_RequestFunctionSlotReview(sFunctionSlotId, DL_RESYNC_BASE_LOST);
        }
        DL_HideOrMarkAbsent(oNPC, DL_DIR_ABSENT);
        DL_SetInteractionStateExplicit(oNPC, DL_DIR_ABSENT, DL_DLG_UNAVAILABLE, DL_SERVICE_NONE);
        DL_RecordBaseLostEvent(oNPC, sFunctionSlotId, DL_DIR_ABSENT);
        DL_LogNpc(oNPC, DL_DEBUG_BASIC, "base lost branch=ABSENT");
        return TRUE;
    }

    DL_HandleUnassignedNpc(oNPC);
    DL_LogNpc(oNPC, DL_DEBUG_BASIC, "base lost branch=UNASSIGNED");
    return TRUE;
}

void DL_MaterializeNpc(object oNPC, object oArea)
{
    int nDirective;
    int nOverride;
    int nAnchorGroup;
    object oPoint;
    object oPolicyFilteredAnchor;

    if (DL_HandleBaseLost(oNPC, oArea))
    {
        return;
    }

    nDirective = DL_ResolveDirective(oNPC, oArea);
    nOverride = DL_GetTopOverride(oNPC, oArea);
    nAnchorGroup = DL_ResolveAnchorGroup(oNPC, nDirective);

    SetLocalInt(oNPC, DL_L_DIRECTIVE, nDirective);
    SetLocalInt(oNPC, DL_L_ANCHOR_GROUP, nAnchorGroup);
    DL_ApplyPlotModeByDirective(oNPC, nDirective);

    if (!DL_IsDirectiveVisible(nDirective) || DL_ShouldSuppressMaterialization(oNPC, nOverride))
    {
        DL_HideOrMarkAbsent(oNPC, nDirective);
        if (nDirective == DL_DIR_ABSENT || nDirective == DL_DIR_UNASSIGNED)
        {
            DL_SetInteractionStateExplicit(oNPC, nDirective, DL_DLG_UNAVAILABLE, DL_SERVICE_NONE);
            return;
        }
        DL_RefreshInteractionState(oNPC, oArea);
        return;
    }

    oPoint = DL_FindAnchorPoint(oNPC, oArea, nAnchorGroup);
    if (!GetIsObjectValid(oPoint))
    {
        oPolicyFilteredAnchor = DL_FindAnchorPointIgnoringPolicy(oNPC, oArea, nAnchorGroup);
        if (GetIsObjectValid(oPolicyFilteredAnchor))
        {
            DL_LogNpc(
                oNPC,
                DL_DEBUG_BASIC,
                "anchor filtered by policy, marking absent: " + GetTag(oPolicyFilteredAnchor)
            );
        }
        else
        {
            DL_LogNpc(oNPC, DL_DEBUG_BASIC, "anchor not found, marking absent");
        }
        DL_HideOrMarkAbsent(oNPC, DL_DIR_ABSENT);
        DL_SetInteractionStateExplicit(oNPC, DL_DIR_ABSENT, DL_DLG_UNAVAILABLE, DL_SERVICE_NONE);
        return;
    }

    if (GetArea(oNPC) != GetArea(oPoint))
    {
        DL_LogNpc(oNPC, DL_DEBUG_BASIC, "cross-area jump to anchor: " + GetTag(oPoint));
    }

    if (DL_ShouldInstantPlace(oNPC, oArea, oPoint))
    {
        DL_ApplyInstantPlacement(oNPC, oPoint);
    }
    else
    {
        DL_ApplyLocalWalk(oNPC, oPoint);
    }

    DL_ApplyActivity(oNPC, DL_ResolveActivityKind(oNPC, nDirective, nAnchorGroup));
    DL_RefreshInteractionState(oNPC, oArea);
}

#endif
