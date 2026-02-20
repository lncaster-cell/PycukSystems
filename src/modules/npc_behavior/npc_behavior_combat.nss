// NPC behavior module: combat state synchronizer (Phase 1 MVP)

const int NPC_STATE_ALERT = 1;
const int NPC_STATE_COMBAT = 2;

string NPC_VAR_STATE = "npc_state";

void main()
{
    object oNpc = OBJECT_SELF;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    if (GetIsInCombat(oNpc))
    {
        SetLocalInt(oNpc, NPC_VAR_STATE, NPC_STATE_COMBAT);
    }
    else if (GetLocalInt(oNpc, NPC_VAR_STATE) == NPC_STATE_COMBAT)
    {
        SetLocalInt(oNpc, NPC_VAR_STATE, NPC_STATE_ALERT);
    }
}
