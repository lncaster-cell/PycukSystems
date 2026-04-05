#include "dl_dialogue_bridge_inc"

int StartingConditional()
{
    return DL_HasServiceMode(OBJECT_SELF, DL_SERVICE_LIMITED);
}
