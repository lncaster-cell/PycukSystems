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
const string AL_L_METRIC_SUMMARY_TICK = "al_metric_summary_tick";
const string AL_L_METRIC_ROUTE_RESYNC_COUNT = "al_metric_route_resync_count";
const string AL_L_METRIC_ACTIVITY_FALLBACK_COUNT = "al_metric_activity_fallback_count";
const string AL_L_METRIC_ROUTE_TRUNCATED_COUNT = "al_metric_route_truncated_count";
const string AL_L_NPC_COUNT = "al_npc_count";
const string AL_L_NPC_FULL_MSG_NEXT = "al_npc_full_msg_next";
const string AL_L_ROUTE_ACTIVE = "r_active";
const string AL_L_ROUTE_SLOT = "r_slot";
const string AL_L_ROUTE_INDEX = "r_idx";
const string AL_L_LAST_ROUTE_RECOVER_TICK = "al_last_route_recover_tick";
const string AL_L_SLEEP_DOCKED = "al_sleep_docked";
const string AL_L_SLEEP_APPROACH_TAG = "al_sleep_approach_tag";
const string AL_L_TRAINING_PARTNER = "al_training_partner";
const string AL_L_TRAINING_PARTNER_CACHED = "al_training_partner_cached";
const string AL_L_TRAINING_NPC1 = "al_training_npc1";
const string AL_L_TRAINING_NPC2 = "al_training_npc2";
const string AL_L_TRAINING_NPC1_REF = "al_training_npc1_ref";
const string AL_L_TRAINING_NPC2_REF = "al_training_npc2_ref";
const string AL_L_BAR_PAIR = "al_bar_pair";
const string AL_L_BAR_BARTENDER = "al_bar_bartender";
const string AL_L_BAR_BARMAID = "al_bar_barmaid";
const string AL_L_BAR_BARTENDER_REF = "al_bar_bartender_ref";
const string AL_L_BAR_BARMAID_REF = "al_bar_barmaid_ref";
const string AL_L_BED_TAG = "al_bed_tag";
const string AL_L_LAST_SLOT = "al_last_slot";
const string AL_L_LAST_BLOCKED_TS = "al_last_blocked_ts";
const string AL_L_AUTO_CLOSE_TOKEN = "al_auto_close_token";
const string AL_L_DEBUG = "al_debug";
const string AL_L_IS_INTERIOR = "al_is_interior";
const string AL_L_REPEAT_NEXT = "al_repeat_next";
const string AL_L_SYNC_TICK = "al_sync_tick";
const string AL_L_WP_ROUTE_INDEX = "al_route_index";
const string AL_L_ROUTE_INDEX_PRESENT = "al_route_index_present";
const string AL_L_ROUTE_INDEX_SET = "al_route_index_set";
const string AL_L_TRANSITION_AREA_TAG = "al_transition_area_tag";
const string AL_L_TRANSITION_WAYPOINT_TAG = "al_transition_waypoint_tag";
const string AL_L_ROUTE_KNOWN_N = "al_route_known_n";
const string AL_L_ROUTE_KNOWN_TAG_PREFIX = "al_route_known_tag_";
const string AL_L_ROUTE_SCAN_SEEN_PREFIX = "al_route_scan_seen_";
const string AL_L_ROUTE_SCAN_TAG_PREFIX = "al_route_scan_tag_";
const string AL_L_ROUTE_REBUILD_SEEN_PREFIX = "al_route_rebuild_seen_";
const string AL_L_ROUTE_REBUILD_TAG_PREFIX = "al_route_rebuild_tag_";
const string AL_L_ROUTE_PREFIX = "al_route_";
const string AL_L_ROUTE_SCAN_TMP_PREFIX = "al_route_scan_tmp_";
const string AL_L_ACTIVITY = "al_activity";

string AL_LocalNpcRegistryEntry(int iIndex)
{
    return "al_npc_" + IntToString(iIndex);
}

string AL_LocalWaypointTag(int iSlot)
{
    return "alwp" + IntToString(iSlot);
}

string AL_LocalRouteTagPrefix(string sTag)
{
    return AL_L_ROUTE_PREFIX + sTag + "_";
}

string AL_LocalRouteScanTagKey(int iIndex)
{
    return AL_L_ROUTE_SCAN_TAG_PREFIX + IntToString(iIndex);
}

string AL_LocalRouteScanSeenKey(string sTag)
{
    return AL_L_ROUTE_SCAN_SEEN_PREFIX + sTag;
}

string AL_LocalRouteRebuildSeenKey(string sTag)
{
    return AL_L_ROUTE_REBUILD_SEEN_PREFIX + sTag;
}

string AL_LocalRouteRebuildTagKey(int iIndex)
{
    return AL_L_ROUTE_REBUILD_TAG_PREFIX + IntToString(iIndex);
}

string AL_LocalRouteKnownTagKey(int iIndex)
{
    return AL_L_ROUTE_KNOWN_TAG_PREFIX + IntToString(iIndex);
}

string AL_LocalRouteScanTmpPrefix(string sTag)
{
    return AL_L_ROUTE_SCAN_TMP_PREFIX + sTag + "_";
}
