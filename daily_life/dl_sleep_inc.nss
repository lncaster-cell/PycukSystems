int DL_GetNpcHomeSlot(object oNpc)
{
    int nSlot = GetLocalInt(oNpc, DL_L_NPC_HOME_SLOT);
    if (nSlot <= 0)
    {
        string sSlot = GetLocalString(oNpc, DL_L_NPC_HOME_SLOT);
        if (sSlot != "")
        {
            nSlot = StringToInt(sSlot);
        }
    }

    if (nSlot <= 0)
    {
        nSlot = 1;
    }

    return nSlot;
}
object DL_ResolveSleepApproachWaypoint(object oNpc)
{
    object oHome = DL_GetHomeArea(oNpc);
    int nSlot = DL_GetNpcHomeSlot(oNpc);
    return DL_GetAreaAnchorWaypoint(
        oNpc,
        oHome,
        "dl_anchor_sleep_approach_" + IntToString(nSlot),
        DL_L_NPC_CACHE_SLEEP_APPROACH,
        TRUE
    );
}
object DL_ResolveSleepBedWaypoint(object oNpc)
{
    object oHome = DL_GetHomeArea(oNpc);
    int nSlot = DL_GetNpcHomeSlot(oNpc);
    return DL_GetAreaAnchorWaypoint(
        oNpc,
        oHome,
        "dl_anchor_sleep_bed_" + IntToString(nSlot),
        DL_L_NPC_CACHE_SLEEP_BED,
        TRUE
    );
}
void DL_ClearSleepExecutionState(object oNpc)
{
    DeleteLocalInt(oNpc, DL_L_NPC_SLEEP_PHASE);
    DeleteLocalString(oNpc, DL_L_NPC_SLEEP_STATUS);
    DeleteLocalString(oNpc, DL_L_NPC_SLEEP_TARGET);
    DeleteLocalString(oNpc, DL_L_NPC_SLEEP_DIAGNOSTIC);
    DL_ClearTransitionExecutionState(oNpc);
}
void DL_SetSleepMissingState(object oNpc, int bInvalidArea)
{
    SetLocalInt(oNpc, DL_L_NPC_SLEEP_PHASE, DL_SLEEP_PHASE_NONE);
    SetLocalString(oNpc, DL_L_NPC_SLEEP_STATUS, "missing_waypoints");
    if (bInvalidArea)
    {
        SetLocalString(oNpc, DL_L_NPC_SLEEP_DIAGNOSTIC, "sleep_target_invalid_area");
    }
    else
    {
        DeleteLocalString(oNpc, DL_L_NPC_SLEEP_DIAGNOSTIC);
    }
    DeleteLocalString(oNpc, DL_L_NPC_SLEEP_TARGET);
    DL_ClearTransitionExecutionState(oNpc);
}
void DL_SetSleepTargetState(object oNpc, object oBed)
{
    SetLocalString(oNpc, DL_L_NPC_SLEEP_TARGET, GetTag(oBed));
    DeleteLocalString(oNpc, DL_L_NPC_SLEEP_DIAGNOSTIC);
}
void DL_QueueMoveAction(object oNpc, location lTarget, int bRun)
{
    AssignCommand(oNpc, ClearAllActions(TRUE));
    AssignCommand(oNpc, ActionMoveToLocation(lTarget, bRun));
}
void DL_QueueJumpAction(object oNpc, location lTarget)
{
    AssignCommand(oNpc, ClearAllActions(TRUE));
    AssignCommand(oNpc, ActionJumpToLocation(lTarget));
}
void DL_ExecuteSleepDirective(object oNpc)
{
    object oApproach = DL_ResolveSleepApproachWaypoint(oNpc);
    object oBed = DL_ResolveSleepBedWaypoint(oNpc);

    if (!GetIsObjectValid(oApproach) || !GetIsObjectValid(oBed))
    {
        DL_SetSleepMissingState(oNpc, FALSE);
        return;
    }

    DL_SetSleepTargetState(oNpc, oBed);
    DL_LogChatDebugEvent(
        oNpc,
        "target_sleep",
        "target dir=SLEEP area=" + GetTag(GetArea(oBed)) + " anchor=" + GetTag(oBed)
    );

    if (DL_WaypointHasTransition(oApproach))
    {
        if (DL_TryExecuteTransitionAtWaypoint(oNpc, oApproach))
        {
            return;
        }
    }

    location lApproach = GetLocation(oApproach);
    location lBed = GetLocation(oBed);
    int nPhase = GetLocalInt(oNpc, DL_L_NPC_SLEEP_PHASE);
    string sStatus = GetLocalString(oNpc, DL_L_NPC_SLEEP_STATUS);
    int bCommittedToBed = nPhase == DL_SLEEP_PHASE_JUMPING || nPhase == DL_SLEEP_PHASE_ON_BED;

    if (!bCommittedToBed && GetDistanceBetween(oNpc, oApproach) > DL_SLEEP_APPROACH_RADIUS)
    {
        if (nPhase != DL_SLEEP_PHASE_MOVING || sStatus != "moving_to_approach")
        {
            SetLocalInt(oNpc, DL_L_NPC_SLEEP_PHASE, DL_SLEEP_PHASE_MOVING);
            SetLocalString(oNpc, DL_L_NPC_SLEEP_STATUS, "moving_to_approach");
            DL_QueueMoveAction(oNpc, lApproach, TRUE);
        }
        return;
    }

    if (!bCommittedToBed)
    {
        SetLocalInt(oNpc, DL_L_NPC_SLEEP_PHASE, DL_SLEEP_PHASE_JUMPING);
        SetLocalString(oNpc, DL_L_NPC_SLEEP_STATUS, "approach_reached");
        nPhase = DL_SLEEP_PHASE_JUMPING;
        sStatus = "approach_reached";
    }

    if (DL_WaypointHasTransition(oBed))
    {
        if (DL_TryExecuteTransitionAtWaypoint(oNpc, oBed))
        {
            return;
        }
    }

    if (GetDistanceBetween(oNpc, oBed) > DL_SLEEP_BED_RADIUS)
    {
        if (nPhase != DL_SLEEP_PHASE_JUMPING || sStatus != "jumping_to_bed")
        {
            SetLocalInt(oNpc, DL_L_NPC_SLEEP_PHASE, DL_SLEEP_PHASE_JUMPING);
            SetLocalString(oNpc, DL_L_NPC_SLEEP_STATUS, "jumping_to_bed");
            DL_QueueJumpAction(oNpc, lBed);
        }
        return;
    }

    if (nPhase != DL_SLEEP_PHASE_ON_BED || sStatus != "on_bed")
    {
        DL_PlaySleepAnimation(oNpc);
    }

    DL_ClearTransitionExecutionState(oNpc);
    SetLocalInt(oNpc, DL_L_NPC_SLEEP_PHASE, DL_SLEEP_PHASE_ON_BED);
    SetLocalString(oNpc, DL_L_NPC_SLEEP_STATUS, "on_bed");
    DL_LogChatDebugEvent(oNpc, "on_bed", "on_bed anchor=" + GetTag(oBed));
}
