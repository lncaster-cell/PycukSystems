// Module 3 metrics helper API.
// Contract: entrypoints и core должны писать метрики только через Module3MetricInc/Module3MetricAdd.

const string MODULE3_METRIC_PREFIX = "module3_metric_";

const string MODULE3_METRIC_SPAWN_COUNT = "module3_metric_spawn_count";
const string MODULE3_METRIC_PERCEPTION_COUNT = "module3_metric_perception_count";
const string MODULE3_METRIC_DAMAGED_COUNT = "module3_metric_damaged_count";
const string MODULE3_METRIC_DEATH_COUNT = "module3_metric_death_count";
const string MODULE3_METRIC_DIALOGUE_COUNT = "module3_metric_dialogue_count";
const string MODULE3_METRIC_AREA_ENTER_COUNT = "module3_metric_area_enter_count";
const string MODULE3_METRIC_AREA_EXIT_COUNT = "module3_metric_area_exit_count";
const string MODULE3_METRIC_MODULE_LOAD_COUNT = "module3_metric_module_load_count";
const string MODULE3_METRIC_QUEUE_OVERFLOW_COUNT = "module3_metric_queue_overflow_count";
const string MODULE3_METRIC_QUEUE_COALESCED_COUNT = "module3_metric_queue_coalesced_count";
const string MODULE3_METRIC_QUEUE_DEFERRED_COUNT = "module3_metric_queue_deferred_count";
const string MODULE3_METRIC_QUEUE_DROPPED_COUNT = "module3_metric_queue_dropped_count";
const string MODULE3_METRIC_QUEUE_ENQUEUED_COUNT = "module3_metric_queue_enqueued_count";
const string MODULE3_METRIC_QUEUE_STARVATION_GUARD_TRIPS = "module3_metric_queue_starvation_guard_trips";
const string MODULE3_METRIC_TICK_BUDGET_EXCEEDED_TOTAL = "module3_metric_tick_budget_exceeded_total";
const string MODULE3_METRIC_DEGRADED_MODE_TOTAL = "module3_metric_degraded_mode_total";
const string MODULE3_METRIC_PROCESSED_TOTAL = "module3_metric_processed_total";
const string MODULE3_METRIC_PENDING_AGE_MS = "module3_metric_pending_age_ms";

void Module3MetricAdd(object oScope, string sMetric, int nDelta)
{
    int nCurrent;

    if (!GetIsObjectValid(oScope) || nDelta == 0)
    {
        return;
    }

    nCurrent = GetLocalInt(oScope, sMetric);
    SetLocalInt(oScope, sMetric, nCurrent + nDelta);
}

void Module3MetricInc(object oScope, string sMetric)
{
    Module3MetricAdd(oScope, sMetric, 1);
}
