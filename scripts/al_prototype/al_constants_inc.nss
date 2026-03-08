// Shared constants for Ambient Life.

const int AL_SLOT_MAX = 5;
const int AL_MAX_NPCS = 100;
// Max amount of route points copied from area cache to one NPC route slot.
const int AL_ROUTE_MAX_POINTS = 10;

const int AL_EVT_SLOT_BASE = 3000;
const int AL_EVT_SLOT_0 = AL_EVT_SLOT_BASE;
const int AL_EVT_SLOT_5 = 3005;
const int AL_EVT_RESYNC = 3006;
const int AL_EVT_ROUTE_REPEAT = 3007;

// Area-mode limiters for repeat requeue pulses (AL_EVT_ROUTE_REPEAT).
const int AL_ROUTE_REPEAT_MIN_GAP_SECONDS_WARM = 2;
const int AL_ROUTE_REPEAT_MIN_GAP_SECONDS_HOT = 1;

// Shared local-variable keys (dictionary for maintainability).
const string AL_L_ENABLED = "al_enabled";
const string AL_L_EXIT_COUNTED = "al_exit_counted";
const string AL_L_LAST_AREA = "al_last_area";
const string AL_L_PLAYER_COUNT = "al_player_count";
const string AL_L_SLOT = "al_slot";
const string AL_L_ROUTES_CACHED = "al_routes_cached";
const string AL_L_TICK_TOKEN = "al_tick_token";
const string AL_L_TICK_SCHEDULED_TOKEN = "al_tick_scheduled_token";
const string AL_L_TICK_WARM_LEFT = "al_tick_warm_left";
const string AL_L_NPC_COUNT = "al_npc_count";
const string AL_L_NPC_FULL_MSG_NEXT = "al_npc_full_msg_next";
const string AL_L_ROUTE_ACTIVE = "r_active";
const string AL_L_ROUTE_SLOT = "r_slot";
const string AL_L_ROUTE_INDEX = "r_idx";
const string AL_L_LAST_ROUTE_RECOVER_TICK = "al_last_route_recover_tick";
const string AL_L_SLEEP_DOCKED = "al_sleep_docked";
const string AL_L_SLEEP_APPROACH_TAG = "al_sleep_approach_tag";

string AL_LocalNpcRegistryEntry(int iIndex)
{
    return "al_npc_" + IntToString(iIndex);
}

string AL_LocalWaypointTag(int iSlot)
{
    return "alwp" + IntToString(iSlot);
}
