Config                            = {}
Config.Locale                     = 'en'

Config.MaxInService               = 100
Config.EnableSocietyOwnedVehicles = false

Config.ImpundPrice = 100
Config.DrawDistance               = 100.0

Config.MarkerSize                 = {x = 1.5, y = 1.5, z = 0.5}
Config.MarkerColor                = {r = 50, g = 50, b = 204}


Config.Zones = {
	Blip = {
		Coords  = vector3(-368.2418,-130.7473, 38.66516),
		Sprite  = 488,
		Display = 4,
		Scale   = 0.3,
		Colour  = 24,
		name = 'Mechanic'
	},
	CustomCarLocation = {x = -320.2418, y = -131.4593, z = 38.96851},
	--BossAction = {x = -346.8396, y = -128.0967, z = 39.0022},
	Cloakroom = vector3(-311.2484, -137.222, 39.0022),
	ItemInventory = vector3(-344.7033, -125.0242, 39.0022),
	CarSpawn = vector3(-360.1187, -122.5055, 38.68201),
	CarSpawnLocation = {
		{coords = vector3(-376.9187, -126.9626, 38.58093), heading = 34.0157, radius = 6.0}
	}
}

Config.CustomUniforms = {
	shagerd = {
		{
			label = "لباس کار",
			model = {
				male = {
					tshirt_1 = 28,  tshirt_2 = 0,
					torso_1 = 35,   torso_2 = 0,
					decals_1 = 0,   decals_2 = 0,
					arms = 38,
					pants_1 = 28,   pants_2 = 0,
					shoes_1 = 10,   shoes_2 = 0,
					mask_1  = 0,    mask_2  = 0,
					bproof_1  = 0, bproof_2  = 0,
					helmet_1 = 10,  helmet_2 = 4,
					chain_1 = 0,    chain_2 = 38,
					ears_1 = 0,     ears_2 = 0,
					glasses_1 = 0,     glasses_2 = 0
				},
				female = {
					tshirt_1 = 33,  tshirt_2 = 0,
					torso_1 = 92,   torso_2 = 0,
					decals_1 = 0,   decals_2 = 0,
					arms = 26,
					pants_1 = 47,   pants_2 = 0,
					shoes_1 = 27,   shoes_2 = 0,
					helmet_1 = -1,  helmet_2 = 0,
					chain_1 = 0,    chain_2 = 0,
					ears_1 = 2,     ears_2 = 0
				}
			}
		}
	},
	mecanic = {
		{
			label = "لباس کار",
			model = {
				male = {
					tshirt_1 = 28,  tshirt_2 = 0,
					torso_1 = 35,   torso_2 = 0,
					decals_1 = 0,   decals_2 = 0,
					arms = 38,
					pants_1 = 28,   pants_2 = 0,
					shoes_1 = 10,   shoes_2 = 0,
					mask_1  = 0,    mask_2  = 0,
					bproof_1  = 0, bproof_2  = 0,
					helmet_1 = 10,  helmet_2 = 4,
					chain_1 = 0,    chain_2 = 38,
					ears_1 = 0,     ears_2 = 0,
					glasses_1 = 0,     glasses_2 = 0
				},
				female = {
					tshirt_1 = 33,  tshirt_2 = 0,
					torso_1 = 92,   torso_2 = 0,
					decals_1 = 0,   decals_2 = 0,
					arms = 26,
					pants_1 = 47,   pants_2 = 0,
					shoes_1 = 27,   shoes_2 = 0,
					helmet_1 = -1,  helmet_2 = 0,
					chain_1 = 0,    chain_2 = 0,
					ears_1 = 2,     ears_2 = 0
				}
			}
		}
	},
	karshenas = {
		{
			label = "لباس کار",
			model = {
				male = {
					tshirt_1 = 28,  tshirt_2 = 0,
					torso_1 = 35,   torso_2 = 0,
					decals_1 = 0,   decals_2 = 0,
					arms = 38,
					pants_1 = 28,   pants_2 = 0,
					shoes_1 = 10,   shoes_2 = 0,
					mask_1  = 0,    mask_2  = 0,
					bproof_1  = 0, bproof_2  = 0,
					helmet_1 = 10,  helmet_2 = 4,
					chain_1 = 0,    chain_2 = 38,
					ears_1 = 0,     ears_2 = 0,
					glasses_1 = 0,     glasses_2 = 0
				},
				female = {
					tshirt_1 = 33,  tshirt_2 = 0,
					torso_1 = 92,   torso_2 = 0,
					decals_1 = 0,   decals_2 = 0,
					arms = 26,
					pants_1 = 47,   pants_2 = 0,
					shoes_1 = 27,   shoes_2 = 0,
					helmet_1 = -1,  helmet_2 = 0,
					chain_1 = 0,    chain_2 = 0,
					ears_1 = 2,     ears_2 = 0
				}
			}
		}
	},
	karshenasf = {
		{
			label = "لباس کار",
			model = {
				male = {
					tshirt_1 = 28,  tshirt_2 = 0,
					torso_1 = 35,   torso_2 = 0,
					decals_1 = 0,   decals_2 = 0,
					arms = 38,
					pants_1 = 28,   pants_2 = 0,
					shoes_1 = 10,   shoes_2 = 0,
					mask_1  = 0,    mask_2  = 0,
					bproof_1  = 0, bproof_2  = 0,
					helmet_1 = 10,  helmet_2 = 4,
					chain_1 = 0,    chain_2 = 38,
					ears_1 = 0,     ears_2 = 0,
					glasses_1 = 0,     glasses_2 = 0
				},
				female = {
					tshirt_1 = 33,  tshirt_2 = 0,
					torso_1 = 92,   torso_2 = 0,
					decals_1 = 0,   decals_2 = 0,
					arms = 26,
					pants_1 = 47,   pants_2 = 0,
					shoes_1 = 27,   shoes_2 = 0,
					helmet_1 = -1,  helmet_2 = 0,
					chain_1 = 0,    chain_2 = 0,
					ears_1 = 2,     ears_2 = 0
				}
			}
		}
	},
	boss = {
		{
			label = "لباس کار",
			model = {
				male = {
					tshirt_1 = 28,  tshirt_2 = 0,
					torso_1 = 35,   torso_2 = 0,
					decals_1 = 0,   decals_2 = 0,
					arms = 38,
					pants_1 = 28,   pants_2 = 0,
					shoes_1 = 10,   shoes_2 = 0,
					mask_1  = 0,    mask_2  = 0,
					bproof_1  = 0, bproof_2  = 0,
					helmet_1 = 10,  helmet_2 = 4,
					chain_1 = 0,    chain_2 = 38,
					ears_1 = 0,     ears_2 = 0,
					glasses_1 = 0,     glasses_2 = 0
				},
				female = {
					tshirt_1 = 33,  tshirt_2 = 0,
					torso_1 = 92,   torso_2 = 0,
					decals_1 = 0,   decals_2 = 0,
					arms = 26,
					pants_1 = 47,   pants_2 = 0,
					shoes_1 = 27,   shoes_2 = 0,
					helmet_1 = -1,  helmet_2 = 0,
					chain_1 = 0,    chain_2 = 0,
					ears_1 = 2,     ears_2 = 0
				}
			}
		}
	}
}

Config.SubJobUniforms = {}
