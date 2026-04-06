#pragma once

#include "daily_life/dl_const_inc"

int DL_ResolveActivityKind(object oNPC, int nDirective, int nAnchorGroup)
{
    if (nDirective == DL_DIR_SLEEP)
    {
        return DL_ACT_SLEEP;
    }
    if (nDirective == DL_DIR_WORK)
    {
        return DL_ACT_WORK;
    }
    if (nDirective == DL_DIR_SERVICE)
    {
        return DL_ACT_SERVICE_IDLE;
    }
    if (nDirective == DL_DIR_SOCIAL || nAnchorGroup == DL_AG_SOCIAL)
    {
        return DL_ACT_SOCIAL;
    }
    if (nDirective == DL_DIR_DUTY || nDirective == DL_DIR_HOLD_POST)
    {
        return DL_ACT_DUTY_IDLE;
    }
    if (nDirective == DL_DIR_HIDE_SAFE || nDirective == DL_DIR_LOCKDOWN_BASE)
    {
        return DL_ACT_HIDE;
    }
    return DL_ACT_NONE;
}

void DL_ApplyActivity(object oNPC, int nActivityKind)
{
    SetLocalInt(oNPC, DL_L_ACTIVITY_KIND, nActivityKind);
}

void DL_ApplyActivityAndMove(object oNPC, int nActivityKind, object oPoint)
{
    DL_ApplyActivity(oNPC, nActivityKind);
    AssignCommand(oNPC, ClearAllActions());
    if (GetIsObjectValid(oPoint))
    {
        AssignCommand(oNPC, ActionMoveToObject(oPoint, TRUE));
    }
}
