-- Atlas Bank Server

os.loadAPI("bankapi.lua")

local defaultAssets = {
	official_coin = {
		id = "atm:official_coin",
		name = {fr="Monnaie officielle", en="Official Coin"},
		basePrice = 100,
		fluctuationPercent = 10,
		depositFactor = 0.97,
		withdrawFactor = 1.04,
		targetStock = 512,
		stock = 0,
		allowDeposit = true,
		allowWithdraw = true
	},
	raw_credit = {
		id = "minecraft:diamond",
		name = {fr="Cristal brut", en="Raw Credit Crystal"},
		basePrice = 64,
		fluctuationPercent = 18,
		depositFactor = 0.95,
		withdrawFactor = 1.08,
		targetStock = 1024,
		stock = 0,
		allowDeposit = true,
		allowWithdraw = true
	},
	vault_pearl = {
		id = "minecraft:emerald",
		name = {fr="Perle de coffre", en="Vault Pearl"},
		basePrice = 240,
		fluctuationPercent = 25,
		depositFactor = 0.94,
		withdrawFactor = 1.1,
		targetStock = 128,
		stock = 0,
		allowDeposit = true,
		allowWithdraw = true
	}
}

local localization = {
	fr = {
		title = "Serveur Atlas Bank, ne pas eteindre",
		error_invalidamount = "Montant invalide",
		error_from = "Compte source invalide",
		error_to = "Compte destinataire invalide",
		error_account = "Compte introuvable",
		error_same = "Impossible d'utiliser le meme compte en source et destination",
		error_notenoughbalance = "Solde insuffisant",
		error_unknownasset = "Actif inconnu",
		success_transaction = "Transaction reussie",
		success_update = "Mise a jour reussie",
		success_account = "Compte cree avec succes",
		account_deleted = "Compte supprime avec succes",
		withdraw_description = "Retrait bancaire",
		deposit_description = "Depot bancaire",
		password = "Mot de passe admin",
		password_explanation = "Mot de passe utilise par les terminaux admin",
		reserve_ratio = "Taux de reserve",
		reserve_ratio_explanation = "Part du stock retirable par le public (en %)",
		market = "Voir le marche",
		add_stock = "Approvisionner un actif",
		add_stock_steps = {"Choisir l'actif", "Quantite a ajouter ou retirer"},
		language = "Langue",
		fr = "Francais",
		en = "English",
		not_assigned = "- non assigne -",
		asset_updated = "Actif mis a jour",
		waiting_modem = "Modem requis. Connectez un modem pour continuer..."
	},
	en = {
		title = "Atlas Bank Server, do not turn off",
		error_invalidamount = "Invalid amount",
		error_from = "Invalid source account",
		error_to = "Invalid target account",
		error_account = "Account not found",
		error_same = "Cannot use the same account as source and destination",
		error_notenoughbalance = "Insufficient balance",
		error_unknownasset = "Unknown asset",
		success_transaction = "Transaction successful",
		success_update = "Update successful",
		success_account = "Account created successfully",
		account_deleted = "Account deleted successfully",
		withdraw_description = "Bank withdrawal",
		deposit_description = "Bank deposit",
		password = "Admin password",
		password_explanation = "Password used by admin terminals",
		reserve_ratio = "Reserve ratio",
		reserve_ratio_explanation = "Publicly withdrawable stock share (%)",
		market = "View market",
		add_stock = "Adjust asset stock",
		add_stock_steps = {"Choose asset", "Quantity to add or remove"},
		language = "Language",
		fr = "Francais",
		en = "English",
		not_assigned = "- not assigned -",
		asset_updated = "Asset updated",
		waiting_modem = "Modem required. Connect a modem to continue..."
	}
}

local filePath = "bank/"
local clientData = {}
local settings = {
	lang = "fr",
	terminalPassword = "1234",
	reserveRatio = 25,
	bankName = "Atlas Bank",
	currencyLabel = "Credits",
	transferFeePercent = 0
}
local assets = {}

local function ensureBankFolders()
	fs.makeDir(filePath)
	fs.makeDir(filePath.."clientData")
end

local function saveSerialized(path, data)
	local f = fs.open(path, "w")
	f.write(textutils.serialise(data))
	f.close()
end

local function loadSerialized(path, fallback)
	if (not fs.exists(path)) then
		return fallback
	end
	local f = fs.open(path, "r")
	local raw = f.readAll()
	f.close()
	local parsed = textutils.unserialise(raw)
	if (parsed == nil) then
		return fallback
	end
	return parsed
end

local function saveSettings()
	saveSerialized(filePath.."settings.txt", settings)
end

local function loadSettings()
	settings = loadSerialized(filePath.."settings.txt", settings)
end

local function saveAssets()
	saveSerialized(filePath.."assets.txt", assets)
end

local function loadAssets()
	assets = loadSerialized(filePath.."assets.txt", nil)
	if (assets == nil) then
		assets = defaultAssets
		saveAssets()
	end
end

local function loadClients()
	clientData = {}
	if (not fs.exists(filePath.."clientList.txt")) then
		return
	end

	local f = fs.open(filePath.."clientList.txt", "r")
	local line = f.readLine()
	while line ~= nil and line ~= "" do
		local key = line
		local info = loadSerialized(filePath.."clientData/"..key.."/info.txt", nil)
		if (info ~= nil) then
			clientData[key] = info
		end
		line = f.readLine()
	end
	f.close()
end

local function saveClientList()
	local f = fs.open(filePath.."clientList.txt", "w")
	for key, _ in pairs(clientData) do
		f.writeLine(key)
	end
	f.close()
end

local function updateClientFile(key)
	local info = clientData[key]
	if (info == nil) then
		return false, localization[settings.lang].error_account
	end
	fs.makeDir(filePath.."clientData/"..key)
	saveSerialized(filePath.."clientData/"..key.."/info.txt", info)
	return true, localization[settings.lang].success_update
end

local function appendTransactionToLog(from, to, amount, balance, time, description)
	local path = filePath.."clientData/"..from.."/log.txt"
	local f = fs.open(path, "a")
	f.writeLine("other")
	f.writeLine(to)
	f.writeLine("amount")
	f.writeLine(tostring(-amount))
	f.writeLine("balance")
	f.writeLine(tostring(balance))
	f.writeLine("time")
	f.writeLine(time)
	f.writeLine("description")
	f.writeLine(description or "")
	f.writeLine("")
	f.close()
end

local function getCurrentTime()
	return os.date("%d/%m/%Y %H:%M")
end

local function getClientData(data)
	loadClients()
	return true, clientData
end

local function resolveAssetName(asset)
	return asset.name[settings.lang] or asset.name.en or asset.id
end

local function clamp(value, minValue, maxValue)
	if (value < minValue) then return minValue end
	if (value > maxValue) then return maxValue end
	return value
end

local function round2(value)
	return math.floor(value * 100 + 0.5) / 100
end

local function quoteAsset(assetId, asset)
	local fluctuation = (asset.fluctuationPercent or 0) / 100
	local target = asset.targetStock or 1
	local stock = asset.stock or 0
	local ratio = stock / math.max(1, target)
	local pressure = clamp(1 - ratio, -1, 1)
	local multiplier = clamp(1 + pressure * fluctuation, 1 - fluctuation, 1 + fluctuation)
	local referencePrice = round2((asset.basePrice or 0) * multiplier)
	local depositPrice = round2(referencePrice * (asset.depositFactor or 1))
	local withdrawPrice = round2(referencePrice * (asset.withdrawFactor or 1))
	local maxWithdraw = 0

	if (asset.allowWithdraw) then
		maxWithdraw = math.floor(stock * ((settings.reserveRatio or 25) / 100))
	end

	return {
		id = assetId,
		name = resolveAssetName(asset),
		stock = stock,
		targetStock = target,
		referencePrice = referencePrice,
		depositPrice = depositPrice,
		withdrawPrice = withdrawPrice,
		maxWithdraw = maxWithdraw,
		allowDeposit = asset.allowDeposit == true,
		allowWithdraw = asset.allowWithdraw == true
	}
end

local function getAssetQuotes(data)
	local quotes = {}
	for assetId, asset in pairs(assets) do
		table.insert(quotes, quoteAsset(assetId, asset))
	end
	table.sort(quotes, function(a, b) return a.name < b.name end)
	return true, quotes
end

local function getServerData(data)
	return true, {
		lang = settings.lang,
		terminalPassword = settings.terminalPassword,
		bankName = settings.bankName,
		currencyLabel = settings.currencyLabel,
		reserveRatio = settings.reserveRatio,
		transferFeePercent = settings.transferFeePercent
	}
end

local function transaction(data)
	loadClients()
	local from = tostring(data.from)
	local to = tostring(data.to)
	local amount = tonumber(data.amount)
	local description = data.description or ""

	if (amount == nil or amount <= 0) then
		return false, localization[settings.lang].error_invalidamount
	end
	if (from == to) then
		return false, localization[settings.lang].error_same
	end
	if (clientData[from] == nil) then
		return false, localization[settings.lang].error_from.." ("..from..")"
	end
	if (clientData[to] == nil) then
		return false, localization[settings.lang].error_to.." ("..to..")"
	end

	amount = round2(amount)
	local fee = round2(amount * ((settings.transferFeePercent or 0) / 100))
	local total = amount + fee

	if (clientData[from].balance < total) then
		return false, localization[settings.lang].error_notenoughbalance
	end

	clientData[from].balance = round2(clientData[from].balance - total)
	clientData[to].balance = round2(clientData[to].balance + amount)

	updateClientFile(from)
	updateClientFile(to)

	local time = getCurrentTime()
	appendTransactionToLog(from, to, amount, clientData[from].balance, time, description)
	appendTransactionToLog(to, from, -amount, clientData[to].balance, time, description)

	return true, localization[settings.lang].success_transaction
end

local function deposit(data)
	loadClients()
	local key = tostring(data.key)
	local amount = tonumber(data.amount)
	if (amount == nil or amount <= 0) then
		return false, localization[settings.lang].error_invalidamount
	end
	if (clientData[key] == nil) then
		return false, localization[settings.lang].error_from.." ("..key..")"
	end

	clientData[key].balance = round2(clientData[key].balance + amount)
	updateClientFile(key)
	appendTransactionToLog(key, key, -amount, clientData[key].balance, getCurrentTime(), localization[settings.lang].deposit_description)
	return true, localization[settings.lang].success_transaction
end

local function withdraw(data)
	loadClients()
	local key = tostring(data.key)
	local amount = tonumber(data.amount)
	if (amount == nil or amount <= 0) then
		return false, localization[settings.lang].error_invalidamount
	end
	if (clientData[key] == nil) then
		return false, localization[settings.lang].error_from.." ("..key..")"
	end
	if (clientData[key].balance < amount) then
		return false, localization[settings.lang].error_notenoughbalance
	end

	clientData[key].balance = round2(clientData[key].balance - amount)
	updateClientFile(key)
	appendTransactionToLog(key, key, amount, clientData[key].balance, getCurrentTime(), localization[settings.lang].withdraw_description)
	return true, localization[settings.lang].success_transaction
end

local function getTransactionLog(data)
	local key = tostring(data.key)
	local log = {}
	local path = filePath.."clientData/"..key.."/log.txt"
	if (not fs.exists(path)) then
		return true, log
	end

	local f = fs.open(path, "r")
	local line = f.readLine()
	local count = 1
	while line ~= nil do
		local entry = {other="", amount=0, balance=0, time="", description=""}
		while line ~= nil and line ~= "" do
			if (line == "other") then
				entry.other = f.readLine()
			elseif (line == "amount") then
				entry.amount = f.readLine()
			elseif (line == "balance") then
				entry.balance = f.readLine()
			elseif (line == "time") then
				entry.time = f.readLine()
			elseif (line == "description") then
				entry.description = f.readLine()
			end
			line = f.readLine()
		end
		log[count] = entry
		count = count + 1
		line = f.readLine()
	end
	f.close()
	return true, log
end

local function newClient(data)
	loadClients()
	local name = data.name
	local color = data.color

	local bankKey = "2000"
	local firstFreeClientNumber = 0
	while firstFreeClientNumber < 9999 do
		firstFreeClientNumber = firstFreeClientNumber + 1
		local clientNumber = string.rep("0", 4-string.len(tostring(firstFreeClientNumber)))..tostring(firstFreeClientNumber)
		local exists = false
		for key, _ in pairs(clientData) do
			if (string.sub(key, 5, 8) == clientNumber) then
				exists = true
				break
			end
		end
		if (not exists) then
			break
		end
	end

	local clientNumber = string.rep("0", 4-string.len(tostring(firstFreeClientNumber)))..tostring(firstFreeClientNumber)
	local randomKey = ""
	for i=1, 8 do
		randomKey = randomKey..tostring(math.random(10)-1)
	end
	local key = bankKey..clientNumber..randomKey

	clientData[key] = {
		name = name,
		balance = 0,
		color = color
	}

	saveClientList()
	updateClientFile(key)
	local logFile = fs.open(filePath.."clientData/"..key.."/log.txt", "w")
	logFile.close()

	return true, localization[settings.lang].success_account
end

local function deleteAccount(data)
	loadClients()
	local key = tostring(data.key)
	clientData[key] = nil
	saveClientList()
	fs.delete(filePath.."clientData/"..key)
	return true, localization[settings.lang].account_deleted
end

local function adjustAssetStock(data)
	local assetId = data.assetId
	local amount = tonumber(data.amount)
	if (assets[assetId] == nil) then
		return false, localization[settings.lang].error_unknownasset
	end
	if (amount == nil) then
		return false, localization[settings.lang].error_invalidamount
	end

	assets[assetId].stock = math.max(0, math.floor((assets[assetId].stock or 0) + amount))
	saveAssets()
	return true, localization[settings.lang].asset_updated
end

local function processRequest(func, sender, data)
	local success, response = func(data)
	rednet.send(sender, {success = success, response = response}, "mermegold")
end

ensureBankFolders()
loadSettings()
loadAssets()
loadClients()

local modem = peripheral.find("modem")
while (modem == nil) do
	modem = peripheral.find("modem")
	if (modem == nil) then
		term.setBackgroundColor(colors.red)
		term.setTextColor(colors.white)
		term.clear()
		term.setCursorPos(1,1)
		print(localization[settings.lang].waiting_modem)
		os.pullEvent("peripheral")
	end
end
peripheral.find("modem", rednet.open)

function listen()
	while true do
		local sender, message = rednet.receive("mermegold")
		if (message.action == "getClientData") then
			processRequest(getClientData, sender, message)
		elseif (message.action == "getServerData") then
			processRequest(getServerData, sender, message)
		elseif (message.action == "getTransactionLog") then
			processRequest(getTransactionLog, sender, message)
		elseif (message.action == "transaction") then
			processRequest(transaction, sender, message)
		elseif (message.action == "deposit") then
			processRequest(deposit, sender, message)
		elseif (message.action == "withdraw") then
			processRequest(withdraw, sender, message)
		elseif (message.action == "new") then
			processRequest(newClient, sender, message)
		elseif (message.action == "delete") then
			processRequest(deleteAccount, sender, message)
		elseif (message.action == "getAssetQuotes") then
			processRequest(getAssetQuotes, sender, message)
		elseif (message.action == "adjustAssetStock") then
			processRequest(adjustAssetStock, sender, message)
		else
			rednet.send(sender, {success = false, response = "Requete invalide"}, "mermegold")
		end
	end
end

local function assetOptions()
	local options = {}
	for assetId, asset in pairs(assets) do
		table.insert(options, {
			option = assetId,
			text = resolveAssetName(asset).." | stock "..tostring(asset.stock)
		})
	end
	table.sort(options, function(a, b) return a.text < b.text end)
	return options
end

function main()
	while true do
		local command = bankapi.optionMenu(localization[settings.lang].title, {
			{option = "language", text = localization[settings.lang].language..": "..localization[settings.lang][settings.lang]},
			{option = "password", text = localization[settings.lang].password..": "..settings.terminalPassword},
			{option = "reserve", text = localization[settings.lang].reserve_ratio..": "..settings.reserveRatio.."%"},
			{option = "market", text = localization[settings.lang].market},
			{option = "stock", text = localization[settings.lang].add_stock},
		}, 2, 42)

		if (command == "language") then
			local selected = bankapi.optionMenu(localization[settings.lang].language, {
				{option = "fr", text = "Francais"},
				{option = "en", text = "English"},
			}, 2)
			settings.lang = selected
			saveSettings()
		elseif (command == "password") then
			local newPassword = bankapi.inputTextScreen({localization[settings.lang].password_explanation}, 1, 12)
			if (newPassword ~= nil and newPassword ~= "") then
				settings.terminalPassword = newPassword
				saveSettings()
			end
		elseif (command == "reserve") then
			local amount = bankapi.inputNumberScreen({localization[settings.lang].reserve_ratio_explanation}, 1)
			if (amount ~= nil) then
				settings.reserveRatio = math.max(1, math.min(100, tonumber(amount)))
				saveSettings()
			end
		elseif (command == "market") then
			local success, quotes = getAssetQuotes({})
			if (success) then
				bankapi.marketQuotesScreen(settings.bankName, quotes, settings.currencyLabel)
			end
		elseif (command == "stock") then
			local assetId = bankapi.optionMenu(localization[settings.lang].add_stock, assetOptions(), 2, 42)
			if (assetId ~= nil) then
				local quantity = bankapi.inputNumberScreen(localization[settings.lang].add_stock_steps, 2)
				if (quantity ~= nil) then
					local success, message = adjustAssetStock({assetId = assetId, amount = tonumber(quantity)})
					bankapi.responseScreen(success, message)
				end
			end
		end
	end
end

parallel.waitForAll(listen, main)
