ESX = nil
local HasAlreadyEnteredMarker = false
local CurrentAction, CurrentActionMsg, CurrentActionData = nil, '', {}
local isDead, isBusy = false, false
local myCar, CarBeforeChanges, blipInServices = {}, {}, {}
local totalPrice = 0
local isInMarker, hasExited, letSleep = false, false, true
local currentStation, currentPart, currentPartNum
local lsMenuIsShowed, playerInService, isInShopMenu = false, false, false
local Vehicles

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	ESX.PlayerData = ESX.GetPlayerData()
	
	
	ESX.TriggerServerCallback('master_mechanicjob:getVehiclesPrices', function(vehicles)
		Vehicles = vehicles
	end)
end)

-- Create blips
Citizen.CreateThread(function()
	local blip = AddBlipForCoord(Config.Zones.Blip.Coords)

	SetBlipSprite (blip, Config.Zones.Blip.Sprite)
	SetBlipDisplay(blip, Config.Zones.Blip.Display)
	SetBlipScale(blip, 1.2)
	SetBlipColour (blip, Config.Zones.Blip.Colour)
	SetBlipAsShortRange(blip, true)

	BeginTextCommandSetBlipName('STRING')
	AddTextComponentSubstringPlayerName(Config.Zones.Blip.name)
	EndTextCommandSetBlipName(blip)
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic' then
			
			isInMarker, hasExited, letSleep = false, false, true
			currentPart = nil
			local playerPed = PlayerPedId()
			local playerCoords = GetEntityCoords(playerPed)

			local distance = #(playerCoords - Config.Zones.Cloakroom)

			if distance < Config.DrawDistance then
				DrawMarker(20, Config.Zones.Cloakroom, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.0, 1.0, 1.0, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, true, false, false, false)
				letSleep = false

				if distance < Config.MarkerSize.x then
					isInMarker, currentPart = true, 'Cloakroom'
				end
			end
			
			distance = #(playerCoords - Config.Zones.ItemInventory)

			if distance < Config.DrawDistance then
				DrawMarker(20, Config.Zones.ItemInventory, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.0, 1.0, 1.0, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, true, false, false, false)
				letSleep = false

				if distance < Config.MarkerSize.x then
					isInMarker, currentPart = true, 'ItemInventory'
				end
			end

			distance = #(playerCoords - Config.Zones.CarSpawn)

			if distance < Config.DrawDistance then
				DrawMarker(36, Config.Zones.CarSpawn, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.0, 1.0, 1.0, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, true, false, false, false)
				letSleep = false

				if distance < Config.MarkerSize.x then
					isInMarker, currentPart = true, 'CarSpawn'
				end
			end

			if isInMarker and not HasAlreadyEnteredMarker or (isInMarker and LastPart ~= currentPart) then
				if LastPart and LastPart ~= currentPart then
					TriggerEvent('master_mechanicjob:hasExitedMarker', currentPart)
					hasExited = true
				end
				
				HasAlreadyEnteredMarker = true
				LastPart                = currentPart
				TriggerEvent('master_mechanicjob:hasEnteredMarker', currentPart)
			end

			if not hasExited and not isInMarker and HasAlreadyEnteredMarker then
				HasAlreadyEnteredMarker = false
				TriggerEvent('master_mechanicjob:hasExitedMarker', LastPart)
			end

			if letSleep then
				Citizen.Wait(2000)
			end
		else
			Citizen.Wait(10000)
		end
	end
end)

RegisterNetEvent('master_keymap:e')
AddEventHandler('master_keymap:e', function() 
	if CurrentAction and  ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic' then
		if CurrentAction == 'menu_cloakroom' then
			OpenCloakroomMenu()
		elseif CurrentAction == 'menu_items' then
			ESX.TriggerServerCallback('esx_service:isInService', function(isInService)
				if isInService then
					OpenGetStocksMenu()
				else
					exports.pNotify:SendNotification({text = "شما در حال انجام وظیفه نمی باشید!", type = "error", timeout = 3000})
				end
			end, ESX.PlayerData.job.name)
		elseif CurrentAction == 'menu_cars' then
			ESX.TriggerServerCallback('esx_service:isInService', function(isInService)
				if isInService then
					OpenVehicleSpawnerMenu()
				else
					exports.pNotify:SendNotification({text = "شما در حال انجام وظیفه نمی باشید!", type = "error", timeout = 3000})
				end
			end, ESX.PlayerData.job.name)
		end

		CurrentAction = nil
	end
end)

RegisterNetEvent('master_keymap:f6')
AddEventHandler('master_keymap:f6', function()
	if not isDead and ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic' then
		ESX.TriggerServerCallback('esx_service:isInService', function(isInService)
			if isInService then
				OpenMobileMechanicActionsMenu()
			else
				exports.pNotify:SendNotification({text = "شما در حال انجام وظیفه نمی باشید!", type = "error", timeout = 3000})
			end
		end, ESX.PlayerData.job.name)
	end
end)

function OpenMobileMechanicActionsMenu()
	ESX.UI.Menu.CloseAll()
	
	if ESX.PlayerData.job.grade_name == 'boss' then
		elements = {
			{label = _U('billing'),       value = 'billing'},
			{label = _U('repair'),        value = 'fix_vehicle'},
			{label = _U('clean'),         value = 'clean_vehicle'},
			{label = _U('imp_veh'),       value = 'del_vehicle'},
			{label = 'شخصی سازی خودرو',       value = 'custom_vehicle'},
			{label = 'پنل مدیریت', value = 'boss_action'},
		}
	else
		elements = {
			{label = _U('billing'),       value = 'billing'},
			{label = _U('repair'),        value = 'fix_vehicle'},
			{label = _U('clean'),         value = 'clean_vehicle'},
			{label = _U('imp_veh'),       value = 'del_vehicle'},
			{label = 'شخصی سازی خودرو',       value = 'custom_vehicle'},
			--{label = _U('place_objects'), value = 'object_spawner'}
		}
	end
	
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'mobile_mechanic_actions', {
		title    = _U('mechanic'),
		align    = 'top-right',
		elements = elements
	
	}, function(data, menu)
		if isBusy then return end

		if data.current.value == 'billing' then
			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'billing', {
				title = _U('invoice_amount')
			}, function(data, menu)
				local amount = tonumber(data.value)

				if amount == nil or amount < 0 then
					exports.pNotify:SendNotification({text = _U('amount_invalid'), type = "error", timeout = 3000})
				else
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
					if closestPlayer == -1 or closestDistance > 3.0 then
						exports.pNotify:SendNotification({text = _U('no_players_nearby'), type = "error", timeout = 3000})
					else
						menu.close()
						TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(closestPlayer), 'society_mechanic', _U('mechanic'), amount)
					end
				end
			end, function(data, menu)
				menu.close()
			end)
		elseif data.current.value == 'boss_action' then
			menu.close()
			TriggerEvent('master_society:RequestOpenBossMenu')
		elseif data.current.value == 'fix_vehicle' then
			local playerPed = PlayerPedId()
			local vehicle   = ESX.Game.GetVehicleInDirection()
			local coords    = GetEntityCoords(playerPed)

			if IsPedSittingInAnyVehicle(playerPed) then
				exports.pNotify:SendNotification({text = _U('inside_vehicle'), type = "error", timeout = 3000})
				return
			end

			if DoesEntityExist(vehicle) then
				isBusy = true
				ESX.TriggerServerCallback('master_mechanicjob:repair_car', function(success)
					if success then
						RepairCar(vehicle, nil)
					else
						isBusy = false
					end
				end)				
			else
				exports.pNotify:SendNotification({text = _U('no_vehicle_nearby'), type = "error", timeout = 3000})
			end
		elseif data.current.value == 'clean_vehicle' then
			local playerPed = PlayerPedId()
			local vehicle   = ESX.Game.GetVehicleInDirection()
			local coords    = GetEntityCoords(playerPed)

			if IsPedSittingInAnyVehicle(playerPed) then
				exports.pNotify:SendNotification({text = _U('inside_vehicle'), type = "error", timeout = 3000})
				return
			end

			if DoesEntityExist(vehicle) then
				isBusy = true
				TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_MAID_CLEAN', 0, true)
				Citizen.CreateThread(function()
					Citizen.Wait(10000)

					SetVehicleDirtLevel(vehicle, 0)
					ClearPedTasksImmediately(playerPed)

					exports.pNotify:SendNotification({text = _U('vehicle_cleaned'), type = "success", timeout = 3000})
					isBusy = false
				end)
			else
				exports.pNotify:SendNotification({text = _U('no_vehicle_nearby'), type = "error", timeout = 3000})
			end
		elseif data.current.value == 'del_vehicle' then
			local playerPed = PlayerPedId()

			if IsPedSittingInAnyVehicle(playerPed) then
				exports.pNotify:SendNotification({text = _U('inside_vehicle'), type = "error", timeout = 3000})
				return
			else
				local vehicle = ESX.Game.GetVehicleInDirection()

				if DoesEntityExist(vehicle) then
					TriggerServerEvent('master_mechanicjob:impound_carstart', vehicle)
				else
					exports.pNotify:SendNotification({text = _U('must_near'), type = "error", timeout = 3000})
				end
			end
		--[[elseif data.current.value == 'object_spawner' then
			local playerPed = PlayerPedId()

			if IsPedSittingInAnyVehicle(playerPed) then
				exports.pNotify:SendNotification({text = _U('inside_vehicle'), type = "error", timeout = 3000})
				return
			end

			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'mobile_mechanic_actions_spawn', {
				title    = _U('objects'),
				align    = 'top-right',
				elements = {
					{label = _U('roadcone'), value = 'prop_roadcone02a'},
					{label = _U('toolbox'),  value = 'prop_toolchest_01'}
			}}, function(data2, menu2)
				local model   = data2.current.value
				local coords  = GetEntityCoords(playerPed)
				local forward = GetEntityForwardVector(playerPed)
				local x, y, z = table.unpack(coords + forward * 1.0)

				if model == 'prop_roadcone02a' then
					z = z - 2.0
				elseif model == 'prop_toolchest_01' then
					z = z - 2.0
				end

				ESX.Game.SpawnObject(model, {x = x, y = y, z = z}, function(obj)
					SetEntityHeading(obj, GetEntityHeading(playerPed))
					PlaceObjectOnGroundProperly(obj)
				end)
			end, function(data2, menu2)
				menu2.close()
			end)]]--
		elseif data.current.value == 'custom_vehicle' then
			local playerCoords = GetEntityCoords(GetPlayerPed(-1))
			if(Vdist(playerCoords.x, playerCoords.y, playerCoords.z, Config.Zones.Cloakroom.x, Config.Zones.Cloakroom.y, Config.Zones.Cloakroom.z) < 30) then
				CustomizeCar()
			else
				exports.pNotify:SendNotification({text = "شما در نزدیکی مکانیکی نیستید.", type = "error", timeout = 4000})
			end
		end
	end, function(data, menu)
		menu.close()
	end)
end

RegisterNetEvent('master_mechanicjob:impound_carstart')
AddEventHandler('master_mechanicjob:impound_carstart', function(veh)
	if isBusy then
		return
	end
	
	local playerPed = PlayerPedId()
	isBusy = true
	
	TaskStartScenarioInPlace(playerPed, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
	Citizen.Wait(5000)
	ClearPedTasks(playerPed)
	exports.pNotify:SendNotification({text = _U('vehicle_impounded'), type = "success", timeout = 3000})
	ESX.Game.DeleteVehicle(veh)
	isBusy = false
end)

local isJackRaised = false
function RepairCar(vehicle, carJackObj)
	player = GetPlayerPed(-1)
	
	TaskTurnPedToFaceEntity(player, vehicle, 1.0)
	Citizen.Wait(1000)
	FreezeEntityPosition(vehicle, true)
	local vehPos = GetEntityCoords(vehicle)
	
	local heading = GetEntityHeading(vehicle)
	if carJackObj == nil then
		carJackObj = CreateObject(GetHashKey("prop_carjack"), vehPos.x, vehPos.y, vehPos.z - 0.95, true, true, true)
		SetEntityHeading(carJackObj, heading)
		FreezeEntityPosition(carJackObj, true)
	end
	
	local objPos = GetEntityCoords(carJackObj)
	-- Request & Load Animation:
	local anim_dict = "anim@amb@business@weed@weed_inspecting_lo_med_hi@"
	local anim_lib	= "weed_crouch_checkingleaves_idle_02_inspector"
	RequestAnimDict(anim_dict)
	while not HasAnimDictLoaded(anim_dict) do
		Citizen.Wait(100)
	end
	TaskPlayAnim(player, anim_dict, anim_lib, 2.0, -3.5, -1, 1, false, false, false, false)
	Citizen.Wait(1000)
	ClearPedTasks(player)
	
	local count = 5
	while true do
		vehPos = GetEntityCoords(vehicle)
		objPos = GetEntityCoords(carJackObj)
		if count > 0 then 
			TaskPlayAnim(player, anim_dict, anim_lib, 3.5, -3.5, -1, 1, false, false, false, false)
			Citizen.Wait(1000)
			ClearPedTasks(player)
			if not isJackRaised then
				SetEntityCoordsNoOffset(vehicle, vehPos.x, vehPos.y, (vehPos.z+0.10), true, false, false, true)
				SetEntityCoordsNoOffset(carJackObj, objPos.x, objPos.y, (objPos.z+0.10), true, false, false, true)
			else
				SetEntityCoordsNoOffset(vehicle, vehPos.x, vehPos.y, (vehPos.z-0.10), true, false, false, true)
				SetEntityCoordsNoOffset(carJackObj, objPos.x, objPos.y, (objPos.z-0.10), true, false, false, true)
			end
			FreezeEntityPosition(vehicle, true)
			FreezeEntityPosition(carJackObj, true)
			count = count - 1
		end
		if count <= 0 then 
			ClearPedTasks(player)
			if isJackRaised then
				FreezeEntityPosition(vehicle, false)
				if DoesEntityExist(carJackObj) then 
					DeleteEntity(carJackObj)
					DeleteObject(carJackObj)
				end
				carJackObj = nil
				isJackRaised = false
				isBusy = false
			else
				isJackRaised = true
			end
			break
		end
	end
	ClearPedTasks(player)
	
	if isJackRaised then	
		Citizen.Wait(200)
		TaskStartScenarioInPlace(player, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
		Citizen.Wait(5000)
		TaskStartScenarioInPlace(player, 'PROP_HUMAN_BUM_BIN', 0, true)
		Citizen.Wait(5000)
		TaskStartScenarioInPlace(player, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
		Citizen.Wait(5000)

		SetVehicleFixed(vehicle)
		SetVehicleDeformationFixed(vehicle)
		SetVehicleUndriveable(vehicle, false)
		SetVehicleEngineOn(vehicle, true, true)
		ClearPedTasksImmediately(player)
		exports.pNotify:SendNotification({text = _U('vehicle_repaired'), type = "success", timeout = 3000})
		
		RepairCar(vehicle, carJackObj)
	end
end

function cleanPlayer(playerPed)
	SetPedArmour(playerPed, 0)
	ClearPedBloodDamage(playerPed)
	ResetPedVisibleDamage(playerPed)
	ClearPedLastWeaponDamage(playerPed)
	ResetPedMovementClipset(playerPed, 0)
end

function setUniform(uniform, playerPed)
	TriggerEvent('skinchanger:getSkin', function(skin)
		local uniformObject
		local uniform = uniform
		
		if skin.sex == 0 then
			uniformObject = Config.Uniforms[ESX.PlayerData.job.name][uniform].male
		else
			uniformObject = Config.Uniforms[ESX.PlayerData.job.name][uniform].female
		end

		if uniformObject then
			TriggerEvent('skinchanger:loadClothes', skin, uniformObject)
		else
			exports.pNotify:SendNotification({text = 'لباس موجود نیست!', type = "info", timeout = 3000})
		end
	end)
end

function setCustomUniform(uniform, playerPed)
	TriggerEvent('skinchanger:getSkin', function(skin)
		local uniformObject

		if skin.sex == 0 then
			uniformObject = uniform.male
		else
			uniformObject = uniform.female
		end
		
		if uniformObject then
			TriggerEvent('skinchanger:loadClothes', skin, uniformObject)
		else
			exports.pNotify:SendNotification({text = 'لباس موجود نیست!', type = "info", timeout = 3000})
		end
	end)
end

function OpenCloakroomMenu()
	local playerPed = PlayerPedId()
	local grade = ESX.PlayerData.job.grade_name

	local elements = {
		{label = 'لباس شهروندی', value = 'citizen_wear'}
	}
	
	if Config.CustomUniforms[grade] ~= nil then
		for k,v in ipairs(Config.CustomUniforms[grade]) do
			table.insert(elements, {label = v.label, value = 'custom_players', model = v.model})
		end
	end
	
	if ESX.PlayerData.job.job_sub ~= nil and Config.SubJobUniforms[ESX.PlayerData.job.job_sub] ~= nil then
		for k,v in ipairs(Config.SubJobUniforms[ESX.PlayerData.job.job_sub]) do
			table.insert(elements, {label = v.label, value = 'custom_players', model = v.model})
		end
	end

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'cloakroom', {
		title    = 'لباس',
		align    = 'right',
		elements = elements
	}, function(data, menu)
		cleanPlayer(playerPed)

		if data.current.value == 'citizen_wear' then
			menu.close()
			ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
				local model = nil
				
				if skin.sex == 0 then
            		model = GetHashKey("mp_m_freemode_01")
          		else
            		model = GetHashKey("mp_f_freemode_01")
          		end

          		RequestModel(model)
          		while not HasModelLoaded(model) do
            	RequestModel(model)
            		Citizen.Wait(1)
          		end

          		SetPlayerModel(PlayerId(), model)
          		SetModelAsNoLongerNeeded(model)

          		TriggerEvent('skinchanger:loadSkin', skin)
				  TriggerEvent('esx:restoreLoadout')
			end)
		
			ESX.TriggerServerCallback('esx_service:isInService', function(isInService)
				if isInService and ESX.PlayerData.job.name ~= 'fbi' then
					playerInService = false

					local notification = {
						title    = _U('service_anonunce'),
						subject  = '',
						msg      = _U('service_out_announce', GetPlayerName(PlayerId())),
						iconType = 1
					}

					TriggerServerEvent('esx_service:notifyAllInService', notification, ESX.PlayerData.job.name)

					TriggerServerEvent('esx_service:disableService', ESX.PlayerData.job.name)
					TriggerEvent('master_mechanicjob:updateBlip')
					exports.pNotify:SendNotification({text = _U('service_out'), type = "info", timeout = 3000})
				end
			end, ESX.PlayerData.job.name)
		end

		if data.current.value ~= 'citizen_wear' then
			local awaitService

			ESX.TriggerServerCallback('esx_service:isInService', function(isInService)
				if not isInService then

					ESX.TriggerServerCallback('esx_service:enableService', function(canTakeService, maxInService, inServiceCount)
						if not canTakeService then
							exports.pNotify:SendNotification({text = _U('service_max', inServiceCount, maxInService), type = "error", timeout = 3000})
						else
							awaitService = true
							playerInService = true

							local notification = {
								title    = _U('service_anonunce'),
								subject  = '',
								msg      = _U('service_in_announce', GetPlayerName(PlayerId())),
								iconType = 1
							}

							TriggerServerEvent('esx_service:notifyAllInService', notification, ESX.PlayerData.job.name)
							TriggerEvent('master_mechanicjob:updateBlip')
							exports.pNotify:SendNotification({text = _U('service_in'), type = "info", timeout = 3000})
						end
					end, ESX.PlayerData.job.name)

				else
					awaitService = true
				end
			end, ESX.PlayerData.job.name)

			while awaitService == nil do
				Citizen.Wait(5)
			end

			-- if we couldn't enter service don't let the player get changed
			if not awaitService then
				return
			end
		end

		if data.current.value == 'custom_players' then
			setCustomUniform(data.current.model, playerPed)
			return
		end
		
		if data.current.uniform then
			setUniform(data.current.uniform, playerPed)
		end
		
	end, function(data, menu)
		menu.close()

		CurrentAction     = 'menu_cloakroom'
		CurrentActionMsg  = _U('open_cloackroom')
		CurrentActionData = {}
	end)
end

function OpenGetStocksMenu()
	ESX.TriggerServerCallback('master_mechanicjob:getItems', function(items)
		local elements = {}

		for i=1, #items, 1 do
			table.insert(elements, {
				label = items[i].label,
				value = i
			})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_menu', {
			title    = 'لوازم',
			align    = 'right',
			elements = elements
		}, function(data, menu)
			menu.close()

			ESX.TriggerServerCallback('master_mechanicjob:GetItem', function()
				OpenGetStocksMenu()
			end, items[data.current.value].name, items[data.current.value].amount)
		end, function(data, menu)
			menu.close()
		end)
	end, 'item')
end

AddEventHandler('master_mechanicjob:hasEnteredMarker', function(part)

	if part == 'Cloakroom' then
		CurrentAction     = 'menu_cloakroom'
		CurrentActionMsg  = _U('open_cloackroom')
		CurrentActionData = {}
	elseif part == 'ItemInventory' then
		CurrentAction     = 'menu_items'
		CurrentActionMsg  = 'جهت دسترسی به لوازم E بزنید.'
		CurrentActionData = {}
	elseif part == 'CarSpawn' then
		CurrentAction     = 'menu_cars'
		CurrentActionMsg  = 'جهت دسترسی به منوی ماشینها لطفا E بزنید.'
		CurrentActionData = {}
	end
	
	if CurrentActionMsg ~= nil then
		exports.pNotify:SendNotification({text = CurrentActionMsg, type = "info", timeout = 4000})
	end
end)

AddEventHandler('master_mechanicjob:hasExitedMarker', function(part)
	if not isInShopMenu then
		ESX.UI.Menu.CloseAll()
	end
	
	CurrentAction = nil
end)


RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
end)

AddEventHandler('esx:onPlayerDeath', function(data) isDead = true end)
AddEventHandler('esx:onPlayerSpawn', function(spawn) isDead = false end)
AddEventHandler('playerSpawned', function() isDead = false end)

function OpenVehicleSpawnerMenu()
	local playerCoords = GetEntityCoords(PlayerPedId())
	PlayerData = ESX.GetPlayerData()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle', {
		title    = 'گاراژ',
		align    = 'right',
		elements = {
			{label = 'خودرو ها', action = 'garage'},
			{label = 'انتقال ماشین به گاراژ', action = 'store_garage'}
	}}, function(data, menu)
		if data.current.action == 'garage' then
			local garage = {}

			ESX.TriggerServerCallback('esx_vehicleshop:retrieveJobGradeVehicles', function(jobVehicles)
				if #jobVehicles > 0 then
					local allVehicleProps = {}

					for k,v in ipairs(jobVehicles) do
						if IsModelInCdimage(v.name) then
							local label = v.label
							local car_plate = 'MC ' .. v.id
							car_data = {}
							if v.model_data ~= nil then
								car_data = json.decode(v.model_data)
							end
							
							car_data.plate = car_plate
							
							table.insert(garage, {
								label = label,
								model = v.name,
								plate = car_plate,
								stored = true
							})

							allVehicleProps[car_plate] = car_data
						end
					end

					if #garage > 0 then
						ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_garage', {
							title    = _U('garage_title'),
							align    = 'right',
							elements = garage
						}, function(data2, menu2)
							if data2.current.stored then
								local foundSpawn, spawnPoint = GetAvailableVehicleSpawnPoint()

								if foundSpawn then
									menu2.close()

									ESX.Game.SpawnVehicle(data2.current.model, spawnPoint.coords, spawnPoint.heading, function(vehicle)
										local vehicleProps = allVehicleProps[data2.current.plate]
										
										ESX.Game.SetVehicleProperties(vehicle, vehicleProps)
										--local debugp = ESX.Game.GetVehicleProperties(vehicle)
										--print_r(debugp)
										TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
										--TriggerServerEvent('esx_vehicleshop:setJobVehicleState', data2.current.plate, false)

										local vehNet = NetworkGetNetworkIdFromEntity(vehicle)
										local plate = GetVehicleNumberPlateText(vehicle)
										TriggerServerEvent("car_lock:GiveKeys", vehNet, plate)
										exports.pNotify:SendNotification({text = _U('garage_released'), type = "success", timeout = 5000})
									end)
								else
									exports.pNotify:SendNotification({text = "فضای خالی برای خارج کردن خودرو وجود ندارد.", type = "error", timeout = 5000})
								end
							else
								exports.pNotify:SendNotification({text = _U('garage_notavailable'), type = "error", timeout = 4000})
							end
						end, function(data2, menu2)
							menu2.close()
						end)
					else
						exports.pNotify:SendNotification({text = _U('garage_empty'), type = "error", timeout = 4000})
					end
				else
					exports.pNotify:SendNotification({text = _U('garage_empty'), type = "error", timeout = 4000})
				end
			end, 'car')
		elseif data.current.action == 'store_garage' then
			StoreVehicle()
		end
	end, function(data, menu)
		menu.close()
	end)
end

function GetAvailableVehicleSpawnPoint()
	local spawnPoints = Config.Zones.CarSpawnLocation
	local found, foundSpawnPoint = false, nil

	for i=1, #spawnPoints, 1 do
		if ESX.Game.IsSpawnPointClear(spawnPoints[i].coords, spawnPoints[i].radius) then
			found, foundSpawnPoint = true, spawnPoints[i]
			break
		end
	end

	if found then
		return true, foundSpawnPoint
	else
		exports.pNotify:SendNotification({text = _U('vehicle_blocked'), type = "error", timeout = 6000})	
		return false
	end
end

function StoreVehicle()
	local ped = GetPlayerPed(-1)
	local playerCoords = GetEntityCoords(PlayerPedId())
    if (DoesEntityExist(ped) and not IsEntityDead(ped)) then 
        local pos = GetEntityCoords(ped)

        if (IsPedSittingInAnyVehicle(ped)) then 
            local vehicle = GetVehiclePedIsIn(ped, false)
			if (GetPedInVehicleSeat( vehicle, -1 ) == ped) then
				local entity = vehicle
				local attempt = 0

				exports.pNotify:SendNotification({text = "خودرو شما به گاراژ منتقل شد.", type = "success", timeout = 4000})
				while not NetworkHasControlOfEntity(entity) and attempt < 30.0 and DoesEntityExist(entity) do
					Wait(100)
					NetworkRequestControlOfEntity(entity)
					attempt = attempt + 1
				end

				if DoesEntityExist(entity) and NetworkHasControlOfEntity(entity) then
					ESX.Game.DeleteVehicle(entity)
					return
				end
			else 
				exports.pNotify:SendNotification({text = "شما باید پشت فرمان باشید.", type = "error", timeout = 4000})
			end
        else
            exports.pNotify:SendNotification({text = "شما باید در خودرو باشید.", type = "error", timeout = 4000})
        end 
    end
end

function CustomizeCar()
	local playerPed = PlayerPedId()
	if not IsPedSittingInAnyVehicle(playerPed) then
		exports.pNotify:SendNotification({text = 'شما باید درون خودرو باشید.', type = "error", timeout = 3000})
		return
	end
	local vehicle = GetVehiclePedIsIn(playerPed, false)
	if vehicle then
		local tmp_myCar = ESX.Game.GetVehicleProperties(vehicle)
		ESX.TriggerServerCallback('master_mechanicjob:check_car', function(status)
			if status == true then
				lsMenuIsShowed = true

				Citizen.CreateThread(function()
					while lsMenuIsShowed do
						Citizen.Wait(0)
						DisableControlAction(2, 288, true)
						DisableControlAction(2, 289, true)
						DisableControlAction(2, 170, true)
						DisableControlAction(2, 167, true)
						DisableControlAction(2, 168, true)
						DisableControlAction(2, 23, true)
						DisableControlAction(0, 75, true)  -- Disable exit vehicle
						DisableControlAction(27, 75, true) -- Disable exit vehicle
					end
				end)
				
				
				FreezeEntityPosition(vehicle, true)

				myCar = tmp_myCar
				CarBeforeChanges = myCar
				totalPrice = 0
				ESX.UI.Menu.CloseAll()
				GetAction({value = 'main'})
			else
				isBusy = false
				exports.pNotify:SendNotification({text = 'مالک این خودرو مشخص نیست، امکان شخصی سازی وجود ندارد.', type = "error", timeout = 3000})
			end
		end, tmp_myCar)
	else
		exports.pNotify:SendNotification({text = 'شما باید درون خودرو باشید.', type = "error", timeout = 3000})
	end
end

function GetAction(data)
	local elements  = {}
	local menuName  = ''
	local menuTitle = ''
	local parent    = nil

	local playerPed = PlayerPedId()
	local vehicle = GetVehiclePedIsIn(playerPed, false)
	local currentMods = ESX.Game.GetVehicleProperties(vehicle)

	if data.value == 'modSpeakers' or
		data.value == 'modTrunk' or
		data.value == 'modHydrolic' or
		data.value == 'modEngineBlock' or
		data.value == 'modAirFilter' or
		data.value == 'modStruts' or
		data.value == 'modTank' then
		SetVehicleDoorOpen(vehicle, 4, false)
		SetVehicleDoorOpen(vehicle, 5, false)
	elseif data.value == 'modDoorSpeaker' then
		SetVehicleDoorOpen(vehicle, 0, false)
		SetVehicleDoorOpen(vehicle, 1, false)
		SetVehicleDoorOpen(vehicle, 2, false)
		SetVehicleDoorOpen(vehicle, 3, false)
	else
		SetVehicleDoorsShut(vehicle, false)
	end

	local vehiclePrice = 50000

	for i=1, #Vehicles, 1 do
		if GetEntityModel(vehicle) == GetHashKey(Vehicles[i].model) then
			vehiclePrice = Vehicles[i].price
			break
		end
	end

	for k,v in pairs(Config.Menus) do

		if data.value == k then

			menuName  = k
			menuTitle = v.label
			parent    = v.parent

			if v.modType then
				
				if v.modType == 22 then
					table.insert(elements, {label = " " .. _U('by_default'), modType = k, modNum = false})
				elseif v.modType == 'neonColor' or v.modType == 'tyreSmokeColor' then -- disable neon
					table.insert(elements, {label = " " ..  _U('by_default'), modType = k, modNum = {0, 0, 0}})
				elseif v.modType == 'color1' or v.modType == 'color2' or v.modType == 'pearlescentColor' or v.modType == 'wheelColor' then
					local num = myCar[v.modType]
					table.insert(elements, {label = " " .. _U('by_default'), modType = k, modNum = num})
				elseif v.modType == 17 then
					table.insert(elements, {label = " " .. _U('no_turbo'), modType = k, modNum = false})
 				else
					table.insert(elements, {label = " " .. _U('by_default'), modType = k, modNum = -1})
				end

				if v.modType == 14 then -- HORNS
					for j = 0, 51, 1 do
						local _label = ''
						if j == currentMods.modHorns then
							_label = GetHornName(j) .. ' - <span style="color:cornflowerblue;">'.. _U('installed') ..'</span>'
						else
							price = math.floor(vehiclePrice * v.price / 100)
							_label = GetHornName(j) .. ' - <span style="color:green;">$' .. price .. ' </span>'
						end
						table.insert(elements, {label = _label, modType = k, modNum = j})
					end
				elseif v.modType == 'plateIndex' then -- PLATES
					for j = 0, 4, 1 do
						local _label = ''
						if j == currentMods.plateIndex then
							_label = GetPlatesName(j) .. ' - <span style="color:cornflowerblue;">'.. _U('installed') ..'</span>'
						else
							price = math.floor(vehiclePrice * v.price / 100)
							_label = GetPlatesName(j) .. ' - <span style="color:green;">$' .. price .. ' </span>'
						end
						table.insert(elements, {label = _label, modType = k, modNum = j})
					end
				elseif v.modType == 22 then -- NEON
					local _label = ''
					if currentMods.modXenon then
						_label = _U('neon') .. ' - <span style="color:cornflowerblue;">'.. _U('installed') ..'</span>'
					else
						price = math.floor(vehiclePrice * v.price / 100)
						_label = _U('neon') .. ' - <span style="color:green;">$' .. price .. ' </span>'
					end
					table.insert(elements, {label = _label, modType = k, modNum = true})
				elseif v.modType == 'neonColor' or v.modType == 'tyreSmokeColor' then -- NEON & SMOKE COLOR
					local neons = GetNeons()
					price = math.floor(vehiclePrice * v.price / 100)
					for i=1, #neons, 1 do
						table.insert(elements, {
							label = '<span style="color:rgb(' .. neons[i].r .. ',' .. neons[i].g .. ',' .. neons[i].b .. ');">' .. neons[i].label .. ' - <span style="color:green;">$' .. price .. '</span>',
							modType = k,
							modNum = { neons[i].r, neons[i].g, neons[i].b }
						})
					end
				elseif v.modType == 'color1' or v.modType == 'color2' or v.modType == 'pearlescentColor' or v.modType == 'wheelColor' then -- RESPRAYS
					local colors = GetColors(data.color)
					for j = 1, #colors, 1 do
						local _label = ''
						price = math.floor(vehiclePrice * v.price / 100)
						_label = colors[j].label .. ' - <span style="color:green;">$' .. price .. ' </span>'
						table.insert(elements, {label = _label, modType = k, modNum = colors[j].index})
					end
				elseif v.modType == 'windowTint' then -- WINDOWS TINT
					for j = 1, 5, 1 do
						local _label = ''
						if j == currentMods.modHorns then
							_label = GetWindowName(j) .. ' - <span style="color:cornflowerblue;">'.. _U('installed') ..'</span>'
						else
							price = math.floor(vehiclePrice * v.price / 100)
							_label = GetWindowName(j) .. ' - <span style="color:green;">$' .. price .. ' </span>'
						end
						table.insert(elements, {label = _label, modType = k, modNum = j})
					end
				elseif v.modType == 23 then -- WHEELS RIM & TYPE
					local props = {}

					props['wheels'] = v.wheelType
					ESX.Game.SetVehicleProperties(vehicle, props)

					local modCount = GetNumVehicleMods(vehicle, v.modType)
					for j = 0, modCount, 1 do
						local modName = GetModTextLabel(vehicle, v.modType, j)
						if modName then
							local _label = ''
							if j == currentMods.modFrontWheels then
								_label = GetLabelText(modName) .. ' - <span style="color:cornflowerblue;">'.. _U('installed') ..'</span>'
							else
								price = math.floor(vehiclePrice * v.price / 100)
								_label = GetLabelText(modName) .. ' - <span style="color:green;">$' .. price .. ' </span>'
							end
							table.insert(elements, {label = _label, modType = 'modFrontWheels', modNum = j, wheelType = v.wheelType, price = v.price})
						end
					end
				elseif v.modType == 11 or v.modType == 12 or v.modType == 13 or v.modType == 15 or v.modType == 16 then
					SetVehicleModKit(vehicle, 0)
					local modCount = GetNumVehicleMods(vehicle, v.modType) -- UPGRADES
					for j = 0, modCount, 1 do
						local _label = ''
						if j == currentMods[k] then
							_label = _U('level', j+1) .. ' - <span style="color:cornflowerblue;">'.. _U('installed') ..'</span>'
						else
							price = math.floor(vehiclePrice * v.price[j+1] / 100)
							_label = _U('level', j+1) .. ' - <span style="color:green;">$' .. price .. ' </span>'
						end
						table.insert(elements, {label = _label, modType = k, modNum = j})
						if j == modCount-1 then
							break
						end
					end
				elseif v.modType == 17 then -- TURBO
					local _label = ''
					if currentMods[k] then
						_label = 'Turbo - <span style="color:cornflowerblue;">'.. _U('installed') ..'</span>'
					else
						_label = 'Turbo - <span style="color:green;">$' .. math.floor(vehiclePrice * v.price[1] / 100) .. ' </span>'
					end
					table.insert(elements, {label = _label, modType = k, modNum = true})
				else
					local modCount = GetNumVehicleMods(vehicle, v.modType) -- BODYPARTS
					for j = 0, modCount, 1 do
						local modName = GetModTextLabel(vehicle, v.modType, j)
						if modName then
							local _label = ''
							if j == currentMods[k] then
								_label = GetLabelText(modName) .. ' - <span style="color:cornflowerblue;">'.. _U('installed') ..'</span>'
							else
								price = math.floor(vehiclePrice * v.price / 100)
								_label = GetLabelText(modName) .. ' - <span style="color:green;">$' .. price .. ' </span>'
							end
							table.insert(elements, {label = _label, modType = k, modNum = j})
						end
					end
				end
			else
				if data.value == 'primaryRespray' or data.value == 'secondaryRespray' or data.value == 'pearlescentRespray' or data.value == 'modFrontWheelsColor' then
					for i=1, #Config.Colors, 1 do
						if data.value == 'primaryRespray' then
							table.insert(elements, {label = Config.Colors[i].label, value = 'color1', color = Config.Colors[i].value})
						elseif data.value == 'secondaryRespray' then
							table.insert(elements, {label = Config.Colors[i].label, value = 'color2', color = Config.Colors[i].value})
						elseif data.value == 'pearlescentRespray' then
							table.insert(elements, {label = Config.Colors[i].label, value = 'pearlescentColor', color = Config.Colors[i].value})
						elseif data.value == 'modFrontWheelsColor' then
							table.insert(elements, {label = Config.Colors[i].label, value = 'wheelColor', color = Config.Colors[i].value})
						end
					end
				else
					for l,w in pairs(v) do
						if l ~= 'label' and l ~= 'parent' then
							table.insert(elements, {label = w, value = l})
						end
					end
				end
			end
			break
		end
	end

	if data.value == 'main' then
		table.insert(elements, {label = "مبلغ کل فاکتور", modType = "mk_options", factors = true})		
		table.insert(elements, {label = "بازگرداندن تغییرات", modType = "mk_options", returncar = true})		
	end
	
	table.sort(elements, function(a, b)
		return a.label < b.label
	end)

	OpenLSMenu(elements, menuName, menuTitle, parent)
end


function OpenLSMenu(elems, menuName, menuTitle, parent)
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), menuName,
	{
		title    = menuTitle,
		align    = 'top-right',
		elements = elems
	}, function(data, menu)
		local isRimMod, found, otherOptions = false, false, false
		local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

		if data.current.modType == "modFrontWheels" then
			isRimMod = true
		elseif data.current.modType == "mk_options" then
			otherOptions = true
		end
		
		for k,v in pairs(Config.Menus) do

			if k == data.current.modType or isRimMod or otherOptions then

				if data.current.label == _U('by_default') or string.match(data.current.label, _U('installed')) then
					exports.pNotify:SendNotification({text = _U('already_own', data.current.label), type = "error", timeout = 3000})
					TriggerEvent('master_mechanicjob:installMod', 0)
				else
					local vehiclePrice = 50000

					for i=1, #Vehicles, 1 do
						if GetEntityModel(vehicle) == GetHashKey(Vehicles[i].model) then
							vehiclePrice = Vehicles[i].price
							break
						end
					end
					
					if data.current.factors then
						exports.pNotify:SendNotification({text = 'شما برای این خودرو مبلغ ' .. totalPrice .. '$ خرج کردید.', type = "info", timeout = 3000})
						return
					elseif data.current.returncar then
						ESX.Game.SetVehicleProperties(vehicle, CarBeforeChanges)
						lsMenuIsShowed = false
						FreezeEntityPosition(vehicle, false)
						TriggerServerEvent('master_mechanicjob:refreshOwnedVehicle', CarBeforeChanges, totalPrice)
						totalPrice = 0
						exports.pNotify:SendNotification({text = 'خودرو به حالت اولیه بازگشت.', type = "info", timeout = 3000})
					elseif isRimMod then
						price = math.floor(vehiclePrice * data.current.price / 100)
						TriggerServerEvent('master_mechanicjob:buyMod', price)
					elseif v.modType == 11 or v.modType == 12 or v.modType == 13 or v.modType == 15 or v.modType == 16 then
						price = math.floor(vehiclePrice * v.price[data.current.modNum + 1] / 100)
						TriggerServerEvent('master_mechanicjob:buyMod', price)
					elseif v.modType == 17 then
						price = math.floor(vehiclePrice * v.price[1] / 100)
						TriggerServerEvent('master_mechanicjob:buyMod', price)
					else
						price = math.floor(vehiclePrice * v.price / 100)
						TriggerServerEvent('master_mechanicjob:buyMod', price)
					end
				end

				menu.close()
				found = true
				break
			end

		end

		if not found then
			GetAction(data.current)
		end
	end, function(data, menu) -- on cancel
		menu.close()
		TriggerEvent('master_mechanicjob:cancelInstallMod')

		local playerPed = PlayerPedId()
		local vehicle = GetVehiclePedIsIn(playerPed, false)
		SetVehicleDoorsShut(vehicle, false)

		if parent == nil then
			lsMenuIsShowed = false
			local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
			FreezeEntityPosition(vehicle, false)
			myCar = {}
		end
	end, function(data, menu) -- on change
		UpdateMods(data.current)
	end)
end

function UpdateMods(data)
	local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

	if data.modType then
		local props = {}
		
		if data.wheelType then
			props['wheels'] = data.wheelType
			ESX.Game.SetVehicleProperties(vehicle, props)
			props = {}
		elseif data.modType == 'neonColor' then
			if data.modNum[1] == 0 and data.modNum[2] == 0 and data.modNum[3] == 0 then
				props['neonEnabled'] = { false, false, false, false }
			else
				props['neonEnabled'] = { true, true, true, true }
			end
			ESX.Game.SetVehicleProperties(vehicle, props)
			props = {}
		elseif data.modType == 'tyreSmokeColor' then
			props['modSmokeEnabled'] = true
			ESX.Game.SetVehicleProperties(vehicle, props)
			props = {}
		end

		props[data.modType] = data.modNum
		ESX.Game.SetVehicleProperties(vehicle, props)
	end
end

RegisterNetEvent('master_mechanicjob:installMod')
AddEventHandler('master_mechanicjob:installMod', function(price)
	local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
	totalPrice = totalPrice + price
	myCar = ESX.Game.GetVehicleProperties(vehicle)
	TriggerServerEvent('master_mechanicjob:refreshOwnedVehicle', myCar, 0)
end)

RegisterNetEvent('master_mechanicjob:cancelInstallMod')
AddEventHandler('master_mechanicjob:cancelInstallMod', function()
	local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
	if (GetPedInVehicleSeat(vehicle, -1) ~= PlayerPedId()) then
		 vehicle = GetPlayersLastVehicle(PlayerPedId())
	end
		ESX.Game.SetVehicleProperties(vehicle, myCar)
	if not (myCar.modTurbo) then
		ToggleVehicleMod(vehicle,  18, false)
	end
	if not (myCar.modXenon) then
		ToggleVehicleMod(vehicle,  22, false)
	end
	if not (myCar.windowTint) then
		SetVehicleWindowTint(vehicle, 0)
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(60000)
		TriggerEvent('master_mechanicjob:updateBlip')
	end
end)

RegisterNetEvent('master_mechanicjob:updateBlip')
AddEventHandler('master_mechanicjob:updateBlip', function()

	-- Refresh all blips
	for k, existingBlip in pairs(blipInServices) do
		RemoveBlip(existingBlip)
	end

	-- Clean the blip table
	blipInServices = {}

	if not playerInService then
		return
	end
	
	while ESX == nil do
		Citizen.Wait(0)
	end
	
	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(6000)
	end

	ESX.PlayerData = ESX.GetPlayerData()

	if ESX.PlayerData.job and (ESX.PlayerData.job.name == 'mechanic') then
		ESX.TriggerServerCallback('esx_service:getInServOnlinePlayers', function(players)
			for i=1, #players, 1 do
				if players[i].job.name == ESX.PlayerData.job.name then
					local id = GetPlayerFromServerId(players[i].source)
					if NetworkIsPlayerActive(id) and GetPlayerPed(id) ~= PlayerPedId() then
						createBlip(id)
					end
				end
			end
		end, ESX.PlayerData.job.name)
	end
end)

function createBlip(id)
	local ped = GetPlayerPed(id)
	local blip = GetBlipFromEntity(ped)

	if not DoesBlipExist(blip) then -- Add blip and create head display on player
		blip = AddBlipForEntity(ped)
		SetBlipSprite(blip, 1)
		ShowHeadingIndicatorOnBlip(blip, true) -- Player Blip indicator
		SetBlipRotation(blip, math.ceil(GetEntityHeading(ped))) -- update rotation
		SetBlipNameToPlayerName(blip, id) -- update blip name
		SetBlipScale(blip, 0.7) -- set scale
		SetBlipAsShortRange(blip, true)

		table.insert(blipInServices, blip) -- add blip to array so we can remove it later
	end
end
