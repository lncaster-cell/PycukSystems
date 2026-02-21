// NPC behavior module: shared constants and handlers for event hooks.

const int NPC_STATE_IDLE = 0;
const int NPC_STATE_ALERT = 1;
const int NPC_STATE_COMBAT = 2;

const int NPC_DEFAULT_IDLE_INTERVAL = 6;
const int NPC_DEFAULT_COMBAT_INTERVAL = 2;
const int NPC_TICK_PROCESS_LIMIT = 32;
const int NPC_MIN_TICK_INTERVAL_SEC = 1;
const float NPC_AREA_TICK_INTERVAL_SEC = 1.0;
const int NPC_AREA_BUDGET_PER_TICK = 20;

const int NPC_EVENT_PRIORITY_CRITICAL = 3;
const int NPC_EVENT_PRIORITY_HIGH = 2;
const int NPC_EVENT_PRIORITY_NORMAL = 1;
const int NPC_EVENT_PRIORITY_LOW = 0;

const int NPC_AREA_QUEUE_CAPACITY = 96;
const int NPC_AREA_DEGRADED_HIGH_WATERMARK = 72;
const int NPC_AREA_DEGRADED_LOW_WATERMARK = 24;
const int NPC_COALESCE_WINDOW_SEC = 2;
const int NPC_AREA_CRITICAL_RESERVE = 8;
const int NPC_AREA_QUEUE_STORAGE_CAPACITY = NPC_AREA_QUEUE_CAPACITY + NPC_AREA_CRITICAL_RESERVE;

const int NPC_DEFAULT_FLAG_DECAYS = TRUE;
const int NPC_DEFAULT_FLAG_LOOTABLE_CORPSE = TRUE;
const int NPC_DEFAULT_FLAG_DISABLE_AI_WHEN_HIDDEN = FALSE;
const int NPC_DEFAULT_FLAG_DIALOG_INTERRUPTIBLE = TRUE;
const int NPC_DEFAULT_DECAY_TIME_SEC = 5;

// [Runtime Internal] служебные переменные оркестрации и state-machine.
string NPC_VAR_STATE = "npc_state";
string NPC_VAR_LAST_TICK = "npc_last_tick";
string NPC_VAR_PROCESSED_TICK = "npc_processed_in_tick";
string NPC_VAR_DEFERRED_EVENTS = "npc_deferred_events";
string NPC_VAR_PENDING_TOTAL = "npc_pending_total";
string NPC_VAR_PENDING_PRIORITY = "npc_pending_priority";
string NPC_VAR_PENDING_CRITICAL = "npc_pending_critical";
string NPC_VAR_PENDING_HIGH = "npc_pending_high";
string NPC_VAR_PENDING_NORMAL = "npc_pending_normal";
string NPC_VAR_PENDING_LOW = "npc_pending_low";

// [Area Queue State] bounded queue + degraded mode (Phase 1 contract).
string NPC_VAR_AREA_QUEUE_DEPTH = "npc_area_queue_depth";
string NPC_VAR_AREA_QUEUE_CRITICAL = "npc_area_queue_critical";
string NPC_VAR_AREA_QUEUE_HIGH = "npc_area_queue_high";
string NPC_VAR_AREA_QUEUE_NORMAL = "npc_area_queue_normal";
string NPC_VAR_AREA_QUEUE_LOW = "npc_area_queue_low";
string NPC_VAR_AREA_QUEUE_TAIL = "npc_area_queue_tail";
string NPC_VAR_AREA_QUEUE_SLOT_ACTIVE = "npc_area_queue_slot_active_";
string NPC_VAR_AREA_QUEUE_SLOT_PRIORITY = "npc_area_queue_slot_priority_";
string NPC_VAR_AREA_QUEUE_SLOT_OWNER = "npc_area_queue_slot_owner_";
string NPC_VAR_AREA_DEGRADED = "npc_area_degraded_mode";
string NPC_VAR_AREA_ACTIVE = "nb_area_active";
string NPC_VAR_AREA_TIMER_RUNNING = "nb_area_timer_running";
string NPC_VAR_AREA_TICK_SEQ = "nb_area_tick_seq";

// [Behavior Flags] минимальный runtime-контракт.
string NPC_VAR_FLAG_DECAYS = "npc_flag_decays";
string NPC_VAR_FLAG_DIALOG_INTERRUPTIBLE = "npc_flag_dialog_interruptible";
string NPC_VAR_FLAG_DISABLE_AI_WHEN_HIDDEN = "npc_flag_disable_ai_when_hidden";
string NPC_VAR_FLAG_PLOT = "npc_flag_plot";
string NPC_VAR_FLAG_LOOTABLE_CORPSE = "npc_flag_lootable_corpse";
string NPC_VAR_FLAG_DISABLE_OBJECT = "npc_flag_disable_object";
string NPC_VAR_RUNTIME_HIDDEN = "npc_runtime_hidden";
string NPC_VAR_FLAG_DECAYS_SET = "npc_flag_decays_set";
string NPC_VAR_FLAG_LOOTABLE_CORPSE_SET = "npc_flag_lootable_corpse_set";
string NPC_VAR_FLAG_DISABLE_AI_WHEN_HIDDEN_SET = "npc_flag_disable_ai_when_hidden_set";
string NPC_VAR_FLAG_DIALOG_INTERRUPTIBLE_SET = "npc_flag_dialog_interruptible_set";

string NPC_VAR_DECAY_TIME_SEC = "npc_decay_time_sec";
string NPC_VAR_TICK_INTERVAL_IDLE_SEC = "npc_tick_interval_idle_sec";
string NPC_VAR_TICK_INTERVAL_COMBAT_SEC = "npc_tick_interval_combat_sec";
string NPC_VAR_INIT_DONE = "npc_behavior_init_done";

// [Runtime Metrics] счетчики и runtime-метрики для минимальной телеметрии.
string NPC_VAR_METRIC_SPAWN = "npc_metric_spawn_count";
string NPC_VAR_METRIC_PERCEPTION = "npc_metric_perception_count";
string NPC_VAR_METRIC_DAMAGED = "npc_metric_damaged_count";
string NPC_VAR_METRIC_PHYSICAL_ATTACKED = "npc_metric_physical_attacked_count";
string NPC_VAR_METRIC_SPELL_CAST_AT = "npc_metric_spell_cast_at_count";
string NPC_VAR_METRIC_DEATH = "npc_metric_death_count";
string NPC_VAR_METRIC_DIALOG = "npc_metric_dialog_count";
string NPC_VAR_METRIC_HEARTBEAT = "npc_metric_heartbeat_count";
string NPC_VAR_METRIC_HEARTBEAT_SKIPPED = "npc_metric_heartbeat_skipped_count";
string NPC_VAR_METRIC_COMBAT_ROUND = "npc_metric_combat_round_count";
string NPC_VAR_METRIC_INTAKE_BYPASS_CRITICAL = "npc_metric_intake_bypass_critical";

string NPC_VAR_METRIC_AREA_PROCESSED = "npc_area_metric_processed_count";
string NPC_VAR_METRIC_AREA_SKIPPED = "npc_area_metric_skipped_count";
// Только deferred по budget/очереди area-tick (не включает heartbeat skip/guard причины).
string NPC_VAR_METRIC_AREA_DEFERRED = "npc_area_metric_deferred_count";
string NPC_VAR_METRIC_AREA_OVERFLOW = "npc_area_metric_queue_overflow_count";

int NpcBehaviorOnHeartbeat(object oNpc);
int NpcBehaviorConsumePending(object oNpc, int nPriority);

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


void NpcBehaviorPendingAdjust(object oNpc, int nPriority, int nDelta)
{
    int nPendingTotal;
    int nBucketValue;
    string sBucketVar;
    int nTopPriority;

    if (!GetIsObjectValid(oNpc) || nPriority < NPC_EVENT_PRIORITY_LOW || nPriority > NPC_EVENT_PRIORITY_CRITICAL || nDelta == 0)
    {
        return;
    }

    if (nPriority == NPC_EVENT_PRIORITY_CRITICAL)
    {
        sBucketVar = NPC_VAR_PENDING_CRITICAL;
    }
    else if (nPriority == NPC_EVENT_PRIORITY_HIGH)
    {
        sBucketVar = NPC_VAR_PENDING_HIGH;
    }
    else if (nPriority == NPC_EVENT_PRIORITY_NORMAL)
    {
        sBucketVar = NPC_VAR_PENDING_NORMAL;
    }
    else
    {
        sBucketVar = NPC_VAR_PENDING_LOW;
    }

    nBucketValue = GetLocalInt(oNpc, sBucketVar) + nDelta;
    if (nBucketValue < 0)
    {
        nBucketValue = 0;
    }
    SetLocalInt(oNpc, sBucketVar, nBucketValue);

    nPendingTotal = GetLocalInt(oNpc, NPC_VAR_PENDING_TOTAL) + nDelta;
    if (nPendingTotal < 0)
    {
        nPendingTotal = 0;
    }
    SetLocalInt(oNpc, NPC_VAR_PENDING_TOTAL, nPendingTotal);

    nTopPriority = NPC_EVENT_PRIORITY_LOW;
    if (GetLocalInt(oNpc, NPC_VAR_PENDING_CRITICAL) > 0)
    {
        nTopPriority = NPC_EVENT_PRIORITY_CRITICAL;
    }
    else if (GetLocalInt(oNpc, NPC_VAR_PENDING_HIGH) > 0)
    {
        nTopPriority = NPC_EVENT_PRIORITY_HIGH;
    }
    else if (GetLocalInt(oNpc, NPC_VAR_PENDING_NORMAL) > 0)
    {
        nTopPriority = NPC_EVENT_PRIORITY_NORMAL;
    }

    if (nPendingTotal <= 0)
    {
        nTopPriority = NPC_EVENT_PRIORITY_LOW;
    }
    SetLocalInt(oNpc, NPC_VAR_PENDING_PRIORITY, nTopPriority);
}

int NpcBehaviorIsHostileForCombat(object oNpc, object oTarget)
{
    if (!GetIsObjectValid(oNpc) || !GetIsObjectValid(oTarget))
    {
        return FALSE;
    }

    // NWScript contract: GetIsReactionTypeHostile(oSource, oTarget)
    // проверяет отношение source -> target. Для combat-enter используем
    // двустороннюю проверку, чтобы не терять переходы при faction/charm кейсах,
    // где hostility может быть асимметричной в конкретный тик.
    if (GetIsReactionTypeHostile(oNpc, oTarget) || GetIsReactionTypeHostile(oTarget, oNpc))
    {
        return TRUE;
    }

    return FALSE;
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

string NpcBehaviorAreaQueueSlotVar(string sPrefix, int nSlot)
{
    return sPrefix + IntToString(nSlot);
}

void NpcBehaviorAreaQueueSetSlot(object oArea, int nSlot, object oOwner, int nPriority)
{
    SetLocalInt(oArea, NpcBehaviorAreaQueueSlotVar(NPC_VAR_AREA_QUEUE_SLOT_ACTIVE, nSlot), TRUE);
    SetLocalInt(oArea, NpcBehaviorAreaQueueSlotVar(NPC_VAR_AREA_QUEUE_SLOT_PRIORITY, nSlot), nPriority);
    SetLocalObject(oArea, NpcBehaviorAreaQueueSlotVar(NPC_VAR_AREA_QUEUE_SLOT_OWNER, nSlot), oOwner);
}

void NpcBehaviorAreaQueueClearSlot(object oArea, int nSlot)
{
    DeleteLocalInt(oArea, NpcBehaviorAreaQueueSlotVar(NPC_VAR_AREA_QUEUE_SLOT_ACTIVE, nSlot));
    DeleteLocalInt(oArea, NpcBehaviorAreaQueueSlotVar(NPC_VAR_AREA_QUEUE_SLOT_PRIORITY, nSlot));
    DeleteLocalObject(oArea, NpcBehaviorAreaQueueSlotVar(NPC_VAR_AREA_QUEUE_SLOT_OWNER, nSlot));
}

int NpcBehaviorAreaQueueFindInsertSlot(object oArea, int nStart)
{
    int nProbe;
    int nSlot;

    for (nProbe = 0; nProbe < NPC_AREA_QUEUE_STORAGE_CAPACITY; nProbe++)
    {
        nSlot = (nStart + nProbe) % NPC_AREA_QUEUE_STORAGE_CAPACITY;
        if (GetLocalInt(oArea, NpcBehaviorAreaQueueSlotVar(NPC_VAR_AREA_QUEUE_SLOT_ACTIVE, nSlot)) != TRUE)
        {
            return nSlot;
        }
    }

    return -1;
}

int NpcBehaviorAreaQueuePush(object oArea, object oOwner, int nPriority)
{
    int nTail;
    int nSlot;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oOwner))
    {
        return FALSE;
    }

    nTail = GetLocalInt(oArea, NPC_VAR_AREA_QUEUE_TAIL);
    nSlot = NpcBehaviorAreaQueueFindInsertSlot(oArea, nTail);
    if (nSlot < 0)
    {
        return FALSE;
    }

    NpcBehaviorAreaQueueSetSlot(oArea, nSlot, oOwner, nPriority);
    SetLocalInt(oArea, NPC_VAR_AREA_QUEUE_TAIL, (nSlot + 1) % NPC_AREA_QUEUE_STORAGE_CAPACITY);
    NpcBehaviorAreaQueueAdjust(oArea, nPriority, 1);
    return TRUE;
}

int NpcBehaviorAreaQueueEvictSlot(object oArea, int nSlot)
{
    object oOwner;
    int nPriority;

    if (!GetIsObjectValid(oArea) || nSlot < 0 || nSlot >= NPC_AREA_QUEUE_STORAGE_CAPACITY)
    {
        return FALSE;
    }

    if (GetLocalInt(oArea, NpcBehaviorAreaQueueSlotVar(NPC_VAR_AREA_QUEUE_SLOT_ACTIVE, nSlot)) != TRUE)
    {
        return FALSE;
    }

    nPriority = GetLocalInt(oArea, NpcBehaviorAreaQueueSlotVar(NPC_VAR_AREA_QUEUE_SLOT_PRIORITY, nSlot));
    oOwner = GetLocalObject(oArea, NpcBehaviorAreaQueueSlotVar(NPC_VAR_AREA_QUEUE_SLOT_OWNER, nSlot));

    NpcBehaviorAreaQueueClearSlot(oArea, nSlot);
    NpcBehaviorAreaQueueAdjust(oArea, nPriority, -1);

    if (GetIsObjectValid(oOwner))
    {
        NpcBehaviorPendingAdjust(oOwner, nPriority, -1);
    }

    return TRUE;
}

int NpcBehaviorAreaQueueFindVictimSlot(object oArea)
{
    int nSlot;
    int nPriority;

    for (nSlot = 0; nSlot < NPC_AREA_QUEUE_STORAGE_CAPACITY; nSlot++)
    {
        if (GetLocalInt(oArea, NpcBehaviorAreaQueueSlotVar(NPC_VAR_AREA_QUEUE_SLOT_ACTIVE, nSlot)) == TRUE)
        {
            nPriority = GetLocalInt(oArea, NpcBehaviorAreaQueueSlotVar(NPC_VAR_AREA_QUEUE_SLOT_PRIORITY, nSlot));
            if (nPriority == NPC_EVENT_PRIORITY_LOW)
            {
                return nSlot;
            }
        }
    }

    for (nSlot = 0; nSlot < NPC_AREA_QUEUE_STORAGE_CAPACITY; nSlot++)
    {
        if (GetLocalInt(oArea, NpcBehaviorAreaQueueSlotVar(NPC_VAR_AREA_QUEUE_SLOT_ACTIVE, nSlot)) == TRUE)
        {
            nPriority = GetLocalInt(oArea, NpcBehaviorAreaQueueSlotVar(NPC_VAR_AREA_QUEUE_SLOT_PRIORITY, nSlot));
            if (nPriority == NPC_EVENT_PRIORITY_NORMAL)
            {
                return nSlot;
            }
        }
    }

    for (nSlot = 0; nSlot < NPC_AREA_QUEUE_STORAGE_CAPACITY; nSlot++)
    {
        if (GetLocalInt(oArea, NpcBehaviorAreaQueueSlotVar(NPC_VAR_AREA_QUEUE_SLOT_ACTIVE, nSlot)) == TRUE)
        {
            nPriority = GetLocalInt(oArea, NpcBehaviorAreaQueueSlotVar(NPC_VAR_AREA_QUEUE_SLOT_PRIORITY, nSlot));
            if (nPriority == NPC_EVENT_PRIORITY_HIGH)
            {
                return nSlot;
            }
        }
    }

    return -1;
}

int NpcBehaviorAreaQueueConsumeByOwner(object oArea, object oOwner, int nPriority)
{
    int nSlot;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oOwner))
    {
        return FALSE;
    }

    for (nSlot = 0; nSlot < NPC_AREA_QUEUE_STORAGE_CAPACITY; nSlot++)
    {
        if (GetLocalInt(oArea, NpcBehaviorAreaQueueSlotVar(NPC_VAR_AREA_QUEUE_SLOT_ACTIVE, nSlot)) == TRUE
            && GetLocalInt(oArea, NpcBehaviorAreaQueueSlotVar(NPC_VAR_AREA_QUEUE_SLOT_PRIORITY, nSlot)) == nPriority
            && GetLocalObject(oArea, NpcBehaviorAreaQueueSlotVar(NPC_VAR_AREA_QUEUE_SLOT_OWNER, nSlot)) == oOwner)
        {
            NpcBehaviorAreaQueueClearSlot(oArea, nSlot);
            NpcBehaviorAreaQueueAdjust(oArea, nPriority, -1);
            NpcBehaviorPendingAdjust(oOwner, nPriority, -1);
            return TRUE;
        }
    }

    return FALSE;
}

void NpcBehaviorAreaQueueReset(object oArea)
{
    int nSlot;

    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    for (nSlot = 0; nSlot < NPC_AREA_QUEUE_STORAGE_CAPACITY; nSlot++)
    {
        NpcBehaviorAreaQueueClearSlot(oArea, nSlot);
    }

    SetLocalInt(oArea, NPC_VAR_AREA_QUEUE_DEPTH, 0);
    SetLocalInt(oArea, NPC_VAR_AREA_QUEUE_CRITICAL, 0);
    SetLocalInt(oArea, NPC_VAR_AREA_QUEUE_HIGH, 0);
    SetLocalInt(oArea, NPC_VAR_AREA_QUEUE_NORMAL, 0);
    SetLocalInt(oArea, NPC_VAR_AREA_QUEUE_LOW, 0);
    SetLocalInt(oArea, NPC_VAR_AREA_QUEUE_TAIL, 0);
}

int NpcBehaviorAreaTryQueueEvent(object oArea, object oOwner, int nPriority)
{
    int nQueueDepth;
    int nVictimSlot;

    if (!GetIsObjectValid(oArea))
    {
        return TRUE;
    }

    nQueueDepth = GetLocalInt(oArea, NPC_VAR_AREA_QUEUE_DEPTH);
    if (nQueueDepth < NPC_AREA_QUEUE_CAPACITY)
    {
        return NpcBehaviorAreaQueuePush(oArea, oOwner, nPriority);
    }

    NpcBehaviorMetricInc(oArea, NPC_VAR_METRIC_AREA_OVERFLOW);

    // CRITICAL events выполняют owner-aware вытеснение: удаляется конкретный slot (LOW -> NORMAL -> HIGH).
    if (nPriority == NPC_EVENT_PRIORITY_CRITICAL)
    {
        nVictimSlot = NpcBehaviorAreaQueueFindVictimSlot(oArea);
        if (nVictimSlot >= 0)
        {
            if (NpcBehaviorAreaQueueEvictSlot(oArea, nVictimSlot))
            {
                NpcBehaviorMetricInc(oArea, NPC_VAR_METRIC_AREA_DEFERRED);
                return NpcBehaviorAreaQueuePush(oArea, oOwner, nPriority);
            }
        }

        // Emergency reserve: CRITICAL может превысить nominal capacity.
        if (nQueueDepth < NPC_AREA_QUEUE_STORAGE_CAPACITY)
        {
            return NpcBehaviorAreaQueuePush(oArea, oOwner, nPriority);
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
    int bQueued;

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
    }

    oArea = GetArea(oNpc);
    bQueued = NpcBehaviorAreaTryQueueEvent(oArea, oNpc, nPriority);
    if (!bQueued)
    {
        return FALSE;
    }

    if (sCoalesceVar != "")
    {
        SetLocalInt(oNpc, sCoalesceVar, nNow);
    }

    NpcBehaviorPendingAdjust(oNpc, nPriority, 1);

    return TRUE;
}


int NpcBehaviorConsumePending(object oNpc, int nPriority)
{
    if (!GetIsObjectValid(oNpc) || nPriority < NPC_EVENT_PRIORITY_LOW || nPriority > NPC_EVENT_PRIORITY_CRITICAL)
    {
        return FALSE;
    }

    if (nPriority == NPC_EVENT_PRIORITY_CRITICAL && GetLocalInt(oNpc, NPC_VAR_PENDING_CRITICAL) <= 0)
    {
        return FALSE;
    }

    if (nPriority == NPC_EVENT_PRIORITY_HIGH && GetLocalInt(oNpc, NPC_VAR_PENDING_HIGH) <= 0)
    {
        return FALSE;
    }

    if (nPriority == NPC_EVENT_PRIORITY_NORMAL && GetLocalInt(oNpc, NPC_VAR_PENDING_NORMAL) <= 0)
    {
        return FALSE;
    }

    if (nPriority == NPC_EVENT_PRIORITY_LOW && GetLocalInt(oNpc, NPC_VAR_PENDING_LOW) <= 0)
    {
        return FALSE;
    }

    NpcBehaviorPendingAdjust(oNpc, nPriority, -1);
    return TRUE;
}

int NpcBehaviorGetTopPendingPriority(object oNpc)
{
    int nTopPriority;

    if (!GetIsObjectValid(oNpc) || GetLocalInt(oNpc, NPC_VAR_PENDING_TOTAL) <= 0)
    {
        return -1;
    }

    if (GetLocalInt(oNpc, NPC_VAR_PENDING_CRITICAL) > 0)
    {
        return NPC_EVENT_PRIORITY_CRITICAL;
    }

    if (GetLocalInt(oNpc, NPC_VAR_PENDING_HIGH) > 0)
    {
        return NPC_EVENT_PRIORITY_HIGH;
    }

    if (GetLocalInt(oNpc, NPC_VAR_PENDING_NORMAL) > 0)
    {
        return NPC_EVENT_PRIORITY_NORMAL;
    }

    if (GetLocalInt(oNpc, NPC_VAR_PENDING_LOW) > 0)
    {
        return NPC_EVENT_PRIORITY_LOW;
    }

    nTopPriority = GetLocalInt(oNpc, NPC_VAR_PENDING_PRIORITY);
    if (nTopPriority < NPC_EVENT_PRIORITY_LOW || nTopPriority > NPC_EVENT_PRIORITY_CRITICAL)
    {
        return -1;
    }

    return nTopPriority;
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

int NpcBehaviorNormalizeInterval(int nValue, int nDefault)
{
    if (nValue < NPC_MIN_TICK_INTERVAL_SEC)
    {
        return nDefault;
    }

    return nValue;
}

void NpcBehaviorInitialize(object oNpc)
{
    SetLocalInt(oNpc, NPC_VAR_STATE, NPC_STATE_IDLE);
    SetLocalInt(oNpc, NPC_VAR_LAST_TICK, 0);
    SetLocalInt(oNpc, NPC_VAR_PROCESSED_TICK, 0);
    SetLocalInt(oNpc, NPC_VAR_DEFERRED_EVENTS, 0);
    SetLocalInt(oNpc, NPC_VAR_PENDING_TOTAL, 0);
    SetLocalInt(oNpc, NPC_VAR_PENDING_PRIORITY, NPC_EVENT_PRIORITY_LOW);
    SetLocalInt(oNpc, NPC_VAR_PENDING_CRITICAL, 0);
    SetLocalInt(oNpc, NPC_VAR_PENDING_HIGH, 0);
    SetLocalInt(oNpc, NPC_VAR_PENDING_NORMAL, 0);
    SetLocalInt(oNpc, NPC_VAR_PENDING_LOW, 0);
    SetLocalInt(oNpc, NPC_VAR_INIT_DONE, TRUE);
}

int NpcBehaviorGetInterval(object oNpc)
{
    int nInterval;

    if (GetLocalInt(oNpc, NPC_VAR_STATE) == NPC_STATE_COMBAT)
    {
        nInterval = GetLocalInt(oNpc, NPC_VAR_TICK_INTERVAL_COMBAT_SEC);
        return NpcBehaviorNormalizeInterval(nInterval, NPC_DEFAULT_COMBAT_INTERVAL);
    }

    nInterval = GetLocalInt(oNpc, NPC_VAR_TICK_INTERVAL_IDLE_SEC);
    return NpcBehaviorNormalizeInterval(nInterval, NPC_DEFAULT_IDLE_INTERVAL);
}

int NpcBehaviorShouldProcessAtTime(object oNpc, int nNow)
{
    int nLastTick = GetLocalInt(oNpc, NPC_VAR_LAST_TICK);
    int nIntervalSec = NpcBehaviorGetInterval(oNpc);

    if (nLastTick == 0)
    {
        return TRUE;
    }

    return (NpcBehaviorElapsedSec(nNow, nLastTick) >= nIntervalSec);
}

int NpcBehaviorShouldProcess(object oNpc)
{
    return NpcBehaviorShouldProcessAtTime(oNpc, NpcBehaviorTickNow());
}

int NpcBehaviorCountPlayersInArea(object oArea)
{
    object oObject;
    int nCount;

    if (!GetIsObjectValid(oArea))
    {
        return 0;
    }

    oObject = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oObject))
    {
        if (GetObjectType(oObject) == OBJECT_TYPE_CREATURE && GetIsPC(oObject))
        {
            nCount = nCount + 1;
        }

        oObject = GetNextObjectInArea(oArea);
    }

    return nCount;
}

int NpcBehaviorAreaIsActive(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return FALSE;
    }

    return (GetLocalInt(oArea, NPC_VAR_AREA_ACTIVE) == TRUE);
}

void NpcBehaviorAreaTickLoop(object oArea);

void NpcBehaviorAreaActivate(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    SetLocalInt(oArea, NPC_VAR_AREA_ACTIVE, TRUE);
    if (GetLocalInt(oArea, NPC_VAR_AREA_TIMER_RUNNING) == TRUE)
    {
        return;
    }

    SetLocalInt(oArea, NPC_VAR_AREA_TIMER_RUNNING, TRUE);
    DelayCommand(0.0, NpcBehaviorAreaTickLoop(oArea));
}

void NpcBehaviorAreaDeactivate(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    SetLocalInt(oArea, NPC_VAR_AREA_ACTIVE, FALSE);
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
    int bFlagDecaysSet;
    int bFlagLootableCorpseSet;
    int bFlagDisableAiWhenHiddenSet;
    int bFlagDialogInterruptibleSet;
    int nFlagDecays;
    int nFlagLootableCorpse;
    int nFlagDisableAiWhenHidden;
    int nFlagDialogInterruptible;
    int nDecayTimeSec;
    int nIdleIntervalSec;
    int nCombatIntervalSec;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }


    SetLocalInt(oNpc, NPC_VAR_FLAG_PLOT, GetPlotFlag(oNpc));

    bFlagDecaysSet = GetLocalInt(oNpc, NPC_VAR_FLAG_DECAYS_SET);
    nFlagDecays = GetLocalInt(oNpc, NPC_VAR_FLAG_DECAYS);
    if (bFlagDecaysSet != TRUE)
    {
        nFlagDecays = NPC_DEFAULT_FLAG_DECAYS;
    }
    else if (nFlagDecays != FALSE && nFlagDecays != TRUE)
    {
        nFlagDecays = NPC_DEFAULT_FLAG_DECAYS;
    }
    SetLocalInt(oNpc, NPC_VAR_FLAG_DECAYS, nFlagDecays);
    SetLocalInt(oNpc, NPC_VAR_FLAG_DECAYS_SET, TRUE);

    bFlagLootableCorpseSet = GetLocalInt(oNpc, NPC_VAR_FLAG_LOOTABLE_CORPSE_SET);
    nFlagLootableCorpse = GetLocalInt(oNpc, NPC_VAR_FLAG_LOOTABLE_CORPSE);
    if (bFlagLootableCorpseSet != TRUE)
    {
        nFlagLootableCorpse = NPC_DEFAULT_FLAG_LOOTABLE_CORPSE;
    }
    else if (nFlagLootableCorpse != FALSE && nFlagLootableCorpse != TRUE)
    {
        nFlagLootableCorpse = NPC_DEFAULT_FLAG_LOOTABLE_CORPSE;
    }
    SetLocalInt(oNpc, NPC_VAR_FLAG_LOOTABLE_CORPSE, nFlagLootableCorpse);
    SetLocalInt(oNpc, NPC_VAR_FLAG_LOOTABLE_CORPSE_SET, TRUE);

    bFlagDisableAiWhenHiddenSet = GetLocalInt(oNpc, NPC_VAR_FLAG_DISABLE_AI_WHEN_HIDDEN_SET);
    nFlagDisableAiWhenHidden = GetLocalInt(oNpc, NPC_VAR_FLAG_DISABLE_AI_WHEN_HIDDEN);
    if (bFlagDisableAiWhenHiddenSet != TRUE)
    {
        nFlagDisableAiWhenHidden = NPC_DEFAULT_FLAG_DISABLE_AI_WHEN_HIDDEN;
    }
    else if (nFlagDisableAiWhenHidden != FALSE && nFlagDisableAiWhenHidden != TRUE)
    {
        nFlagDisableAiWhenHidden = NPC_DEFAULT_FLAG_DISABLE_AI_WHEN_HIDDEN;
    }
    SetLocalInt(oNpc, NPC_VAR_FLAG_DISABLE_AI_WHEN_HIDDEN, nFlagDisableAiWhenHidden);
    SetLocalInt(oNpc, NPC_VAR_FLAG_DISABLE_AI_WHEN_HIDDEN_SET, TRUE);

    bFlagDialogInterruptibleSet = GetLocalInt(oNpc, NPC_VAR_FLAG_DIALOG_INTERRUPTIBLE_SET);
    nFlagDialogInterruptible = GetLocalInt(oNpc, NPC_VAR_FLAG_DIALOG_INTERRUPTIBLE);
    if (bFlagDialogInterruptibleSet != TRUE)
    {
        nFlagDialogInterruptible = NPC_DEFAULT_FLAG_DIALOG_INTERRUPTIBLE;
    }
    else if (nFlagDialogInterruptible != FALSE && nFlagDialogInterruptible != TRUE)
    {
        nFlagDialogInterruptible = NPC_DEFAULT_FLAG_DIALOG_INTERRUPTIBLE;
    }
    SetLocalInt(oNpc, NPC_VAR_FLAG_DIALOG_INTERRUPTIBLE, nFlagDialogInterruptible);
    SetLocalInt(oNpc, NPC_VAR_FLAG_DIALOG_INTERRUPTIBLE_SET, TRUE);

    nDecayTimeSec = GetLocalInt(oNpc, NPC_VAR_DECAY_TIME_SEC);
    if (nDecayTimeSec <= 0)
    {
        nDecayTimeSec = NPC_DEFAULT_DECAY_TIME_SEC;
    }
    SetLocalInt(oNpc, NPC_VAR_DECAY_TIME_SEC, nDecayTimeSec);

    nIdleIntervalSec = GetLocalInt(oNpc, NPC_VAR_TICK_INTERVAL_IDLE_SEC);
    nIdleIntervalSec = NpcBehaviorNormalizeInterval(nIdleIntervalSec, NPC_DEFAULT_IDLE_INTERVAL);
    SetLocalInt(oNpc, NPC_VAR_TICK_INTERVAL_IDLE_SEC, nIdleIntervalSec);

    nCombatIntervalSec = GetLocalInt(oNpc, NPC_VAR_TICK_INTERVAL_COMBAT_SEC);
    nCombatIntervalSec = NpcBehaviorNormalizeInterval(nCombatIntervalSec, NPC_DEFAULT_COMBAT_INTERVAL);
    SetLocalInt(oNpc, NPC_VAR_TICK_INTERVAL_COMBAT_SEC, nCombatIntervalSec);

    if (GetLocalInt(oNpc, NPC_VAR_INIT_DONE) != TRUE)
    {
        NpcBehaviorInitialize(oNpc);
    }

    if (GetLocalInt(oNpc, NPC_VAR_FLAG_DISABLE_OBJECT) == TRUE)
    {
        NpcBehaviorMetricInc(oNpc, NPC_VAR_METRIC_SPAWN);
        return;
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

    if (!NpcBehaviorTryIntakeEvent(oNpc, NPC_EVENT_PRIORITY_HIGH, "perception"))
    {
        return;
    }

    NpcBehaviorMetricInc(oNpc, NPC_VAR_METRIC_PERCEPTION);

    // В COMBAT переходим, если hostility есть хотя бы в одну сторону:
    // npc -> seen (базовый сценарий контракта NWScript) или seen -> npc
    // для совместимости с faction/charm асимметрией.
    if (NpcBehaviorIsHostileForCombat(oNpc, oSeen))
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
    int bQueued;

    if (!GetIsObjectValid(oNpc) || NpcBehaviorIsDisabled(oNpc))
    {
        return;
    }

    bQueued = NpcBehaviorTryIntakeEvent(oNpc, NPC_EVENT_PRIORITY_CRITICAL, "");
    if (!bQueued)
    {
        NpcBehaviorMetricInc(oNpc, NPC_VAR_METRIC_INTAKE_BYPASS_CRITICAL);
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

    if (!NpcBehaviorTryIntakeEvent(oNpc, NPC_EVENT_PRIORITY_HIGH, "combat_round"))
    {
        return;
    }

    NpcBehaviorMetricInc(oNpc, NPC_VAR_METRIC_COMBAT_ROUND);

    if (!GetIsInCombat(oNpc) && GetLocalInt(oNpc, NPC_VAR_STATE) == NPC_STATE_COMBAT)
    {
        SetLocalInt(oNpc, NPC_VAR_STATE, NPC_STATE_ALERT);
    }

    NpcBehaviorOnHeartbeat(oNpc);
}

void NpcBehaviorOnPhysicalAttacked(object oNpc)
{
    object oAttacker = GetLastAttacker();
    int bQueued;

    if (!GetIsObjectValid(oNpc) || NpcBehaviorIsDisabled(oNpc))
    {
        return;
    }

    bQueued = NpcBehaviorTryIntakeEvent(oNpc, NPC_EVENT_PRIORITY_CRITICAL, "");
    if (!bQueued)
    {
        NpcBehaviorMetricInc(oNpc, NPC_VAR_METRIC_INTAKE_BYPASS_CRITICAL);
    }

    NpcBehaviorMetricInc(oNpc, NPC_VAR_METRIC_PHYSICAL_ATTACKED);

    // В COMBAT переходим по двусторонней hostility-проверке, чтобы корректно
    // отрабатывать faction/charm сценарии и порядок source/target по контракту.
    if (NpcBehaviorIsHostileForCombat(oNpc, oAttacker))
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

    if (!NpcBehaviorTryIntakeEvent(oNpc, NPC_EVENT_PRIORITY_HIGH, "spell_cast_at"))
    {
        return;
    }

    NpcBehaviorMetricInc(oNpc, NPC_VAR_METRIC_SPELL_CAST_AT);

    // В COMBAT переходим по двусторонней hostility-проверке, чтобы корректно
    // отрабатывать faction/charm сценарии и порядок source/target по контракту.
    if (NpcBehaviorIsHostileForCombat(oNpc, oCaster))
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

    // Death is terminal: cleanup pending queue state before terminal side-effects
    // so per-NPC counters and area buckets cannot leak after death.
    NpcBehaviorFlushPendingQueueState(oNpc);

    NpcBehaviorMetricInc(oNpc, NPC_VAR_METRIC_DEATH);

    if (GetLocalInt(oNpc, NPC_VAR_FLAG_LOOTABLE_CORPSE) == FALSE)
    {
        SetLootable(oNpc, FALSE);
    }

    if (GetLocalInt(oNpc, NPC_VAR_FLAG_DECAYS) == TRUE)
    {
        // NPC_VAR_DECAY_TIME_SEC хранится в секундах и используется без конвертации.
        nDecaySeconds = GetLocalInt(oNpc, NPC_VAR_DECAY_TIME_SEC);
        if (nDecaySeconds <= 0)
        {
            nDecaySeconds = 5;
        }

        DelayCommand(IntToFloat(nDecaySeconds), DestroyObject(oNpc));
    }
}

void NpcBehaviorOnDialogue(object oNpc)
{
    if (!GetIsObjectValid(oNpc) || NpcBehaviorIsDisabled(oNpc))
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
    if (!NpcBehaviorShouldProcessAtTime(oNpc, nNow))
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
    // Compatibility wrapper: canonical OnEndCombatRound path is centralized above.
    NpcBehaviorOnEndCombatRound(oNpc);
}

void NpcBehaviorOnAreaTick(object oArea)
{
    object oObject;
    int nEligibleCount = 0;
    int nEligibleIndex = 0;
    int nStartOffset;
    int nSeq;
    int nBudget;
    int nProcessed = 0;
    int nSkipped = 0;
    int nDeferredByBudget = 0;
    int nPendingBefore;
    int nPendingPriority;

    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    oObject = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oObject))
    {
        if (GetObjectType(oObject) == OBJECT_TYPE_CREATURE
            && !GetIsPC(oObject)
            && !GetIsDead(oObject)
            && GetLocalInt(oObject, NPC_VAR_FLAG_DISABLE_OBJECT) != TRUE
            && GetLocalInt(oObject, NPC_VAR_INIT_DONE) == TRUE)
        {
            nEligibleCount = nEligibleCount + 1;
        }

        oObject = GetNextObjectInArea(oArea);
    }

    if (nEligibleCount <= 0)
    {
        // В зоне не осталось eligible NPC: очищаем накопленную очередь, чтобы degraded mode мог сняться без обработки heartbeat.
        SetLocalInt(oArea, NPC_VAR_PROCESSED_TICK, 0);
        NpcBehaviorAreaQueueReset(oArea);
        NpcBehaviorUpdateAreaDegradedMode(oArea);
        return;
    }

    nSeq = GetLocalInt(oArea, NPC_VAR_AREA_TICK_SEQ);
    nStartOffset = nSeq % nEligibleCount;
    SetLocalInt(oArea, NPC_VAR_AREA_TICK_SEQ, nSeq + 1);

    nBudget = NPC_AREA_BUDGET_PER_TICK;
    if (nBudget > NPC_TICK_PROCESS_LIMIT)
    {
        nBudget = NPC_TICK_PROCESS_LIMIT;
    }

    oObject = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oObject) && nProcessed < nBudget)
    {
        if (GetObjectType(oObject) == OBJECT_TYPE_CREATURE
            && !GetIsPC(oObject)
            && !GetIsDead(oObject)
            && GetLocalInt(oObject, NPC_VAR_FLAG_DISABLE_OBJECT) != TRUE
            && GetLocalInt(oObject, NPC_VAR_INIT_DONE) == TRUE)
        {
            if (nEligibleIndex >= nStartOffset)
            {
                nPendingBefore = GetLocalInt(oObject, NPC_VAR_PENDING_TOTAL);
                nPendingPriority = NpcBehaviorGetTopPendingPriority(oObject);

                // Heartbeat dispatch is the single throttle gate: processed/skipped metrics are decided only by NpcBehaviorOnHeartbeat.
                if (NpcBehaviorOnHeartbeat(oObject))
                {
                    nProcessed = nProcessed + 1;

                    if (nPendingBefore > 0 && nPendingPriority >= NPC_EVENT_PRIORITY_LOW)
                    {
                        NpcBehaviorAreaQueueConsumeByOwner(oArea, oObject, nPendingPriority);
                    }
                }
                else
                {
                    nSkipped = nSkipped + 1;
                }
            }

            nEligibleIndex = nEligibleIndex + 1;
        }

        oObject = GetNextObjectInArea(oArea);
    }

    if (nProcessed < nBudget && nStartOffset > 0)
    {
        nEligibleIndex = 0;
        oObject = GetFirstObjectInArea(oArea);
        while (GetIsObjectValid(oObject) && nProcessed < nBudget)
        {
            if (GetObjectType(oObject) == OBJECT_TYPE_CREATURE
                && !GetIsPC(oObject)
                && !GetIsDead(oObject)
                && GetLocalInt(oObject, NPC_VAR_FLAG_DISABLE_OBJECT) != TRUE
                && GetLocalInt(oObject, NPC_VAR_INIT_DONE) == TRUE)
            {
                if (nEligibleIndex >= nStartOffset)
                {
                    break;
                }

                nPendingBefore = GetLocalInt(oObject, NPC_VAR_PENDING_TOTAL);
                nPendingPriority = NpcBehaviorGetTopPendingPriority(oObject);

                if (NpcBehaviorOnHeartbeat(oObject))
                {
                    nProcessed = nProcessed + 1;

                    if (nPendingBefore > 0 && nPendingPriority >= NPC_EVENT_PRIORITY_LOW)
                    {
                        NpcBehaviorAreaQueueConsumeByOwner(oArea, oObject, nPendingPriority);
                    }
                }
                else
                {
                    nSkipped = nSkipped + 1;
                }

                nEligibleIndex = nEligibleIndex + 1;
            }

            oObject = GetNextObjectInArea(oArea);
        }
    }

    // Deferred здесь трактуется строго как eligible NPC, которые не дошли до обработки
    // из-за исчерпания area-tick budget в текущей ротации/очереди.
    if (nProcessed >= nBudget)
    {
        nDeferredByBudget = nEligibleCount - (nProcessed + nSkipped);
        if (nDeferredByBudget < 0)
        {
            nDeferredByBudget = 0;
        }
    }

    SetLocalInt(oArea, NPC_VAR_PROCESSED_TICK, nProcessed);
    NpcBehaviorMetricAdd(oArea, NPC_VAR_METRIC_AREA_PROCESSED, nProcessed);
    NpcBehaviorMetricAdd(oArea, NPC_VAR_METRIC_AREA_SKIPPED, nSkipped);
    if (nDeferredByBudget > 0)
    {
        NpcBehaviorMetricAdd(oArea, NPC_VAR_METRIC_AREA_DEFERRED, nDeferredByBudget);
    }

    NpcBehaviorUpdateAreaDegradedMode(oArea);
}

void NpcBehaviorAreaTickLoop(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    if (!NpcBehaviorAreaIsActive(oArea))
    {
        SetLocalInt(oArea, NPC_VAR_AREA_TIMER_RUNNING, FALSE);
        return;
    }

    NpcBehaviorOnAreaTick(oArea);
    DelayCommand(NPC_AREA_TICK_INTERVAL_SEC, NpcBehaviorAreaTickLoop(oArea));
}
