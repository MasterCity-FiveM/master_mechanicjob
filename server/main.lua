ESX                = nil
jobItems  = {}
local Vehicles

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

TriggerEvent('esx_service:activateService', 'mechanic', Config.MaxInService)


TriggerEvent('esx_phone:registerNumber', 'mechanic', _U('mechanic_customer'), true, true)
TriggerEvent('master_society:registerSociety', 'mechanic', 'mechanic', 'society_mechanic', 'society_mechanic', 'society_mechanic', {type = 'private'})

RegisterServerEvent('master_mechanicjob:impound_carstart')
AddEventHandler('master_mechanicjob:impound_carstart', function(veh)
	ESX.RunCustomFunction("anti_ddos", source, 'master_mechanicjob:impound_carstart', {veh = veh})
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

ESX.RegisterServerCallback('master_mechanicjob:repair_car', function(source, cb)
	ESX.RunCustomFunction("anti_ddos", source, 'master_mechanicjob:repair_car', {})
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
		return
	end
	
	TriggerClientEvent("pNotify:SendNotification", _source, { text = "شما جعبه ابزار ندارید.", type = "error", timeout = 3000, layout = "bottomCenter"})
	cb(false)
end)

ESX.RegisterServerCallback('master_mechanicjob:getItems', function(source, cb, item_type)
	ESX.RunCustomFunction("anti_ddos", source, 'master_mechanicjob:getItems', {item_type = item_type})
	local xPlayer = ESX.GetPlayerFromId(source)
	items = {}
	if xPlayer == nil or xPlayer.job == nil or xPlayer.job.name == nil then
		cb(items)
		return
	end	
	
	if xPlayer.job.name ~= 'mechanic' then
		cb(items)
		return
	end
	
	if jobItems[xPlayer.job.name] == nil then
		jobItems[xPlayer.job.name] = {}
	end
	
	if jobItems[xPlayer.job.name][xPlayer.job.grade_name] == nil  then
		jobItems[xPlayer.job.name][xPlayer.job.grade_name] = {}
	end
	
	if jobItems[xPlayer.job.name][xPlayer.job.grade_name][item_type] == nil  then
		jobItems[xPlayer.job.name][xPlayer.job.grade_name][item_type] = {}
	else
		cb(jobItems[xPlayer.job.name][xPlayer.job.grade_name][item_type])
		return
	end
	
	if xPlayer.job_sub ~= nil then
		MySQL.Async.fetchAll('SELECT * FROM job_items WHERE job = @job AND (grade = @grade or grade = @subjob) AND item_type = @item_type', {
			['@job'] = xPlayer.job.name,
			['@grade'] = xPlayer.job.grade_name,
			['@item_type'] = item_type,
			['@subjob'] = xPlayer.job_sub
		}, function(result)
			jobItems[xPlayer.job.name][xPlayer.job.grade_name .. '_' .. xPlayer.job_sub][item_type] = result
			cb(result)
		end)
	else
		MySQL.Async.fetchAll('SELECT * FROM job_items WHERE job = @job AND grade = @grade AND item_type = @item_type', {
			['@job'] = xPlayer.job.name,
			['@grade'] = xPlayer.job.grade_name,
			['@item_type'] = item_type
		}, function(result)
			jobItems[xPlayer.job.name][xPlayer.job.grade_name][item_type] = result
			cb(result)
		end)
	end
end)

function GetItemCount(source, item)
    local xPlayer = ESX.GetPlayerFromId(source)
    local items = xPlayer.getInventoryItem(item)

    if items == nil then
        return 0
    else
        return items.count
    end
end

ESX.RegisterServerCallback('master_mechanicjob:GetItem', function(source, cb, itemName, amount)
	ESX.RunCustomFunction("anti_ddos", source, 'master_mechanicjob:GetItem', {itemName = itemName, amount = amount})
	local source = source
	local xPlayer = ESX.GetPlayerFromId(source)
	
	local item = itemName
	local ItemFound = false
	local item_amount = tonumber(amount)
	
	if xPlayer == nil or xPlayer.job == nil or xPlayer.job.name == nil then
		cb()
		return
	end
	
	if jobItems[xPlayer.job.name] == nil or jobItems[xPlayer.job.name][xPlayer.job.grade_name] == nil or jobItems[xPlayer.job.name][xPlayer.job.grade_name]['item'] == nil then
		GetJobItems(xPlayer.job.name, xPlayer.job.grade_name, 'item')
		cb()
		return
	end
	
	if item_amount < 1 and item_amount > 500 then
		cb()
		return
	end
	
	local items = jobItems[xPlayer.job.name][xPlayer.job.grade_name]['item']
	
	for i=1, #items, 1 do
		if items[i].name == item then
			ItemFound = true
			break
		end
	end
	
	if not ItemFound then
		TriggerClientEvent("pNotify:SendNotification", source, { text = "شما مجوز دریافت این وسیله را ندارید.", type = "error", timeout = 5000, layout = "bottomCenter"})
		cb()
		return
	end
	
	if GetItemCount(source, item) > 0 then
		TriggerClientEvent("pNotify:SendNotification", source, { text = "شما قبلا این وسیله را تحویل گرفتید.", type = "error", timeout = 5000, layout = "bottomCenter"})
	else
		xPlayer.addInventoryItem(item, item_amount)
		TriggerClientEvent("pNotify:SendNotification", source, { text = "وسیله مورد نظر تحویل شما داده شد.", type = "success", timeout = 5000, layout = "bottomCenter"})
	end
	cb()
end)

ESX.RegisterServerCallback('master_mechanicjob:getVehiclesPrices', function(source, cb)
	ESX.RunCustomFunction("anti_ddos", source, 'master_mechanicjob:getVehiclesPrices', {})
	if not Vehicles then
		MySQL.Async.fetchAll('SELECT * FROM vehicles', {}, function(result)
			local vehicles = {}

			for i=1, #result, 1 do
				table.insert(vehicles, {
					model = result[i].model,
					price = result[i].price
				})
			end

			Vehicles = vehicles
			cb(Vehicles)
		end)
	else
		cb(Vehicles)
	end
end)

RegisterServerEvent('master_mechanicjob:buyMod')
AddEventHandler('master_mechanicjob:buyMod', function(price)
	ESX.RunCustomFunction("anti_ddos", source, 'master_mechanicjob:buyMod', {price = price})
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	price = tonumber(price)

	if Config.IsMechanicJobOnly then
		local societyAccount

		TriggerEvent('esx_addonaccount:getSharedAccount', 'society_mechanic', function(account)
			societyAccount = account
		end)

		if price < societyAccount.money then
			TriggerClientEvent('master_mechanicjob:installMod', _source, price)
			TriggerClientEvent("pNotify:SendNotification", _source, { text = _U('purchased'), type = "success", timeout = 3000, layout = "bottomCenter"})
			societyAccount.removeMoney(price)
		else
			TriggerClientEvent('master_mechanicjob:cancelInstallMod', _source)
			TriggerClientEvent("pNotify:SendNotification", _source, { text = _U('not_enough_money'), type = "error", timeout = 3000, layout = "bottomCenter"})
		end
	else
		if price < xPlayer.getMoney() then
			TriggerClientEvent('master_mechanicjob:installMod', _source, price)
			TriggerClientEvent("pNotify:SendNotification", _source, { text = _U('purchased'), type = "success", timeout = 3000, layout = "bottomCenter"})
			xPlayer.removeMoney(price)
		else
			TriggerClientEvent('master_mechanicjob:cancelInstallMod', _source)
			TriggerClientEvent("pNotify:SendNotification", _source, { text = _U('not_enough_money'), type = "error", timeout = 3000, layout = "bottomCenter"})
		end
	end
end)

ESX.RegisterServerCallback('master_mechanicjob:check_car', function(source, cb, vehicleProps)
	ESX.RunCustomFunction("anti_ddos", source, 'master_mechanicjob:check_car', {vehicleProps = vehicleProps})
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT vehicle FROM owned_vehicles WHERE plate = @plate', {
		['@plate'] = vehicleProps.plate
	}, function(result)
		if result[1] then
			cb(true)
		else
			cb(false)
		end
	end)
end)

RegisterServerEvent('master_mechanicjob:refreshOwnedVehicle')
AddEventHandler('master_mechanicjob:refreshOwnedVehicle', function(vehicleProps, totalPrice)
	ESX.RunCustomFunction("anti_ddos", source, 'master_mechanicjob:refreshOwnedVehicle', {totalPrice = totalPrice})
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT vehicle FROM owned_vehicles WHERE plate = @plate', {
		['@plate'] = vehicleProps.plate
	}, function(result)
		if result[1] then
			local vehicle = json.decode(result[1].vehicle)
			
			if vehicleProps.model == vehicle.model then
				MySQL.Async.execute('UPDATE owned_vehicles SET vehicle = @vehicle WHERE plate = @plate', {
					['@plate'] = vehicleProps.plate,
					['@vehicle'] = json.encode(vehicleProps)
				})
				
				if totalPrice and totalPrice > 0 then
					xPlayer.addMoney(totalPrice)
				end
			else
				print(('master_mechanicjob: %s attempted to upgrade vehicle with mismatching vehicle model!'):format(xPlayer.identifier))
			end
		end
	end)
end)