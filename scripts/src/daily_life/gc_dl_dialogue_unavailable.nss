#include "dl_dialogue_bridge_inc"

int StartingConditional()
{
    return DL_HasDialogueMode(OBJECT_SELF, DL_DLG_UNAVAILABLE);
}
