ESX                = nil
PlayersHarvesting  = {}
PlayersHarvesting2 = {}
PlayersHarvesting3 = {}
PlayersCrafting    = {}
PlayersCrafting2   = {}
PlayersCrafting3   = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

if Config.MaxInService ~= -1 then
	TriggerEvent('esx_service:activateService', 'mechanic', Config.MaxInService)
end

TriggerEvent('esx_phone:registerNumber', 'mechanic', _U('mechanic_customer'), true, true)
TriggerEvent('esx_society:registerSociety', 'mechanic', 'mechanic', 'society_mechanic', 'society_mechanic', 'society_mechanic', {type = 'private'})

RegisterServerEvent('master_mechanicjob:impound_carstart')
AddEventHandler('master_mechanicjob:impound_carstart', function(veh)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	if xPlayer == nil or xPlayer.job == nil or xPlayer.job.name == nil then
		return
	end
	
	if xPlayer.job.name ~= 'mechanic' then
		return
	end
		
	Citizen.CreateThread(function()
		TriggerClientEvent('master_mechanicjob:impound_carstart', _source, veh)
		Citizen.Wait(5000)
		xPlayer.addMoney(Config.ImpundPrice)
	end)
end)

RegisterServerEvent('master_mechanicjob:repair_car')
AddEventHandler('master_mechanicjob:repair_car', function(vb)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	if xPlayer == nil or xPlayer.job == nil or xPlayer.job.name == nil then
		cb(false)
		return
	end
	
	if xPlayer.job.name ~= 'mechanic' then
		cb(false)
		return
	end
	
	RepairKitCount = xPlayer.getInventoryItem('repairkit').count
	
	if RepairKitCount >= 1 then
		xPlayer.removeInventoryItem('repairkit', 1)
		cb(true)
	end
	
	TriggerClientEvent("pNotify:SendNotification", _source, { text = "شما جعبه ابزار ندارید.", type = "error", timeout = 3000, layout = "bottomCenter"})
	cb(false)
end)

