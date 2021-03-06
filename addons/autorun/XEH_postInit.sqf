#include "script_component.hpp"
#include "\a3\editor_f\Data\Scripts\dikCodes.h"

// Autorun loop
[{
    if !(GVAR(isAutoRunActive)) exitWith {};

    if !(call FUNC(canAutoRun)) exitWith {
        GVAR(isAutoRunActive) = false;
        KGE_LOGINFO("Autorun stopped");
    };

    private ["_animation"];
    _animation = GVAR(autoRunMode) call FUNC(getAnimation);

    KGE_Player playMoveNow _animation;

    // Change to last mode
    if !(isNil QGVAR(lastMode)) then {
         GVAR(autoRunMode) = GVAR(lastMode);
         GVAR(lastMode) = nil;
    };
}, 0.02, []] call CBA_fnc_addPerFrameHandler;

["KGE","kge_autorun_toggle", "Starts and stops autorun", {call FUNC(toggleOn); true}, {true}, [DIK_C, [false, true, false]], false] call CBA_fnc_addKeybind;
["KGE","kge_autorun_mode", "Change autorun mode", {call FUNC(toggleMode); true}, {true}, [DIK_B, [false, true, false]], false] call CBA_fnc_addKeybind;

[{
    (findDisplay 46) displayAddEventHandler ["KeyDown", {_this call FUNC(actionKeyCheck); false}];
}, [], {!(isNull (findDisplay 46))}] call EFUNC(common,waitUntil);

// Disable autorun when teleported
["onTeleport", {
    GVAR(isAutoRunActive) = false;
    KGE_Player playMoveNow "";
}] call AFUNC(common,addEventHandler);

KGE_LOGINFO("Autorun Module Initialized.");
