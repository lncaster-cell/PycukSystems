// NPC behavior module: shared constants and handlers for event hooks.

const int NPC_STATE_IDLE = 0;
const int NPC_STATE_ALERT = 1;
const int NPC_STATE_COMBAT = 2;

const int NPC_DEFAULT_IDLE_INTERVAL = 6;
const int NPC_DEFAULT_COMBAT_INTERVAL = 2;
const int NPC_TICK_PROCESS_LIMIT = 32;

string NPC_VAR_STATE = "npc_state";
string NPC_VAR_LAST_TICK = "npc_last_tick";
string NPC_VAR_PROCESSED_TICK = "npc_processed_in_tick";
string NPC_VAR_DEFERRED_EVENTS = "npc_deferred_events";

// Флаги/параметры поведения: их можно заполнять на OnSpawn
// из шаблонов NPC или выставлять вручную в тулчете/скриптах инициализации.
string NPC_VAR_FLAG_DECAYS = "npc_flag_decays";
string NPC_VAR_FLAG_RESURRECTABLE = "npc_flag_resurrectable";
string NPC_VAR_FLAG_SELECTABLE_WHEN_DEAD = "npc_flag_selectable_when_dead";
string NPC_VAR_FLAG_SPIRIT_OVERRIDE = "npc_flag_spirit_override";
string NPC_VAR_FLAG_IMMORTAL = "npc_flag_immortal";
string NPC_VAR_FLAG_ALWAYS_SEEN = "npc_flag_always_seen";
string NPC_VAR_FLAG_DIALOG_INTERRUPTIBLE = "npc_flag_dialog_interruptible";
string NPC_VAR_FLAG_CAN_TALK_TO_CREATURES = "npc_flag_can_talk_to_creatures";
string NPC_VAR_FLAG_DISABLE_AI_WHEN_HIDDEN = "npc_flag_disable_ai_when_hidden";
string NPC_VAR_FLAG_PLOT = "npc_flag_plot";
string NPC_VAR_FLAG_LOOTABLE_CORPSE = "npc_flag_lootable_corpse";
string NPC_VAR_FLAG_DISABLE_OBJECT = "npc_flag_disable_object";
string NPC_VAR_RUNTIME_HIDDEN = "npc_runtime_hidden";

string NPC_VAR_DECAY_TIME_SEC = "npc_decay_time_sec";
string NPC_VAR_PERCEPTION_RANGE = "npc_perception_range";
string NPC_VAR_WALK_SPEED = "npc_walk_speed";
string NPC_VAR_SOUNDSET = "npc_soundset";

string NPC_VAR_METRIC_SPAWN = "npc_metric_spawn_count";
string NPC_VAR_METRIC_PERCEPTION = "npc_metric_perception_count";
string NPC_VAR_METRIC_DAMAGED = "npc_metric_damaged_count";
string NPC_VAR_METRIC_DEATH = "npc_metric_death_count";
string NPC_VAR_METRIC_DIALOG = "npc_metric_dialog_count";

int NpcBehaviorTickNow()
{
    return GetTimeHour() * 3600 + GetTimeMinute() * 60 + GetTimeSecond();
}

int NpcBehaviorGetInterval(object oNpc)
{
    if (GetLocalInt(oNpc, NPC_VAR_STATE) == NPC_STATE_COMBAT)
    {
        return NPC_DEFAULT_COMBAT_INTERVAL;
    }

    return NPC_DEFAULT_IDLE_INTERVAL;
}

int NpcBehaviorShouldProcess(object oNpc, int nNow)
{
    int nLastTick = GetLocalInt(oNpc, NPC_VAR_LAST_TICK);
    int nInterval = NpcBehaviorGetInterval(oNpc);

    if (nLastTick == 0)
    {
        return TRUE;
    }

    return ((nNow - nLastTick) >= nInterval);
}

int NpcBehaviorIsDisabled(object oNpc)
{
    if (GetLocalInt(oNpc, NPC_VAR_FLAG_DISABLE_OBJECT) == TRUE)
    {
        return TRUE;
    }

    if (GetLocalInt(oNpc, NPC_VAR_FLAG_DISABLE_AI_WHEN_HIDDEN) == TRUE && GetLocalInt(oNpc, NPC_VAR_RUNTIME_HIDDEN) == TRUE)
    {
        return TRUE;
    }

    return FALSE;
}

void NpcBehaviorMetricInc(object oNpc, string sMetric)
{
    SetLocalInt(oNpc, sMetric, GetLocalInt(oNpc, sMetric) + 1);
}

void NpcBehaviorHandleIdle(object oNpc)
{
    if (GetIsObjectValid(GetNearestCreature(CREATURE_TYPE_PLAYER_CHAR, PLAYER_CHAR_IS_PC, oNpc)) == FALSE)
    {
        ActionRandomWalk();
    }
}

void NpcBehaviorHandleCombat(object oNpc)
{
    if (GetIsInCombat(oNpc) == FALSE)
    {
        SetLocalInt(oNpc, NPC_VAR_STATE, NPC_STATE_ALERT);
    }
}

void NpcBehaviorOnSpawn(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    SetLocalInt(oNpc, NPC_VAR_STATE, NPC_STATE_IDLE);
    SetLocalInt(oNpc, NPC_VAR_FLAG_PLOT, GetPlotFlag(oNpc));

    if (GetLocalInt(oNpc, NPC_VAR_DECAY_TIME_SEC) <= 0)
    {
        SetLocalInt(oNpc, NPC_VAR_DECAY_TIME_SEC, 5000);
    }

    NpcBehaviorMetricInc(oNpc, NPC_VAR_METRIC_SPAWN);
}

void NpcBehaviorOnPerception(object oNpc)
{
    object oSeen = GetLastPerceived();

    if (!GetIsObjectValid(oNpc) || !GetIsObjectValid(oSeen) || NpcBehaviorIsDisabled(oNpc))
    {
        return;
    }

    NpcBehaviorMetricInc(oNpc, NPC_VAR_METRIC_PERCEPTION);

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
        SetLocalInt(oNpc, NPC_VAR_DEFERRED_EVENTS, GetLocalInt(oNpc, NPC_VAR_DEFERRED_EVENTS) + 1);
    }
}

void NpcBehaviorOnDamaged(object oNpc)
{
    if (!GetIsObjectValid(oNpc) || NpcBehaviorIsDisabled(oNpc))
    {
        return;
    }

    NpcBehaviorMetricInc(oNpc, NPC_VAR_METRIC_DAMAGED);

    if (GetCurrentHitPoints(oNpc) > 0)
    {
        SetLocalInt(oNpc, NPC_VAR_STATE, NPC_STATE_COMBAT);
    }
}

void NpcBehaviorOnDeath(object oNpc)
{
    int nDecaySeconds;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    NpcBehaviorMetricInc(oNpc, NPC_VAR_METRIC_DEATH);

    if (GetLocalInt(oNpc, NPC_VAR_FLAG_LOOTABLE_CORPSE) == FALSE)
    {
        SetLootable(oNpc, FALSE);
    }

    if (GetLocalInt(oNpc, NPC_VAR_FLAG_DECAYS) == TRUE)
    {
        nDecaySeconds = GetLocalInt(oNpc, NPC_VAR_DECAY_TIME_SEC) / 1000;
        if (nDecaySeconds <= 0)
        {
            nDecaySeconds = 5;
        }

        DelayCommand(IntToFloat(nDecaySeconds), DestroyObject(oNpc));
    }
}

void NpcBehaviorOnDialogue(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    NpcBehaviorMetricInc(oNpc, NPC_VAR_METRIC_DIALOG);

    if (GetLocalInt(oNpc, NPC_VAR_FLAG_DIALOG_INTERRUPTIBLE) == FALSE)
    {
        AssignCommand(oNpc, ClearAllActions());
    }

    if (GetLocalInt(oNpc, NPC_VAR_STATE) == NPC_STATE_COMBAT)
    {
        SetLocalInt(oNpc, NPC_VAR_STATE, NPC_STATE_ALERT);
    }
}

int NpcBehaviorOnHeartbeat(object oNpc)
{
    int nNow;

    if (!GetIsObjectValid(oNpc) || GetIsDead(oNpc) || NpcBehaviorIsDisabled(oNpc))
    {
        return FALSE;
    }

    nNow = NpcBehaviorTickNow();
    if (!NpcBehaviorShouldProcess(oNpc, nNow))
    {
        return FALSE;
    }

    if (GetLocalInt(oNpc, NPC_VAR_STATE) == NPC_STATE_COMBAT)
    {
        NpcBehaviorHandleCombat(oNpc);
    }
    else
    {
        NpcBehaviorHandleIdle(oNpc);
    }

    SetLocalInt(oNpc, NPC_VAR_LAST_TICK, nNow);
    return TRUE;
}

void NpcBehaviorOnAreaTick(object oArea)
{
    object oObject = GetFirstObjectInArea(oArea);
    int nProcessed = 0;

    while (GetIsObjectValid(oObject) && nProcessed < NPC_TICK_PROCESS_LIMIT)
    {
        if (GetObjectType(oObject) == OBJECT_TYPE_CREATURE && !GetIsPC(oObject))
        {
            if (NpcBehaviorOnHeartbeat(oObject))
            {
                nProcessed = nProcessed + 1;
            }
        }

        oObject = GetNextObjectInArea(oArea);
    }

    SetLocalInt(oArea, NPC_VAR_PROCESSED_TICK, nProcessed);
}
