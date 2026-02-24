# Module Skeleton (platform template)

Шаблон нового модуля в `src/modules/*` для проверки масштабируемости механизма подключения.

## Назначение

- показать обязательные thin-entrypoints;
- зафиксировать lifecycle API (`Init/Start/Pause/Stop/Reload`);
- показать минимальный каркас метрик и деградационных сигналов.

> В шаблоне нет предметной логики: только platform-contract слой.

## Файлы

- `mod_skel_core.nss` — **канонический** lifecycle и helper API include;
- `module_skeleton_core.nss` — deprecated compatibility shim (`#include "mod_skel_core"`);
- `module_skeleton_module_load.nss` — thin-entrypoint для bootstrap;
- `module_skeleton_area_tick.nss` — thin-entrypoint loop;
- `module_skeleton_spawn.nss` — thin-entrypoint entity bootstrap.

## Contract check

```bash
bash scripts/check_module_skeleton_include_contract.sh
```
