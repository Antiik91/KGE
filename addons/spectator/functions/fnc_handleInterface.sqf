/*
 * Author: SilentSpike
 * Handles spectator interface events
 *
 * Arguments:
 * 0: Event name <STRING>
 * 1: Event arguments <ANY>
 *
 * Return Value:
 * None <NIL>
 *
 * Example:
 * ["onLoad",_this] call ace_spectator_fnc_handleInterface
 *
 * Public: No
 */

#include "..\script_component.hpp"

params ["_mode",["_args",[]]];

switch (toLower _mode) do {
    case "onload": {
        _args params ["_display"];

        // Always show interface and hide map upon opening
        [_display,nil,nil,!GVAR(showInterface),GVAR(showMap)] call FUNC(toggleInterface);

        // Keep unit list and tree up to date
        [FUNC(handleUnits), 5, _display] call CBA_fnc_addPerFrameHandler;

        // Handle 3D unit icons
        GVAR(iconHandler) = addMissionEventHandler ["Draw3D",FUNC(handleIcons)];

        // Populate the help window
        private "_help";
        _help = (_display displayCtrl IDC_HELP) controlsGroupCtrl IDC_HELP_LIST;
        {
            _i = _help lbAdd (_x select 0);
            if ((_x select 1) == "") then {
                _help lbSetPicture [_i,"\A3\ui_f\data\map\markers\military\dot_CA.paa"];
                _help lbSetPictureColor [_i,[COL_FORE]];
            } else {
                _help lbSetTooltip [_i,_x select 1];
            };
        } forEach [
            ["Interface",""],
            ["Toggle Unit List","1"],
            ["Toggle Help","2"],
            ["Toggle Toolbar","3"],
            ["Toggle Compass","4"],
            ["Toggle Unit Icons","5"],
            ["Toggle Map","M"],
            ["Toggle Interface","Backspace"],
            ["Free Camera",""],
            ["Camera Forward","W"],
            ["Camera Backward","S"],
            ["Camera Left","A"],
            ["Camera Right","D"],
            ["Camera Up","Q"],
            ["Camera Down","Z"],
            ["Pan Camera","RMB (Hold)"],
            ["Dolly Camera","LMB (Hold)"],
            ["Speed Boost","Shift (Hold)"],
            ["Focus on Unit","F"],
            ["Camera Attributes",""],
            ["Next Camera","Up Arrow"],
            ["Previous Camera","Down Arrow"],
            ["Next Unit","Right Arrow"],
            ["Previous Unit","Left Arrow"],
            ["Next Vision Mode","N"],
            ["Previous Vision Mode","Ctrl + N"],
            ["Adjust Zoom","Scrollwheel"],
            ["Adjust Speed","Ctrl + Scrollwheel"],
            ["Increment Zoom","Num-/Num+"],
            ["Increment Speed","Ctrl + Num-/Num+"],
            ["Reset Zoom","Alt + Num-"],
            ["Reset Speed","Alt + Num+"]
        ];

        // Handle support for BI's respawn counter
        [{
            if !(isNull (GETUVAR(RscRespawnCounter,displayNull))) then {
                disableSerialization;
                private ["_counter","_title","_back","_timer","_frame","_x","_y"];
                _counter = GETUVAR(RscRespawnCounter,displayNull);
                _title = _counter displayCtrl 1001;
                _back = _counter displayCtrl 1002;
                _timer = _counter displayCtrl 1003;
                _frame = _counter ctrlCreate ["RscFrame",1008];

                _x = safeZoneX + safeZoneW - TOOL_W * 4 - MARGIN * 3;
                _y = safeZoneY + safeZoneH - TOOL_H;

                // Timer
                _title ctrlSetPosition [_x,_y,TOOL_W,TOOL_H];
                _back ctrlSetPosition [_x,_y,TOOL_W,TOOL_H];
                _timer ctrlSetPosition [_x,_y,TOOL_W,TOOL_H];
                _frame ctrlSetPosition [_x,_y,TOOL_W,TOOL_H];

                _title ctrlSetBackgroundColor [0,0,0,0];
                _back ctrlSetBackgroundColor [COL_BACK];
                _timer ctrlSetFontHeight TOOL_H;
                _frame ctrlSetTextColor [COL_FORE];

                _title ctrlCommit 0;
                _back ctrlCommit 0;
                _timer ctrlCommit 0;
                _frame ctrlCommit 0;
            };
        },[],0.5] call EFUNC(common,waitAndExecute);
    };
    case "onunload": {
        // Kill GUI PFHs
        removeMissionEventHandler ["Draw3D",GVAR(iconHandler)];
        GVAR(camHandler) = nil;
        GVAR(compHandler) = nil;
        GVAR(iconHandler) = nil;
        GVAR(toolHandler) = nil;

        // Reset variables
        GVAR(camBoom) = 0;
        GVAR(camDolly) = [0,0];
        GVAR(ctrlKey) = false;
        GVAR(heldKeys) = [];
        GVAR(heldKeys) resize 255;
        GVAR(mouse) = [false,false];
        GVAR(mousePos) = [0.5,0.5];
        GVAR(treeSel) = objNull;
    };
    // Mouse events
    case "onmousebuttondown": {
        _args params ["_ctrl","_button"];
        GVAR(mouse) set [_button,true];

        // Detect right click
        if ((_button == 1) && (GVAR(camMode) == 1)) then {
            // In first person toggle sights mode
            GVAR(camGun) = !GVAR(camGun);
            [] call FUNC(transitionCamera);
        };
    };
    case "onmousebuttonup": {
        _args params ["_ctrl","_button"];

        GVAR(mouse) set [_button,false];
        if (_button == 0) then { GVAR(camDolly) = [0,0]; };
    };
    case "onmousezchanged": {
        _args params ["_ctrl","_zChange"];

        // Scroll to change speed, modifier for zoom
        if (GVAR(ctrlKey)) then {
            [nil,nil,nil,nil,nil,nil,nil, GVAR(camSpeed) + _zChange * 0.2] call FUNC(setCameraAttributes);
        } else {
            [nil,nil,nil,nil,nil,nil, GVAR(camZoom) + _zChange * 0.1] call FUNC(setCameraAttributes);
        };
    };
    case "onmousemoving": {
        _args params ["_ctrl","_x","_y"];

        [_x,_y] call FUNC(handleMouse);
    };
    // Keyboard events
    case "onkeydown": {
        _args params ["_display","_dik","_shift","_ctrl","_alt"];

        if ((alive player) && {_dik in (actionKeys "curatorInterface")} && {!isNull (getAssignedCuratorLogic player)}) exitWith {
            [QGVAR(zeus)] call FUNC(interrupt);
            ["zeus"] call FUNC(handleInterface);
        };
        if ((isServer || {serverCommandAvailable "#kick"}) && {_dik in (actionKeys "Chat" + actionKeys "PrevChannel" + actionKeys "NextChannel")}) exitWith {
            false
        };

        // Handle held keys (prevent repeat calling)
        if (GVAR(heldKeys) param [_dik,false]) exitwith {};
        // Exclude movement/adjustment keys so that speed can be adjusted on fly
        if !(_dik in [16,17,30,31,32,44,74,78]) then {
            GVAR(heldKeys) set [_dik,true];
        };

        switch (_dik) do {
            case 1: { // Esc
                [false] call FUNC(setSpectator);
                //[QGVAR(escape)] call FUNC(interrupt);
                //["escape"] call FUNC(handleInterface);
            };
            case 2: { // 1
                [_display,nil,nil,nil,nil,nil,true] call FUNC(toggleInterface);
            };
            case 3: { // 2
                [_display,nil,true] call FUNC(toggleInterface);
            };
            case 4: { // 3
                [_display,nil,nil,nil,nil,true] call FUNC(toggleInterface);
            };
            case 5: { // 4
                [_display,true] call FUNC(toggleInterface);
            };
            case 6: { // 5
                GVAR(showIcons) = !GVAR(showIcons);
            };
            case 14: { // Backspace
                [_display,nil,nil,true] call FUNC(toggleInterface);
            };
            case 16: { // Q
                GVAR(camBoom) = 0.5 * GVAR(camSpeed) * ([1, 2] select _shift);
            };
            case 17: { // W
                GVAR(camDolly) set [1, GVAR(camSpeed) * ([1, 2] select _shift)];
            };
            case 29: { // Ctrl
                GVAR(ctrlKey) = true;
            };
            case 30: { // A
                GVAR(camDolly) set [0, -GVAR(camSpeed) * ([1, 2] select _shift)];
            };
            case 31: { // S
                GVAR(camDolly) set [1, -GVAR(camSpeed) * ([1, 2] select _shift)];
            };
            case 32: { // D
                GVAR(camDolly) set [0, GVAR(camSpeed) * ([1, 2] select _shift)];
            };
            case 33: { // F
                private ["_sel","_vector"];
                _sel = GVAR(treeSel);
                if ((GVAR(camMode) == 0) && {!isNull _sel} && {_sel in GVAR(unitList)}) then {
                    _vector = (positionCameraToWorld [0,0,0]) vectorDiff (positionCameraToWorld [0,0,25]);
                    [nil,nil,nil,(getPosATL _sel) vectorAdd _vector] call FUNC(setCameraAttributes);
                };
            };
            case 44: { // Z
                GVAR(camBoom) = -0.5 * GVAR(camSpeed) * ([1, 2] select _shift);
            };
            case 49: { // N
                if (GVAR(camMode) == 0) then {
                    if (_ctrl) then {
                        [nil,nil,-1] call FUNC(cycleCamera);
                    } else {
                        [nil,nil,1] call FUNC(cycleCamera);
                    };
                };
            };
            case 50: { // M
                [_display,nil,nil,nil,true] call FUNC(toggleInterface);
            };
            case 57: { // Spacebar
                // Freecam attachment here, if in external then set cam pos and attach
            };
            case 74: { // Num -
                if (_alt) exitWith { [nil,nil,nil,nil,nil,nil, 1.25] call FUNC(setCameraAttributes); };
                if (_ctrl) then {
                    [nil,nil,nil,nil,nil,nil,nil, GVAR(camSpeed) - 0.05] call FUNC(setCameraAttributes);
                } else {
                    [nil,nil,nil,nil,nil,nil, GVAR(camZoom) - 0.01] call FUNC(setCameraAttributes);
                };
            };
            case 78: { // Num +
                if (_alt) exitWith { [nil,nil,nil,nil,nil,nil,nil, 2.5] call FUNC(setCameraAttributes); };
                if (_ctrl) then {
                    [nil,nil,nil,nil,nil,nil,nil, GVAR(camSpeed) + 0.05] call FUNC(setCameraAttributes);
                } else {
                    [nil,nil,nil,nil,nil,nil, GVAR(camZoom) + 0.01] call FUNC(setCameraAttributes);
                };
            };
            case 200: { // Up arrow
                [-1] call FUNC(cycleCamera);
            };
            case 203: { // Left arrow
                [nil,1] call FUNC(cycleCamera);
            };
            case 205: { // Right arrow
                [nil,-1] call FUNC(cycleCamera);
            };
            case 208: { // Down arrow
                [1] call FUNC(cycleCamera);
            };
        };

        true
    };
    case "onkeyup": {
        _args params ["_display","_dik","_shift","_ctrl","_alt"];

        // No longer being held
        GVAR(heldKeys) set [_dik,nil];

        switch (_dik) do {
            case 16: { // Q
                GVAR(camBoom) = 0;
            };
            case 17: { // W
                GVAR(camDolly) set [1, 0];
            };
            case 29: { // Ctrl
                GVAR(ctrlKey) = false;
            };
            case 30: { // A
                GVAR(camDolly) set [0, 0];
            };
            case 31: { // S
                GVAR(camDolly) set [1, 0];
            };
            case 32: { // D
                GVAR(camDolly) set [0, 0];
            };
            case 44: { // Z
                GVAR(camBoom) = 0;
            };
        };

        true
    };
    // Tree events
    case "ontreedblclick": {
        // Update camera view when listbox unit is double clicked on
        _args params ["_tree","_sel"];

        // Ensure a unit was selected
        if (count _sel == 3) then {
            private ["_netID","_newUnit","_newMode"];
            _netID = (_args select 0) tvData _sel;
            _newUnit = objectFromNetId _netID;

            // When unit is reselected, toggle camera mode
            if (_newUnit == GVAR(camUnit) || GVAR(camMode) == 0) then {
                _newMode = [2,2,1] select GVAR(camMode);
            };

            [_newMode,_newUnit] call FUNC(transitionCamera);
        };
    };
    case "ontreeselchanged": {
        _args params ["_tree","_sel"];

        if (count _sel == 3) then {
            GVAR(treeSel) = objectFromNetId (_tree tvData _sel);
        } else {
            GVAR(treeSel) = objNull;
        };
    };
    case "onunitsupdate": {
        _args params ["_tree"];
        private ["_cachedUnits","_cachedGrps","_cachedSides","_s","_g","_grp","_u","_unit","_side"];

        // Cache existing group and side nodes and cull removed data
        _cachedUnits = [];
        _cachedGrps = [];
        _cachedSides = [];

        for "_s" from 0 to ((_tree tvCount []) - 1) do {
            for "_g" from 0 to ((_tree tvCount [_s]) - 1) do {
                _grp = groupFromNetID (_tree tvData [_s,_g]);

                if (_grp in GVAR(groupList)) then {
                    _cachedGrps pushBack _grp;
                    _cachedGrps pushBack _g;

                    for "_u" from 0 to ((_tree tvCount [_s,_g])) do {
                        _unit = objectFromNetId (_tree tvData [_s,_g,_u]);

                        if (_unit in GVAR(unitList) && {alive _unit} && {_unit getVariable [QEGVAR(respawn,alive), true]}) then {
                            _cachedUnits pushBack _unit;
                        } else {
                            _tree tvDelete [_s,_g,_u];
                        };
                    };
                } else {
                    _tree tvDelete [_s,_g];
                };
            };

            if ((_tree tvCount [_s]) > 0) then {
                _cachedSides pushBack (_tree tvText [_s]);
                _cachedSides pushBack _s;
            } else {
                _tree tvDelete [_s];
            };
        };

        // Update the tree from the unit list
        {
            _grp = group _x;
            _side = [side _grp] call BIS_fnc_sideName;
            _hasPlayers = {isPlayer _x} count (units _grp) != 0;

            // Show only groups with players in them
            //if(GVAR(showAIList) || _hasPlayers) then {
                // Use correct side node
                if !(_side in _cachedSides) then {
                    // Add side node
                    _s = _tree tvAdd [[], _side];

                    if(_hasPlayers) then {
                        _tree tvExpand [_s];
                    };

                    _cachedSides pushBack _side;
                    _cachedSides pushBack _s;
                } else {
                    // If side already processed, use existing node
                    _s = _cachedSides select ((_cachedSides find _side) + 1);
                };

                // Use correct group node
                if !(_grp in _cachedGrps) then {
                    // Add group node
                    _g = _tree tvAdd [[_s], groupID _grp];
                    _tree tvSetData [[_s,_g], netID _grp];

                    if(_hasPlayers) then {
                        _tree tvExpand [_s,_g];
                    };

                    _cachedGrps pushBack _grp;
                    _cachedGrps pushBack _g;
                } else {
                    // If group already processed, use existing node
                    _g = _cachedGrps select ((_cachedGrps find _grp) + 1);
                };

                _u = _tree tvAdd [[_s,_g], GETVAR(_x,GVAR(uName),"")];
                _tree tvSetData [[_s,_g,_u], netID _x];
                _tree tvSetPicture [[_s,_g,_u], GETVAR(_x,GVAR(uIcon),"")];
                _tree tvSetPictureColor [[_s,_g,_u], GETVAR(_grp,GVAR(gColor),[ARR_4(1,1,1,1)])];

                _tree tvSort [[_s,_g],false];
            //};
        } forEach (GVAR(unitList) - _cachedUnits);

        _tree tvSort [[],false];

        if ((_tree tvCount []) <= 0) then {
            if(GVAR(showAIList)) then {
                _tree tvAdd [[], "No units"];
            } else {
                _tree tvAdd [[], "No players"];
            }
        };
    };
    // Map events
    case "onmapclick": {
        _args params ["_map","_button","_x","_y","_shift","_ctrl","_alt"];
        private ["_newPos","_oldZ"];

        if ((GVAR(camMode) == 0) && (_button == 0)) then {
            _newPos = _map ctrlMapScreenToWorld [_x,_y];
            _oldZ = (ASLtoATL GVAR(camPos)) select 2;
            _newPos set [2, _oldZ];
            [nil,nil,nil, _newPos] call FUNC(setCameraAttributes);
        };
    };
    // Interrupt events
    case "escape": {
        private "_dlg";

        createDialog (["RscDisplayInterrupt", "RscDisplayMPInterrupt"] select isMultiplayer);

        disableSerialization;
        _dlg = finddisplay 49;
        _dlg displayAddEventHandler ["KeyDown", {
            _key = _this select 1;
            !(_key == 1)
        }];

        // Disable save, respawn, options & manual buttons
        (_dlg displayCtrl 103) ctrlEnable false;
        if !(alive player) then {
            (_dlg displayCtrl 1010) ctrlEnable false;
        };
        (_dlg displayCtrl 101) ctrlEnable false;
        (_dlg displayCtrl 122) ctrlEnable false;

        // Initalize abort button (the "spawn" is a necessary evil)
        (_dlg displayCtrl 104) ctrlAddEventHandler ["ButtonClick",{_this spawn {
            disableSerialization;
            _display = ctrlparent (_this select 0);
            _abort = true;//[localize "str_msg_confirm_return_lobby",nil,localize "str_disp_xbox_hint_yes",localize "str_disp_xbox_hint_no",_display,nil,true] call BIS_fnc_guiMessage;
            if (_abort) then {_display closeDisplay 2; failMission "loser"};
        }}];

        // PFH to re-open display when menu closes
        [{
            if !(isNull (findDisplay 49)) exitWith {};

            // If still a spectator then re-enter the interface
            [QGVAR(escape),false] call FUNC(interrupt);

            [_this select 1] call CBA_fnc_removePerFrameHandler;
        },0] call CBA_fnc_addPerFrameHandler;
    };
    case "zeus": {
        openCuratorInterface;

        [{
            // PFH to re-open display when menu closes
            [{
                if !((isNull curatorCamera) && {isNull (GETMVAR(bis_fnc_moduleRemoteControl_unit,objNull))}) exitWith {};

                // If still a spectator then re-enter the interface
                [QGVAR(zeus),false] call FUNC(interrupt);

                [_this select 1] call CBA_fnc_removePerFrameHandler;
            },0] call CBA_fnc_addPerFrameHandler;
        },[],5] call EFUNC(common,waitAndExecute);

        true
    };
};
