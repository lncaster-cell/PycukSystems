# Ambient Life: контракт интерьеров (HOT/WARM/COLD)

Обновлено: 2026-03-08

Документ описывает текущую политику для interior-area в AL.

## 1) Определение interior-area

Area считается interior, если установлен local:

- `al_is_interior=1`

Контракт intentionally простой: решение принимается локально по area-local без внешнего классификатора.

## 2) Поведение interior по умолчанию

- при unset `al_area_mode` (нет `al_area_mode_is_set=1`) interior получает `COLD` через legacy fallback;
- при explicit `al_area_mode=0` (`COLD`) поведение то же, но это считается валидной явной политикой, а не fallback;
- при explicit, но невалидном значении `al_area_mode` (вне `0..3`) применяется legacy fallback;
- presence игроков может перевести area в `HOT` через OnEnter;
- после выхода последнего игрока interior возвращается в `COLD`.

## 3) Прогрев соседей

При `HOT` на source-area вызывается soft-activation соседей из `al_adjacent_areas`.

Для interior-соседа применяются ограничения:

1. interior-сосед должен существовать по tag;
2. interior-сосед должен быть явно включён в `al_adj_interior_whitelist` source-area.

Если условие не выполнено, прогрев не применяется, а при `al_debug=1` пишется diagnostic fallback.

## 4) Что НЕ делает текущая реализация

- не ведёт глобальный scheduler;
- не делает каскадный multi-hop прогрев;
- не поднимает соседние area выше `WARM`;
- не хранит reason enum/историю переходов в отдельных locals.

## 5) Рекомендованный content-профиль

### 5.1 Для типичных интерьеров (дом, приватная комната)

- `al_is_interior=1`
- не добавлять в чужие `al_adj_interior_whitelist` без причины
- allow wake только по входу игрока

### 5.2 Для полу-публичных интерьеров (таверна/магазин)

- `al_is_interior=1`
- добавить tag area в whitelist соседней уличной area
- при необходимости установить `al_area_mode=WARM` или `HOT` контентно

### 5.3 Для служебных/техзон

- `al_area_mode=OFF`
- не полагаться на wake-path и route-loop

## 6) Диагностика

Включите `al_debug=1` на source-area и проверьте:

- сообщения `adjacency fallback` о пустом/битом списке соседей;
- сообщения о пропуске interior-соседа вне whitelist;
- факт перевода area в `HOT`/`COLD` на входе/выходе игроков.
