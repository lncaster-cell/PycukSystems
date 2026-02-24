# Module Contract (Platform Capability)

Документ фиксирует **общий контракт модульного runtime**, который может применяться не только к NPC, но и к любым новым механикам в `src/modules/*`.

## 1) Thin-entrypoints (обязательно)

Каждый модуль обязан предоставлять тонкие hook-скрипты (thin-entrypoints), где:

- нет предметной/доменной логики;
- выполняется только маршрутизация в core API модуля;
- нет прямой записи бизнес-состояния в entrypoint-файлах;
- наблюдаемость и lifecycle-переходы идут через core/helper-слой.

Минимальный рекомендуемый набор thin-entrypoints:

- `*_module_load.nss` (bootstrap/init);
- `*_area_tick.nss` (runtime loop/tick orchestrator);
- `*_spawn.nss` (entity bootstrap);
- дополнительные hook-скрипты по необходимости механики (`*_damaged`, `*_dialogue`, `*_area_enter`, ...).

## 2) Lifecycle API (обязательно)

Для каждого runtime-модуля должен быть единый lifecycle API со следующими операциями:

- `Init` — инициализация конфигурации/locals, регистрация базовых метрик;
- `Start` — перевод runtime в RUNNING и запуск/рескейджул loop;
- `Pause` — перевод в PAUSED без потери консистентности очередей/pending;
- `Stop` — terminal stop с безопасным shutdown;
- `Reload` — переинициализация конфигурации и безопасное возвращение в RUNNING/PAUSED согласно policy модуля.

Обязательные инварианты lifecycle:

- переходы `RUNNING/PAUSED/STOPPED` должны быть детерминированными и идемпотентными;
- loop не должен рескейджулиться в `STOPPED`;
- `Pause/Resume` не должны повреждать queue/pending counters;
- функции lifecycle доступны из core include, а не реализуются в thin-entrypoints.

## 3) Метрики и деградационные сигналы (обязательно)

Каждый модуль обязан публиковать минимум:

- lifecycle-метрики (`*_metric_init_total`, `*_metric_start_total`, `*_metric_pause_total`, `*_metric_stop_total`, `*_metric_reload_total`);
- runtime-метрики нагрузки (`*_metric_processed_total`, `*_metric_deferred_total`, `*_metric_overflow_total`);
- деградационные счётчики (`*_metric_degraded_mode_total`, `*_metric_degradation_events_total`);
- last-reason сигнал (`*_last_degradation_reason`) с reason-code (например, `EVENT_BUDGET`, `SOFT_BUDGET`, `OVERFLOW`, `DISABLED`).

Требования к сигналам деградации:

- reason-code обязан обновляться при каждом входе в degraded-path;
- degraded-счётчики не должны использоваться как замена reason-code;
- для новых модулей список reason-code фиксируется в README модуля и в contract profile.

## 4) Contract-check automation

Новый модуль считается platform-ready только если:

1. Есть contract profile в `scripts/contracts/<module>.contract`.
2. Есть check-скрипт, проверяющий обязательные паттерны lifecycle и thin-entrypoints.
3. Есть smoke/check script, который запускает lifecycle-contract check и минимум один runtime self-check.

Шаблоны для старта:

- `scripts/contracts/module.contract.template`;
- `scripts/contracts/check_module_contract.template.sh`;
- `scripts/test_module_smoke.template.sh`.
