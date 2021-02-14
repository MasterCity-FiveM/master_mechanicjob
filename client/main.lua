local HasAlreadyEnteredMarker = false
local CurrentAction, CurrentActionMsg, CurrentActionData = nil, '', {}
local isDead, isBusy = false, false
ESX = nil
isInShopMenu = false
local isInMarker, hasExited, letSleep = false, false, true
local currentStation, currentPart, currentPartNum

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	ESX.PlayerData = ESX.GetPlayerData()
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
			OpenGetStocksMenu()
		elseif CurrentAction == 'menu_cars' then
			OpenVehicleSpawnerMenu()
		end

		CurrentAction = nil
	end
end)

RegisterNetEvent('master_keymap:f6')
AddEventHandler('master_keymap:f6', function() 
	if not isDead and ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic' then
		OpenMobileMechanicActionsMenu()
	end
end)

function OpenMobileMechanicActionsMenu()
	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'mobile_mechanic_actions', {
		title    = _U('mechanic'),
		align    = 'top-right',
		elements = {
			{label = _U('billing'),       value = 'billing'},
			{label = _U('repair'),        value = 'fix_vehicle'},
			{label = _U('clean'),         value = 'clean_vehicle'},
			{label = _U('imp_veh'),       value = 'del_vehicle'},
			{label = 'شخصی سازی خودرو',       value = 'custom_vehicle'},
			--{label = _U('place_objects'), value = 'object_spawner'}
	}}, function(data, menu)
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
		
			if Config.EnableESXService then
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
		end

		if Config.EnableESXService and data.current.value ~= 'citizen_wear' then
			local awaitService

			ESX.TriggerServerCallback('esx_service:isInService', function(isInService)
				if not isInService then

					ESX.TriggerServerCallback('esx_service:enableService', function(canTakeService, maxInService, inServiceCount)
						if not canTakeService then
							ESX.ShowNotification(_U('service_max', inServiceCount, maxInService))
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
										TriggerServerEvent("SOSAY_Locking:GiveKeys", vehNet, plate)
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

