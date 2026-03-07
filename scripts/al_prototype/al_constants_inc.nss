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
