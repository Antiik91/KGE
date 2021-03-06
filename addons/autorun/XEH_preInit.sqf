#include "script_component.hpp"

ADDON = false;

PREP(actionKeyCheck);
PREP(canAutoRun);
PREP(getAnimation);
PREP(getTerrainGradient);
PREP(toggleMode);
PREP(toggleOn);

GVAR(autoRunMode) = JOG;
GVAR(isAutoRunActive) = false;
GVAR(terrainGradientMaxIncline) = 30;
GVAR(terrainGradientMaxDecline) = -30;
GVAR(fatigueThreshold) = 0.7;
GVAR(alive) = true;
GVAR(disablingActions) = ["MoveForward", "MoveBack", "MoveUp", "MoveDown", "MoveLeft", "MoveRight", "TurnLeft", "TurnRight", "Crouch", "Prone", "GetOver", "ToggleWeapons", "SwitchWeapon"];
GVAR(disablingAnimation) = ["amovppnemstpsraswrfldnon", "amovpercmstpsnonwnondf", "amovpercmrunsnonwnondf"];

ADDON = true;
