# NPC runtime dashboards (observability artifacts)

Каталог фиксирует **версионируемые артефакты runtime-дашбордов** для Phase 1 NPC perf/SLO.

## Схема артефактов

- `schema_version`: `1.0.0`
- Формат: экспорт Grafana dashboard JSON (`schemaVersion: 39`, Grafana 10+).
- Политика изменений: любое изменение запросов/панелей должно сопровождаться bump `version` в соответствующем JSON и ссылкой в changelog/PR.

## Файлы в каталоге

- `tick_orchestration_dashboard.json`
  - панели: `p50/p95/p99` tick latency, queue depth (`p95/p99`), budget overrun rate.
- `db_flush_dashboard.json`
  - панели: flush duration `p50/p95/p99`, flush error rate, batch size (`avg/p95`).
- `ai_step_cost_dashboard.json`
  - панели: AI step cost (`avg/p95`) и top handlers (mean/p95).

## Источники метрик

Источник данных: Prometheus (`${DS_PROMETHEUS}`).

Ожидаемые series:

- Tick orchestration:
  - `npc_tick_duration_ms_bucket`
  - `npc_tick_queue_depth_bucket`
  - `npc_tick_overrun_total`
  - `npc_tick_total`
- DB flush:
  - `npc_db_flush_duration_ms_bucket`
  - `npc_db_flush_total` (`result=success|error`)
  - `npc_db_flush_batch_size`
- AI step cost:
  - `npc_ai_step_duration_ms_bucket`
  - `npc_ai_step_duration_ms_sum`
  - `npc_ai_step_duration_ms_count`

## Обязательные labels

Минимальный обязательный набор labels для совместимости фильтров и drill-down:

- `module` — имя runtime-модуля (например, `npc`).
- `area` — area-id/area-tag (обязательно для tick и AI метрик).
- `scenario` — benchmark/нагрузочный сценарий (`steady`, `burst`, `tick-budget` и т.д.).
- `handler` — имя AI-handler (обязательно для top-handlers таблиц).
- `result` — результат flush (`success|error`) для расчёта error rate.

Рекомендуемые labels (необязательные, но полезные): `build_sha`, `environment`, `shard`.

## Верификация наличия дашбордов в репозитории

- Наличие дашбордов проверяется по существованию JSON-файлов в этом каталоге.
- Ссылки из `docs/design.md` и `src/modules/npc/README.md` должны указывать именно на этот каталог/файлы.
