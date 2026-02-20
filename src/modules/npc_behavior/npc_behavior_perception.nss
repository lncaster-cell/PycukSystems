// NPC behavior module: perception event handler (Phase 1 MVP)

const int NPC_STATE_IDLE = 0;
const int NPC_STATE_ALERT = 1;
const int NPC_STATE_COMBAT = 2;

string NPC_VAR_STATE = "npc_state";
string NPC_VAR_DEFERRED_EVENTS = "npc_deferred_events";

void main()
{
    object oNpc = OBJECT_SELF;
    object oSeen = GetLastPerceived();

    if (!GetIsObjectValid(oSeen) || !GetIsObjectValid(oNpc))
    {
        return;
    }

    if (GetIsReactionTypeHostile(oSeen, oNpc))
    {
        SetLocalInt(oNpc, NPC_VAR_STATE, NPC_STATE_COMBAT);
        return;
    }

    if (GetLocalInt(oNpc, NPC_VAR_STATE) == NPC_STATE_IDLE)
    {
        SetLocalInt(oNpc, NPC_VAR_STATE, NPC_STATE_ALERT);
    }
    else
    {
        // Простейшая форма deferred/coalesce: повторяющийся сигнал просто считаем метрикой.
        SetLocalInt(oNpc, NPC_VAR_DEFERRED_EVENTS, GetLocalInt(oNpc, NPC_VAR_DEFERRED_EVENTS) + 1);
    }
}
