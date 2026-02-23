# Module 3 perf gate: audit-derived guardrails

Документ фиксирует perf/fault-injection проверки, напрямую выведенные из AL-аудита (`tools/AUDIT.md`), и критерии pass/fail для release-gate Module 3.

## 1) Registry overflow guardrail

**Цель:** подтвердить, что лимит area-registry не приводит к silent failure.

### Сценарий

- Поднять количество NPC в области выше `MAX_NPCS_PER_AREA` (например, 120+ при лимите 100).
- Запустить area-loop в steady режиме с регистрацией новых NPC.

### Проверки

- tick-loop продолжает работу без остановки;
- `registry_overflow_total > 0` и `registry_reject_total > 0`;
- нет повреждения существующих записей (старые NPC продолжают получать update/events).

### Gate

- **PASS:** overflow фиксируется, loop стабилен, деградация диагностируема.
- **FAIL:** переполнение не отражено в метриках или приводит к потере управления уже зарегистрированными NPC.

## 2) Route cache warmup policy guardrail

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

## 3) Silent degradation diagnostics guardrail

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

- [ ] Overflow сценарий добавлен в perf-прогон Module 3.
- [ ] Warmup/rescan сценарий добавлен в perf-прогон Module 3.
- [ ] Fault-injection silent degradation сценарий добавлен в perf-прогон Module 3.
- [ ] Automated fairness checks добавлены в perf-прогон Module 3.
- [ ] Итоговый отчёт содержит явный pass/fail по каждому guardrail.

## 5) Automated fairness checks

**Цель:** формализовать обязательный запуск fairness-анализатора очереди area-loop для Module 3 перед merge.

### Обязательный запуск

Для всех fixture-прогонов Module 3 fairness-анализатор `scripts/analyze_area_queue_fairness.py` должен вызываться со следующими параметрами:

- `--max-starvation-window <N>`
- `--enforce-pause-zero`
- `--max-post-resume-drain-ticks <N>`
- `--min-resume-transitions <N>`

Базовый smoke-прогон выполняется через `scripts/test_module3_fairness.sh` и использует фиксированный набор флагов выше.

### Gate

- **PASS:** все Module 3 fairness fixtures проходят/падают строго согласно ожидаемому сценарию, а обязательные флаги присутствуют во всех запусках.
- **FAIL:** отсутствует хотя бы один обязательный флаг, либо ожидаемое поведение fixture не подтверждается в CI-скрипте.
