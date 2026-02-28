# Ambient Life V3 — Runtime/internal contract reference

Технический справочник по внутреннему контракту runtime. Для ручной настройки используйте `docs/npc_toolset_authoring_contract.md`.

## 1) Three-level local model

### A. Authoring locals (user-facing)

- NPC (canonical):
  - `npc_cfg_role`
  - `npc_cfg_slot_dawn_route`, `npc_cfg_slot_morning_route`, `npc_cfg_slot_afternoon_route`, `npc_cfg_slot_evening_route`, `npc_cfg_slot_night_route`
  - `npc_cfg_force_reactive`, `npc_cfg_allow_physical_hide`
  - optional: `npc_cfg_alert_route`
- Area: `npc_cfg_city`, `npc_cfg_cluster`, `npc_cfg_area_profile`

### B. Derived config (facade-computed)

- `npc_cfg_derived_role`
- `npc_cfg_derived_schedule` (legacy compatibility marker)
- `npc_cfg_derived_area_profile`
- `npc_cfg_derived_cluster_owner`

### C. Runtime locals (engine/internal)

Существующий `npc_*` runtime keyspace: lifecycle/dispatch/LOD/queue/activity/route runtime.

## 2) Canonical runtime locals (`npc_*`)

### NPC-level
- Runtime layer/dispatch:
  - `npc_runtime_layer` / `npc_cfg_layer` / `npc_cfg_reactive`
- Activity/profile:
  - `npc_activity_mode` (`daily|alert`)
  - `npc_activity_slot`
  - `npc_activity_slot_effective`, `npc_activity_route_effective`
  - `npc_activity_state`, `npc_activity_last`, `npc_activity_last_ts`
- Activity runtime-only diagnostics/internal:
  - `npc_activity_resolved_hour`, `npc_activity_area_effective`
  - `npc_activity_slot_fallback`, `npc_activity_invalid_slot_last`
  - `npc_activity_precheck_l1_stamp`, `npc_activity_precheck_l2_stamp`
- Route profile locals (resolved by fallback):
  - `npc_route_profile_slot_<slot>` (`dawn|morning|afternoon|evening|night`)
  - `npc_route_profile_alert` (optional alert override)
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

## 3) Route/mode resolution (canonical)

1. Нормализуется mode (`daily|alert`).
2. Для `alert` сначала проверяется `npc_route_profile_alert`.
3. Иначе используется `npc_route_profile_slot_<current_slot>`.
4. Затем area cache fallback (`npc_route_cache_slot_<slot>` / `npc_route_cache_default`).
5. Иначе `default_route`.

`activity` всегда берётся с waypoint (`npc_route_activity_<route>_<idx>`), а не из slot/mode напрямую.

## 4) Facade compatibility rules

- Facade — тонкий слой над текущим runtime, не второй runtime.
- Legacy bridge (`al_* -> npc_*`) остаётся migration-only и не ломается.
- Низкоуровневые runtime locals сохраняют обратную совместимость.
- Preset schedule authoring (`npc_cfg_schedule` + work/home/leisure) остаётся legacy/compatibility path и не считается каноническим контрактом.
- При наличии уже выставленных runtime/config locals фасад применяет пресеты как defaults и не должен агрессивно перетирать explicit overrides.

## 5) Legacy AL migration bridge

Legacy `al_*` поддерживается только как migration adapter (`npc_legacy_al_bridge_inc.nss`).

### Поддержанный subset `al_* -> npc_*`
- `al_slot` -> `npc_activity_slot` (legacy aliases `default|priority|critical` normalизуются в daypart `afternoon|morning|night`)
- `al_route` мигрируется только как compatibility source маршрута; активный runtime-path использует slot-route profile chain
- `al_schedule_enabled` -> `npc_activity_schedule_enabled` (legacy flag only; canonical slot resolver ignores schedule windows)
- `al_schedule_critical_start/end`, `al_schedule_priority_start/end` не мигрируются в canonical behavior path
- `al_route_default|priority|critical` -> area route profile defaults (`npc_route_profile_*`) с canonical daypart slot-map
- `al_route_count_*|loop_*|tag_*|pause_*|activity_*` -> canonical `npc_route_*`

### Intentionally not supported
- Любые legacy AL ключи вне указанного subset.
- Неподдержанные/невалидные route значения не становятся canonical truth автоматически; используется controlled fallback + diagnostics.
