// Module 3: area OnExit entrypoint (thin wrapper).

#include "module3_core"

void main()
{
    Module3OnAreaExit(OBJECT_SELF, GetExitingObject());
}
