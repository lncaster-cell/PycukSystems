# Ambient Life QA Checklist

Версия чеклиста: 2026-03-07 (обновлено)

## 1) Smoke: lifecycle area

1. Игрок входит в пустую area:
   - `al_player_count` становится `1`;
   - `al_area_mode` -> `HOT`;
   - у area увеличивается `al_tick_token`;
   - регистрированные NPC получают `AL_EVT_RESYNC`.

2. Второй игрок входит в ту же area:
   - `al_player_count` инкрементируется;
   - wake-path повторно не запускается.

3. Последний игрок выходит:
   - `al_player_count` -> `0`;
   - `AL_HandleAreaBecameEmpty` переводит area в `COLD`;
   - route cache инвалидируется;
   - NPC скрываются.

## 2) Smoke: tick pipeline

1. В `HOT` тик идёт с hot period (`15s`).
2. При warm-tail (`al_tick_warm_left`) происходит переход `HOT -> WARM`.
3. В `COLD/OFF` тик не продолжает планирование.
4. При stale token отложенный тик безопасно прерывается.
5. При `al_debug>=1` каждые 20 тиков появляется summary-лог `AL: area metric summary` с текущими счётчиками area.

## 3) Smoke: adjacency / interior

1. На source-area задать `al_adjacent_areas="area_b"`.
2. Убедиться, что при пробуждении source-area сосед получает минимум `WARM`.
3. Если сосед interior (`al_is_interior=1`) и не в whitelist:
   - прогрев не применяется;
   - при `al_debug=1` виден fallback-log.
4. Добавить interior tag в `al_adj_interior_whitelist` и повторить тест.

## 4) Smoke: registry integrity

1. Проверить dense-массив `al_npc_0..al_npc_count-1` без дыр после unregister.
2. Проверить, что NPC при смене area удаляется из старой и добавляется в новую registry.
3. При переполнении (`>100`) убедиться, что лишние NPC не регистрируются и есть throttled debug.

## 5) Smoke: route/activity safety

1. Невалидный route/activity должен уводить NPC в безопасный fallback.
2. `AL_EVT_ROUTE_REPEAT` игнорируется, если route неактивен или слот устарел.
3. Для парных ролей (training/bar) при разрыве пары обе стороны переходят в fallback-активность.
4. После fallback-сценариев проверить, что в summary корректно отражаются счётчики:
   - `al_metric_summary_tick` монотонно растёт на каждом area tick;
   - `al_metric_activity_fallback_count` увеличивается после fallback активностей;
   - `al_metric_route_resync_count` и `al_metric_route_truncated_count` не уменьшаются и меняются только при соответствующих кейсах.

## 6) Regression notes

После любых правок scripts/al_prototype обязательно прогонять секции 1–5 минимум на:

- одной уличной area;
- одной interior area;
- одной area с высокой плотностью NPC.
