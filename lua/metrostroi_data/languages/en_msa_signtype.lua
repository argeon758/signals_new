--Types
Type_Signals = {[0] = "Choose Type","Signal","Sign","Autodrive (PAM)","Autostop","KGU"}
Type_Signal = {
    {"Inside",			1},
    {"Outside Big",		2},
    {"Outside Small",	3},
    {"Dwarf",			4},
    {"Invisible",		5},
    {"New Inside",		6},
    {"Dwarf SPB",		7}
}
Type_Signal_Route = {[0] = "Choose Type","Auto", "Manual","Repeater","Emergency"}
Type_PAM = {
	[0] = "Choose Type","Commands (Plank)","Station Braking (Plank)", "Open Doors Command",
	"PA Light Sensor","PA Marker","UPPS Sensor","SBPP Sensor"
}
Type_Autostops = {[0] = "Choose Type","Separated", "Inertial", "Static", "Inertial single-acting"}
Type_Signs = {
	[0] = "Choose Type",
	"Speed Restrictions",
	"OPV (Stop Markers)",
	"Enclosing Signs",
	"Service Stuff",
	"Driving Regimes (Default)",
	"Driving Regimes (New Trains)",
	"Stop Signs"
}
Type_Signs_Speed = {
    {"NF (OCh)",		0},
    {"10 km/h",			60},
    {"35 km/h",			33},
    {"40 km/h",			1},
    {"50 km/h",			44},
    {"60 km/h",			2},
    {"70 km/h",			3},
    {"80 km/h",			4},
    {"Street NF (OCh)",	26},
	{"Street 35 km/h",	27},
	{"Street 40 km/h",	28},
	{"Street 50 km/h",	45},
	{"Street 60 km/h",	29},
	{"Street 70 km/h",	30},
	{"Street 80 km/h",	31},
	{"X25/40 km/h",		61},
	{"X35/60 km/h",		62},
	{"X40/70 km/h",		63},
	{"ALS-0",			47},
	{"ALS-NF",			48}
}
Type_Signs_OPV = {
    {"OPV (lit)",		10},
    {"OPV",				66},
    {"3-car OPV",		67},
    {"4-car OPV",		68},
    {"5-car OPV",		69},
    {"6-car OPV",		70},
    {"On-Track OPV",	71}
}
Type_Signs_Opasno = {
    {"Danger",				8},
    {"EB Limit",			12},
    {"EB Start",			19},
    {"Station Lift Down Device Sign",20},
    {"Danger 200 m",		44},
    {"Street EB Limit",		42},
    {"Blast Door",			43}
}
Type_Signs_Service = {
    {"Station Border",			5},
    {"C (Horn)",				18},
    {"Street C (Horn)",			6},
    {"Right Doors",				21},
    {"Phone ▲",					22},
    {"Phone ▼",					23},
    {"013 End",					49},
    {"334 End",					50},
    {"Third Rail End",			35},
	{"Third Rail End (Inv.)",	36}
}
Type_Signs_TED = {
    {"TED On",				16},
    {"TED Off",				17},
    {"T Start",				13},
    {"T End",				14},
    {"T Assemble",			15},
    {"Street T Assemble",	32},
    {"X-2",					46},
    {"X-2 Street",			51},
    {"T-1",					53},
    {"T Test",				64},
	{"T Test 100 m",		65}
}
Type_Signs_TED_new = {
	{"TED Off Catch-Up",			211},
	{"TED Off",						213},
	{"TED Off 2 Black Stripes (2)",	214},
	{"TED Off Catch-Up (Small)",	215},
	{"TED Off 2 Black Stripes",		216},
	{"TED Off 1 Red Stripe",		217},
	{"TED Off 1 Blue Stripe",		218},
	{"TED Off 4 Blue Stripes",		219},
	{"TED On 10%",					220},
	{"TED On 20%",					221},
	{"TED On 30%",					222},
	{"TED On 40%",					223},
	{"TED On 50%",					224},
	{"TED On 60%",					225},
	{"TED On 70%",					226},
	{"TED On 80%",					227},
	{"TED On 90%",					228},
	{"TED On 100%",					229},
	{"TED On Catch-Up",				230},
	{"TED On",						232},
	{"TED On 2 Black Stripes",		233},
	{"TED On Catch-Up (Small)",		234},
	{"TED On 2 Black Stripes (2)",	235},
	{"TED On 1 Red Stripe",			236},
	{"TED On 1 Blue Stripe",		237},
	{"TED On 4 Blue Stripes",		238},
}
Type_Signs_Stop = {
    {"UP1",				24},
    {"UP2",				37},
    {"UP3",				38},
    {"UP4",				39},
    {"UP5",				40},
    {"UP6",				41},
    {"3",				52},
    {"4",				54},
    {"5",				55},
	{"6",				56},
	{"Street 5",		57},
	{"Street 6",		58},
	{"STOP (!)",		11},
	{"Street STOP",		7},
	{"Street STOP!!!",	25},
	{"Deadend (Night)",	9},
	{"15m",	241}
}
Type_Signs_Choice = {
    [1] = Type_Signs_Speed,
    [2] = Type_Signs_OPV,
    [3] = Type_Signs_Opasno,
    [4] = Type_Signs_Service,
    [5] = Type_Signs_TED,
    [6] = Type_Signs_TED_new,
    [7] = Type_Signs_Stop,
}