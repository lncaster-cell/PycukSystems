#include "dl_all_inc"

void main()
{
    object oPC = GetPCSpeaker();
    DL_PrepareConversationState(OBJECT_SELF);
    DL_OpenConversationStore(OBJECT_SELF, oPC);
}
