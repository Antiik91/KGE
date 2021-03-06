/*
 * Author: nikolauska
 *
 * Adds fired event to vehicle if not already added
 *
 * Argument:
 * 0: Object
 *
 * Return value:
 *
 */

#include "..\script_component.hpp"

params [["_unit", KGE_Player, [objNull]]];

private ["_vehicle"];
_vehicle = vehicle _unit;

if !(isNil {_unit getVariable [QGVAR(firedEvent), nil]}) exitWith {};
if !([GVAR(allowedTanks), (typeOf _vehicle)] call cba_fnc_hashHasKey) exitWith {};

_unit setvariable [QGVAR(firedEvent), [_vehicle, _vehicle addEventHandler ["Fired", {_this call FUNC(firedEvent)}]]];

KGE_LOGINFO_1("Fired event added for %1",_vehicle);
