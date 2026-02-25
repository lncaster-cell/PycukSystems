# Ambient Life V3 Toolset Authoring Contract (Canonical)

Этот документ — **канонический** контракт настройки контента для нового runtime `src/modules/npc/*`.

## 1) Hook scripts (обязательная привязка)

- Module OnLoad: `npc_module_load`
- Area OnEnter / OnExit: `npc_area_enter` / `npc_area_exit`
- Area heartbeat/timer dispatch: `npc_area_tick` и `npc_area_maintenance` (через runtime scheduler)
- Creature hooks:
  - OnSpawn: `npc_spawn`
  - OnPerception: `npc_perception` (только для reactive-path)
  - OnDamaged: `npc_damaged` (только для reactive-path)
  - OnDeath: `npc_death`
  - OnDialogue: `npc_dialogue`

## 2) Canonical locals (npc_*)

### NPC-level
- Runtime layer/dispatch:
  - `npc_runtime_layer` / `npc_cfg_layer` / `npc_cfg_reactive`
- Activity/profile:
  - `npc_activity_slot`, `npc_activity_route`
  - `npc_activity_slot_effective`, `npc_activity_route_effective`
  - `npc_activity_state`, `npc_activity_last`, `npc_activity_last_ts`
- Waypoint/route runtime:
  - `npc_activity_wp_index`, `npc_activity_wp_count`, `npc_activity_wp_loop`
  - `npc_activity_route_tag`, `npc_activity_action`
  - `npc_route_count_<route>`, `npc_route_loop_<route>`, `npc_route_tag_<route>`, `npc_route_pause_ticks_<route>`, `npc_route_activity_<route>_<idx>`
- LOD/projection:
  - `npc_npc_sim_lod`, `npc_npc_projected_state`
  - `npc_lod_hidden_at`, `npc_lod_projected_*`
- Optional physical hide:
  - `npc_cfg_lod_physical_hide` (per-NPC opt-in)

### Area-level
- Lifecycle/cluster:
  - `npc_area_state`, `npc_area_cluster_owner`, `npc_area_interest_state`
- Runtime dispatch:
  - `npc_dispatch_mode`
- Cluster knobs:
  - `npc_cfg_cluster_grace_sec`
  - `npc_cfg_cluster_interior_soft_cap`, `npc_cfg_cluster_interior_hard_cap`
  - `npc_cfg_cluster_transition_rate`, `npc_cfg_cluster_transition_burst`
- LOD knobs:
  - `npc_cfg_lod_running_hide`, `npc_cfg_lod_running_hide_distance`, `npc_cfg_lod_running_reveal_distance`
  - `npc_cfg_lod_running_debounce_sec`, `npc_cfg_lod_min_hidden_sec`, `npc_cfg_lod_min_visible_sec`
  - `npc_cfg_lod_reveal_cooldown_sec`, `npc_cfg_lod_phase_step_sec`
  - `npc_cfg_lod_physical_hide_enabled`, `npc_cfg_lod_physical_min_hidden_sec`, `npc_cfg_lod_physical_min_visible_sec`, `npc_cfg_lod_physical_cooldown_sec`

### Waypoint/route anchors
- Используется canonical `npc_route_*` keyspace (count/loop/tag/activity/pause).
- Route id/tag должны быть валидными (`[a-z0-9_]`, с fallback к default policy).

## 3) Legacy AL migration bridge

Legacy `al_*` поддерживается только как **migration-only adapter** (`npc_legacy_al_bridge_inc.nss`).
После нормализации canonical truth остаётся `npc_*`.

### Поддержанный subset `al_* -> npc_*`
- `al_slot` -> `npc_activity_slot`
- `al_route` -> `npc_activity_route` (через normalize/fallback)
- `al_schedule_enabled` -> `npc_activity_schedule_enabled`
- `al_schedule_critical_start/end` -> `npc_schedule_start_critical` / `npc_schedule_end_critical`
- `al_schedule_priority_start/end` -> `npc_schedule_start_priority` / `npc_schedule_end_priority`
- `al_route_default|priority|critical` -> area route profile defaults (`npc_route_profile_*`)
- `al_route_count_*|loop_*|tag_*|pause_*|activity_*` -> canonical `npc_route_*`

### Intentionally not supported
- Любые legacy AL ключи вне указанного subset.
- Неподдержанные/невалидные route значения не становятся canonical truth автоматически; вместо этого используется controlled fallback + diagnostics.

## 4) Migration points and idempotency

- Migration-on-spawn: `NpcBhvrLegacyBridgeMigrateNpc`
- Migration-on-activate: `NpcBhvrLegacyBridgeMigrateAreaDefaults`
- Idempotency: version stamps
  - `npc_legacy_bridge_npc_version`
  - `npc_legacy_bridge_area_version`

## 5) Diagnostics

- `npc_metric_legacy_migrated_npc_total`
- `npc_metric_legacy_migrated_area_total`
- `npc_metric_legacy_normalized_keys_total`
- `npc_metric_legacy_unsupported_keys_total`
- `npc_metric_legacy_fallback_total`
