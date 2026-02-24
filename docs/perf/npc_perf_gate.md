# NPC Bhvr perf gate: audit-derived guardrails

Документ фиксирует perf/fault-injection проверки, напрямую выведенные из AL-аудита (`tools/AUDIT.md`), и критерии pass/fail для release-gate NPC Bhvr.

## Baseline reference-point

Для всех сравнений perf-gate NPC Bhvr reference-point задаётся **только** current baseline-файлом `docs/perf/npc_baseline_report.md`.

- Если baseline отсутствует или старше 14 дней, результаты сравнения считаются `BLOCKED` до обновления baseline.
- `docs/perf/reports/*` используется только как historical archive для ретроспективного анализа трендов и не является current baseline для gate-сравнений.

## 1) Registry overflow guardrail

**Цель:** подтвердить, что лимит area-registry не приводит к silent failure.

### Сценарий

- Поднять количество NPC в области выше `MAX_NPCS_PER_AREA` (например, 120+ при лимите 100).
- Запустить area-loop в steady режиме с регистрацией новых NPC.

### Проверки

- tick-loop продолжает работу без остановки;
- `npc_metric_registry_overflow_total > 0` и `npc_metric_registry_reject_total > 0`;
- нет повреждения существующих записей (старые NPC продолжают получать update/events).

### Gate

- **PASS:** overflow фиксируется, loop стабилен, деградация диагностируема.
- **FAIL:** переполнение не отражено в метриках или приводит к потере управления уже зарегистрированными NPC.

## 2) Route cache warmup policy guardrail *(future/blocked)*

**Статус:** BLOCKED до внедрения route-cache в runtime `src/modules/npc/*`.

**Цель:** исключить повторный дорогостоящий area scan после первичного warmup.

### Сценарий

- Очистить/инвалидировать route cache.
- Выполнить первый warmup (OnEnter или prewarm-hook).
- Повторить вход в область 3–5 раз без invalidate.

### Проверки

- первый warmup может дать контролируемый latency spike;
- `route_cache_warmup_total` увеличивается на первом прогреве;
- `route_cache_rescan_total` не растёт на повторных входах;
- `route_cache_hit_ratio` остаётся в ожидаемом диапазоне (например, `>= 0.95` после warmup).

### Gate

- **PASS:** warmup однократный, повторные OnEnter не запускают полный re-scan.
- **FAIL:** каждый вход запускает re-scan или hit ratio указывает на отсутствие рабочего cache.

## 3) Silent degradation diagnostics guardrail *(future/blocked)*

**Статус:** PARTIAL — базовая reason-specific degradation telemetry внедрена в runtime (`degradation_events_total`, `degradation_by_reason_*`, `diagnostic_dropped_total`); full fault-injection matrix остаётся в работе.

**Цель:** убедиться, что деградационные ветки не остаются «тихими».

### Сценарий

- Выполнить fault-injection для причин: `OVERFLOW`, `QUEUE_PRESSURE`, `ROUTE_MISS`, `DISABLED`.
- Запустить короткие burst-серии с включённой диагностикой.

### Проверки

- каждый fault-кейс увеличивает `degradation_events_total`;
- reason-specific счётчики (`degradation_by_reason_*`) растут строго по ожидаемой причине;
- diagnostic stream содержит соответствующий reason-code;
- `diagnostic_dropped_total` не превышает установленный лимит rate-limit policy.

### Gate

- **PASS:** все fault-кейсы наблюдаемы в метриках и диагностике.
- **FAIL:** хотя бы один fault-кейс не имеет метрики или reason-code в диагностике.

## 4) Release gate integration checklist

- [ ] Overflow сценарий добавлен в perf-прогон NPC Bhvr.
- [ ] Warmup/rescan сценарий добавлен в perf-прогон NPC Bhvr *(BLOCKED: route cache ещё не внедрён)*.
- [ ] Fault-injection silent degradation сценарий добавлен в perf-прогон NPC Bhvr *(PARTIAL: telemetry готова, отсутствует полный набор fault-fixtures и прогон).*
- [ ] Automated fairness checks добавлены в perf-прогон NPC Bhvr.
- [ ] Tick budget/degraded-mode сценарий добавлен в perf-прогон NPC Bhvr.
- [ ] Итоговый отчёт содержит явный pass/fail по каждому guardrail.

## 5) Automated fairness checks

**Цель:** формализовать обязательный запуск fairness-анализатора очереди area-loop для NPC Bhvr перед merge.

### Обязательный запуск

Для всех fixture-прогонов NPC Bhvr fairness-анализатор `scripts/analyze_area_queue_fairness.py` должен вызываться со следующими параметрами:

- `--max-starvation-window <N>`
- `--enforce-pause-zero`
- `--max-post-resume-drain-ticks <N>`
- `--min-resume-transitions <N>`

Базовый smoke-прогон выполняется через `scripts/test_npc_smoke.sh`: он запускает `scripts/test_npc_fairness.sh` и `scripts/test_npc_activity_route_contract.sh` с фиксированным набором флагов выше.

### Gate

- **PASS:** все NPC Bhvr fairness fixtures проходят/падают строго согласно ожидаемому сценарию, а обязательные флаги присутствуют во всех запусках.
- **FAIL:** отсутствует хотя бы один обязательный флаг, либо ожидаемое поведение fixture не подтверждается в CI-скрипте.

## 6) Tick budget / degraded-mode guardrail

**Цель:** зафиксировать bounded обработку area-tick и детерминированный перенос хвоста очереди между тиками.

### Сценарий

- Установить runtime-конфиги области: `npc_tick_max_events` и `npc_tick_soft_budget_ms` в заведомо малые значения (например, `2` и `8`).
- Сформировать burst, превышающий бюджет тика (очередь HIGH/NORMAL + CRITICAL).
- Запустить 5–10 последовательных тиков и снять метрики по области.

### Проверки

- за тик обрабатывается не более `npc_tick_max_events` событий (`processed_total` растёт bounded-инкрементом);
- tick-loop прекращает обработку при достижении soft-бюджета `npc_tick_soft_budget_ms` **или** event budget;
- при наличии хвоста после budget cutoff включается degraded-mode и растут `tick_budget_exceeded_total` и `degraded_mode_total`;
- `tick_budget_exceeded_total` и `degraded_mode_total` синхронно увеличиваются только при budget cutoff с ненулевым хвостом pending;
- `queue_deferred_count` растёт только когда есть хвост после budget cutoff;
- backlog-age surrogate `pending_age_ms` (pending * 1000 ms per tick) увеличивается, пока есть pending, и перестаёт расти после drain.

### Gate

- **PASS:** budget-ограничение соблюдается по обоим лимитам (`max events per tick` и `soft time budget`), деградация наблюдаема, хвост очереди дренируется в последующих тиках без reordering.
- **FAIL:** tick обрабатывает сверх budget, либо нет явной телеметрии budget/degraded-path.
