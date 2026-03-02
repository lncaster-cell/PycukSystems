// Shared constants for Ambient Life.

const int AL_SLOT_MAX = 5;
const int AL_MAX_NPCS = 100;
// Max amount of route points copied from area cache to one NPC route slot.
const int AL_ROUTE_MAX_POINTS = 10;

const int AL_EVT_SLOT_BASE = 3000;
const int AL_EVT_SLOT_0 = AL_EVT_SLOT_BASE;
const int AL_EVT_SLOT_5 = AL_EVT_SLOT_BASE + AL_SLOT_MAX;
const int AL_EVT_RESYNC = AL_EVT_SLOT_BASE + AL_SLOT_MAX + 1;
const int AL_EVT_ROUTE_REPEAT = AL_EVT_SLOT_BASE + AL_SLOT_MAX + 2;

