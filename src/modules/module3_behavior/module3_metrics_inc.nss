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
const string MODULE3_METRIC_QUEUE_DEFERRED_COUNT = "module3_metric_queue_deferred_count";
const string MODULE3_METRIC_QUEUE_ENQUEUED_COUNT = "module3_metric_queue_enqueued_count";
const string MODULE3_METRIC_QUEUE_STARVATION_GUARD_TRIPS = "module3_metric_queue_starvation_guard_trips";

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
