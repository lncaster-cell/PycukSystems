# Roadmap реализации Area Modes для Ambient Life

Контекст (зафиксировано):
- slot-driven ядро сохраняется;
- HOT/COLD строятся поверх текущего lifecycle;
- WARM добавляется как новый режим;
- interiors по умолчанию COLD;
- adjacency и quarter ownership читаются через area locals;
- debug и операционная диагностика идут через чат.

## Этап 0 — контракт и аудит

| Пункт | Содержание |
|---|---|
| **1. Цель** | Зафиксировать единый контракт area modes (HOT/WARM/COLD/OFF), точки интеграции в существующий lifecycle и критерии обратной совместимости c legacy (`al_player_count`). |
| **2. Затронутые файлы/модули** | `scripts/al_prototype/al_area_mode_contract_inc.nss`, `scripts/al_prototype/al_area_constants_inc.nss`, `docs/ambient-life-technical.md`, `docs/behavior-module-audit-2026-03-04.md` (разделы по рискам/наблюдаемости). |
| **3. Минимальный объём изменений** | (а) инвентаризация текущих area/npc lifecycle-точек, где читается «теплота» area; (б) матрица переходов режимов; (в) перечень обязательных locals: `al_area_mode`, `al_quarter_id`, `al_adjacent_areas`; (г) аудит debug-сообщений для fallback и конфликтов конфигурации. Без изменения runtime-поведения. |
| **4. Основные риски** | Разные команды по-разному трактуют WARM (как ускоренный HOT vs как «пред-HOT»); конфликт legacy-логики с новым local-режимом; недоописанные OFF-сценарии (maintenance/dev area). |
| **5. Smoke-сценарии** | Документарные сценарии (без runtime-правок): 1) area без `al_area_mode` -> legacy HOT/COLD; 2) area с валидным `al_area_mode` -> приоритет контракта; 3) битый mode value -> deterministic fallback и debug-сообщение. |
| **6. Что согласовать до реализации** | Каноничные enum-значения режимов; приоритет источников (explicit local > derived legacy); формат adjacency (CSV по tag) и правила валидации; минимальный набор debug-сообщений в чат (формат, throttle, audience). |

---

## Этап 1 — минимальный HOT/COLD поверх текущего lifecycle

| Пункт | Содержание |
|---|---|
| **1. Цель** | Перевести текущую implicit-модель (`players > 0 => HOT`) в явный mode-контур без ломки slot-driven цикла и существующего wake/freeze пайплайна. |
| **2. Затронутые файлы/модули** | `scripts/al_prototype/al_area_onenter.nss`, `scripts/al_prototype/al_area_onexit.nss`, `scripts/al_prototype/al_mod_onleave.nss`, `scripts/al_prototype/al_area_tick_inc.nss`, `scripts/al_prototype/al_npc_reg_inc.nss`, `scripts/al_prototype/al_area_mode_contract_inc.nss`, `scripts/al_prototype/al_debug_inc.nss`. |
| **3. Минимальный объём изменений** | (а) в точках wake/freeze использовать `AL_GetAreaModeOrLegacy` как источник решения; (б) HOT удерживает текущий tick/RESYNC semantics; (в) COLD повторяет существующий empty-area freeze (hide + очистка runtime route-state); (г) debug-лог в чат при mode transition HOT↔COLD. |
| **4. Основные риски** | Дубли transition-событий из двух источников (`player_count` и explicit mode); race между OnExit и module leave fallback; случай «mode=COLD, но игрок уже в area». |
| **5. Smoke-сценарии** | 1) Первый вход игрока: COLD->HOT, wake 1–6, тик стартует; 2) Выход последнего игрока: HOT->COLD, единый empty handler; 3) Re-enter после freeze: корректный token bump, stale ticks не оживают; 4) Явный `al_area_mode=HOT` при `player_count=0` — area остаётся активной по контракту. |
| **6. Что согласовать до реализации** | Правило истины при конфликте explicit mode и player_count; список областей, где allowed forced HOT; границы чат-диагностики (все transition или только аномалии). |

---

## Этап 2 — interiors default COLD + whitelist exceptions

| Пункт | Содержание |
|---|---|
| **1. Цель** | Снизить фоновую нагрузку: interior-area по умолчанию замораживаются (COLD), кроме явно разрешённых исключений. |
| **2. Затронутые файлы/модули** | `scripts/al_prototype/al_area_mode_contract_inc.nss` (резолв режима), area metadata locals (toolset-профили), `docs/ambient-life-technical.md` (policy интерьеров), debug-поток через `scripts/al_prototype/al_debug_inc.nss`. |
| **3. Минимальный объём изменений** | (а) в резолве режима добавить interior-policy default COLD; (б) whitelist-механизм исключений (например, по area tag/локалу `al_mode_whitelist=1`); (в) явный чат-лог, почему interior не ушёл в COLD (whitelist/forced HOT). |
| **4. Основные риски** | Ошибки маркировки interior/exterior; «тихое» выпадение квестовых interiors при забытом whitelist; регресс для сервисных area (shop/tavern), где ожидается постоянная активность. |
| **5. Smoke-сценарии** | 1) Interior без override: стартует/возвращается в COLD; 2) Interior из whitelist: может держать HOT/WARM по правилам; 3) Exterior рядом с interior работает без изменений; 4) debug сообщает причину принятого режима. |
| **6. Что согласовать до реализации** | Источник признака interior (static tag, area local, palette); формат и владельца whitelist (контент-команда или скрипт); SLA на ревизию квестовых interiors до включения default COLD в проде. |

---

## Этап 3 — WARM режим для соседних областей

| Пункт | Содержание |
|---|---|
| **1. Цель** | Ввести one-hop прогрев соседних area: HOT-источник может поднимать adjacency-зоны в WARM без каскадного разгона и без централизованного глобального scheduler. |
| **2. Затронутые файлы/модули** | `scripts/al_prototype/al_area_mode_contract_inc.nss`, `scripts/al_prototype/al_area_tick_inc.nss` (tick cadence для WARM), `scripts/al_prototype/al_area_constants_inc.nss` (`AL_TICK_PERIOD_WARM`, warm repeats), area locals `al_adjacent_areas`, `al_quarter_id`, debug-диагностика (`al_debug_inc`, сообщения из orchestrator-точек). |
| **3. Минимальный объём изменений** | (а) резолв WARM как отдельного режима; (б) локальный one-hop adjacency resolve на основе `al_adjacent_areas`; (в) WARM выполняет облегчённый lifecycle (без полного cold wake teardown); (г) квартал (`al_quarter_id`) используется как guard ownership для распространения прогрева. |
| **4. Основные риски** | Неполный/битый adjacency CSV; петли соседства и event-noise; ложный прогрев через неверный quarter ownership; накопление warm-тикеров на плотных кластерах area. |
| **5. Smoke-сценарии** | 1) HOT area поднимает прямых соседей до WARM; 2) WARM не эскалирует соседей дальше (нет WARM->WARM каскада); 3) сосед из другого quarter не прогревается при включённом ownership guard; 4) битая adjacency-конфигурация даёт fallback в локальный режим + debug в чат. |
| **6. Что согласовать до реализации** | Точный алгоритм quarter ownership (строгое равенство id или mapping); TTL/время удержания WARM после потери HOT-источника; лимит количества соседей на area для защиты от шума. |

---

## Этап 4 — hysteresis / anti-oscillation / optional budget

| Пункт | Содержание |
|---|---|
| **1. Цель** | Стабилизировать режимы при флуктуациях событий и ограничить вычислительную нагрузку через controlled деградацию WARM/HOT. |
| **2. Затронутые файлы/модули** | `scripts/al_prototype/al_area_tick_inc.nss` (таймеры, окна hysteresis), `scripts/al_prototype/al_area_mode_contract_inc.nss` (правила переходов), `scripts/al_prototype/al_area_constants_inc.nss` (пороги/таймауты), debug/telemetry через `al_debug_inc` и area locals-счётчики. |
| **3. Минимальный объём изменений** | (а) минимальное время удержания HOT/WARM перед понижением; (б) debounce на частые переходы HOT<->WARM<->COLD; (в) optional budget: ограничение числа area, которые могут быть одновременно в WARM/HOT в квартале/регионе; (г) чат-диагностика причин downgrade (hysteresis/budget cap). |
| **4. Основные риски** | Слишком агрессивный budget ухудшает живость мира; слишком мягкий hysteresis не решает oscillation; сложность отладки при сочетании budget + adjacency + interior policy. |
| **5. Smoke-сценарии** | 1) Пограничный поток игроков не вызывает «пилу» режимов; 2) при budget cap новые кандидаты в WARM корректно отклоняются и логируются; 3) после истечения hysteresis area понижается предсказуемо; 4) HOT-критичные area из whitelist не деградируют из-за budget (если так решено политикой). |
| **6. Что согласовать до реализации** | Значения hysteresis-окон и cooldown; модель budget (per quarter/per shard/global); список приоритетных area, которые нельзя throttling-ить; формат телеметрии и критерии успеха (oscillation rate, active area count, server tick impact). |

---

## Сквозные договорённости между этапами

1. **Backwards compatibility:** пока rollout не завершён, legacy HOT/COLD через `al_player_count` остаётся поддерживаемым fallback.
2. **Incremental rollout:** включение по кварталам/группам area, а не «одним флагом» на весь модуль.
3. **Debug-first:** каждое fallback-решение по режимам должно иметь читаемую чат-диагностику (с троттлингом).
4. **Контент-гейт:** изменения режимов не выкатываются без ревизии area locals (`al_adjacent_areas`, `al_quarter_id`, interior markers, whitelist flags).
5. **DoD на этап:** этап считается закрытым только после smoke-сценариев и формального апдейта техдока/аудита.
