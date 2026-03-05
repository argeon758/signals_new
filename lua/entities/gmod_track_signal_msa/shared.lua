if checkMSAblacklist() then return end
ENT.Type			= "anim"
ENT.PrintName		= "Signalling Element"
ENT.Category		= "Metrostroi (utility)"

ENT.Spawnable		= false
ENT.AdminSpawnable	= false

ENT.TrafficLightModels = {}
ENT.RenderOffset = {}
ENT.LongThreshold = {}
ENT.UseRoutePointerFont = {}
ENT.RoutePointerFontWidth = {}
ENT.BasePos = {}
ENT.BasePosition = Vector(-110,32,0)

ENT.ReloadModels = true
ENT.Signal_IS = "W"
Metrostroi.LiterWarper = {
	A = "f",B = ",",V = "d",G = "u",D = "l",E = "t",J = ";",Z = "p",
	I = "b",Y = "q",K = "r",L = "k",M = "v",N = "y",O = "j",P = "g",
	R = "h",S = "c",T = "n",U = "e",F = "a",H = "[",C = "w",
	--Y = "",--ЧЩЪЫЬЭЮ
	W = "o",Q = "z",
}

vector_mirror = Vector(-1, 1, 1)
vector_unit = Vector(1, 1, 1)

angle_flip = Angle(0, 180, 0)

-- Lamp indexes
-- 0 Red
-- 1 Yellow
-- 2 Green
-- 3 Blue
-- 4 Second yellow (flashing yellow)
-- 5 White
Metrostroi.RoutePointer = {
	[""] = 0,
	["0"] = 10,
	["D"] = 11,
}
for i = 1,9 do
	Metrostroi.RoutePointer[tostring(i)] = i
end
Metrostroi.Lenses = {
	["R"] = Color(255,0,0),
	["Y"] = Color(255,127,0),
	-- ["G"] = Color(0,255,144),
	["G"] = Color(0,255,174),
	-- ["G"] = Color(0,255,204),
	["W"] = Color(150,200,255),
	["B"] = Color(0,10,255),
	["I"] = Color(226,190,154),
	["X"] = Color(226,236,255),
}

Metrostroi.IncandescentLenses = {
	["R"] = Color(255,0,0),
	["Y"] = Color(255,127,0),
	-- ["G"] = Color(0,255,144),
	-- ["G"] = Color(0,255,174),
	["G"] = Color(0,255,204),
	-- ["W"] = Color(196,224,255),
	["W"] = Color(170,211,255),
	["B"] = Color(0,10,255),
	["I"] = Color(226,190,154),
	["X"] = Color(226,236,255),
}

Metrostroi.Colors = {}
for k,color in pairs(Metrostroi.Lenses) do
	Metrostroi.Colors[k] = color:ToVector()
end

Metrostroi.IncandescentColors = {}
for k, color in pairs(Metrostroi.IncandescentLenses) do
	Metrostroi.IncandescentColors[k] = color:ToVector()
end

Metrostroi.SigSpriteOffset = Vector(0, 32, 0)
--[[
ENT.LightType = 0
ENT.Name = ""
ENT.Lenses = {
}
ENT.RouteNumber = ""
ENT.OnlyARS = false

ENT.Routes = {
}
]]
ENT.AutostopModel = {
	"models/metrostroi/signals/mus/autostop.mdl",
	Vector(41-115,80,1.5)
}

ENT.OldRouteNumberSetup = {
	"fs1234DABVGEIKMNP",
	"WkFXd","LR",
	Vector(6,0,10.5),
	{
		["1"]=2,["2"]=3,["3"]=4,["4"]=5,D=8,
		A=6,B=7,V=9,G=10,E=11,I=12,K=13,M=14,N=15,P=16,
		Q=0,Z=1
	},
	{["F"]=1,["L"]=3,["R"]=1,W=4,k=5,d=2},
}
ENT.NewRouteNumberSetup = {
	["0"] = 1,  ["1"] = 2,  ["2"] = 4,  ["3"] = 6,  ["4"] = 7,
	["5"] = 8,  ["6"] = 9,  ["7"] = 10, ["8"] = 11, ["9"] = 12,
	A = 13, B = 14, V = 26, G = 18, D = 15,
	E = 16, I = 19, K = 20, M = 22, N = 23,
	P = 24, F = 17, R = 25, L = 21,
	Q = 3,  Z = 5,
}
ENT.SpriteMat = Material( "sprites/light_ignorez" )

Metrostroi.SigTypeNames = {}
Metrostroi.SigTypeSpriteMul = {}
--------------------------------------------------------------------------------
-- Inside
--------------------------------------------------------------------------------
Metrostroi.SigTypeNames[0] = 'Inside'
Metrostroi.SigTypeSpriteMul[0] = 1
ENT.BasePos[0] = Vector(0,0,0)
ENT.RenderOffset[0] = Vector(-93.5, 0, 110)
ENT.TrafficLightModels[0] = {
	m1	= "models/signals_msa/tunnels/dtm_support.mdl",
	dtm	= "models/signals_msa/tunnels/dtm_tunnel.mdl",
	m2	= "models/signals_msa/tunnels/pole.mdl",
	m2_long =  "models/signals_msa/tunnels/pole_long.mdl",
	m2_long_pos = Vector(0,0,21),
	m2_long_replace = "pole_",
	lense_scale = 0.791,
	noleft = true,
	name	= Vector(-10,3.5,-6),
	name_one	= Vector(-10,3.5,1),
	name_s	= Vector(112, 10, 0.5),
	name_s_ang	= Angle(0, 0, -90),
	name_out 	= Vector(11.5,2.5+30,36.6+16),
	boxname = Vector(13.5,33.5,52.25),
	step = Vector(0, 0, 9.15),
	stationboxoffset = Vector(13,39.25,50),
	[1]	= { Vector(0,0,30), "models/signals_msa/tunnels/old/light2_spb.mdl", {
				[0] = Vector(0,-22,19),
				[1] = Vector(0,-22,9.6),--
				["glass"]	= {
					{"models/metrostroi/signals/mus/lamp_lens_colored.mdl",Vector(0,4,19)},
					{"models/metrostroi/signals/mus/lamp_lens_colored.mdl",Vector(0,4,9.6)},
				},
				["kron"] = {
					{"models/signals_msa/tunnels/kron.mdl", Vector(0,0,0),1,right = true, short = true},
					{"models/signals_msa/tunnels/kron_mirror.mdl", Vector(0,0,0),1,left = true, short = true},
					{"models/signals_msa/tunnels/kron_l.mdl", Vector(0,0,0),1,right = true, long = true},
					{"models/signals_msa/tunnels/kron_l_mirror.mdl", Vector(0,0,0),1,left = true, long = true},
				},	
			}},
	[2]	= { Vector(0,0,43), "models/signals_msa/tunnels/old/light3_spb.mdl", {
				[0] = Vector(0,-22,28.4),
				[1] = Vector(0,-22,19),
				[2] = Vector(0,-22,9.6),---27.54
				["glass"]	= {
					{"models/metrostroi/scb/signals/lamp_lens.mdl",Vector(0,4,28.4)},
					{"models/metrostroi/scb/signals/lamp_lens.mdl",Vector(0,4,19)},
					{"models/metrostroi/scb/signals/lamp_lens.mdl",Vector(0,4,9.6)},
				},
				["kron"] = {
					{"models/signals_msa/tunnels/kron.mdl", Vector(0,0,0),1,right = true, short = true},
					{"models/signals_msa/tunnels/kron_mirror.mdl", Vector(0,0,0),1,left = true, short = true},
					{"models/signals_msa/tunnels/kron_l.mdl", Vector(0,0,0),1,right = true, long = true},
					{"models/signals_msa/tunnels/kron_l_mirror.mdl", Vector(0,0,0),1,left = true, long = true},
				},	
				}},
	X_glasses	= {
		{
			{"models/signals_msa/tunnels/zag_new.mdl",Vector(0,5,19)},
			{"models/signals_msa/tunnels/zag_new.mdl",Vector(0,5,9.6)},
		},
		{
			{"models/signals_msa/tunnels/zag_new.mdl",Vector(0,5,28.4)},
			{"models/signals_msa/tunnels/zag_new.mdl",Vector(0,5,19)},
			{"models/signals_msa/tunnels/zag_new.mdl",Vector(0,5,9.6)},
		},
	},

	M = { Vector(0,0,17), "models/signals_msa/tunnels/old/path_ind_msk.mdl", {
		["kron"] = {
			{"models/signals_msa/tunnels/kron.mdl", Vector(0,0,0),1,right = true, short = true},
			{"models/signals_msa/tunnels/kron_mirror.mdl", Vector(0,0,0),1,left = true, short = true},
			{"models/signals_msa/tunnels/kron_l.mdl", Vector(0,0,0),1,right = true, long = true},
			{"models/signals_msa/tunnels/kron_l_mirror.mdl", Vector(0,0,0),1,left = true, long = true},
		},
	}, Vector(1.85, 2.7, 9.5), 0.525, 0.525, 0.125},
	arsletter = true,
}


--------------------------------------------------------------------------------
-- Outside
--------------------------------------------------------------------------------
local SpecialLensConfig = {
    Vector(0,0,35),
    "models/signals_msa/outdoors/light1.mdl",
    {
        [0] = Vector(0,0.5,9.4),
        ["glass"] = {
            {"models/metrostroi/scb/signals/lamp_lens.mdl", Vector(0,33,9.4 ), 1.2},
        }
    }
}
Metrostroi.SigTypeNames[1] = 'Outside'
Metrostroi.SigTypeSpriteMul[1] = 0.75
ENT.BasePos[1] = Vector(0,0,0)
ENT.RenderOffset[1] = Vector(-100,-3,180)
ENT.LongThreshold[1] = 1
ENT.TrafficLightModels[1] = {
	["m1"]	= "models/signals_msa/tunnels/dtm_support.mdl",
	dtm	= "models/signals_msa/tunnels/dtm_tunnel.mdl",
	["m2"]	= "models/mp_signals/mp_signals_outside_pole1.mdl",
	name	= Vector(0,3,30),
	boxname = Vector(13,34,36.5),
	boxnamestart = Vector(13,34,36.5),
	stationboxoffset = Vector(13,38,50),
	[1]	= { Vector(0,0,55), "models/signals_msa/outdoors/light2.mdl", {
				[0] = Vector(0,0.5,23.4),
				[1] = Vector(0,0.5,9.4),
				["glass"]	= {
					{"models/metrostroi/scb/signals/lamp_lens.mdl",Vector(0,33,23.4), 1.2},
					{"models/metrostroi/scb/signals/lamp_lens.mdl",Vector(0,33,9.4 ), 1.2},
				}
				}},
	[2]	= { Vector(0,0,56), "models/signals_msa/outdoors/light3.mdl", {
				[0] = Vector(0,0.5,37.4),
				[1] = Vector(0,0.5,23.4),
				[2] = Vector(0,0.5,9.4),
				["glass"]	= {
					{"models/metrostroi/scb/signals/lamp_lens.mdl",Vector(0,33,37.4), 1.2},
					{"models/metrostroi/scb/signals/lamp_lens.mdl",Vector(0,33,23.4), 1.2},
					{"models/metrostroi/scb/signals/lamp_lens.mdl",Vector(0,33,9.4 ), 1.2},
				}
				} },
	X_glasses	= {
		{
			{"models/signals/msa/old_signals/standart/zag_old.mdl",Vector(0,13.3,19.95)},
			{"models/signals/msa/old_signals/standart/zag_old.mdl",Vector(0,13.3,7.97 )},
		},
		{
			{"models/signals/msa/old_signals/standart/zag_old.mdl",Vector(0,13.3,30.88)},
			{"models/signals/msa/old_signals/standart/zag_old.mdl",Vector(0,13.3,19.95)},
			{"models/signals/msa/old_signals/standart/zag_old.mdl",Vector(0,13.3,7.97 )},
		},
	},
	["W"] = SpecialLensConfig,
	["R"] = SpecialLensConfig,
	["G"] = SpecialLensConfig,
	["Y"] = SpecialLensConfig,
	["B"] = SpecialLensConfig,
	M = { Vector(0,0,40), "models/signals/msa/old_signals/standart/sign_5.mdl", {}, Vector(7,11, 25), 3.6, 3.4, 5},
	noleft = true,
}

--------------------------------------------------------------------------------
-- Outside box
--------------------------------------------------------------------------------
Metrostroi.SigTypeNames[2] = 'Outside box'
Metrostroi.SigTypeSpriteMul[2] = 0.75
ENT.BasePos[2] = Vector(0,0,0)
ENT.RenderOffset[2] = Vector(-100, 0.85, 105)
ENT.LongThreshold[2] = 1
ENT.TrafficLightModels[2] = {
	m1	= "models/signals_msa/tunnels/dtm_support.mdl",
	m2	= "models/signals_msa/tunnels/pole.mdl",
	m2_long =  "models/signals_msa/tunnels/pole_long.mdl",
	["name"]	= Vector(-3,2.5,7),
	name_one	= Vector(10.07,0.5,3),
	boxname = Vector(13,34,36.5),
	stationboxoffset = Vector(13,38,50),
	[1]	= { Vector(0,0,42), "models/metrostroi/signals/mus/light_outside2_2.mdl", {
				[0] = Vector(10.07,-29.7,27.55),
				[1] = Vector(10.07,-29.7,16),
				["glass"]	= {
					{"models/metrostroi/signals/mus/lamp_lens.mdl",Vector(10.39,2.32,27.55)},
					{"models/metrostroi/signals/mus/lamp_lens.mdl",Vector(10.39,2.32,16)},
				}
				}},
	[2]	= { Vector(0,0,47), "models/metrostroi/signals/mus/light_outside2_3.mdl", {
				[0] = Vector(10.07,-29.7,39.37),
				[1] = Vector(10.07,-29.7,27.55),
				[2] = Vector(10.07,-29.7,16),
				["glass"]	= {
					{"models/metrostroi/signals/mus/lamp_lens.mdl",Vector(10.39,2.32,39.37)},
					{"models/metrostroi/signals/mus/lamp_lens.mdl",Vector(10.39,2.32,27.55)},
					{"models/metrostroi/signals/mus/lamp_lens.mdl",Vector(10.39,2.32,16)},
				}
				}},
	[3]	= { Vector(0,0,47), "models/metrostroi/signals/mus/light_outside2_4.mdl", {
				[0] = Vector(10.07,-29.7,50.45),
				[1] = Vector(10.07,-29.7,39.37),
				[2] = Vector(10.07,-29.7,27.55),
				[3] = Vector(10.07,-29.7,16),
				["glass"]	= {
					{"models/metrostroi/signals/mus/lamp_lens.mdl",Vector(10.39,2.32,50.45)},
					{"models/metrostroi/signals/mus/lamp_lens.mdl",Vector(10.39,2.32,39.37)},
					{"models/metrostroi/signals/mus/lamp_lens.mdl",Vector(10.39,2.32,27.55)},
					{"models/metrostroi/signals/mus/lamp_lens.mdl",Vector(10.39,2.32,16)},
				}
				}},
	X_glasses	= {
		{
			{"models/signals/msa/old_signals/standart/zag_old.mdl",Vector(10.39,2.32,27.55)},
			{"models/signals/msa/old_signals/standart/zag_old.mdl",Vector(10.39,2.32,16)},
		},
		{
			{"models/signals/msa/old_signals/standart/zag_old.mdl",Vector(10.39,2.32,39.37)},
			{"models/signals/msa/old_signals/standart/zag_old.mdl",Vector(10.39,2.32,27.55)},
			{"models/signals/msa/old_signals/standart/zag_old.mdl",Vector(10.39,2.32,16)},
		},
		{
			{"models/signals/msa/old_signals/standart/zag_old.mdl",Vector(10.39,2.32,50.45)},
			{"models/signals/msa/old_signals/standart/zag_old.mdl",Vector(10.39,2.32,39.37)},
			{"models/signals/msa/old_signals/standart/zag_old.mdl",Vector(10.39,2.32,27.55)},
			{"models/signals/msa/old_signals/standart/zag_old.mdl",Vector(10.39,2.32,16)},
		},
	},
	M = { Vector(0,0,24), "models/signals/msa/old_signals/standart/sign_4.mdl", {}, Vector(13.8,2, 22.8), 1.8, 2.1, 4},
}

--------------------------------------------------------------------------------
-- Dwarf
--------------------------------------------------------------------------------
Metrostroi.SigTypeNames[3] = 'Dwarf'
Metrostroi.SigTypeSpriteMul[3] = 0.75
ENT.BasePos[3] = Vector(0,0,0)
ENT.RenderOffset[3] = Vector(-100,0,-8)
ENT.TrafficLightModels[3] = {
	name	= Vector(0,9,27),
	[1]	= { Vector(15,0,0), "models/signals_msa/outdoors/small/light2_beton.mdl", {
		[0] = Vector(0,-28,53.7),
		[1] = Vector(0,-28,43.4),
		-- ["glass_inside"]	= {
		-- 	{"models/metrostroi/signals/mus/lamp_lens_colored.mdl",Vector(0.1,2.32+2.5-0.65,54.9+10.8), 0.95*0.86875},
		-- 	{"models/metrostroi/signals/mus/lamp_lens_colored.mdl",Vector(0.1,2.32+2.5-0.65,54.9), 0.95*0.86875},
		-- },
		["glass"]	= {
			{"models/metrostroi/scb/signals/lamp_lens.mdl",Vector(0,4.8,53.7)},
			{"models/metrostroi/scb/signals/lamp_lens.mdl",Vector(0,4.8,43.4)},
		},
	}},
	[2]	= { Vector(15,0,0), "models/signals_msa/outdoors/small/light3_beton.mdl", {
		[0] = Vector(0,-28,64.1),
		[1] = Vector(0,-28,53.7),
		[2] = Vector(0,-28,43.4),
		["glass"]	= {
			{"models/metrostroi/scb/signals/lamp_lens.mdl",Vector(0,4.8,64.1)},
			{"models/metrostroi/scb/signals/lamp_lens.mdl",Vector(0,4.8,53.7)},
			{"models/metrostroi/scb/signals/lamp_lens.mdl",Vector(0,4.8,43.4)},
		},
	}},
	X_glasses	= {
		{
			{"models/signals_msa/tunnels/zag_new.mdl",Vector(0,5,53.7), 1.2},
			{"models/signals_msa/tunnels/zag_new.mdl",Vector(0,5,43.4), 1.2},
		},
		{
			{"models/signals_msa/tunnels/zag_new.mdl",Vector(0,5,64.1), 1.2},
			{"models/signals_msa/tunnels/zag_new.mdl",Vector(0,5,53.7), 1.2},
			{"models/signals_msa/tunnels/zag_new.mdl",Vector(0,5,43.4), 1.2},
		},
	},
	noleft = true,
}
--------------------------------------------------------------------------------
-- Invisible
--------------------------------------------------------------------------------
Metrostroi.SigTypeNames[4] = 'Invisible'
Metrostroi.SigTypeSpriteMul[4] = 1
ENT.RenderOffset[4] = Vector(0,0,100)
ENT.TrafficLightModels[4] = {
	["m1"]	=			"models/metrostroi_train/81-717/buttons_pam/pam_0.mdl",
	["m2"]	=			"models/metrostroi_train/81-717/buttons_pam/pam_0.mdl",
	boxname =			Vector(11.5,35,50),
	boxname_autostop =	Vector(23.5,8.25,57.5),
	stationboxoffset =	Vector(13,38,50),
	boxnamestreet =		Vector(13,38,50),
	["name"] =			Vector(11.5, 19.5, 52.5),
	["name_s"] =		Vector(0, 10, 0.5),
	["name_s_ang"] =	Angle(0,0,0),
	["name_out"] =		Vector(112.5,15,4),
	arsletter = true,
}
--------------------------------------------------------------------------------
-- Virus New
--------------------------------------------------------------------------------
Metrostroi.SigTypeNames[5] = 'Virus New'
Metrostroi.SigTypeSpriteMul[5] = 1
ENT.BasePos[5] = Vector(0,0,0)
ENT.RenderOffset[5] = Vector(-93.6, 0, 108)
ENT.TrafficLightModels[5] = {
	m1	= "models/signals_msa/tunnels/dtm_support.mdl",
	dtm = "models/signals_msa/tunnels/dtm_tunnel.mdl",
	m2	= "models/signals_msa/tunnels/pole.mdl",
	m2_long =  "models/signals_msa/tunnels/pole_long.mdl",
	m2_long_pos = Vector(0,0,46),
	m2_long_replace = "pole_",
	name	= Vector(-10,3.5,0),
	name_one	= Vector(-10,3.5,0),
	noleft = false,
	kronOff = Vector(0,0,13),
	step = Vector(0,0,10.75),
	boxname = Vector(13.5,40,52.25),
	stationboxoffset = Vector(13,38,50),
	single	= { Vector(0,0,24), "models/signals_msa/tunnels/light_single_2.mdl", {
				[0] = Vector(0,-28.85,7.9),--
				["glass"]	= {
					{"models/metrostroi/scb/signals/lamp_lens.mdl",Vector(0,3,7.9)},
				}
			}},
	[0]	= { Vector(20,0,24), "models/signals_msa/tunnels/light_1_2.mdl", {
				[0] = Vector(0,-28.85,7.9),--
				["glass"]	= {
					{"models/metrostroi/scb/signals/lamp_lens.mdl",Vector(0,3,7.9)},
				},
				["kron"] = {
					{"models/signals_msa/tunnels/kron.mdl", Vector(0,0,0),1,right = true, short = true},
					{"models/signals_msa/tunnels/kron_mirror.mdl", Vector(0,0,0),1,left = true, short = true},
				},	
			}},
	X	= { Vector(0,0,46), "models/signals_msa/tunnels/light_1_2.mdl", {
			[0] = Vector(7.22,-29.56,12.93),---27.54
			["glass"]	= {
				{"models/signals_msa/tunnels/zag_newt.mdl",Vector(0,0,0)},
			},
			["kron"] = {
					{"models/signals_msa/tunnels/kron.mdl", Vector(0,0,0),1,right = true, short = true},
					{"models/signals_msa/tunnels/kron_mirror.mdl", Vector(0,0,0),1,left = true, short = true},
					{"models/signals_msa/tunnels/kron_l.mdl", Vector(0,0,0),1,right = true, long = true},
					{"models/signals_msa/tunnels/kron_l_mirror.mdl", Vector(0,0,0),1,left = true, long = true},
			},	
		}
	},
	M = { Vector(0,0,24.5), "models/signals_msa/tunnels/path_ind.mdl", {
		["kron"] = {
			{"models/signals_msa/tunnels/kron.mdl", Vector(0,0,0),1,right = true, short = true},
			{"models/signals_msa/tunnels/kron_mirror.mdl", Vector(0,0,0),1,left = true, short = true},
		},
	}, Vector(1.85, 2.7, 9.5), 0.525, 0.525, 0.125},
	M_double = { Vector(0,0,24.5), "models/signals_msa/tunnels/path_ind_double.mdl", {}, Vector(13.1,2, 19.5), 1.75, 2.05, 4},
	M_single = { Vector(0,0,24.5), "models/signals_msa/tunnels/path_ind_single.mdl", {}},
}
--------------------------------------------------------------------------------
-- Dwarf SPB
--------------------------------------------------------------------------------
Metrostroi.SigTypeNames[6] = 'Dwarf SPB'
Metrostroi.SigTypeSpriteMul[6] = 0.75
ENT.BasePos[6] = Vector(0,0,0)
ENT.RenderOffset[6] = Vector(-95,0,-8)
ENT.TrafficLightModels[6] = {
	name	= Vector(0,9.356,106.5),
	[1]	= { Vector(0,0,0), "models/signals_msa/outdoors/small/light2_metal.mdl", {
				[0] = Vector(0,-27,126.63),
				[1] = Vector(0,-27,116.7),
				["glass"]	= {
					{"models/metrostroi/scb/signals/lamp_lens.mdl",Vector(0,4.8,126.63)},
					{"models/metrostroi/scb/signals/lamp_lens.mdl",Vector(0,4.8,116.7)},
				}
				}},
	[2]	= { Vector(0,0,0), "models/signals_msa/outdoors/small/light3_metal.mdl", {
				[0] = Vector(0,-27,137.5),
				[1] = Vector(0,-27,126.63),
				[2] = Vector(0,-27,116.7),
				["glass"]	= {
					{"models/metrostroi/scb/signals/lamp_lens.mdl",Vector(0,4.8,137.5)},
					{"models/metrostroi/scb/signals/lamp_lens.mdl",Vector(0,4.8,126.63)},
					{"models/metrostroi/scb/signals/lamp_lens.mdl",Vector(0,4.8,116.7)},
				}
		}},
	X_glasses	= {
		{
			{"models/signals_msa/tunnels/zag_new.mdl",Vector(0,5.5,126.63),1.2},
			{"models/signals_msa/tunnels/zag_new.mdl",Vector(0,5.5,116.7),1.2},
		},
		{
			{"models/signals_msa/tunnels/zag_new.mdl",Vector(0,5.5,137.5),1.2},
			{"models/signals_msa/tunnels/zag_new.mdl",Vector(0,5.5,126.63),1.2},
			{"models/signals_msa/tunnels/zag_new.mdl",Vector(0,5.5,116.7),1.2},
		},
	},
	noleft = true,
}


ENT.SignalConverter = {
	R = 1,
	Y = 2,
	G = 3,
	B = 4,
	W = 5
}

ENT.SpriteConverter = {
	[1] = 'R',
	[2] = 'Y',
	[3] = 'G',
	[4] = 'B',
	[5] = 'W'
}
ENT.SpriteMultiplier = {
	[1] = 1,
	[2] = 1,
	[3] = 0.75,
	[4] = 1.25,
	[5] = 1
}


for i = 0,(#ENT.TrafficLightModels) do
	--SERVER
	ENT.TrafficLightModels[i].ArsBox = {model = "models/metrostroi/signals/mus/ars_box.mdl"}
	ENT.TrafficLightModels[i].ArsBoxMittor = {model = "models/metrostroi/signals/mus/ars_box_mittor.mdl"}
	
	--CLIENT
	ENT.BasePos[i] = ENT.BasePos[i] or ENT.BasePosition
	ENT.TrafficLightModels[i].LampIndicator = {
		models = {
			"models/metrostroi/signals/mus/light_lampindicator.mdl",
			"models/metrostroi/signals/mus/light_lampindicator2.mdl",
			"models/metrostroi/signals/mus/light_lampindicator3.mdl",
			"models/metrostroi/signals/mus/light_lampindicator4.mdl",
			"models/metrostroi/signals/mus/light_lampin2dicator5.mdl",
			numb = "models/signals/msa/old_signals/old_ind/light_lampinsdicator_numb.mdl",
			lamp = "models/signals/msa/old_signals/old_ind/light_lampindicator_lamp.mdl",
		},
		Vector(7.9), -- Indicator model offset if left
		Vector(0), -- Indicator model offset
		Vector(8), -- Sep (on short kron) Indicator model offset
		Vector(-12,0,0), -- Sep (on short kron) Indicator model offset if left
		Vector(3,0,3), -- Arrow offset
		Vector(20,0,-12), -- Arrow offset if left
	}
	ENT.TrafficLightModels[i].LampBase = {model = "models/metrostroi/signals/mus/lamp_base_fix.mdl"}
	ENT.TrafficLightModels[i].SignLetterSmall = {model = "models/metrostroi/signals/mus/sign_letter_small.mdl", Vector(1.5,0,0), Vector(-1.5,0,0)}
	ENT.TrafficLightModels[i].SignLetter = {model = "models/metrostroi/signals/mus/sign_letter.mdl", z = 5.85}
	ENT.TrafficLightModels[i].LetMaterials = {str = "models/metrostroi/signals/let/"}
	
	ENT.TrafficLightModels[i].RouteNumberOffset = Vector(10,0,0)
	ENT.TrafficLightModels[i].DoubleOffset = Vector(0,0,1.62)
	ENT.TrafficLightModels[i].RouteNumberOffset2 = Vector(0,0,7.2)
	ENT.TrafficLightModels[i].SpecRouteNumberOffset = Vector(3,-1,3)
	ENT.TrafficLightModels[i].RouteNumberOffset3 = Vector(10.5,0,-6)
	ENT.TrafficLightModels[i].SpecRouteNumberOffset2 = Vector(-0.8,1,0.94)
	ENT.TrafficLightModels[i].RouaOffset = Vector(6.2,0,24.5)
end