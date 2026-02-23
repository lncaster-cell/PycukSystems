# Module 3 perf-gate (гибрид AL + NPC runtime)

Документ определяет **отдельный** performance gate для Module 3 (гибридный слой: AL content orchestration + runtime-контур из `npc_behavior`) и не является частью Phase 1 NPC acceptance.

## 1) Матрица сценариев

Матрица покрывает ключевые режимы гибрида: массовые ambient-активности, burst combat transitions и смешанную multi-area нагрузку.

| Scenario ID | Профиль нагрузки | Topology | Раскладка | Цель сценария |
|---|---|---|---|---|
| M3-S1 | Massive ambient activities (medium) | single-area | 80 NPC в 1 area, 70% route/slot active | Проверка AL-оркестрации в одном hot-spot |
| M3-S2 | Massive ambient activities (high) | multi-area | 160 NPC по 4 area (40/40/40/40), 65% route/slot active | Проверка масштабирования dispatch + area ownership |
| M3-S3 | Burst combat transitions | single-area | 60 NPC, burst волнa: каждые 30s перевод 40% IDLE→ALERT/COMBAT | Проверка устойчивости state transitions и приоритизации |
| M3-S4 | Burst combat transitions | multi-area | 120 NPC по 4 area (30/30/30/30), несинхронные bursts | Проверка межобластных накладных расходов при боевых всплесках |
| M3-S5 | Mixed multi-area pressure | multi-area | 200 NPC по 5 area (50/40/40/35/35), ambient + combat + migration | Стресс гибридного runtime под mixed нагрузкой |
| M3-S6 | Mixed multi-area + budget pressure | multi-area | 240 NPC по 6 area (40 each), принудительно зажатый tick budget | Проверка деградации и поведения AL-layer под ограничением бюджета |

---

## 2) Измеряемые метрики

Для каждого сценария обязательно собирать:
- `p50_tick_ms`
- `p95_tick_ms`
- `p99_tick_ms`
- `queue_depth_max`
- `flush_ms_p95`
- `sqlite_busy_count`
- `event_latency_ms_p95`
- `activity_dispatch_latency_ms_p95` *(новая метрика AL-layer)*
- `route_slot_reassignment_churn_per_min` *(новая метрика AL-layer)*
- `skipped_activity_rate_pct` *(новая метрика AL-layer)*

### Определения
- **tick percentiles** — перцентили времени игрового тика в ms.
- **queue depth** — максимальная длина внутренней очереди задач/событий за прогон.
- **flush_ms** — время сброса батчей persist/flush, p95 в ms.
- **SQLITE_BUSY count** — число конфликтов блокировок SQLite за прогон.
- **event latency** — задержка от публикации события до завершения handler, p95 в ms.
- **activity dispatch latency** — p95 задержки от постановки AL-активности в dispatcher до начала её исполнения.
- **route/slot reassignment churn** — количество переназначений route/slot на NPC в минуту (drift/oscillation индикатор).
- **skipped activity rate** — доля активностей, пропущенных scheduler'ом из-за budget pressure (% от кандидатов к выполнению).

---

## 3) Пороговые значения pass/fail

Сценарий считается **PASS**, только если все метрики укладываются в пороги.

| Scenario ID | p50 tick | p95 tick | p99 tick | queue depth max | flush_ms p95 | SQLITE_BUSY count | event latency p95 | activity dispatch latency p95 | route/slot reassignment churn (/min) | skipped activity rate (%) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| M3-S1 | ≤ 10 ms | ≤ 18 ms | ≤ 24 ms | ≤ 110 | ≤ 14 ms | ≤ 1 | ≤ 28 ms | ≤ 20 ms | ≤ 22 | ≤ 4.0% |
| M3-S2 | ≤ 12 ms | ≤ 22 ms | ≤ 30 ms | ≤ 180 | ≤ 18 ms | ≤ 2 | ≤ 34 ms | ≤ 26 ms | ≤ 28 | ≤ 6.0% |
| M3-S3 | ≤ 13 ms | ≤ 24 ms | ≤ 34 ms | ≤ 210 | ≤ 20 ms | ≤ 2 | ≤ 38 ms | ≤ 30 ms | ≤ 35 | ≤ 8.0% |
| M3-S4 | ≤ 15 ms | ≤ 28 ms | ≤ 38 ms | ≤ 260 | ≤ 23 ms | ≤ 3 | ≤ 44 ms | ≤ 34 ms | ≤ 40 | ≤ 9.0% |
| M3-S5 | ≤ 17 ms | ≤ 32 ms | ≤ 44 ms | ≤ 330 | ≤ 28 ms | ≤ 4 | ≤ 52 ms | ≤ 42 ms | ≤ 48 | ≤ 11.0% |
| M3-S6 | ≤ 19 ms | ≤ 36 ms | ≤ 50 ms | ≤ 390 | ≤ 32 ms | ≤ 5 | ≤ 60 ms | ≤ 48 ms | ≤ 55 | ≤ 14.0% |

### Правила интерпретации
1. **Hard-fail метрики:** `p99_tick_ms`, `sqlite_busy_count`, `event_latency_ms_p95`, `activity_dispatch_latency_ms_p95`, `skipped_activity_rate_pct`.
2. Любое превышение hard-fail метрики в любом валидном прогоне = **FAIL** сценария.
3. Для остальных метрик требуется соответствие порогам в агрегированной статистике по 3+ прогонам.

---

## 4) Порядок запуска и длительность

Минимум **3 прогона на сценарий**. Рекомендуется 5 для спорных/пограничных значений.

### Порядок выполнения
1. Warm-up окружения: 7 минут (без записи в отчёт).
2. Сценарии выполняются в порядке: **M3-S1 → M3-S2 → M3-S3 → M3-S4 → M3-S5 → M3-S6**.
3. Для каждого сценария:
   - Run A: 20 минут;
   - Cooldown: 4 минуты;
   - Run B: 20 минут;
   - Cooldown: 4 минуты;
   - Run C: 20 минут.
4. Технический сбой (не perf-деградация) требует перезапуска прогона с пометкой `rerun`.

### Минимальный объём данных
- 6 сценариев × 3 прогона × 20 минут = **360 минут чистых измерений**.
- Финальный verdict по Module 3 perf-gate формируется только после полного набора данных.

---

## 5) Формат отчёта для Module 3 perf-gate

Отчёт сохраняется в `docs/perf_reports/<date>_module3_perf_gate.md` и включает:

1. **Контекст теста**
   - commit SHA
   - ветка
   - конфигурация runtime/БД
   - дата/время
2. **Таблица результатов (агрегат по 3+ прогонам)**
3. **Список отклонений и регрессий**
4. **Финальный вывод:** `merge allowed` или `merge blocked`

### Шаблон таблицы результатов

| Scenario ID | Runs | p50 tick | p95 tick | p99 tick | queue depth max | flush_ms p95 | SQLITE_BUSY count | event latency p95 | activity dispatch latency p95 | route/slot reassignment churn | skipped activity rate | Verdict |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| M3-S1 | 3 | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | PASS/FAIL |
| M3-S2 | 3 | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | PASS/FAIL |
| M3-S3 | 3 | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | PASS/FAIL |
| M3-S4 | 3 | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | PASS/FAIL |
| M3-S5 | 3 | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | PASS/FAIL |
| M3-S6 | 3 | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | PASS/FAIL |

### Правило итогового решения (только для Module 3)
- **merge allowed**: все сценарии M3-S1–M3-S6 имеют `PASS`.
- **merge blocked**: хотя бы один сценарий M3-S1–M3-S6 имеет `FAIL`.
- Это правило применяется **отдельно** от Phase 1 NPC perf/checklist и не может быть «поглощено» их статусом.

---

## 6) Разграничение с Phase 1 NPC

- `docs/npc_perf_test_plan.md` остаётся нормативом только для Phase 1 NPC-модуля.
- Настоящий документ — обязательный perf-gate для Module 3 hybrid AL/NPC runtime.
- Решения по merge для Module 3 принимаются только по результатам этого документа.
