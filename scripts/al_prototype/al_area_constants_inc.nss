// Shared constants for Area tick pipeline.

const float AL_TICK_PERIOD = 45.0;
const int AL_SYNC_TICK_INTERVAL = 4;

// Area mode contract.
// al_area_mode local must keep one of AL_AREA_MODE_* explicit values.
// Absence of this local is interpreted via legacy behavior in contract helpers.
const string AL_AREA_MODE_LOCAL_KEY = "al_area_mode";

const int AL_AREA_MODE_HOT = 1;
const int AL_AREA_MODE_WARM = 2;
const int AL_AREA_MODE_COLD = 3;
const int AL_AREA_MODE_OFF = 4;
