#ifndef DL_INTERACT_INC_NSS
#define DL_INTERACT_INC_NSS

#include "dl_const_inc"
#include "dl_override_inc"
#include "dl_resolver_inc"

void DL_SetDialogueMode(object oNPC, int nDialogueMode)
{
    SetLocalInt(oNPC, DL_L_DIALOGUE_MODE, nDialogueMode);
}

void DL_SetServiceMode(object oNPC, int nServiceMode)
{
    SetLocalInt(oNPC, DL_L_SERVICE_MODE, nServiceMode);
}

void DL_ApplyResolvedInteractionState(object oNPC, int nDirective, int nAnchorGroup, int nDialogueMode, int nServiceMode)
{
    SetLocalInt(oNPC, DL_L_DIRECTIVE, nDirective);
    SetLocalInt(oNPC, DL_L_ANCHOR_GROUP, nAnchorGroup);
    DL_SetDialogueMode(oNPC, nDialogueMode);
    DL_SetServiceMode(oNPC, nServiceMode);
}

void DL_RefreshInteractionState(object oNPC, object oArea)
{
    // Recomputes directive/anchor/dialogue/service from current resolver state.
    // Do not call after forced/manual states (for example, explicit ABSENT/UNASSIGNED),
    // because it can overwrite the manually fixed directive.
    int nDirective = DL_ResolveDirective(oNPC, oArea);
    int nOverride = DL_GetTopOverride(oNPC, oArea);

    DL_ApplyResolvedInteractionState(
        oNPC,
        nDirective,
        DL_ResolveAnchorGroup(oNPC, nDirective),
        DL_ResolveDialogueMode(oNPC, nDirective, nOverride),
        DL_ResolveServiceMode(oNPC, nDirective, nOverride)
    );
}

void DL_SetInteractionStateExplicit(object oNPC, int nDirective, int nDialogueMode, int nServiceMode)
{
    DL_ApplyResolvedInteractionState(
        oNPC,
        nDirective,
        DL_ResolveAnchorGroup(oNPC, nDirective),
        nDialogueMode,
        nServiceMode
    );
}

#endif
