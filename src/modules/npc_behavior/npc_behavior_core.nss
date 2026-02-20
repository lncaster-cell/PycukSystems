// NPC behavior module: shared constants and handlers for event hooks.

const int NPC_STATE_IDLE = 0;
const int NPC_STATE_ALERT = 1;
const int NPC_STATE_COMBAT = 2;

const int NPC_DEFAULT_IDLE_INTERVAL = 6;
const int NPC_DEFAULT_COMBAT_INTERVAL = 2;
const int NPC_TICK_PROCESS_LIMIT = 32;

const int NPC_DEFAULT_FLAG_DECAYS = TRUE;
const int NPC_DEFAULT_FLAG_LOOTABLE_CORPSE = TRUE;
const int NPC_DEFAULT_FLAG_DISABLE_AI_WHEN_HIDDEN = FALSE;
const int NPC_DEFAULT_FLAG_DIALOG_INTERRUPTIBLE = TRUE;
const int NPC_DEFAULT_DECAY_TIME_SEC = 5000;

// [Runtime Internal] служебные переменные оркестрации и state-machine.
string NPC_VAR_STATE = "npc_state";
string NPC_VAR_LAST_TICK = "npc_last_tick";
string NPC_VAR_PROCESSED_TICK = "npc_processed_in_tick";
string NPC_VAR_DEFERRED_EVENTS = "npc_deferred_events";

// [Behavior Flags] минимальный runtime-контракт.
// Сюда оставляем только те параметры, которые реально используются обработчиками
// и могут быть переопределены скриптами во время жизни NPC.
string NPC_VAR_FLAG_DECAYS = "npc_flag_decays";
string NPC_VAR_FLAG_DIALOG_INTERRUPTIBLE = "npc_flag_dialog_interruptible";
string NPC_VAR_FLAG_DISABLE_AI_WHEN_HIDDEN = "npc_flag_disable_ai_when_hidden";
string NPC_VAR_FLAG_PLOT = "npc_flag_plot";
string NPC_VAR_FLAG_LOOTABLE_CORPSE = "npc_flag_lootable_corpse";
string NPC_VAR_FLAG_DISABLE_OBJECT = "npc_flag_disable_object";
string NPC_VAR_RUNTIME_HIDDEN = "npc_runtime_hidden";

string NPC_VAR_DECAY_TIME_SEC = "npc_decay_time_sec";

// [Runtime Metrics] счетчики и runtime-метрики для минимальной телеметрии.
string NPC_VAR_METRIC_SPAWN = "npc_metric_spawn_count";
string NPC_VAR_METRIC_PERCEPTION = "npc_metric_perception_count";
string NPC_VAR_METRIC_DAMAGED = "npc_metric_damaged_count";
string NPC_VAR_METRIC_DEATH = "npc_metric_death_count";
string NPC_VAR_METRIC_DIALOG = "npc_metric_dialog_count";
string NPC_VAR_METRIC_HEARTBEAT = "npc_metric_heartbeat_count";
string NPC_VAR_METRIC_HEARTBEAT_SKIPPED = "npc_metric_heartbeat_skipped_count";
string NPC_VAR_METRIC_COMBAT_ROUND = "npc_metric_combat_round_count";

string NPC_VAR_METRIC_AREA_PROCESSED = "npc_area_metric_processed_count";
string NPC_VAR_METRIC_AREA_SKIPPED = "npc_area_metric_skipped_count";
string NPC_VAR_METRIC_AREA_DEFERRED = "npc_area_metric_deferred_count";

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

void NpcBehaviorMetricAdd(object oTarget, string sMetric, int nValue)
{
    if (!GetIsObjectValid(oTarget) || nValue == 0)
    {
        return;
    }

    SetLocalInt(oTarget, sMetric, GetLocalInt(oTarget, sMetric) + nValue);
}

void NpcBehaviorMetricInc(object oTarget, string sMetric)
{
    NpcBehaviorMetricAdd(oTarget, sMetric, 1);
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
    int nFlagDecays;
    int nFlagLootableCorpse;
    int nFlagDisableAiWhenHidden;
    int nFlagDialogInterruptible;
    int nDecayTimeSec;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    SetLocalInt(oNpc, NPC_VAR_STATE, NPC_STATE_IDLE);
    SetLocalInt(oNpc, NPC_VAR_FLAG_PLOT, GetPlotFlag(oNpc));

    // [Behavior Flags] explicit defaults и fallback-валидация контрактных переменных.
    nFlagDecays = GetLocalInt(oNpc, NPC_VAR_FLAG_DECAYS);
    if (nFlagDecays != FALSE && nFlagDecays != TRUE)
    {
        nFlagDecays = NPC_DEFAULT_FLAG_DECAYS;
    }
    SetLocalInt(oNpc, NPC_VAR_FLAG_DECAYS, nFlagDecays);

    nFlagLootableCorpse = GetLocalInt(oNpc, NPC_VAR_FLAG_LOOTABLE_CORPSE);
    if (nFlagLootableCorpse != FALSE && nFlagLootableCorpse != TRUE)
    {
        nFlagLootableCorpse = NPC_DEFAULT_FLAG_LOOTABLE_CORPSE;
    }
    SetLocalInt(oNpc, NPC_VAR_FLAG_LOOTABLE_CORPSE, nFlagLootableCorpse);

    nFlagDisableAiWhenHidden = GetLocalInt(oNpc, NPC_VAR_FLAG_DISABLE_AI_WHEN_HIDDEN);
    if (nFlagDisableAiWhenHidden != FALSE && nFlagDisableAiWhenHidden != TRUE)
    {
        nFlagDisableAiWhenHidden = NPC_DEFAULT_FLAG_DISABLE_AI_WHEN_HIDDEN;
    }
    SetLocalInt(oNpc, NPC_VAR_FLAG_DISABLE_AI_WHEN_HIDDEN, nFlagDisableAiWhenHidden);

    nFlagDialogInterruptible = GetLocalInt(oNpc, NPC_VAR_FLAG_DIALOG_INTERRUPTIBLE);
    if (nFlagDialogInterruptible != FALSE && nFlagDialogInterruptible != TRUE)
    {
        nFlagDialogInterruptible = NPC_DEFAULT_FLAG_DIALOG_INTERRUPTIBLE;
    }
    SetLocalInt(oNpc, NPC_VAR_FLAG_DIALOG_INTERRUPTIBLE, nFlagDialogInterruptible);

    nDecayTimeSec = GetLocalInt(oNpc, NPC_VAR_DECAY_TIME_SEC);
    if (nDecayTimeSec <= 0)
    {
        nDecayTimeSec = NPC_DEFAULT_DECAY_TIME_SEC;
    }
    SetLocalInt(oNpc, NPC_VAR_DECAY_TIME_SEC, nDecayTimeSec);

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

void NpcBehaviorOnEndCombatRound(object oNpc)
{
    if (!GetIsObjectValid(oNpc) || NpcBehaviorIsDisabled(oNpc))
    {
        return;
    }

    NpcBehaviorMetricInc(oNpc, NPC_VAR_METRIC_END_COMBAT_ROUND);

    if (!GetIsInCombat(oNpc) && GetLocalInt(oNpc, NPC_VAR_STATE) == NPC_STATE_COMBAT)
    {
        SetLocalInt(oNpc, NPC_VAR_STATE, NPC_STATE_ALERT);
    }
}

void NpcBehaviorOnPhysicalAttacked(object oNpc)
{
    object oAttacker = GetLastAttacker();

    if (!GetIsObjectValid(oNpc) || NpcBehaviorIsDisabled(oNpc))
    {
        return;
    }

    NpcBehaviorMetricInc(oNpc, NPC_VAR_METRIC_PHYSICAL_ATTACKED);

    if (GetIsObjectValid(oAttacker) && GetIsReactionTypeHostile(oAttacker, oNpc))
    {
        SetLocalInt(oNpc, NPC_VAR_STATE, NPC_STATE_COMBAT);
    }
}

void NpcBehaviorOnSpellCastAt(object oNpc)
{
    object oCaster = GetLastSpellCaster();

    if (!GetIsObjectValid(oNpc) || NpcBehaviorIsDisabled(oNpc))
    {
        return;
    }

    NpcBehaviorMetricInc(oNpc, NPC_VAR_METRIC_SPELL_CAST_AT);

    if (GetIsObjectValid(oCaster) && GetIsReactionTypeHostile(oCaster, oNpc))
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
        NpcBehaviorMetricInc(oNpc, NPC_VAR_METRIC_HEARTBEAT_SKIPPED);
        return FALSE;
    }

    NpcBehaviorMetricInc(oNpc, NPC_VAR_METRIC_HEARTBEAT);

    nNow = NpcBehaviorTickNow();
    if (!NpcBehaviorShouldProcess(oNpc, nNow))
    {
        NpcBehaviorMetricInc(oNpc, NPC_VAR_METRIC_HEARTBEAT_SKIPPED);
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

void NpcBehaviorOnCombatRound(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    NpcBehaviorMetricInc(oNpc, NPC_VAR_METRIC_COMBAT_ROUND);
    NpcBehaviorOnHeartbeat(oNpc);
}

void NpcBehaviorOnAreaTick(object oArea)
{
    object oObject = GetFirstObjectInArea(oArea);
    int nProcessed = 0;
    int nSkipped = 0;
    int nDeferred = 0;

    while (GetIsObjectValid(oObject))
    {
        if (GetObjectType(oObject) == OBJECT_TYPE_CREATURE && !GetIsPC(oObject))
        {
            if (nProcessed < NPC_TICK_PROCESS_LIMIT)
            {
                if (NpcBehaviorOnHeartbeat(oObject))
                {
                    nProcessed = nProcessed + 1;
                }
                else
                {
                    nSkipped = nSkipped + 1;
                }
            }
            else
            {
                nDeferred = nDeferred + 1;
            }
        }

        oObject = GetNextObjectInArea(oArea);
    }

    SetLocalInt(oArea, NPC_VAR_PROCESSED_TICK, nProcessed);
    NpcBehaviorMetricAdd(oArea, NPC_VAR_METRIC_AREA_PROCESSED, nProcessed);
    NpcBehaviorMetricAdd(oArea, NPC_VAR_METRIC_AREA_SKIPPED, nSkipped);
    NpcBehaviorMetricAdd(oArea, NPC_VAR_METRIC_AREA_DEFERRED, nDeferred);
}
