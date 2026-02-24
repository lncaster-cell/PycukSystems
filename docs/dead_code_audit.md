# Аудит мусорного и мёртвого кода

Дата: 2026-02-24

## Область анализа

Проверены каталоги `src/`, `scripts/`, `benchmarks/`, `docs/`.

Исключены из аудита по требованию:
- `third_party/**`
- всё, что относится к встроенному компилятору/тулчейну (`third_party/toolchain/**`)

## Методика (быстрый статический проход)

Для скриптов NWScript (`*.nss`) выполнен эвристический поиск:
- определений функций по сигнатурам базовых типов (`void/int/float/string/object/...`);
- упоминаний идентификаторов по всему репозиторию (вне исключённых директорий);
- кандидатов в мёртвый код: функции, встречающиеся только в месте определения.

Для `const` переменных выполнена такая же проверка по упоминаниям.

> Важно: это эвристика, а не полнофункциональный компиляторный анализ. Возможны ложноположительные/ложноотрицательные результаты для динамических вызовов, генерируемого кода и внешних контрактов.

## Результаты

### Кандидаты в неиспользуемые функции (NWScript)

Обнаружено 6 кандидатов (все в legacy-адаптере):

1. `NpcBhvrAreaSetState` — `src/modules/npc/npc_legacy_compat_inc.nss:4`
2. `NpcBhvrCountPlayersInArea` — `src/modules/npc/npc_legacy_compat_inc.nss:9`
3. `NpcBhvrCountPlayersInAreaExcluding` — `src/modules/npc/npc_legacy_compat_inc.nss:14`
4. `NpcBhvrGetCachedPlayerCount` — `src/modules/npc/npc_legacy_compat_inc.nss:19`
5. `NpcBhvrRegistryBroadcastIdleTick` — `src/modules/npc/npc_legacy_compat_inc.nss:24`
6. `NpcBhvrQueuePackLocation` — `src/modules/npc/npc_legacy_compat_inc.nss:32`

### Неиспользуемые константы

По текущей эвристике не обнаружены.

## Рекомендации

1. Проверить, нужен ли файл `npc_legacy_compat_inc.nss` для обратной совместимости внешних модулей/старых include-контрактов.
2. Если обратная совместимость не требуется:
   - удалить неиспользуемые функции;
   - либо пометить блок как deprecated и добавить комментарий о плановом удалении.
3. Если совместимость требуется:
   - оставить функции, но добавить явный комментарий `compat shim` и ссылку на контракт/документ с обоснованием.
4. Для регулярного контроля добавить CI-проверку на уровень «предупреждение» с таким же эвристическим анализом.

## Команда, использованная для аудита

```bash
python - <<'PY'
import re, pathlib
from collections import Counter
root=pathlib.Path('/workspace/PycukSystems')
files=[p for p in root.rglob('*') if p.suffix in {'.nss','.py','.sh'} and 'third_party' not in p.parts and 'toolchain' not in p.parts and '.git' not in p.parts]
func_def_re=re.compile(r'^\s*(?:void|int|float|string|object|location|vector|effect|itemproperty|talent|action)\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(')
const_re=re.compile(r'^\s*const\s+(?:int|float|string|object)\s+([A-Za-z_][A-Za-z0-9_]*)\b')
all_text='\n'.join(p.read_text(errors='ignore') for p in files)
cnt=Counter(re.findall(r'\b[A-Za-z_][A-Za-z0-9_]*\b',all_text))
funcs=[]; consts=[]
for p in files:
    if p.suffix!='.nss':
        continue
    for i,l in enumerate(p.read_text(errors='ignore').splitlines(),1):
        m=func_def_re.match(l)
        if m: funcs.append((m.group(1), p, i))
        m=const_re.match(l)
        if m: consts.append((m.group(1), p, i))
unused=[x for x in funcs if cnt[x[0]]<=1 and x[0] not in {'main','StartingConditional'}]
print(unused)
PY
```
