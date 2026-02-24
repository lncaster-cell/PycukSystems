// NPC Bhvr runtime core (preparation contour).
// Обязательные контракты:
// 1) lifecycle area-controller,
// 2) bounded queue + priority buckets,
// 3) единый вход в метрики через helper API.

#include "npc_metrics_inc"
#include "npc_activity_inc"
#include "npc_sql_api_inc"
#include "npc_wb_inc"

const int NPC_BHVR_AREA_STATE_STOPPED = 0;
const int NPC_BHVR_AREA_STATE_RUNNING = 1;
const int NPC_BHVR_AREA_STATE_PAUSED = 2;

const int NPC_BHVR_PRIORITY_CRITICAL = 0;
const int NPC_BHVR_PRIORITY_HIGH = 1;
const int NPC_BHVR_PRIORITY_NORMAL = 2;
const int NPC_BHVR_PRIORITY_LOW = 3;

const int NPC_BHVR_REASON_UNSPECIFIED = 0;
const int NPC_BHVR_REASON_PERCEPTION = 1;
const int NPC_BHVR_REASON_DAMAGE = 2;

const int NPC_BHVR_DEGRADATION_REASON_NONE = 0;
const int NPC_BHVR_DEGRADATION_REASON_EVENT_BUDGET = 1;
const int NPC_BHVR_DEGRADATION_REASON_SOFT_BUDGET = 2;
const int NPC_BHVR_DEGRADATION_REASON_OVERFLOW = 4;
const int NPC_BHVR_DEGRADATION_REASON_QUEUE_PRESSURE = 5;
const int NPC_BHVR_DEGRADATION_REASON_ROUTE_MISS = 6;
const int NPC_BHVR_DEGRADATION_REASON_DISABLED = 7;

const string NPC_BHVR_PENDING_STATUS_STR_QUEUED = "queued";
const string NPC_BHVR_PENDING_STATUS_STR_RUNNING = "running";
const string NPC_BHVR_PENDING_STATUS_STR_PROCESSED = "processed";
const string NPC_BHVR_PENDING_STATUS_STR_DEFERRED = "deferred";
const string NPC_BHVR_PENDING_STATUS_STR_DROPPED = "dropped";


const int NPC_BHVR_QUEUE_MAX = 64;
const int NPC_BHVR_REGISTRY_MAX = 100;
const int NPC_BHVR_STARVATION_STREAK_LIMIT = 3;
const int NPC_BHVR_TICK_MAX_EVENTS_DEFAULT = 4;
const int NPC_BHVR_TICK_SOFT_BUDGET_MS_DEFAULT = 25;
const int NPC_BHVR_TICK_SIMULATED_EVENT_COST_MS = 8;
const int NPC_BHVR_TICK_MAX_EVENTS_HARD_CAP = 64;
const int NPC_BHVR_TICK_SOFT_BUDGET_MS_HARD_CAP = 1000;
const int NPC_BHVR_TICK_CARRYOVER_MAX_EVENTS = 4;
const int NPC_BHVR_TICK_FLAG_EVENT_BUDGET_REACHED = 1;
const int NPC_BHVR_TICK_FLAG_SOFT_BUDGET_REACHED = 2;
const int NPC_BHVR_TICK_FLAG_BUDGET_EXCEEDED = 4;
// Deferred cap contract: ограничивает только deferred-backlog в очереди.
// Источник истины — area-local счётчик npc_queue_deferred_total с reconcile-guardrail.
const int NPC_BHVR_TICK_DEFERRED_CAP = 16;
const float NPC_BHVR_AREA_TICK_INTERVAL_RUNNING_SEC = 1.0;
const float NPC_BHVR_AREA_TICK_INTERVAL_PAUSED_WATCHDOG_SEC = 30.0;
const float NPC_BHVR_AREA_MAINTENANCE_WATCHDOG_INTERVAL_SEC = 60.0;

const string NPC_BHVR_VAR_AREA_STATE = "npc_area_state";
const string NPC_BHVR_VAR_AREA_TIMER_RUNNING = "npc_area_timer_running";
const string NPC_BHVR_VAR_MAINT_TIMER_RUNNING = "npc_area_maint_timer_running";
const string NPC_BHVR_VAR_MAINT_SELF_HEAL_FLAG = "npc_area_maint_self_heal";
const string NPC_BHVR_VAR_QUEUE_DEPTH = "npc_queue_depth";
const string NPC_BHVR_VAR_QUEUE_PENDING_TOTAL = "npc_queue_pending_total";
const string NPC_BHVR_VAR_QUEUE_DEFERRED_TOTAL = "npc_queue_deferred_total";
const string NPC_BHVR_VAR_QUEUE_CURSOR = "npc_queue_cursor";
const string NPC_BHVR_VAR_FAIRNESS_STREAK = "npc_fairness_streak";
const string NPC_BHVR_VAR_TICK_MAX_EVENTS = "npc_tick_max_events";
const string NPC_BHVR_VAR_TICK_SOFT_BUDGET_MS = "npc_tick_soft_budget_ms";
const string NPC_BHVR_CFG_TICK_MAX_EVENTS = "npc_cfg_tick_max_events";
const string NPC_BHVR_CFG_TICK_SOFT_BUDGET_MS = "npc_cfg_tick_soft_budget_ms";
const string NPC_BHVR_VAR_TICK_DEGRADED_MODE = "npc_tick_degraded_mode";
const string NPC_BHVR_VAR_TICK_DEGRADED_STREAK = "npc_tick_degraded_streak";
const string NPC_BHVR_VAR_TICK_DEGRADED_TOTAL = "npc_tick_degraded_total";
const string NPC_BHVR_VAR_TICK_BUDGET_EXCEEDED_TOTAL = "npc_tick_budget_exceeded_total";
const string NPC_BHVR_VAR_TICK_LAST_DEGRADATION_REASON = "npc_tick_last_degradation_reason";
const string NPC_BHVR_VAR_TICK_PROCESSED = "npc_tick_processed";
const string NPC_BHVR_VAR_QUEUE_BACKLOG_AGE_TICKS = "npc_queue_backlog_age_ticks";
const string NPC_BHVR_VAR_TICK_CARRYOVER_EVENTS = "npc_tick_carryover_events";
const string NPC_BHVR_VAR_REGISTRY_COUNT = "npc_registry_count";
const string NPC_BHVR_VAR_REGISTRY_PREFIX = "npc_registry_";
const string NPC_BHVR_VAR_REGISTRY_INDEX_PREFIX = "npc_registry_index_";
const string NPC_BHVR_VAR_NPC_UID = "npc_uid";
const string NPC_BHVR_VAR_NPC_UID_COUNTER = "npc_uid_counter";
const string NPC_BHVR_VAR_PLAYER_COUNT = "npc_player_count";
const string NPC_BHVR_VAR_PLAYER_COUNT_INITIALIZED = "npc_player_count_initialized";
const int NPC_BHVR_PENDING_STATUS_QUEUED = 1;
const int NPC_BHVR_PENDING_STATUS_RUNNING = 2;
const int NPC_BHVR_PENDING_STATUS_PROCESSED = 3;
const int NPC_BHVR_PENDING_STATUS_DEFERRED = 4;
const int NPC_BHVR_PENDING_STATUS_DROPPED = 5;

const string NPC_BHVR_VAR_PENDING_PRIORITY = "npc_pending_priority";
const string NPC_BHVR_VAR_PENDING_REASON = "npc_pending_reason";
const string NPC_BHVR_VAR_PENDING_STATUS = "npc_pending_status";
const string NPC_BHVR_VAR_PENDING_UPDATED_AT = "npc_pending_updated_at";

#include "npc_registry_inc"
#include "npc_queue_inc"
#include "npc_tick_inc"
#include "npc_lifecycle_inc"

void NpcBhvrOnAreaTick(object oArea)
{
    NpcBhvrOnAreaTickImpl(oArea);
}

void NpcBhvrOnAreaMaintenance(object oArea)
{
    NpcBhvrOnAreaMaintenanceImpl(oArea);
}

void NpcBhvrBootstrapModuleAreas()
{
    NpcBhvrBootstrapModuleAreasImpl();
}

void NpcBhvrOnSpawn(object oNpc)
{
    object oArea;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_SPAWN_COUNT);
    NpcBhvrActivityOnSpawn(oNpc);

    oArea = GetArea(oNpc);
    if (GetIsObjectValid(oArea))
    {
        NpcBhvrRegistryInsert(oArea, oNpc);
        if (!NpcBhvrAreaIsRunning(oArea))
        {
            NpcBhvrAreaActivate(oArea);
        }
    }
}

void NpcBhvrOnPerception(object oNpc)
{
    object oArea;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_PERCEPTION_COUNT);
    oArea = GetArea(oNpc);
    NpcBhvrQueueEnqueue(oArea, oNpc, NPC_BHVR_PRIORITY_HIGH, NPC_BHVR_REASON_PERCEPTION);
}

void NpcBhvrOnDamaged(object oNpc)
{
    object oArea;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_DAMAGED_COUNT);
    oArea = GetArea(oNpc);
    NpcBhvrQueueEnqueue(oArea, oNpc, NPC_BHVR_PRIORITY_CRITICAL, NPC_BHVR_REASON_DAMAGE);
}

void NpcBhvrOnDeath(object oNpc)
{
    object oArea;

    NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_DEATH_COUNT);
    oArea = GetArea(oNpc);
    if (GetIsObjectValid(oArea))
    {
        NpcBhvrRegistryRemove(oArea, oNpc);
    }
}

void NpcBhvrOnDialogue(object oNpc)
{
    NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_DIALOGUE_COUNT);
}

void NpcBhvrOnAreaEnter(object oArea, object oEntering)
{
    int nPlayers;
    int nEnteringType;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oEntering))
    {
        return;
    }

    NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_AREA_ENTER_COUNT);
    if (!GetIsPC(oEntering))
    {
        nEnteringType = GetObjectType(oEntering);
        if (nEnteringType != OBJECT_TYPE_CREATURE)
        {
            // Ранний фильтр снижает noise в npc_metric_registry_reject_total.
            return;
        }

        NpcBhvrRegistryInsert(oArea, oEntering);
        return;
    }

    if (GetIsDM(oEntering))
    {
        return;
    }

    nPlayers = NpcBhvrGetCachedPlayerCount(oArea) + 1;
    SetLocalInt(oArea, NPC_BHVR_VAR_PLAYER_COUNT, nPlayers);
    SetLocalInt(oArea, NPC_BHVR_VAR_PLAYER_COUNT_INITIALIZED, TRUE);

    if (!NpcBhvrAreaIsRunning(oArea))
    {
        NpcBhvrAreaActivate(oArea);
    }
}

void NpcBhvrOnAreaExit(object oArea, object oExiting)
{
    int nPlayers;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oExiting))
    {
        return;
    }

    NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_AREA_EXIT_COUNT);

    if (!GetIsPC(oExiting))
    {
        NpcBhvrRegistryRemove(oArea, oExiting);
        NpcBhvrAreaRouteCacheInvalidate(oArea);
        return;
    }

    if (GetIsDM(oExiting))
    {
        return;
    }

    nPlayers = NpcBhvrGetCachedPlayerCount(oArea) - 1;
    if (nPlayers < 0)
    {
        // Self-heal: clamp + rebuild on desync instead of allowing negative cached state.
        nPlayers = NpcBhvrCountPlayersInAreaExcluding(oArea, oExiting);
        if (nPlayers < 0)
        {
            nPlayers = 0;
        }
    }

    SetLocalInt(oArea, NPC_BHVR_VAR_PLAYER_COUNT, nPlayers);
    SetLocalInt(oArea, NPC_BHVR_VAR_PLAYER_COUNT_INITIALIZED, TRUE);

    // Pause policy mirrors auto-idle-stop player definition: only non-DM PCs keep area active.
    if (nPlayers <= 0)
    {
        NpcBhvrAreaPause(oArea);
    }
}

void NpcBhvrOnModuleLoad()
{
    NpcSqliteInit();
    NpcSqliteHealthcheck();
    NpcBhvrMetricInc(GetModule(), NPC_BHVR_METRIC_MODULE_LOAD_COUNT);
    NpcBhvrBootstrapModuleAreas();
}
