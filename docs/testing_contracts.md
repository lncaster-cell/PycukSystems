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
