# NPC Activity Contract Checklist


Чеклист фиксирует проверяемые инварианты activity-layer контракта NPC Bhvr из `src/modules/npc/README.md` и даёт команды для быстрого smoke/regression прогона.

## 1) Route fallback resolve order

Инвариант (`NpcBhvrActivityResolveRouteProfile`): effective route выбирается строго в таком порядке:
1. `npc_activity_route` на NPC (если явно задан);
2. `npc_route_profile_slot_<slot>` на NPC;
3. `npc_route_profile_default` на NPC;
4. `npc_route_profile_slot_<slot>` на area;
5. `npc_route_profile_default` на area;
6. `default_route`.

**Что считается fail:** любой рефакторинг, который нарушает приоритет источников (например, area override раньше NPC override).

## 2) Разделение configured vs effective route

Инвариант:
- `npc_activity_route` хранит только явно сконфигурированный route (или очищается);
- `npc_activity_route_effective` всегда хранит итог fallback-резолва (валидный route-id или `default_route`).

**Что считается fail:** смешение семантик (например, запись fallback-значения в configured поле).

## 3) Поведение при invalid route/slot

Инварианты:
- `NpcBhvrActivityNormalizeConfiguredRouteOrEmpty` отбрасывает невалидный route-id и не блокирует fallback-цепочку;
- `slot` нормализуется в daypart (`dawn|morning|afternoon|evening|night`), legacy `default|priority|critical` допустимы только как alias;
- в `NpcBhvrActivityOnIdleTick` пустые/невалидные `slot/route` допустимы и приводятся к валидному effective маршруту через fallback.

**Что считается fail:** невалидные route/slot сохраняются и напрямую ломают ветвление idle-dispatch.

## 4) Cooldown/dispatch: canonical flow + mode (`daily|alert`)

Инварианты для `NpcBhvrActivityOnIdleTick`:
- при `cooldown > 0` — только декремент cooldown на 1 и early-return;
- при `cooldown == 0` выбирается ровно одна ветка:
  1. resolve current time slot (daypart);
  2. resolve effective route через fallback-цепочку;
  3. применить единый dispatch `NpcBhvrActivityApplyRouteState(route, "idle_route", cooldown=1)`.

**Что считается fail:** множественный dispatch за один idle tick, либо обход canonical route-apply path через semantic-ветки как основной путь.

## 5) Waypoint/route-point runtime semantics

Порт AmbientLiveV2 data-layer считается обязательным: mapping activity-id -> metadata (custom/numeric anims, requirements) не должен деградировать относительно legacy `al_acts_inc.nss`.

Инварианты для `NpcBhvrActivityApplyRouteState` и `NpcBhvrActivityOnIdleTick`:
- при наличии `npc_route_count_<routeId> > 0` route-dispatch использует waypoint-индекс `npc_activity_wp_index`;
- loop-policy берётся из `npc_route_loop_<routeId>` (`>0` loop, `<0` stop-at-tail, `0` default loop);
- `npc_activity_route_tag` участвует в формировании состояния `<base_state>_<tag>_<i>_of_<N>`;
- `npc_activity_slot_emote` резолвится через slot-aware цепочку `NPC-local(slot) -> area-local(slot) -> area-global -> NPC-global`;
- `npc_activity_action` вычисляется детерминированно из mode/slot/waypoint (`alert => guard_hold`, `daily+morning => patrol_*`, иначе `ambient_*`), а `npc_route_pause_ticks_<routeId>` добавляется к cooldown.

**Что считается fail:** waypoint-индекс не обновляется после dispatch, route-tag игнорируется при наличии waypoint-count, или slot-emote не резолвится по slot-aware цепочке.

## 6) E2E daypart semantics (`npc_activity_slot`, `npc_activity_route_effective`, `npc_activity_last_ts`)

Инварианты e2e-уровня для расписаний:
- переходы `npc_activity_slot` по времени детерминированы через daypart mapping (`dawn|morning|afternoon|evening|night`);
- после daypart-resolve dispatch всегда идёт по единому route path (`NpcBhvrActivityApplyRouteState`);
- boundary-кейсы проверяются явно для daypart mapping и границы суток (`23:59:59 -> 00:00:00`);
- schedule windows не участвуют в canonical model и не влияют на выбор slot;
- `npc_activity_route_effective` следует fallback-цепочке независимо от невалидного configured route;
- `npc_activity_last_ts` формируется как `hour*3600 + minute*60 + second` и корректно сбрасывается при переходе суток.

**Что считается fail:** несогласованные переходы слота на границах окна/суток, отсутствие fallback при пустом расписании, либо нарушение контракта `route_effective`/`last_ts`.

---

## 7) Legacy note: schedule-window keys

Инвариант (`NpcBhvrActivityIsHourInWindow`):
- при `start == end` окно трактуется как **пустое** (`FALSE` для любого часа), а не как 24/7;
- schedule-window ключи считаются legacy-only и не являются частью canonical поведенческого пути.

**Что считается fail:** любая реализация/документация, в которой `start == end` начинает активировать слот круглосуточно.

---

## Как проверить (команды из `scripts/`)

> Ниже — минимальный набор проверок, который должен выполняться перед merge изменений activity-layer.

### 1. Контрактные lifecycle-паттерны модуля NPC

```bash
bash scripts/check_npc_lifecycle_contract.sh
```

**Pass признаки:**
- в выводе есть строка `[OK] npc lifecycle contract checks passed`.

**Fail признаки:**
- `[FAIL]` (missing/unexpected pattern, отсутствующий файл, отсутствующий контракт).

### 2. Self-check fairness/gate-анализаторов (включая негативные сценарии)

```bash
bash scripts/test_npc_fairness.sh
```

**Pass признаки:**
- есть `[OK] NPC Bhvr gate checks passed` для positive fixture;
- negative fixtures действительно падают внутри test harness;
- финальная строка: `[OK] NPC Bhvr fairness analyzer tests passed`.

**Fail признаки:**
- любая строка вида `[FAIL] ...`;
- нет финального `[OK] NPC Bhvr fairness analyzer tests passed`.


### 3. Activity route/waypoint/daypart e2e contract (одной командой)

```bash
bash scripts/test_npc_activity_contract.sh
```

**Pass признаки:**
- есть `[OK] npc_activity route contract tests passed`;
- есть `[OK] NPC activity waypoint contract tests passed`;
- есть `[OK] npc_activity slot contract tests passed`;
- есть `[OK] npc_activity route_effective contract tests passed`;
- есть `[OK] npc_activity last_ts contract tests passed`.

**Fail признаки:**
- `[FAIL]` по любому из контрактов route/waypoint/schedule e2e.

### 4. Компиляционный smoke-check include/runtime контура

```bash
bash scripts/compile.sh check
```

**Pass признаки:**
- команда завершается с кодом `0`;
- нет критических ошибок компиляции в `src/modules/npc/*`.

**Fail признаки:**
- non-zero exit code;
- ошибки компиляции/инклудов, блокирующие runtime-контур.

---

## Практика использования чеклиста

- Прогоняйте команды из секции «Как проверить» после любых изменений в:
  - `src/modules/npc/npc_activity_inc.nss`,
  - `src/modules/npc/npc_core.nss`,
  - adapter/runtime контрактах activity routing.
- При любом fail фиксируйте причину в PR и обновляйте regression-кейсы в `docs/perf/fixtures/npc/*` при изменении ожиданий.
