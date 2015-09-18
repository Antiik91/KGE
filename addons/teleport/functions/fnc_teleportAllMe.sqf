/*
 * Author: nikolauska
 *
 * Teleport unit to map position
 *
 * Argument:
 * 0: Unit to be teleported <Object>
 * 1: Position to teleport <Position> (Empty position start mapclick event)
 *
 * Return value:
 *
 */

#include "..\script_component.hpp"

private ["_inVehicle"];
_inVehicle = 0;

{
    if(!local _x && {_x getVariable ["KGE_alive", true]}) then {
        if(((vehicle _x) == _x) && {!(surfaceIsWater (getPosASL _x))}) then {
            [_x, GVAR(player)] call FUNC(toBehind);
        } else {
            INC(_inVehicle);
        };
    };
} forEach (call cba_fnc_players);

if(_inVehicle != 0) then {
    Hint "Some players were in vehicle or in water and were not teleported";
};
