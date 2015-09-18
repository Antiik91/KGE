/*
 * Author: SilentSpike
 * Adds units to spectator whitelist/blacklist and refreshes the filter units
 *
 * Arguments:
 * 0: Units to add to the whitelist <ARRAY>
 * 1: Use blacklist <BOOL> <OPTIONAL>
 *
 * Return Value:
 * None <NIL>
 *
 * Example:
 * [allUnits,true] call ace_spectator_fnc_updateUnits
 *
 * Public: Yes
 */

#include "..\script_component.hpp"

params [["_newUnits",[],[[]]],["_blacklist",false,[false]]];

// Function only matters on player clients
if !(hasInterface) exitWith {};

// If adding to a list we can exit here, since it won't show up until the UI refreshes anyway
/*
if !(_newUnits isEqualTo []) exitWith {
    if (_blacklist) then {
        GVAR(unitWhitelist) = GVAR(unitWhitelist) - _newUnits;
        GVAR(unitBlacklist) append _newUnits;
    } else {
        GVAR(unitBlacklist) = GVAR(unitBlacklist) - _newUnits;
        GVAR(unitWhitelist) append _newUnits;
    };
};
*/
private ["_sides","_cond","_filteredUnits","_filteredGroups"];

// Filter units and append to list
_filteredUnits = [];
{
    if (
        (_x call EFUNC(common,isAlive)) &&
        {_x getVariable ["KGE_alive", true]}
    ) then {
        _filteredUnits pushBack _x;
    };
} forEach (allUnits);// - GVAR(unitBlacklist));
//_filteredUnits append GVAR(unitWhitelist);

// Cache icons and colour for drawing
_filteredGroups = [];
{
    // Intentionally re-applied to units in case their status changes
    _x call FUNC(cacheUnitInfo);
    _filteredGroups pushBack (group _x);
} forEach _filteredUnits;

// Replace previous lists entirely (removes any no longer valid)
GVAR(unitList) = _filteredUnits arrayIntersect _filteredUnits;
GVAR(groupList) = _filteredGroups arrayIntersect _filteredGroups;
