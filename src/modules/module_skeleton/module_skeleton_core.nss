#include "nw_i0_plot"

const string MOD_SKEL_VAR_STATE = "mod_skel_state";
const string MOD_SKEL_VAR_LAST_DEGRADATION_REASON = "mod_skel_last_degradation_reason";

const int MOD_SKEL_STATE_STOPPED = 0;
const int MOD_SKEL_STATE_RUNNING = 1;
const int MOD_SKEL_STATE_PAUSED = 2;

void ModuleSkeletonMetricInc(object oScope, string sMetric)
{
    SetLocalInt(oScope, sMetric, GetLocalInt(oScope, sMetric) + 1);
}

void ModuleSkeletonSetDegradationReason(object oScope, string sReason)
{
    SetLocalString(oScope, MOD_SKEL_VAR_LAST_DEGRADATION_REASON, sReason);
    ModuleSkeletonMetricInc(oScope, "mod_skel_metric_degradation_events_total");
}

void ModuleSkeletonInit(object oScope)
{
    SetLocalInt(oScope, MOD_SKEL_VAR_STATE, MOD_SKEL_STATE_STOPPED);
    ModuleSkeletonMetricInc(oScope, "mod_skel_metric_init_total");
}

void ModuleSkeletonStart(object oScope)
{
    SetLocalInt(oScope, MOD_SKEL_VAR_STATE, MOD_SKEL_STATE_RUNNING);
    ModuleSkeletonMetricInc(oScope, "mod_skel_metric_start_total");
}

void ModuleSkeletonPause(object oScope)
{
    SetLocalInt(oScope, MOD_SKEL_VAR_STATE, MOD_SKEL_STATE_PAUSED);
    ModuleSkeletonMetricInc(oScope, "mod_skel_metric_pause_total");
}

void ModuleSkeletonStop(object oScope)
{
    SetLocalInt(oScope, MOD_SKEL_VAR_STATE, MOD_SKEL_STATE_STOPPED);
    ModuleSkeletonMetricInc(oScope, "mod_skel_metric_stop_total");
}

void ModuleSkeletonReload(object oScope)
{
    ModuleSkeletonMetricInc(oScope, "mod_skel_metric_reload_total");
    ModuleSkeletonStart(oScope);
}

void ModuleSkeletonEntrypointOnModuleLoad()
{
    object oModule = GetModule();
    ModuleSkeletonInit(oModule);
    ModuleSkeletonStart(oModule);
}

void ModuleSkeletonEntrypointOnAreaTick(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    if (GetLocalInt(oArea, MOD_SKEL_VAR_STATE) != MOD_SKEL_STATE_RUNNING)
    {
        return;
    }

    ModuleSkeletonMetricInc(oArea, "mod_skel_metric_processed_total");
}

void ModuleSkeletonEntrypointOnSpawn(object oSubject)
{
    if (!GetIsObjectValid(oSubject))
    {
        return;
    }

    ModuleSkeletonMetricInc(oSubject, "mod_skel_metric_spawn_total");
}
