# NPC module (behavior runtime) — полная документация

Этот документ описывает **модуль поведения NPC** из `src/modules/npc/`: как он устроен, как работает в рантайме, как подключить и настроить его в тулсете (NWN2 Toolset), какие локальные переменные и контракты используются, и как проверять модуль после изменений.

> Область документа: только `src/modules/npc`.
> Папка `third_party/` и компилятор внутри неё не относятся к этому модулю и в рамках этого README не используются.

---

## 1) Что входит в модуль

Каталог `src/modules/npc/` состоит из двух частей:

1. **Thin entrypoint scripts** (тонкие скрипты-хуки событий).
   Они почти ничего не решают сами, а делегируют в core.
2. **Core/include слой** (`npc_core`, `npc_activity_inc`, `npc_metrics_inc`) с основной логикой lifecycle, очереди, активностей и метрик.

### Состав файлов

- `npc_core.nss` — центральная runtime-логика:
  - lifecycle area-controller (`RUNNING/PAUSED/STOPPED`),
  - bounded queue с приоритетами,
  - tick pipeline и degraded mode,
  - обработка hook-событий,
  - интеграция write-behind flush.
- `npc_activity_inc.nss` — activity adapter/runtime:
  - слот/маршрут/состояние NPC,
  - schedule-aware выбор route,
  - waypoint/activity разрешение.
- `npc_metrics_inc.nss` — helper API для метрик.
- Thin hooks:
  - `npc_spawn.nss`
  - `npc_perception.nss`
  - `npc_damaged.nss`
  - `npc_death.nss`
  - `npc_dialogue.nss`
  - `npc_area_enter.nss`
  - `npc_area_exit.nss`
  - `npc_area_tick.nss`
  - `npc_area_maintenance.nss`
  - `npc_module_load.nss`

---

## 2) Архитектура и модель выполнения

## 2.1 Lifecycle по области

Для каждой area хранится состояние:

- `STOPPED` — loop не активен;
- `RUNNING` — обычный tick processing;
- `PAUSED` — watchdog-режим (редкий тик + обслуживание).

Главные принципы:

- В RUNNING модуль обрабатывает очередь событий и activity.
- В PAUSED основной интенсивный loop выключен, но есть watchdog и maintenance.
- При полном idle и отсутствии игроков area может быть автоматически остановлена.

## 2.2 Очередь событий NPC

Очередь bounded (ограниченная), приоритетная:

- `CRITICAL`
- `HIGH`
- `NORMAL`
- `LOW`

Особенности:

- coalesce/anti-duplicate: повторные события не раздувают очередь бесконтрольно;
- starvation guard: low-priority bucket не должен голодать вечно;
- overflow guardrail: при переполнении применяются правила деградации и trim/drop;
- deferred accounting: часть задач может быть отложена и учитывается отдельными счётчиками.

## 2.3 Tick pipeline (high-level)

Один area tick проходит через стадии:

1. **Подготовка бюджетов** (events/budget/carryover).
2. **Budgeted work** — цикл обработки очереди в пределах budget.
3. **Degradation/carryover** — выставление режима деградации и перенос бюджета.
4. **Deferred reconcile/trim** — защитные операции на deferred backlog.
5. **Backlog telemetry + idle stop policy**.
6. **Flush write-behind** (по условию).
7. **Планирование следующего тика** по state.

Эта стадийность нужна, чтобы разделять hot-path и maintenance-path и держать поведение предсказуемым.

---

## 3) Карта hook-скриптов для тулсета

Ниже — какие entrypoint-скрипты назначать на события в NWN2 Toolset.

> Важно: это thin wrappers. Их нельзя перегружать бизнес-логикой — логика живет в `npc_core`/include.

| Toolset hook | Script |
|---|---|
| Module OnLoad | `npc_module_load` |
| Creature OnSpawn | `npc_spawn` |
| Creature OnPerception | `npc_perception` |
| Creature OnDamaged | `npc_damaged` |
| Creature OnDeath | `npc_death` |
| Creature OnConversation / Dialogue | `npc_dialogue` |
| Area OnEnter | `npc_area_enter` |
| Area OnExit | `npc_area_exit` |
| Area Tick dispatcher (через DelayCommand) | `npc_area_tick` |
| Area maintenance watchdog | `npc_area_maintenance` |

Практика интеграции:

- Назначайте эти скрипты как canonical hooks в шаблонах существ/областей модуля.
- Не создавайте отдельные «альтернативные» копии с теми же обязанностями — это ломает контрактный контур.

---

## 4) Настройка в тулсете: пошагово

### Шаг 1. Подключить исходники

Убедитесь, что `npc_*.nss`, `npc_core.nss`, `npc_activity_inc.nss`, `npc_metrics_inc.nss` присутствуют в вашем рабочем наборе скриптов модуля.

### Шаг 2. Назначить event hooks

В NWN2 Toolset:

- на уровне **Module properties** выставить `OnLoad = npc_module_load`;
- на уровне **Area properties** привязать вход/выход (`npc_area_enter`, `npc_area_exit`) в используемом у вас пайплайне;
- на уровне **Creature blueprint/template** назначить:
  - `OnSpawn = npc_spawn`
  - `OnPerception = npc_perception`
  - `OnDamaged = npc_damaged`
  - `OnDeath = npc_death`
  - `OnConversation = npc_dialogue` (или ваш эквивалент поля диалога).

### Шаг 3. Проверить старт lifecycle

После загрузки модуля (`npc_module_load`) runtime должен:

- инициализировать подсистемы,
- применить tick runtime config,
- активировать/восстановить area loops в корректных состояниях.

### Шаг 4. Проверить базовые NPC locals

Для NPC стоит проверить наличие runtime locals после spawn/первых тиков:

- `npc_activity_slot`
- `npc_activity_route_effective`
- `npc_activity_state`
- `npc_activity_last`
- `npc_activity_last_ts`

Для area:

- `npc_area_state`
- `npc_queue_pending_total`
- `npc_tick_max_events`
- `npc_tick_soft_budget_ms`

### Шаг 5. Проверить, что loop «живой»

Косвенные признаки:

- меняются метрики processed/degraded,
- обновляется activity state у NPC,
- при idle очередь не растёт,
- при нагрузке queue budget ограничивает обработку, но не стопорит модуль.

---

## 5) Конфигурация runtime (что можно настраивать)

## 5.1 Tick budget

Поддерживаются ключи конфигурации:

- `npc_cfg_tick_max_events`
- `npc_cfg_tick_soft_budget_ms`

Цепочка применения:

1. area-local override,
2. module-local fallback,
3. встроенные defaults.

Нормализация:

- значения ограничиваются hard-cap внутри runtime,
- итог сохраняется в:
  - `npc_tick_max_events`
  - `npc_tick_soft_budget_ms`

## 5.2 Очередь и деградация

Контур использует:

- bounded queue,
- reason-коды деградации,
- deferred cap,
- carryover events.

Это значит: при пиковых нагрузках модуль «сбрасывает давление» по правилам, а не деградирует в неуправляемую задержку.

## 5.3 Activity slot/route

NPC runtime учитывает:

- slot (`default/priority/critical`),
- route profile,
- route tag,
- schedule windows,
- waypoint loop/count/index.

Некорректные значения нормализуются в допустимые и отмечаются метриками invalid-route/invalid-slot.

---

## 6) Runtime-переменные (сокращенный справочник)

## 6.1 Area locals

- `npc_area_state`
- `npc_area_timer_running`
- `npc_area_maint_timer_running`
- `npc_queue_depth`
- `npc_queue_pending_total`
- `npc_queue_deferred_total`
- `npc_tick_max_events`
- `npc_tick_soft_budget_ms`
- `npc_tick_carryover_events`
- `npc_tick_degraded_mode`
- `npc_tick_last_degradation_reason`
- `npc_player_count`

## 6.2 NPC locals (activity/pending)

- `npc_activity_slot`
- `npc_activity_route`
- `npc_activity_route_effective`
- `npc_activity_state`
- `npc_activity_last`
- `npc_activity_last_ts`
- `npc_activity_cooldown`
- `npc_activity_wp_index`
- `npc_activity_wp_count`
- `npc_activity_wp_loop`

Pending/queue зеркало:

- `npc_pending_priority`
- `npc_pending_reason`
- `npc_pending_status`
- `npc_pending_updated_at`

---

## 7) Метрики и диагностика

Модуль использует helper API метрик и пишет runtime-счётчики для наблюдаемости.

Полезные направления мониторинга:

- throughput:
  - `processed_total`
- деградация:
  - `tick_budget_exceeded_total`
  - `degraded_mode_total`
  - `degradation_events_total`
  - `tick_last_degradation_reason`
- очередь:
  - dropped/deferred counters
  - pending/deferred totals
- maintenance:
  - self-heal reconcile counters

Если видите устойчивый рост degraded/overflow — увеличивайте budget аккуратно и/или снижайте интенсивность генерации событий у контента.

---

## 8) Рекомендации по тюнингу в тулсете

1. **Начинайте с дефолтов** и меняйте только при фактической нагрузке.
2. **Повышайте budget постепенно**:
   - сначала `npc_cfg_tick_max_events`;
   - затем при необходимости `npc_cfg_tick_soft_budget_ms`.
3. **Не назначайте CRITICAL без необходимости** — это bypass fairness.
4. **Проверяйте schedule/route данные на контенте** (ошибки маршрутов маскируются fallback-механизмами, но стоят метрик и качества поведения).
5. **Сохраняйте thin-hook модель**: любые расширения добавляйте в include/core, а не в entrypoint-файлы.

---

## 9) Процедура валидации после изменений

Минимальный набор:

```bash
bash scripts/test_npc_smoke.sh
bash scripts/check_npc_lifecycle_contract.sh
bash scripts/test_npc_fairness.sh
bash scripts/test_npc_activity_contract.sh
```

Дополнительно (по необходимости):

```bash
bash scripts/test_npc_activity_lifecycle_smoke.sh
bash scripts/test_npc_activity_schedule_contract.sh
bash scripts/test_npc_activity_route_contract.sh
```

---

## 10) Типичные проблемы и что проверить

### Проблема: NPC «замирают»

Проверьте:

- правильность hook-скриптов на blueprint,
- `npc_area_state` (не осталась ли area в STOPPED/PAUSED),
- queue pending/deferred totals,
- presence `npc_activity_route_effective` и `npc_activity_state`.

### Проблема: сильная деградация под нагрузкой

Проверьте:

- `tick_budget_exceeded_total` и reason-коды,
- не превышен ли разумный queue pressure,
- настройку `npc_cfg_tick_max_events` / `npc_cfg_tick_soft_budget_ms`.

### Проблема: route/slot ведут себя «не так»

Проверьте:

- валидность route id/tag,
- schedule окна,
- не срабатывает ли fallback (через метрики invalid-route/invalid-slot).

---

## 11) Правила расширения модуля

Чтобы не ломать контракт:

- сохраняйте thin entrypoints тонкими;
- новую behavior-логику добавляйте в include/core;
- не меняйте ключевые local key names без миграционного слоя;
- при любой оптимизации сохраняйте совместимость lifecycle/queue/activity контрактов;
- после изменений всегда гоняйте contract checks.

---

## 12) Краткий интеграционный чеклист

- [ ] Скрипты `src/modules/npc` подключены в проект модуля.
- [ ] Hook-скрипты назначены в NWN2 Toolset согласно таблице.
- [ ] На module load вызывается `npc_module_load`.
- [ ] После запуска подтверждён живой area loop.
- [ ] Проверены базовые area/NPC locals.
- [ ] Прогнаны smoke + lifecycle + fairness + activity контракты.

Если все пункты отмечены — NPC behavior module считается корректно интегрированным и готовым к дальнейшему контентному развитию.
