#include "al_constants_inc"
#include "al_area_tick_inc"

void main()
{
    // Этот entrypoint может вызываться часто (например heartbeat),
    // дедупликация планирования следующего тика выполняется внутри AreaTick().
    object oArea = OBJECT_SELF;
    AreaTick(oArea, GetLocalInt(oArea, AL_L_TICK_TOKEN));
}
