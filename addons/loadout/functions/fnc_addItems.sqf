/*
 * Author: nikolauska
 *
 * Add item to unit
 *
 * Argument:
 * 0: Config path <Config>
 * 1: Loadout target <Object>
 *
 * Return value:
 *
 */

#include "..\script_component.hpp"

params ["_configPath", "_loadoutTarget"];

{ _loadoutTarget addItem (_x call FUNC(fixer)); } forEach getArray (_configPath);