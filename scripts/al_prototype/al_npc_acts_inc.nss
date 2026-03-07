// NPC activity compatibility facade.
//
// This file intentionally keeps the historic include name for backwards
// compatibility. Prefer direct includes of focused modules in entrypoints.

#include "al_npc_activity_apply_inc"
#include "al_npc_sleep_inc"
#include "al_npc_pair_revalidate_inc"

// Include layering contract (one-way):
// - al_npc_activity_apply_inc -> {al_acts_inc, al_constants_inc, al_debug_inc, al_npc_routes}
// - al_npc_sleep_inc          -> {al_npc_activity_apply_inc}
// - al_npc_pair_revalidate_inc-> {al_debug_inc}
// - al_npc_acts_inc           -> {al_npc_activity_apply_inc, al_npc_sleep_inc, al_npc_pair_revalidate_inc}
// Entrypoints should include only the specific modules they use.
