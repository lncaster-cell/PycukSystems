# Технический аудит модуля поведения (AL)

Оригинальная дата аудита: 2026-03-04
Актуализация формулировок: 2026-03-07

## Область аудита

Покрытие: runtime-контур в `scripts/al_prototype`.

- area lifecycle: `al_area_onenter`, `al_area_onexit`, `al_mod_onleave`, `al_area_tick_inc`;
- area mode contract: `al_area_constants_inc`, `al_area_mode_contract_inc`;
- registry и NPC orchestration: `al_npc_reg_inc`, `al_npc_onspawn`, `al_npc_onud`, `al_npc_ondeath`;
- route/activity domain: `al_route_cache_inc`, `al_npc_onud`, `al_npc_activity_apply_inc`, `al_npc_sleep_inc`, `al_npc_pair_revalidate_inc`, `al_npc_routes`, `al_acts_inc`.

## Итоговое заключение

Архитектура остаётся production-пригодной: lifecycle детерминированный, stale tick гасятся через token-механику, а fallback-ветки в целом безопасны для игрового состояния.

## Подтверждённые сильные стороны

1. **Token-safe tick orchestration**
   - stale DelayCommand тики не исполняются после изменения `al_tick_token`.

2. **Единый empty-area cleanup**
   - выход последнего игрока и `OnClientLeave` сходятся к `AL_HandleAreaBecameEmpty`.

3. **Предсказуемый area-mode контракт**
   - валидный enum читается напрямую;
   - при невалидном значении используется deterministic legacy fallback.

4. **Защита от контент-ошибок**
   - при проблемах маршрута/активности NPC не зависает в неопределённом состоянии, а уходит в безопасный режим.

## Текущие риски

1. **Ограниченная телеметрия fallback-веток**
   - нет встроенных counters по частоте route/activity fallback.

2. **Нагрузка при высокой плотности NPC**
   - `AL_EVT_ROUTE_REPEAT` может увеличивать event-noise на crowded area.

3. **Критичность качества metadata**
   - ошибки в `alwp*`, `al_activity`, `al_transition_*` напрямую отражаются на стабильности поведения.

4. **Лимит registry**
   - `AL_MAX_NPCS=100` — жёсткий потолок участников на area.

## Рекомендации

### Высокий приоритет

- Ввести метрики на area: route_resync/activity_fallback/route_truncation.
- Добавить pre-release validator контентных настроек маршрутов.

### Средний приоритет

- Подготовить нагрузочный профиль для сцен с высокой плотностью AL-NPC.
- Формализовать профильные рекомендации по частоте repeat и длине маршрутов.

### Низкий приоритет

- Опциональный reason-tracking transitions для расширенной диагностики режимов area.

## Минимальный regression smoke после правок

1. first enter -> wake + resync;
2. slot boundary -> slot broadcast;
3. route repeat на активном NPC;
4. last exit -> freeze/hide;
5. re-enter -> повторный wake без дублей registry.
