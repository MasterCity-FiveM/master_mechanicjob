local HasAlreadyEnteredMarker, LastZone = false, nil
local CurrentAction, CurrentActionMsg, CurrentActionData = nil, '', {}
local CurrentlyTowedVehicle, Blips, NPCOnJob, NPCTargetTowable, NPCTargetTowableZone = nil, {}, false, nil, nil
local NPCHasSpawnedTowable, NPCLastCancel, NPCHasBeenNextToTowable, NPCTargetDeleterZone = false, GetGameTimer() - 5 * 60000, false, false
local isDead, isBusy = false, false
ESX = nil

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

RegisterNetEvent('master_keymap:e')
AddEventHandler('master_keymap:e', function() 
	if CurrentAction then
		if IsControlJustReleased(0, 38) and ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic' then

			if CurrentAction == 'mechanic_actions_menu' then
				OpenMechanicActionsMenu()
			elseif CurrentAction == 'mechanic_harvest_menu' then
				OpenMechanicHarvestMenu()
			elseif CurrentAction == 'mechanic_craft_menu' then
				OpenMechanicCraftMenu()
			elseif CurrentAction == 'delete_vehicle' then

				if Config.EnableSocietyOwnedVehicles then
					local vehicleProps = ESX.Game.GetVehicleProperties(CurrentActionData.vehicle)
					TriggerServerEvent('esx_society:putVehicleInGarage', 'mechanic', vehicleProps)
				else
					if
						GetEntityModel(vehicle) == GetHashKey('flatbed')   or
						GetEntityModel(vehicle) == GetHashKey('towtruck2') or
						GetEntityModel(vehicle) == GetHashKey('slamvan3')
					then
						TriggerServerEvent('esx_service:disableService', 'mechanic')
					end
				end

				ESX.Game.DeleteVehicle(CurrentActionData.vehicle)

			elseif CurrentAction == 'remove_entity' then
				DeleteEntity(CurrentActionData.entity)
			end

			CurrentAction = nil
		end
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
			{label = _U('place_objects'), value = 'object_spawner'}
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
				exports.pNotify:SendNotification({text = _U('inside_vehicle'), type = "success", timeout = 3000})
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
				local vehicle = GetVehiclePedIsIn(playerPed, false)

				if GetPedInVehicleSeat(vehicle, -1) == playerPed then
					TriggerServerEvent('master_mechanicjob:impound_carstart', vehicle)
				else
					exports.pNotify:SendNotification({text = _U('must_seat_driver'), type = "error", timeout = 3000})
				end
			else
				local vehicle = ESX.Game.GetVehicleInDirection()

				if DoesEntityExist(vehicle) then
					TriggerServerEvent('master_mechanicjob:impound_carstart', vehicle)
				else
					exports.pNotify:SendNotification({text = _U('must_near'), type = "error", timeout = 3000})
				end
			end
		elseif data.current.value == 'object_spawner' then
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
			end)
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
