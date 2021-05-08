ESX                = nil
jobItems  = {}
local Vehicles
local IsPlayerReq = {}
local Mechanics = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

while ESX == nil do
	Citizen.Wait(1)
end

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
		TriggerEvent('master_warden:InvalidRequest', '[Mechanic] Impound car start', xPlayer.source)
		return
	end
		
	Citizen.CreateThread(function()
		TriggerClientEvent('master_mechanicjob:impound_carstart', _source, veh)
		Citizen.Wait(5000)
		xPlayer.addMoney(Config.ImpundPrice)
	end)
end)

ESX.RegisterServerCallback('master_mechanicjob:SpawnGarageCar', function (source, cb, carname)
	-- TODO CHECK CAR ALLOWED
	local _source = source
	ESX.RunCustomFunction("anti_ddos", _source, 'master_vehicles:SpawnGarageCar', {})
	local xPlayer = ESX.GetPlayerFromId(_source)
	if xPlayer.job.name == 'mechanic' then
		TriggerEvent('master_warden:AllowSpawnCar', xPlayer.source)
		cb(true)
	else
		TriggerEvent('master_warden:InvalidRequest', '[Mechanic] Spawn garage car', xPlayer.source)
	end
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
		TriggerEvent('master_warden:InvalidRequest', '[Mechanic] Repair car', xPlayer.source)
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
		cb({})
		return
	end	
	
	if xPlayer.job.name ~= 'mechanic' then
		TriggerEvent('master_warden:InvalidRequest', '[Mechanic] Get items', xPlayer.source)
		cb({})
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
	
	if xPlayer.job.name ~= 'mechanic' then
		TriggerEvent('master_warden:InvalidRequest', '[Mechanic] Get item', xPlayer.source)
		cb({})
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

RegisterServerEvent('master_mechanicjob:FinishCustom')
AddEventHandler('master_mechanicjob:FinishCustom', function()
	local _Source = source
	local xPlayer = ESX.GetPlayerFromId(_Source)
	if not xPlayer.job or xPlayer.job.name ~= 'mechanic' then
		return
	end
	
	if Mechanics[_Source] then
		local ThisCar = Mechanics[_Source]
		IsPlayerReq[ThisCar].customer = _Source
		IsPlayerReq[ThisCar].incustom = false
		TriggerClientEvent('master_mechanicjob:CloseMenus', _Source)
		--TriggerClientEvent('master_mechanicjob:CloseMenus', IsPlayerReq[ThisCar].source)
		TriggerClientEvent('master_mechanicjob:Default', IsPlayerReq[ThisCar].source , IsPlayerReq[ThisCar].props)
		TriggerClientEvent("pNotify:SendNotification", IsPlayerReq[ThisCar].source, { text = 'ارتقا خودرو شما به پایان رسید.', type = "success", timeout = 6000, layout = "bottomCenter"})
		TriggerClientEvent("pNotify:SendNotification", _Source, { text = 'ارتقا خودرو به پایان رسید، کل مبلغ: ' .. IsPlayerReq[ThisCar].price .. '$', type = "success", timeout = 12000, layout = "bottomCenter"})
		Mechanics[_Source] = nil
	else
		TriggerClientEvent("pNotify:SendNotification", _Source, { text = 'شما درخواست ارتقایی نداشتید.', type = "error", timeout = 3000, layout = "bottomCenter"})
	end
end)

ESX.RegisterServerCallback('master_mechanicjob:checkStatus', function(source, cb, vehicle)
	ESX.RunCustomFunction("anti_ddos", source, 'master_mechanicjob:checkStatus', {})
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(source)
	local plate = vehicle.plate
	if not plate then
		return
	end
	
	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE plate = @plate', {["@plate"] = tostring(plate)},
	function(result)
		if result[1] ~= nil then
			if IsPlayerReq[plate] then
				if IsPlayerReq[plate].incustom == true then
					TriggerClientEvent("pNotify:SendNotification", _source, { text = 'خوردو شما در حال ارتقا می باشد.', type = "error", timeout = 3000, layout = "bottomCenter"})
				else
					cb(true)
				end
			else
				cb(false)
				TriggerClientEvent("pNotify:SendNotification", _source, { text = 'درخواست شما ثبت شد.', type = "success", timeout = 6000, layout = "bottomCenter"})
			end
		else
			TriggerClientEvent("pNotify:SendNotification", _source, { text = 'صاحب خودرو مشخص نیست.', type = "error", timeout = 3000, layout = "bottomCenter"})
		end
    end)
end)

ESX.RegisterServerCallback('master_mechanicjob:check_car', function(source, cb, plate)
	ESX.RunCustomFunction("anti_ddos", source, 'master_mechanicjob:check_car', {})
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	if xPlayer.job and xPlayer.job.name ~= 'mechanic' then
		TriggerEvent('master_warden:InvalidRequest', '[Mechanic] check car', xPlayer.source)
		cb(false)
		return
	end
	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE plate = @plate', {
		['@plate'] = plate
	}, function(result)
		if result[1] then
			if IsPlayerReq[plate] then
				if IsPlayerReq[plate].customer == 0 or IsPlayerReq[plate].customer == source then
					if Mechanics[_source] and Mechanics[_source] ~= plate then
						TriggerClientEvent("pNotify:SendNotification", _source, { text = 'شما در حال ارتقا خودرو می باشید.', type = "error", timeout = 3000, layout = "bottomCenter"})
						return
					end
					cb(true, result[1])
					IsPlayerReq[plate].customer = _source
					IsPlayerReq[plate].incustom = true
					Mechanics[_source] = plate
					if IsPlayerReq[plate].source ~= _source then
						TriggerClientEvent('master_mechanicjob:CloseMenus', IsPlayerReq[plate].source)
					end
					TriggerClientEvent("pNotify:SendNotification", IsPlayerReq[plate].source, { text = 'مکانیک ارتقا خوردو شما را شروع کرد.', type = "info", timeout = 3000, layout = "bottomCenter"})
				else
					TriggerClientEvent("pNotify:SendNotification", _source, { text = 'یک مکانیک دیگر درحال ارتقا خودرو می باشد.', type = "error", timeout = 3000, layout = "bottomCenter"})
				end
			else
				TriggerClientEvent("pNotify:SendNotification", _source, { text = 'هیچکس برای ارتقا درخواستی ثبت نکرده است.', type = "error", timeout = 3000, layout = "bottomCenter"})
			end
		else
			cb(false, false)
		end
	end)
end)

RegisterServerEvent('master_mechanicjob:VehiclesInWatingList')
AddEventHandler('master_mechanicjob:VehiclesInWatingList', function(Plate, vehicleProps , NoClean)
	local _Source = source
	if NoClean then
		if not IsPlayerReq[Plate] then
			IsPlayerReq[Plate] = {source = _Source, incustom = false ,customer = 0, price = 0, props = vehicleProps}
		end
	else
		IsPlayerReq[Plate] = nil
	end
end)

ESX.RegisterServerCallback('master_mechanicjob:PriceOfBill', function(source, cb, vehicle)
	if IsPlayerReq[vehicle] then
		cb(IsPlayerReq[vehicle].price)
	else
		cb(0)
	end
end)

ESX.RegisterServerCallback('master_mechanicjob:PayVehicleOrders', function(source, cb, vehicle, payWithBank)
	xPlayer = ESX.GetPlayerFromId(source)
	if IsPlayerReq[vehicle] then
		if payWithBank then
			if xPlayer.getAccount('bank').money >= IsPlayerReq[vehicle].price then
				xPlayer.removeAccountMoney('bank', tonumber(IsPlayerReq[vehicle].price))
				cb(true)
			else
				cb(false)
			end
		else
			if xPlayer.getMoney() >= IsPlayerReq[vehicle].price then
				xPlayer.removeMoney(tonumber(IsPlayerReq[vehicle].price))
				cb(true)
			else
				cb(false)
			end
		end
	else
		cb(true)
	end
end)

RegisterServerEvent('master_mechanicjob:refreshOwnedVehicle')
AddEventHandler('master_mechanicjob:refreshOwnedVehicle', function(vehicleProps)
	ESX.RunCustomFunction("anti_ddos", source, 'master_mechanicjob:refreshOwnedVehicle', {})
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
			end
		end
	end)
end)

RegisterServerEvent('master_mechanicjob:buyMod')
AddEventHandler('master_mechanicjob:buyMod', function(price, plate)
	local _source = source
	price = tonumber(price)
	if IsPlayerReq[plate] then
		IsPlayerReq[plate].price = tonumber(IsPlayerReq[plate].price) + price
	else
		TriggerClientEvent('master_mechanicjob:DontInstallMod', _source)
	end
end)
