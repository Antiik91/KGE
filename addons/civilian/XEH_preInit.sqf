#include "script_component.hpp"

ADDON = false;

PREP(civLoop);
PREP(getRoad);
PREP(mainLoop);
PREP(module);
PREP(spawn);

GVAR(civMen) = [
	"C_man_p_beggar_F",
	"C_man_1",
	"C_man_polo_1_F",
	"C_man_polo_2_F",
	"C_man_polo_3_F",
	"C_man_polo_4_F",
	"C_man_polo_5_F",
	"C_man_polo_6_F",
	"C_man_shorts_1_F",
	"C_man_1_1_F",
	"C_man_1_2_F",
	"C_man_1_3_F",
	"C_man_p_fugitive_F",
	"C_man_p_shorts_1_F",
	"C_man_hunter_1_F",
	"C_man_shorts_2_F",
	"C_man_shorts_3_F",
	"C_man_shorts_4_F"
];
GVAR(civCar) = [
	"C_Offroad_01_F",
	"C_Offroad_01_repair_F",
	"C_Hatchback_01_F",
	"C_Hatchback_01_sport_F",
	"C_SUV_01_F",
	"C_Van_01_transport_F",
	"C_Van_01_box_F",
	"C_Van_01_fuel_F"
];
GVAR(currentAmount) = 0;

ADDON = true;
