// NPC Bhvr metrics helper API.
// Contract: entrypoints и core должны писать метрики только через NpcBhvrMetricInc/NpcBhvrMetricAdd.

const string NPC_BHVR_METRIC_SPAWN_COUNT = "npc_metric_spawn_count";
const string NPC_BHVR_METRIC_PERCEPTION_COUNT = "npc_metric_perception_count";
const string NPC_BHVR_METRIC_DAMAGED_COUNT = "npc_metric_damaged_count";
const string NPC_BHVR_METRIC_DEATH_COUNT = "npc_metric_death_count";
const string NPC_BHVR_METRIC_DIALOGUE_COUNT = "npc_metric_dialogue_count";
const string NPC_BHVR_METRIC_AREA_ENTER_COUNT = "npc_metric_area_enter_count";
const string NPC_BHVR_METRIC_AREA_EXIT_COUNT = "npc_metric_area_exit_count";
const string NPC_BHVR_METRIC_MODULE_LOAD_COUNT = "npc_metric_module_load_count";
const string NPC_BHVR_METRIC_QUEUE_OVERFLOW_COUNT = "npc_metric_queue_overflow_count";
// queue_deferred_count: переход pending-статуса в deferred (дефир очереди, не размер backlog).
const string NPC_BHVR_METRIC_QUEUE_DEFERRED_COUNT = "npc_metric_queue_deferred_count";
// queue_dropped_count: запись завершена со статусом dropped (overflow или invalid subject).
const string NPC_BHVR_METRIC_QUEUE_DROPPED_COUNT = "npc_metric_queue_dropped_count";
const string NPC_BHVR_METRIC_QUEUE_ENQUEUED_COUNT = "npc_metric_queue_enqueued_count";
// queue_coalesced_count: повторное событие обновило существующую pending-запись (coalescing, без дубликата).
const string NPC_BHVR_METRIC_QUEUE_COALESCED_COUNT = "npc_metric_queue_coalesced_count";
const string NPC_BHVR_METRIC_QUEUE_STARVATION_GUARD_TRIPS = "npc_metric_queue_starvation_guard_trips";
const string NPC_BHVR_METRIC_QUEUE_INDEX_HIT_TOTAL = "npc_metric_queue_index_hit_total";
const string NPC_BHVR_METRIC_QUEUE_INDEX_MISS_TOTAL = "npc_metric_queue_index_miss_total";
const string NPC_BHVR_METRIC_REGISTRY_OVERFLOW_TOTAL = "npc_metric_registry_overflow_total";
const string NPC_BHVR_METRIC_REGISTRY_REJECT_TOTAL = "npc_metric_registry_reject_total";
const string NPC_BHVR_METRIC_ACTIVITY_INVALID_SLOT_TOTAL = "npc_metric_activity_invalid_slot_total";
const string NPC_BHVR_METRIC_ACTIVITY_SCHEDULE_WINDOW_INVALID_TOTAL = "npc_metric_activity_schedule_window_invalid_total";
const string NPC_BHVR_METRIC_ACTIVITY_REFRESH_TOTAL = "activity_refresh_total";
const string NPC_BHVR_METRIC_ACTIVITY_REFRESH_SKIPPED_TOTAL = "activity_refresh_skipped_total";

// Tick-budget/degraded-mode metrics.
const string NPC_BHVR_METRIC_PROCESSED_TOTAL = "npc_metric_processed_total";
const string NPC_BHVR_METRIC_TICK_BUDGET_EXCEEDED_TOTAL = "npc_metric_tick_budget_exceeded_total";
const string NPC_BHVR_METRIC_DEGRADED_MODE_TOTAL = "npc_metric_degraded_mode_total";
const string NPC_BHVR_METRIC_DEGRADATION_EVENTS_TOTAL = "npc_metric_degradation_events_total";
const string NPC_BHVR_METRIC_ACTIVITY_INVALID_ROUTE_TOTAL = "npc_metric_activity_invalid_route_total";
// pending_age_ms: интегральный возраст хвоста pending (pending_count * tick_ms surrogate).
const string NPC_BHVR_METRIC_PENDING_AGE_MS = "npc_metric_pending_age_ms";
// paused_watchdog_tick_count: редкий watchdog-тик в PAUSED, отдельный от RUNNING tick-loop.
const string NPC_BHVR_METRIC_PAUSED_WATCHDOG_TICK_COUNT = "npc_metric_paused_watchdog_tick_count";
// maintenance_self_heal_count: число self-heal правок deferred-total в maintenance loop.
const string NPC_BHVR_METRIC_MAINT_SELF_HEAL_COUNT = "npc_metric_maintenance_self_heal_count";
const string NPC_BHVR_METRIC_IDLE_PROCESSED_PER_TICK = "npc_metric_idle_processed_per_tick";
const string NPC_BHVR_METRIC_IDLE_REMAINING = "npc_metric_idle_remaining";

void NpcBhvrMetricSet(object oScope, string sMetric, int nValue)
{
    if (!GetIsObjectValid(oScope))
    {
        return;
    }

    SetLocalInt(oScope, sMetric, nValue);
}

void NpcBhvrMetricAdd(object oScope, string sMetric, int nDelta)
{
    int nCurrent;

    if (!GetIsObjectValid(oScope) || nDelta == 0)
    {
        return;
    }

    nCurrent = GetLocalInt(oScope, sMetric);
    SetLocalInt(oScope, sMetric, nCurrent + nDelta);
}

void NpcBhvrMetricInc(object oScope, string sMetric)
{
    NpcBhvrMetricAdd(oScope, sMetric, 1);
}
