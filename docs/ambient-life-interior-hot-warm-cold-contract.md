# Ambient Life: архитектурный контракт интерьеров (HOT/WARM/COLD)

## 1. Interior policy

### 1.1 Что считать interior-area
Interior-area — это area, удовлетворяющая хотя бы одному из критериев:
1. Контентно закрытое внутреннее пространство (дом, таверна, подвал, магазин, приватная комната).
2. Не является транзитным публичным узлом уличной навигации (площадь, улица, магистраль).
3. Не является системным хабом, который по дизайну обязан держать постоянный runtime.

Базовое правило: **interior по умолчанию стартует и возвращается в COLD**.

### 1.2 HOT/WARM/COLD для interior
- **COLD (default):**
  - непрерывный area tick отсутствует;
  - NPC могут быть скрыты;
  - runtime route-state и расписание не удерживаются;
  - slot-driven логика сохраняется, но исполняется только на wake/активных тиках.
- **WARM:**
  - используется как краткий переходный режим после активности;
  - допускается ограниченное удержание кэшей для быстрого повторного входа;
  - непрерывная симуляция не гарантируется.
- **HOT:**
  - активный игрок в интерьере или явное override-условие;
  - area tick и slot-driven поведение работают в штатном активном режиме.

### 1.3 Принцип ядра
Контракт не меняет slot-driven ядро: слот вычисляется канонически и остаётся источником маршрутов/активностей. Меняется только политика жизненного цикла runtime между периодами активности.

## 2. Required locals

### 2.1 Area kind
Обязательный local на area:
- `al_area_kind` (`string|int enum`) со значениями:
  - `interior`
  - `exterior`
  - `system` (опционально для служебных/особых зон)

Для данного контракта ключевое значение — `interior`.

### 2.2 Force flags
Обязательные override-locals на area:
- `al_force_hot` (`int`, 0/1)
- `al_force_warm` (`int`, 0/1)
- `al_force_cold` (`int`, 0/1)

### 2.3 Приоритет force-флагов
При одновременной установке конфликтующих флагов применяется строгий приоритет:
1. `al_force_cold`
2. `al_force_hot`
3. `al_force_warm`
4. вычисленное состояние по обычной политике

Причина: для интерьеров важно иметь гарантированный аварийный «заморозить сейчас» режим.

## 3. Wake contract

Wake интерьера (обычно при входе первого игрока) выполняется в фиксированном порядке:

1. **Unhide**
   - снять скрытие с зарегистрированных NPC;
   - убедиться, что объект видим/валиден для действий.
2. **Resync**
   - синхронизировать registry;
   - переинициализировать runtime-зависимости (включая пары/контекст активности);
   - выровнять текущий slot и epoch/token.
3. **Route cache**
   - обеспечить готовность route cache для текущего слота/area;
   - если cache валиден (WARM wake), разрешено fast-path без полной пересборки.
4. **Activity apply**
   - применить активность строго из slot/waypoint-источника;
   - при невалидной конфигурации использовать безопасный fallback-activity.

### 3.1 SLA wake
Для interior при входе игрока wake должен быть «быстрым»: первый видимый корректный state NPC — в рамках одного wake-цикла без ожидания длинной фоновой симуляции.

## 4. Freeze contract

Когда интерьер пустеет или принудительно уходит в COLD, выполняется freeze-порядок:

1. **Invalidate tick**
   - инвалидация текущего tick token/epoch;
   - отложенные старые тики должны стать no-op.
2. **Clear scheduling**
   - очистка/сброс runtime-планирования route repeat и связанных отложенных шагов.
3. **Hide**
   - перевод зарегистрированных NPC в скрытое состояние для экономии runtime.
4. **Route runtime reset**
   - сброс runtime route-локалов (`active/index/current slot runtime state`);
   - постоянные контентные данные маршрутов/слотов не удаляются.

### 4.1 Цель freeze
После freeze interior не должен потреблять непрерывный runtime до следующего wake.

## 5. Fast materialization policy

**Нужна.** Для interior рекомендуется ввести fast materialization policy:

1. На wake разрешить быстрый путь «минимум для корректного кадра»:
   - unhide;
   - resync обязательных runtime-ссылок;
   - применение первой валидной активности.
2. Дорогие операции (полный deep-rebuild вторичных кэшей) допускается выполнять лениво, если это не ломает корректность поведения.
3. Политика не отменяет канонический порядок wake/freeze, а только оптимизирует latency первого появления.

## 6. Exceptions policy (whitelist interiors)

Whitelist-исключения допустимы только явно и по area-tag/id.

### 6.1 Разрешённые типы исключений
1. **Always HOT interior**
   - квестовые/системные интерьерные сцены с постоянной активностью.
2. **HOT window**
   - удержание HOT фиксированное время после выхода последнего игрока (антидребезг частых вход/выход).
3. **WARM retention**
   - кратковременное удержание WARM для быстрого re-enter без полной materialization.
4. **No-hide NPC subset**
   - ограниченный поднабор NPC, которым нельзя hide из-за визуального/сценарного контракта.

### 6.2 Ограничения для исключений
- whitelist не должен нарушать slot-driven источник истины;
- whitelist не должен приводить к бесконечному tick в пустом interior без явного обоснования;
- каждое исключение документируется причиной и owner-командой.

## 7. Debug-сообщения в чат

Рекомендуемый минимальный набор диагностик (в debug-area/режиме):

1. `AL_INTERIOR_POLICY area=<tag> kind=<kind> heat=<HOT|WARM|COLD> reason=<computed|force_hot|force_warm|force_cold|whitelist>`
2. `AL_INTERIOR_WAKE_START area=<tag> players=<n> token=<t>`
3. `AL_INTERIOR_WAKE_STEP area=<tag> step=<unhide|resync|route_cache|activity_apply> status=<ok|skip|fail>`
4. `AL_INTERIOR_WAKE_DONE area=<tag> ms=<duration> cache=<hit|miss> slot=<s>`
5. `AL_INTERIOR_FREEZE_START area=<tag> reason=<empty|force_cold|shutdown>`
6. `AL_INTERIOR_FREEZE_STEP area=<tag> step=<invalidate_tick|clear_scheduling|hide|route_reset> status=<ok|skip|fail>`
7. `AL_INTERIOR_FREEZE_DONE area=<tag> token=<t> scheduled=<0|1>`
8. `AL_INTERIOR_WHITELIST area=<tag> mode=<always_hot|hot_window|warm_retention|no_hide_subset> status=<applied|ignored>`

Принцип логирования: коротко, детерминированно, с обязательными полями `area`, `reason`, `status`.

## 8. Risks

1. **Конфликт force-флагов** может приводить к неочевидному heat-state без строгого приоритета.
2. **Слишком агрессивный freeze** может давать «поппинг» NPC при частых входах, если отсутствует warm-retention.
3. **Избыточный whitelist** может размыть цель оптимизации и вернуть постоянную нагрузку.
4. **Неполный resync на wake** даст рассинхрон activity/route у NPC после пробуждения.
5. **Шум debug-логов** в бою/нагруженных зонах может усложнить анализ без фильтрации по уровню.

## 9. Minimal rollout plan

1. **Phase 0 — классификация**
   - разметить interior-area через `al_area_kind`;
   - зафиксировать whitelist-кандидаты и владельцев.
2. **Phase 1 — контракт locals**
   - ввести/проверить `al_force_hot|warm|cold` и приоритет разрешения.
3. **Phase 2 — wake/freeze sequencing**
   - выровнять исполнение в канонический порядок wake и freeze;
   - добавить минимальные debug-сообщения.
4. **Phase 3 — fast materialization**
   - включить fast-path для interior wake;
   - валидировать latency входа в интерьеры.
5. **Phase 4 — whitelist gating**
   - активировать исключения только по списку;
   - метрики: число HOT пустых интерьеров, время wake, число fallback-активностей.
6. **Phase 5 — hardening**
   - ревизия конфликтов force-флагов;
   - ревизия noisy-debug и финальная калибровка retention окон.
