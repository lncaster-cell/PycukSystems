# Полный аудит системы модуля поведения NPC

Аудит выполнен по актуальному коду `src/modules/npc` и эксплуатационным документам `docs/*`.

> В рамках аудита **не анализировались** скрипты из `third_party/`.

## 1) Executive summary

- Модуль реализован как зрелый runtime-контур: lifecycle-controller + bounded priority queue + budgeted tick + maintenance watchdog.
- Поведение стабилизировано через единый `npc_core` API и thin-entrypoint hooks.
- Основной риск эксплуатации — не сам runtime, а контентная дисциплина (валидные route/tag, корректный hook wiring, контроль degraded mode по метрикам).
- Для внедрения в новые/существующие модули добавлен отдельный пошаговый гайд: `docs/npc_behavior_setup_faq.md`.

## 2) Область аудита и что проверялось

Проверены следующие подсистемы:
- hook-контур и точки входа (`npc_module_load`, `npc_spawn`, `npc_area_tick`, и т.д.);
- lifecycle (`RUNNING/PAUSED/STOPPED`) и transitions;
- queue/fairness/deferred contracts;
- activity/runtime dispatch и fallback-цепочки;
- observability-метрики и readiness checks;
- интеграционный контур документации (индекс, runtime orchestration, authoring contract).

## 3) Карта текущей архитектуры

### 3.1 Thin entrypoints + единый фасад

`npc_*.nss` файлы выполняют проксирование в `NpcBhvrOn*` из `npc_core`, что делает логику централизованной и тестопригодной.

### 3.2 Lifecycle области

Состояния:
- `STOPPED` — контур деактивирован;
- `RUNNING` — рабочий тиковый цикл;
- `PAUSED` — watchdog-режим.

Ключевая operational идея: область работает «дорого» только при необходимости, а в idle переводится в более экономичный режим.

### 3.3 Очередь и справедливость

- Bounded queue c приоритетами `CRITICAL/HIGH/NORMAL/LOW`.
- Coalesce исключает дубли pending-субъектов.
- Для non-critical действует starvation guard и rotation fairness.
- Для `damage/critical` путь сохраняет высокий приоритет даже под нагрузкой.

### 3.4 Tick pipeline

В `RUNNING` проходит фиксированный конвейер:
1. idle gate;
2. нормализация budget/limits;
3. budgeted queue processing;
4. degradation + carryover;
5. deferred reconcile/trim;
6. flush и idle-stop проверка.

### 3.5 Activity слой

- Каноническая daypart модель (`dawn/morning/afternoon/evening/night`).
- Маршрутизация через slot-route/alert-route и fallback-резолв.
- Невалидные route/tag не роняют runtime: включается deterministic fallback.

### 3.6 Maintenance и self-heal

Тяжёлые операции (reconcile/compaction/self-heal) вынесены в отдельный watchdog-энтрипоинт для защиты hot-path тика.

## 4) Найденные сильные стороны

1. Хорошо разделены hot-path и maintenance-path (предсказуемый runtime-cost).
2. Метрики покрывают и функциональное состояние, и деградацию под нагрузкой.
3. Модуль поддерживает controlled degradation вместо хаотичного поведения при pressure.
4. Документация по authoring, orchestration и readiness уже есть и обновлена перекрёстными ссылками.

## 5) Риски и точки контроля

1. **Hook wiring drift** — неправильная привязка toolset hooks ломает жизненный цикл.
2. **Content drift в route/tag** — рост fallback-сценариев маскирует проблемы контента.
3. **Budget misconfiguration** — слишком маленькие лимиты провоцируют постоянный degraded mode.
4. **Overuse legacy knobs** — усложняет поддержку и снижает предсказуемость поведения.

## 6) Рекомендации после аудита

### Приоритет P0 (обязательные)
- Перед каждым rollout запускать smoke + lifecycle + activity + fairness контракты.
- В релизный gate добавить проверку на отсутствие длительного degraded streak.

### Приоритет P1 (важные)
- Еженедельно просматривать readiness/perf отчёты и обновлять baseline при изменениях контента.
- Для контент-команд закрепить канонический authoring only через `npc_cfg_*` facade.

### Приоритет P2 (улучшения)
- Сформировать шаблон оперативного инцидент-анализа по метрикам queue/deferred/degraded.
- Автоматизировать публикацию краткого weekly health summary по NPC runtime.

## 7) Пошаговая настройка и FAQ

Пошаговый integration runbook и раздел FAQ вынесены в отдельный документ:

- `docs/npc_behavior_setup_faq.md`

Это сделано, чтобы аудит оставался инженерно-диагностическим, а внедрение/эксплуатация были оформлены как самостоятельная операционная инструкция.
