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

- `scripts/contracts/npc_behavior.contract` — текущий профиль проверок NPC.
- `scripts/contracts/module3.contract` — пустой шаблон для будущего `module3_core.nss`.

## Примеры запуска

### NPC

```bash
bash scripts/check_lifecycle_contract.sh \
  tools/npc_behavior_system/npc_behavior_core.nss \
  src/controllers/lifecycle_controller.nss \
  npc_behavior
```

Или совместимый legacy-вариант:

```bash
bash scripts/check_area_lifecycle_contract.sh
```

### Module 3 (заготовка)

```bash
bash scripts/check_lifecycle_contract.sh \
  tools/module3/module3_core.nss \
  src/controllers/lifecycle_controller.nss \
  module3
```

Пока профиль `module3.contract` пустой, проверка только подтверждает валидность путей и загрузку профиля.
