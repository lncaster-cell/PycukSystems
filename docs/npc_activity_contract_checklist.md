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
- `npc_activity_route_effective` всегда хранит итог fallback-резолва (`default_route|priority_patrol|critical_safe`).

**Что считается fail:** смешение семантик (например, запись fallback-значения в configured поле).

## 3) Поведение при invalid route/slot

Инварианты:
- `NpcBhvrActivityNormalizeConfiguredRouteOrEmpty` отбрасывает невалидный route-id и не блокирует fallback-цепочку;
- `slot` нормализуется в поддерживаемые значения (`default|priority|critical`);
- в `NpcBhvrActivityOnIdleTick` пустые/невалидные `slot/route` допустимы и приводятся к валидному effective маршруту через fallback.

**Что считается fail:** невалидные route/slot сохраняются и напрямую ломают ветвление idle-dispatch.

## 4) Cooldown/dispatch ветвление (`critical_safe`, `priority_patrol`, `default`)

Инварианты для `NpcBhvrActivityOnIdleTick`:
- при `cooldown > 0` — только декремент cooldown на 1 и early-return;
- при `cooldown == 0` выбирается ровно одна ветка:
  1. `critical_safe` (приоритет №1: `slot=critical` или route-map -> `critical_safe`) → `idle_critical_safe`, `cooldown=1`;
  2. `priority_patrol` (приоритет №2: `slot=priority` или route-map -> `priority_patrol`) → `idle_priority_patrol`, `cooldown=2`;
  3. `default` (fallback) → `idle_default`, `cooldown=1`.

**Что считается fail:** отсутствие приоритета critical над priority, множественный dispatch за один idle tick, либо неверный cooldown после dispatch.

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

### 3. Компиляционный smoke-check include/runtime контура

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
