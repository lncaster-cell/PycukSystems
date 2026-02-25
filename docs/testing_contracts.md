# Testing Contracts: lifecycle checks


Этот документ описывает запуск универсальной проверки lifecycle-контрактов для модулей.

## Универсальный скрипт

`scripts/check_lifecycle_contract.sh` принимает:

1. путь к core-файлу,
2. путь к controller-файлу,
3. namespace/prefix модуля,
4. (опционально) путь к contract-профилю.

```bash
bash scripts/check_lifecycle_contract.sh <core_file> <controller_file> <module_prefix> [contract_file]
```

Если `contract_file` не указан, скрипт использует профиль по умолчанию:

```text
scripts/contracts/<module_prefix>.contract
```

## Профили контрактов

- `scripts/contracts/npc.contract` — актуальный профиль проверок NPC lifecycle.

## Примеры запуска

### NPC

```bash
bash scripts/check_npc_lifecycle_contract.sh
```

`check_npc_lifecycle_contract.sh` использует профиль `scripts/contracts/npc.contract`.


## Контракт guardrail-анализатора CSV

Для `scripts/analyze_guardrails.py` поле `lifecycle_state` считается опциональным.
Если колонка отсутствует или значение пустое, состояние по умолчанию интерпретируется как `RUNNING`
(эквивалентно `row.get("lifecycle_state") or "RUNNING"` c последующей нормализацией `strip().upper()`).

Контракт закреплён в `scripts/test_guardrail_analyzer.sh` через fixture
`docs/perf/fixtures/npc/guardrails_missing_lifecycle_state.csv`.

## Контракт rollout readiness audit

Readiness-аудит Ambient Life V3 выполняется скриптом:

```bash
python3 scripts/audit_npc_rollout_readiness.py --repo-root . --scan src
```

Smoke/contract защита:

```bash
bash scripts/test_npc_rollout_readiness_contract.sh
```

Проверка фиксирует:
- наличие canonical source-of-truth документа `docs/npc_toolset_authoring_contract.md`;
- присутствие readiness tiers (`READY/BRIDGEABLE/FALLBACK-RISK/MANUAL/CONFLICTED`);
- согласованность классификации supported/unsupported legacy bridge patterns на fixtures;
- генерацию machine-readable (`json`) и human-readable (`md`) readiness report.

## Контракт batch migration execution helper

Batch migration helper:

```bash
python3 scripts/run_npc_batch_migration.py --repo-root . --tier READY
```

Контрактная проверка helper:

```bash
bash scripts/test_npc_batch_migration_helper_contract.sh
```

Проверка фиксирует:
- dry-run не изменяет контент;
- apply меняет только safe tiers (`READY/BRIDGEABLE`) и только распознанные supported legacy patterns;
- `MANUAL/CONFLICTED` и protected runtime paths не переписываются;
- повторный apply идемпотентен (нет новых изменений после нормализации);
- execution report отражает фактическое поведение миграции.

## Контракт manual remediation backlog + exceptions

Backlog generator:

```bash
python3 scripts/generate_npc_remediation_backlog.py --repo-root .
```

Контрактная проверка:

```bash
bash scripts/test_npc_remediation_backlog_contract.sh
```

Проверка фиксирует:
- стабильную генерацию remediation backlog report (JSON/Markdown);
- наличие remediation categories и priority rules;
- валидацию формата exception registry;
- корректное попадание active exceptions в отчёт как `EXCEPTION`;
- согласованность readiness/execution/backlog на базовых сценариях.
