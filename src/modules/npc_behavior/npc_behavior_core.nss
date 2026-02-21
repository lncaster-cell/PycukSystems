// NPC behavior module: shared constants and handlers for event hooks.

const int NPC_STATE_IDLE = 0;
const int NPC_STATE_ALERT = 1;
const int NPC_STATE_COMBAT = 2;

const int NPC_DEFAULT_IDLE_INTERVAL = 6;
const int NPC_DEFAULT_COMBAT_INTERVAL = 2;
const int NPC_TICK_PROCESS_LIMIT = 32;

const int NPC_EVENT_PRIORITY_CRITICAL = 3;
const int NPC_EVENT_PRIORITY_HIGH = 2;
const int NPC_EVENT_PRIORITY_NORMAL = 1;
const int NPC_EVENT_PRIORITY_LOW = 0;

const int NPC_AREA_QUEUE_CAPACITY = 96;
const int NPC_AREA_DEGRADED_HIGH_WATERMARK = 72;
const int NPC_AREA_DEGRADED_LOW_WATERMARK = 24;
const int NPC_COALESCE_WINDOW_SEC = 2;
const int NPC_AREA_CRITICAL_RESERVE = 8;

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

// [Area Queue State] bounded queue + degraded mode (Phase 1 contract).
string NPC_VAR_AREA_QUEUE_DEPTH = "npc_area_queue_depth";
string NPC_VAR_AREA_QUEUE_CRITICAL = "npc_area_queue_critical";
string NPC_VAR_AREA_QUEUE_HIGH = "npc_area_queue_high";
string NPC_VAR_AREA_QUEUE_NORMAL = "npc_area_queue_normal";
string NPC_VAR_AREA_QUEUE_LOW = "npc_area_queue_low";
string NPC_VAR_AREA_DEGRADED = "npc_area_degraded_mode";

// [Behavior Flags] минимальный runtime-контракт.
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
string NPC_VAR_METRIC_PHYSICAL_ATTACKED = "npc_metric_physical_attacked_count";
string NPC_VAR_METRIC_SPELL_CAST_AT = "npc_metric_spell_cast_at_count";
string NPC_VAR_METRIC_END_COMBAT_ROUND = "npc_metric_end_combat_round_count";
string NPC_VAR_METRIC_DEATH = "npc_metric_death_count";
string NPC_VAR_METRIC_DIALOG = "npc_metric_dialog_count";
string NPC_VAR_METRIC_HEARTBEAT = "npc_metric_heartbeat_count";
string NPC_VAR_METRIC_HEARTBEAT_SKIPPED = "npc_metric_heartbeat_skipped_count";
string NPC_VAR_METRIC_COMBAT_ROUND = "npc_metric_combat_round_count";

string NPC_VAR_METRIC_AREA_PROCESSED = "npc_area_metric_processed_count";
string NPC_VAR_METRIC_AREA_SKIPPED = "npc_area_metric_skipped_count";
string NPC_VAR_METRIC_AREA_DEFERRED = "npc_area_metric_deferred_count";
string NPC_VAR_METRIC_AREA_OVERFLOW = "npc_area_metric_queue_overflow_count";

int NpcBehaviorTickNow()
{
    return GetTimeHour() * 3600 + GetTimeMinute() * 60 + GetTimeSecond();
}

int NpcBehaviorElapsedSec(int nNow, int nLast)
{
    if (nNow >= nLast)
    {
        return nNow - nLast;
    }

    return (24 * 3600 - nLast) + nNow;
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

void NpcBehaviorAreaQueueAdjust(object oArea, int nPriority, int nDelta)
{
    int nDepth;
    int nBucket;
    string sBucketVar;

    if (!GetIsObjectValid(oArea) || nDelta == 0)
    {
        return;
    }

    nDepth = GetLocalInt(oArea, NPC_VAR_AREA_QUEUE_DEPTH) + nDelta;
    if (nDepth < 0)
    {
        nDepth = 0;
    }
    SetLocalInt(oArea, NPC_VAR_AREA_QUEUE_DEPTH, nDepth);

    if (nPriority == NPC_EVENT_PRIORITY_CRITICAL)
    {
        sBucketVar = NPC_VAR_AREA_QUEUE_CRITICAL;
    }
    else if (nPriority == NPC_EVENT_PRIORITY_HIGH)
    {
        sBucketVar = NPC_VAR_AREA_QUEUE_HIGH;
    }
    else if (nPriority == NPC_EVENT_PRIORITY_NORMAL)
    {
        sBucketVar = NPC_VAR_AREA_QUEUE_NORMAL;
    }
    else
    {
        sBucketVar = NPC_VAR_AREA_QUEUE_LOW;
    }

    nBucket = GetLocalInt(oArea, sBucketVar) + nDelta;
    if (nBucket < 0)
    {
        nBucket = 0;
    }
    SetLocalInt(oArea, sBucketVar, nBucket);
}

int NpcBehaviorAreaTryQueueEvent(object oArea, int nPriority)
{
    int nQueueDepth;

    if (!GetIsObjectValid(oArea))
    {
        return TRUE;
    }

    nQueueDepth = GetLocalInt(oArea, NPC_VAR_AREA_QUEUE_DEPTH);
    if (nQueueDepth < NPC_AREA_QUEUE_CAPACITY)
    {
        NpcBehaviorAreaQueueAdjust(oArea, nPriority, 1);
        return TRUE;
    }

    NpcBehaviorMetricInc(oArea, NPC_VAR_METRIC_AREA_OVERFLOW);

    // CRITICAL events могут вытеснить сначала LOW, затем NORMAL/HIGH.
    if (nPriority == NPC_EVENT_PRIORITY_CRITICAL)
    {
        if (GetLocalInt(oArea, NPC_VAR_AREA_QUEUE_LOW) > 0)
        {
            NpcBehaviorAreaQueueAdjust(oArea, NPC_EVENT_PRIORITY_LOW, -1);
            NpcBehaviorAreaQueueAdjust(oArea, NPC_EVENT_PRIORITY_CRITICAL, 1);
            NpcBehaviorMetricInc(oArea, NPC_VAR_METRIC_AREA_DEFERRED);
            return TRUE;
        }

        if (GetLocalInt(oArea, NPC_VAR_AREA_QUEUE_NORMAL) > 0)
        {
            NpcBehaviorAreaQueueAdjust(oArea, NPC_EVENT_PRIORITY_NORMAL, -1);
            NpcBehaviorAreaQueueAdjust(oArea, NPC_EVENT_PRIORITY_CRITICAL, 1);
            NpcBehaviorMetricInc(oArea, NPC_VAR_METRIC_AREA_DEFERRED);
            return TRUE;
        }

        if (GetLocalInt(oArea, NPC_VAR_AREA_QUEUE_HIGH) > 0)
        {
            NpcBehaviorAreaQueueAdjust(oArea, NPC_EVENT_PRIORITY_HIGH, -1);
            NpcBehaviorAreaQueueAdjust(oArea, NPC_EVENT_PRIORITY_CRITICAL, 1);
            NpcBehaviorMetricInc(oArea, NPC_VAR_METRIC_AREA_DEFERRED);
            return TRUE;
        }

        // Emergency reserve: CRITICAL может превысить nominal capacity.
        if (nQueueDepth < (NPC_AREA_QUEUE_CAPACITY + NPC_AREA_CRITICAL_RESERVE))
        {
            NpcBehaviorAreaQueueAdjust(oArea, NPC_EVENT_PRIORITY_CRITICAL, 1);
            return TRUE;
        }
    }

    NpcBehaviorMetricInc(oArea, NPC_VAR_METRIC_AREA_DEFERRED);
    return FALSE;
}

int NpcBehaviorTryIntakeEvent(object oNpc, int nPriority, string sCoalesceKey)
{
    object oArea;
    string sCoalesceVar;
    int nNow;
    int nLast;

    if (!GetIsObjectValid(oNpc))
    {
        return FALSE;
    }

    nNow = NpcBehaviorTickNow();
    if (sCoalesceKey != "")
    {
        sCoalesceVar = "npc_coalesce_" + sCoalesceKey;
        nLast = GetLocalInt(oNpc, sCoalesceVar);

        if (nLast > 0 && NpcBehaviorElapsedSec(nNow, nLast) < NPC_COALESCE_WINDOW_SEC && nPriority < NPC_EVENT_PRIORITY_CRITICAL)
        {
            NpcBehaviorMetricInc(oNpc, NPC_VAR_DEFERRED_EVENTS);
            return FALSE;
        }

        SetLocalInt(oNpc, sCoalesceVar, nNow);
    }

    oArea = GetArea(oNpc);
    return NpcBehaviorAreaTryQueueEvent(oArea, nPriority);
}


void NpcBehaviorAreaDrainQueue(object oArea, int nBudget)
{
    int nTake;

    if (!GetIsObjectValid(oArea) || nBudget <= 0)
    {
        return;
    }

    nTake = GetLocalInt(oArea, NPC_VAR_AREA_QUEUE_LOW);
    if (nTake > nBudget)
    {
        nTake = nBudget;
    }
    NpcBehaviorAreaQueueAdjust(oArea, NPC_EVENT_PRIORITY_LOW, -nTake);
    nBudget = nBudget - nTake;

    if (nBudget <= 0)
    {
        return;
    }

    nTake = GetLocalInt(oArea, NPC_VAR_AREA_QUEUE_NORMAL);
    if (nTake > nBudget)
    {
        nTake = nBudget;
    }
    NpcBehaviorAreaQueueAdjust(oArea, NPC_EVENT_PRIORITY_NORMAL, -nTake);
    nBudget = nBudget - nTake;

    if (nBudget <= 0)
    {
        return;
    }

    nTake = GetLocalInt(oArea, NPC_VAR_AREA_QUEUE_HIGH);
    if (nTake > nBudget)
    {
        nTake = nBudget;
    }
    NpcBehaviorAreaQueueAdjust(oArea, NPC_EVENT_PRIORITY_HIGH, -nTake);
    nBudget = nBudget - nTake;

    if (nBudget <= 0)
    {
        return;
    }

    nTake = GetLocalInt(oArea, NPC_VAR_AREA_QUEUE_CRITICAL);
    if (nTake > nBudget)
    {
        nTake = nBudget;
    }
    NpcBehaviorAreaQueueAdjust(oArea, NPC_EVENT_PRIORITY_CRITICAL, -nTake);
}

void NpcBehaviorUpdateAreaDegradedMode(object oArea)
{
    int nQueueDepth;
    int nIsDegraded;

    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    nQueueDepth = GetLocalInt(oArea, NPC_VAR_AREA_QUEUE_DEPTH);
    nIsDegraded = GetLocalInt(oArea, NPC_VAR_AREA_DEGRADED);

    if (nQueueDepth >= NPC_AREA_DEGRADED_HIGH_WATERMARK)
    {
        SetLocalInt(oArea, NPC_VAR_AREA_DEGRADED, TRUE);
    }
    else if (nIsDegraded == TRUE && nQueueDepth <= NPC_AREA_DEGRADED_LOW_WATERMARK)
    {
        SetLocalInt(oArea, NPC_VAR_AREA_DEGRADED, FALSE);
    }
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

    return (NpcBehaviorElapsedSec(nNow, nLastTick) >= nInterval);
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

    if (!NpcBehaviorTryIntakeEvent(oNpc, NPC_EVENT_PRIORITY_HIGH, "perception"))
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
        NpcBehaviorMetricInc(oNpc, NPC_VAR_DEFERRED_EVENTS);
    }
}

void NpcBehaviorOnDamaged(object oNpc)
{
    if (!GetIsObjectValid(oNpc) || NpcBehaviorIsDisabled(oNpc))
    {
        return;
    }

    NpcBehaviorTryIntakeEvent(oNpc, NPC_EVENT_PRIORITY_CRITICAL, "");
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

    NpcBehaviorTryIntakeEvent(oNpc, NPC_EVENT_PRIORITY_HIGH, "combat_round");
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

    NpcBehaviorTryIntakeEvent(oNpc, NPC_EVENT_PRIORITY_CRITICAL, "");
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

    NpcBehaviorTryIntakeEvent(oNpc, NPC_EVENT_PRIORITY_HIGH, "spell_cast_at");
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

    NpcBehaviorTryIntakeEvent(oNpc, NPC_EVENT_PRIORITY_CRITICAL, "");
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

    if (!NpcBehaviorTryIntakeEvent(oNpc, NPC_EVENT_PRIORITY_NORMAL, "dialogue"))
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
    object oArea;

    if (!GetIsObjectValid(oNpc) || GetIsDead(oNpc) || NpcBehaviorIsDisabled(oNpc))
    {
        NpcBehaviorMetricInc(oNpc, NPC_VAR_METRIC_HEARTBEAT_SKIPPED);
        return FALSE;
    }

    oArea = GetArea(oNpc);
    if (GetIsObjectValid(oArea) && GetLocalInt(oArea, NPC_VAR_AREA_DEGRADED) == TRUE && GetLocalInt(oNpc, NPC_VAR_STATE) == NPC_STATE_IDLE)
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
    int nQueueDepth;

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

    nQueueDepth = GetLocalInt(oArea, NPC_VAR_AREA_QUEUE_DEPTH);
    if (nProcessed > 0 && nQueueDepth > 0)
    {
        NpcBehaviorAreaDrainQueue(oArea, nProcessed);
    }

    NpcBehaviorUpdateAreaDegradedMode(oArea);
}
