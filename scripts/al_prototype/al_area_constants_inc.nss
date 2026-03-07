// Shared constants for Area tick pipeline.

// Canonical area heat/mode enum.
const int AL_AREA_MODE_COLD = 0;
const int AL_AREA_MODE_WARM = 1;
const int AL_AREA_MODE_HOT = 2;
const int AL_AREA_MODE_OFF = 3;

const float AL_TICK_PERIOD_COLD = 45.0;
const float AL_TICK_PERIOD_WARM = 30.0;
const float AL_TICK_PERIOD = 45.0;
const float AL_TICK_PERIOD_HOT = 15.0;
const int AL_SYNC_TICK_INTERVAL = 4;
const int AL_TICK_WARM_REPEATS = 2;

// Canonical local keys for the minimal quarter/adjacency model.
const string AL_AREA_MODE_LOCAL_KEY = "al_area_mode";
const string AL_AREA_QUARTER_LOCAL_KEY = "al_quarter_id";
const string AL_AREA_ADJ_LIST_LOCAL_KEY = "al_adjacent_areas";
const string AL_AREA_ADJ_INTERIOR_WHITELIST_LOCAL_KEY = "al_adj_interior_whitelist";
