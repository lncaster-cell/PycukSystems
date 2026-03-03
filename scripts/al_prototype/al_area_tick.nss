#include "al_area_tick_inc"

void main()
{
    // Этот entrypoint может вызываться часто (например heartbeat),
    // дедупликация планирования следующего тика выполняется внутри AreaTick().
    object oArea = OBJECT_SELF;
    AreaTick(oArea, GetLocalInt(oArea, "al_tick_token"));
}
