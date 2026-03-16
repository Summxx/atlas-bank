-- Atlas Bank Advanced Monitor ATM

os.loadAPI("bankapi.lua")

local shrekbox = require("shrekbox")

local monitor = peripheral.find("monitor")
local chatBox = peripheral.wrap("left")
local playerDetector = peripheral.wrap("right")
-- Vous pouvez utiliser un cote ("top") ou un nom exact de peripherique.
local inventoryConfig = {
	depositPeripheral = "top",
	vaultPeripheral = "back",
	outputPeripheral = "bottom"
}

local function hasMethod(object, methodName)
	return object ~= nil and type(object[methodName]) == "function"
end

local function resolvePeripheral(reference, requiredMethod)
	if (reference == nil or reference == "") then
		return nil, nil
	end
	local peripheralObject = peripheral.wrap(reference)
	if (peripheralObject ~= nil and (requiredMethod == nil or hasMethod(peripheralObject, requiredMethod))) then
		return peripheralObject, reference
	end

	for _, name in ipairs(peripheral.getNames()) do
		if (name == reference) then
			local namedPeripheral = peripheral.wrap(name)
			if (namedPeripheral ~= nil and (requiredMethod == nil or hasMethod(namedPeripheral, requiredMethod))) then
				return namedPeripheral, name
			end
		end
	end

	return nil, nil
end

if (monitor == nil) then
	error("Un advanced monitor est requis pour utiliser le terminal Atlas Bank.")
end
if (chatBox == nil or not hasMethod(chatBox, "sendMessageToPlayer")) then
	error("Une Chat Box Advanced Peripherals doit etre placee a gauche de l'ordinateur.")
end
if (playerDetector == nil or not hasMethod(playerDetector, "getPlayersInRange")) then
	error("Un Player Detector Advanced Peripherals doit etre place a droite de l'ordinateur.")
end

local modem = peripheral.find("modem")
while (modem == nil) do
	modem = peripheral.find("modem")
	if (modem == nil) then
		term.setBackgroundColor(colors.red)
		term.setTextColor(colors.white)
		term.clear()
		term.setCursorPos(1, 1)
		print("Modem requis. Connectez un modem pour continuer...")
		os.pullEvent("peripheral")
	end
end

peripheral.find("modem", rednet.open)
monitor.setTextScale(0.5)

local monitorSide = peripheral.getName(monitor)
local width, height = monitor.getSize()
local viewport = window.create(monitor, 1, 1, width, height, true)
local box = shrekbox.new(viewport)
local pixelLayer = box.add_pixel_layer(5, "pixels")
local textLayer = box.add_text_layer(10, "text")
local serverData = bankapi.getServerData()
local lang = serverData.lang or "fr"

local localization = {
	fr = {
		title = "ATLAS BANK",
		balance = "Solde",
		no_balance = "Aucun compte",
		sleep_title = "ATLAS BANK",
		sleep_subtitle = "Banque privee decentralisee",
		sleep_hint = "Clic droit pour utiliser ou sortir du mode veille",
		sleep_hint_2 = "Advanced monitor en haute resolution",
		no_player = "Aucun joueur detecte a droite",
		player = "Joueur detecte",
		no_account = "Aucun compte Atlas Bank detecte",
		account_ready = "Compte Atlas Bank actif",
		create_account = "Creer mon compte",
		my_account = "Mon compte",
		market = "Marche",
		help = "Aide",
		sleep = "Veille",
		back = "Retour",
		register_title = "Ouverture de compte",
		register_desc = "Le player detector identifie automatiquement le joueur proche.",
		register_button = "Ouvrir mon compte",
		register_need_player = "Approchez-vous du detecteur pour ouvrir un compte.",
		register_success = "Compte cree avec succes.",
		register_error = "Impossible de creer le compte.",
		register_chat_1 = "Votre compte Atlas Bank a ete cree. Cle : ",
		register_chat_2 = " Revenez au terminal pour consulter votre solde.",
		account_title = "Compte bancaire",
		key = "Cle",
		status = "Statut",
		status_online = "Connecte au terminal",
		market_title = "Cours du marche",
		market_empty = "Aucun actif charge.",
		select_asset = "Selectionnez un actif a gauche",
		deposit_asset = "Depot",
		withdraw_asset = "Retrait",
		quantity = "Quantite",
		confirm = "Valider",
		clear = "Effacer",
		close = "Fermer",
		operation_done = "Operation enregistree",
		operation_error = "Operation refusee",
		error_missing_inventory = "Inventaire ATM manquant",
		error_missing_items = "Objets insuffisants dans le depot",
		error_output_blocked = "Sortie ATM indisponible",
		error_vault_blocked = "Reserve ATM indisponible",
		error_notenoughbalance = "Solde insuffisant",
		error_asset_stock = "Reserve publique insuffisante",
		error_partial_move = "Transfert ATM incomplet",
		buy_price = "Achat banque",
		sell_price = "Retrait banque",
		stock = "Reserve",
		withdraw_max = "Retrait max",
		graph = "Graphique live",
		help_title = "Guide rapide",
		help_lines = {
			"1. Placez-vous pres du detecteur du terminal pour etre identifie.",
			"2. Creez votre compte si necessaire.",
			"3. Consultez ensuite votre solde et les cours du marche.",
			"4. Deposez vos objets dans le container du haut.",
			"5. Touchez un actif a gauche pour voir ses details.",
			"6. Les retraits sortent vers le container du bas."
		},
		assist = "Touchez un bouton pour continuer.",
		currency = serverData.currencyLabel or "Credits"
	},
	en = {
		title = "ATLAS BANK",
		balance = "Balance",
		no_balance = "No account",
		sleep_title = "ATLAS BANK",
		sleep_subtitle = "Decentralized private bank",
		sleep_hint = "Right click to use or leave standby mode",
		sleep_hint_2 = "Advanced monitor in high resolution",
		no_player = "No player detected on the right",
		player = "Detected player",
		no_account = "No Atlas Bank account detected",
		account_ready = "Atlas Bank account active",
		create_account = "Create account",
		my_account = "My account",
		market = "Market",
		help = "Help",
		sleep = "Sleep",
		back = "Back",
		register_title = "Open account",
		register_desc = "The player detector automatically identifies the nearby player.",
		register_button = "Open my account",
		register_need_player = "Stand near the detector to open an account.",
		register_success = "Account created successfully.",
		register_error = "Unable to create account.",
		register_chat_1 = "Your Atlas Bank account has been created. Key: ",
		register_chat_2 = " Return to the terminal to check your balance.",
		account_title = "Bank account",
		key = "Key",
		status = "Status",
		status_online = "Connected to terminal",
		market_title = "Market rates",
		market_empty = "No assets loaded.",
		select_asset = "Select an asset on the left",
		deposit_asset = "Deposit",
		withdraw_asset = "Withdraw",
		quantity = "Quantity",
		confirm = "Confirm",
		clear = "Clear",
		close = "Close",
		operation_done = "Operation recorded",
		operation_error = "Operation rejected",
		error_missing_inventory = "ATM inventory missing",
		error_missing_items = "Not enough items in deposit inventory",
		error_output_blocked = "ATM output unavailable",
		error_vault_blocked = "ATM vault unavailable",
		error_notenoughbalance = "Insufficient balance",
		error_asset_stock = "Public reserve is too low",
		error_partial_move = "ATM transfer incomplete",
		buy_price = "Bank buy",
		sell_price = "Withdraw",
		stock = "Reserve",
		withdraw_max = "Max withdraw",
		graph = "Live graph",
		help_title = "Quick guide",
		help_lines = {
			"1. Stand near the terminal detector to be identified.",
			"2. Create your account if needed.",
			"3. Then check your balance and market rates.",
			"4. Put your items in the top deposit inventory.",
			"5. Touch an asset on the left to see details.",
			"6. Withdrawals are sent to the bottom output inventory."
		},
		assist = "Touch a button to continue.",
		currency = serverData.currencyLabel or "Credits"
	}
}

local function t(key)
	return (localization[lang] and localization[lang][key]) or key
end

local theme = {
	bg = colors.black,
	card = colors.gray,
	cardDark = colors.black,
	border = colors.lightGray,
	header = colors.gray,
	headerText = colors.white,
	panelTop = colors.lightGray,
	text = colors.white,
	sub = colors.lightGray,
	accent = colors.cyan,
	success = colors.green,
	successText = colors.black,
	warning = colors.yellow,
	warningText = colors.black,
	primary = colors.blue,
	primaryText = colors.white,
	danger = colors.red,
	dangerText = colors.white,
	muted = colors.gray,
	coin = colors.yellow,
	coinText = colors.black
}

local state = {
	page = "sleep",
	currentPlayer = nil,
	account = nil,
	accountKey = nil,
	quotes = {},
	history = {},
	selectedAsset = nil,
	buttons = {},
	pendingOperation = nil,
	pendingQuantity = "1",
	flashMessage = nil
}

local function clear()
	box.fill(theme.bg)
	pixelLayer.clear()
	textLayer.clear()
end

local function fill(x, y, w, h, bg)
	if (w <= 0 or h <= 0) then
		return
	end
	for row = y, y + h - 1 do
		textLayer.text(x, row, string.rep(" ", w), bg, bg)
	end
end

local function writeAt(x, y, text, fg, bg)
	textLayer.text(x, y, text, fg or theme.text, bg)
end

local function centerText(y, text, fg, bg)
	writeAt(math.max(1, math.floor((width - #text) / 2) + 1), y, text, fg, bg)
end

local function trimText(text, maxLength)
	text = tostring(text or "")
	if (#text <= maxLength) then
		return text
	end
	return string.sub(text, 1, math.max(1, maxLength - 3)) .. "..."
end

local function addButton(id, x, y, w, h)
	state.buttons[#state.buttons + 1] = {
		id = id,
		x1 = x,
		y1 = y,
		x2 = x + w - 1,
		y2 = y + h - 1
	}
end

local function fillRoundedRect(x, y, w, h, color, radius)
	if (w <= 0 or h <= 0) then
		return
	end
	radius = math.max(1, radius or 3)
	local px1 = (x - 1) * 2 + 1
	local py1 = (y - 1) * 3 + 1
	local px2 = (x + w - 1) * 2
	local py2 = (y + h - 1) * 3
	local pr = math.max(1, radius)

	for py = py1, py2 do
		for px = px1, px2 do
			local dx = 0
			local dy = 0
			local left = px1 + pr
			local right = px2 - pr
			local top = py1 + pr
			local bottom = py2 - pr

			if (px < left) then
				dx = left - px
			elseif (px > right) then
				dx = px - right
			end

			if (py < top) then
				dy = top - py
			elseif (py > bottom) then
				dy = py - bottom
			end

			if (dx == 0 or dy == 0 or (dx * dx + dy * dy) <= (pr * pr)) then
				pixelLayer.pixel(px, py, color)
			end
		end
	end
end

local function roundedButton(id, x, y, w, label, bg, fg)
	w = math.max(w, #label + 4)
	fillRoundedRect(x, y, w, 4, bg, 3)
	writeAt(x + math.floor((w - #label) / 2), y + 1, label, fg, nil)
	addButton(id, x, y, w, 4)
	return w
end

local function flatPanel(x, y, w, h, title)
	fillRoundedRect(x, y, w, h, theme.card, 3)
	fillRoundedRect(x, y, w, 2, theme.panelTop, 3)
	if (title ~= nil and title ~= "") then
		writeAt(x + 2, y, title, theme.cardDark, nil)
	end
end

local function statusChip(x, y, text, bg, fg)
	local widthChip = #text + 4
	fillRoundedRect(x, y, widthChip, 1, bg, 2)
	writeAt(x + 2, y, text, fg, nil)
	return widthChip
end

local function hitButton(x, y)
	for _, button in ipairs(state.buttons) do
		if (x >= button.x1 and x <= button.x2 and y >= button.y1 and y <= button.y2) then
			return button.id
		end
	end
	return nil
end

local function normalizePlayerEntry(entry)
	if (type(entry) == "table") then
		return entry.name or entry.username or entry.player or entry[1]
	end
	return entry
end

local function detectPlayer()
	local ok, result = pcall(function()
		return playerDetector.getPlayersInRange(4)
	end)
	if (not ok or type(result) ~= "table" or #result ~= 1) then
		return nil
	end
	return normalizePlayerEntry(result[1])
end

local function sendPlayerMessage(playerName, text)
	if (playerName == nil) then
		return
	end
	pcall(function()
		chatBox.sendMessageToPlayer(text, playerName, serverData.bankName or "Atlas Bank", "<>")
	end)
end

local function getInventory(reference)
	local inventory = select(1, resolvePeripheral(reference, "list"))
	if (inventory == nil or not hasMethod(inventory, "list")) then
		return nil
	end
	return inventory
end

local function getInventoryName(reference)
	local _, name = resolvePeripheral(reference, "list")
	return name
end

local function normalizeItemToken(value)
	value = string.lower(tostring(value or ""))
	value = string.gsub(value, "[%s_%-%.:]", "")
	return value
end

local function getItemDetail(inventory, slot, basic)
	if (inventory == nil) then
		return basic
	end
	if (hasMethod(inventory, "getItemDetail")) then
		local ok, detail = pcall(inventory.getItemDetail, slot)
		if (ok and type(detail) == "table") then
			return detail
		end
	end
	return basic
end

local function assetMatchesItem(quote, basic, detail)
	local wantedId = normalizeItemToken(quote and quote.itemId or "")
	local wantedLabel = normalizeItemToken(quote and (quote.itemLabel or quote.name) or "")
	local itemName = normalizeItemToken((detail and detail.name) or (basic and basic.name) or "")
	local itemShortName = string.match(((detail and detail.name) or (basic and basic.name) or ""), "([^:]+)$") or itemName
	itemShortName = normalizeItemToken(itemShortName)
	local displayName = normalizeItemToken((detail and detail.displayName) or "")

	if (wantedId ~= "" and (itemName == wantedId or itemShortName == wantedId)) then
		return true
	end
	if (wantedLabel ~= "") then
		if (displayName == wantedLabel or itemShortName == wantedLabel) then
			return true
		end
		if (string.find(displayName, wantedLabel, 1, true) ~= nil) then
			return true
		end
		if (string.find(itemShortName, wantedLabel, 1, true) ~= nil) then
			return true
		end
	end
	return false
end

local function countMatchingItems(inventory, quote)
	if (inventory == nil) then
		return 0
	end
	local total = 0
	for slot, basic in pairs(inventory.list()) do
		local detail = getItemDetail(inventory, slot, basic)
		if (assetMatchesItem(quote, basic, detail)) then
			total = total + (basic.count or 0)
		end
	end
	return total
end

local function moveMatchingItems(fromInventory, destinationName, quote, wantedQuantity)
	if (fromInventory == nil or destinationName == nil or not hasMethod(fromInventory, "pushItems")) then
		return 0
	end
	local moved = 0
	local remaining = math.max(0, math.floor(tonumber(wantedQuantity) or 0))
	if (remaining <= 0) then
		return 0
	end

	for slot, basic in pairs(fromInventory.list()) do
		if (remaining <= 0) then
			break
		end
		local detail = getItemDetail(fromInventory, slot, basic)
		if (assetMatchesItem(quote, basic, detail)) then
			local movedNow = 0
			local ok, result = pcall(fromInventory.pushItems, destinationName, slot, remaining)
			if (ok and type(result) == "number") then
				movedNow = result
			end
			moved = moved + movedNow
			remaining = remaining - movedNow
		end
	end

	return moved
end

local function colorFromName(name)
	local colorsList = {colors.cyan, colors.blue, colors.green, colors.orange, colors.magenta, colors.yellow}
	local sum = 0
	for i = 1, #name do
		sum = sum + string.byte(name, i)
	end
	return colorsList[(sum % #colorsList) + 1]
end

local function refreshPlayerAndAccount()
	state.currentPlayer = detectPlayer()
	state.account = nil
	state.accountKey = nil
	if (state.currentPlayer ~= nil) then
		local ok, success, response = pcall(bankapi.getAccountByPlayer, state.currentPlayer)
		if (ok and success and response ~= nil) then
			state.accountKey = response.key
			state.account = response.account
		end
	end
end

local function refreshQuotes()
	local ok, quotes = pcall(bankapi.getAssetQuotes)
	if (not ok or type(quotes) ~= "table") then
		return
	end
	state.quotes = quotes
	for _, quote in ipairs(state.quotes) do
		state.history[quote.id] = state.history[quote.id] or {}
		local history = state.history[quote.id]
		history[#history + 1] = quote.depositPrice
		if (#history > 36) then
			table.remove(history, 1)
		end
	end
	if (state.selectedAsset == nil and #state.quotes > 0) then
		state.selectedAsset = state.quotes[1].id
	end
end

local function selectedQuote()
	if (state.selectedAsset ~= nil) then
		for _, quote in ipairs(state.quotes) do
			if (quote.id == state.selectedAsset) then
				return quote
			end
		end
	end
	if (#state.quotes > 0) then
		state.selectedAsset = state.quotes[1].id
		return state.quotes[1]
	end
	return nil
end

local function drawGraph(x, y, w, h, values)
	fill(x, y, w, h, theme.cardDark)
	if (values == nil or #values == 0) then
		centerText(y + math.floor(h / 2), "-", theme.sub, theme.cardDark)
		return
	end

	local startIndex = math.max(1, #values - w + 1)
	local minValue = values[startIndex]
	local maxValue = values[startIndex]
	for index = startIndex, #values do
		if (values[index] < minValue) then minValue = values[index] end
		if (values[index] > maxValue) then maxValue = values[index] end
	end

	for i = 0, math.min(w - 1, #values - startIndex) do
		local value = values[startIndex + i]
		local normalized = 0
		if (maxValue > minValue) then
			normalized = (value - minValue) / (maxValue - minValue)
		end
		local columnHeight = math.max(1, math.floor(normalized * (h - 1)) + 1)
		for row = 0, columnHeight - 1 do
			local py = y + h - 1 - row
			fill(x + i, py, 1, 1, theme.accent)
		end
	end
end

local function drawHeader()
	fill(1, 1, width, 2, theme.bg)
	writeAt(3, 1, t("title"), theme.text, theme.bg)

	local balanceText = t("no_balance")
	if (state.account ~= nil) then
		balanceText = "$" .. tostring(state.account.balance)
	end
	local coinText = " $ "
	local balanceX = math.max(20, width - #balanceText - #coinText - 3)
	writeAt(balanceX, 1, balanceText, theme.text, theme.bg)
	statusChip(balanceX + #balanceText + 1, 1, "$", theme.coin, theme.coinText)

	fill(1, 2, width, 1, theme.header)
	local subtitle = state.currentPlayer and (t("player") .. ": " .. state.currentPlayer) or t("no_player")
	centerText(2, trimText(subtitle, width - 4), theme.headerText, theme.header)
	if (state.flashMessage ~= nil) then
		local message = trimText(state.flashMessage.text, width - 4)
		local bg = state.flashMessage.success and theme.success or theme.danger
		local fg = state.flashMessage.success and theme.successText or theme.dangerText
		fill(1, 3, width, 1, bg)
		centerText(3, message, fg, bg)
	else
		fill(1, 3, width, 1, theme.bg)
	end
end

local function drawMainShell(activePrimary, activeSecondary)
	local railX = 4
	local railY = 6
	local railW = math.max(20, math.floor(width * 0.22))
	local buttonW = railW - 2
	local contentX = railX + railW + 2
	local contentY = 5
	local contentW = width - contentX - 3
	local contentH = height - 9

	roundedButton(activePrimary == "account" and "account" or "register", railX + 1, railY + 2, buttonW, state.account and t("my_account") or t("create_account"), theme.success, theme.successText)
	roundedButton("market", railX + 1, railY + 7, buttonW, t("market"), theme.primary, theme.primaryText)
	roundedButton("help", railX + 1, railY + 12, buttonW, t("help"), theme.warning, theme.warningText)
	roundedButton("sleep", width - 16, height - 4, 13, t("sleep"), theme.danger, theme.dangerText)

	local borderColor = activeSecondary or theme.border
	flatPanel(contentX, contentY, contentW, contentH, serverData.bankName or "Atlas Bank")
	fill(contentX, contentY + 1, contentW, 1, borderColor)

	return {
		railX = railX,
		railY = railY,
		railW = railW,
		buttonW = buttonW,
		contentX = contentX,
		contentY = contentY,
		contentW = contentW,
		contentH = contentH
	}
end

local function drawSleepPage()
	clear()
	state.buttons = {}
	local cardWidth = math.min(44, width - 6)
	local cardX = math.max(3, math.floor((width - cardWidth) / 2))
	local cardY = math.max(4, math.floor(height / 2) - 5)
	flatPanel(cardX, cardY, cardWidth, 10, "")
	centerText(cardY + 2, t("sleep_title"), theme.text, theme.card)
	centerText(cardY + 4, t("sleep_subtitle"), theme.sub, theme.card)
	centerText(cardY + 6, t("sleep_hint"), theme.accent, theme.card)
	centerText(cardY + 8, t("sleep_hint_2"), theme.sub, theme.card)
	addButton("wake", 1, 1, width, height)
end

local function drawHomePage()
	clear()
	state.buttons = {}
	drawHeader()

	local shell = drawMainShell(state.account and "account" or "register", theme.panelTop)
	local contentX = shell.contentX
	local contentY = shell.contentY
	local contentW = shell.contentW

	local infoY = contentY + 3
	if (state.currentPlayer ~= nil) then
		writeAt(contentX + 3, infoY, trimText(t("player") .. ": " .. state.currentPlayer, contentW - 6), theme.accent, theme.card)
	else
		writeAt(contentX + 3, infoY, trimText(t("no_player"), contentW - 6), theme.warning, theme.card)
	end

	if (state.account ~= nil) then
		writeAt(contentX + 3, infoY + 3, trimText(t("account_ready"), contentW - 6), theme.text, theme.card)
		writeAt(contentX + 3, infoY + 5, trimText(t("balance") .. ": " .. tostring(state.account.balance) .. " " .. t("currency"), contentW - 6), theme.sub, theme.card)
		writeAt(contentX + 3, infoY + 8, trimText(t("assist"), contentW - 6), theme.sub, theme.card)
	else
		writeAt(contentX + 3, infoY + 3, trimText(t("no_account"), contentW - 6), theme.text, theme.card)
		writeAt(contentX + 3, infoY + 5, trimText(t("assist"), contentW - 6), theme.sub, theme.card)
	end
end

local function drawRegisterPage()
	clear()
	state.buttons = {}
	drawHeader()

	local shell = drawMainShell("register", theme.success)
	local panelX = shell.contentX
	local panelY = shell.contentY
	local panelW = shell.contentW
	writeAt(panelX + 3, panelY + 3, trimText(t("register_title"), panelW - 6), theme.text, theme.card)
	writeAt(panelX + 3, panelY + 5, trimText(t("register_desc"), panelW - 6), theme.sub, theme.card)
	if (state.currentPlayer ~= nil) then
		writeAt(panelX + 3, panelY + 8, trimText(t("player") .. ": " .. state.currentPlayer, panelW - 6), theme.accent, theme.card)
		roundedButton("register_confirm", panelX + 3, panelY + 12, panelW - 6, t("register_button"), theme.success, theme.successText)
	else
		writeAt(panelX + 3, panelY + 8, trimText(t("register_need_player"), panelW - 6), theme.warning, theme.card)
	end
end

local function drawAccountPage()
	clear()
	state.buttons = {}
	drawHeader()

	local shell = drawMainShell("account", theme.success)
	local panelX = shell.contentX
	local panelY = shell.contentY
	local panelW = shell.contentW
	writeAt(panelX + 3, panelY + 3, trimText(t("account_title"), panelW - 6), theme.text, theme.card)
	if (state.account ~= nil) then
		writeAt(panelX + 3, panelY + 6, trimText(t("player") .. ": " .. (state.account.playerName or state.currentPlayer or "?"), panelW - 6), theme.text, theme.card)
		writeAt(panelX + 3, panelY + 8, trimText(t("key") .. ": " .. tostring(state.accountKey), panelW - 6), theme.sub, theme.card)
		writeAt(panelX + 3, panelY + 11, trimText(t("balance") .. ": " .. tostring(state.account.balance) .. " " .. t("currency"), panelW - 6), theme.accent, theme.card)
		writeAt(panelX + 3, panelY + 14, trimText(t("status") .. ": " .. t("status_online"), panelW - 6), theme.sub, theme.card)
	else
		writeAt(panelX + 3, panelY + 8, trimText(t("no_account"), panelW - 6), theme.warning, theme.card)
	end
end

local function drawMarketPage()
	clear()
	state.buttons = {}
	drawHeader()

	local shell = drawMainShell("market", theme.primary)
	local listX = shell.contentX + 2
	local listY = shell.contentY + 3
	local listW = math.max(18, math.floor(shell.contentW * 0.34))
	local listH = shell.contentH - 5
	flatPanel(listX, listY, listW, listH, t("market_title"))

	local quote = selectedQuote()
	local detailX = listX + listW + 2
	local detailW = shell.contentX + shell.contentW - detailX - 1
	flatPanel(detailX, listY, detailW, listH, quote and quote.name or t("select_asset"))

	if (#state.quotes == 0) then
		writeAt(listX + 2, listY + 3, trimText(t("market_empty"), listW - 4), theme.sub, theme.card)
	else
		local maxVisible = math.max(3, math.floor((listH - 5) / 4))
		for index, assetQuote in ipairs(state.quotes) do
			if (index > maxVisible) then
				break
			end
			local buttonBg = (assetQuote.id == state.selectedAsset) and theme.panelTop or theme.cardDark
			local buttonFg = (assetQuote.id == state.selectedAsset) and theme.cardDark or theme.text
			local rowY = listY + 2 + ((index - 1) * 4)
			local label = trimText(assetQuote.name, listW - 8)
			fillRoundedRect(listX + 2, rowY, listW - 4, 3, buttonBg, 2)
			writeAt(listX + 4, rowY + 1, label, buttonFg, nil)
			addButton("asset:" .. assetQuote.id, listX + 2, rowY, listW - 4, 3)
		end
	end

	if (quote ~= nil) then
		writeAt(detailX + 2, listY + 3, trimText(t("buy_price") .. ": " .. tostring(quote.depositPrice) .. " " .. t("currency"), detailW - 4), theme.accent, theme.card)
		writeAt(detailX + 2, listY + 5, trimText(t("sell_price") .. ": " .. tostring(quote.withdrawPrice) .. " " .. t("currency"), detailW - 4), theme.text, theme.card)
		writeAt(detailX + 2, listY + 7, trimText(t("stock") .. ": " .. tostring(quote.stock), detailW - 4), theme.sub, theme.card)
		writeAt(detailX + 2, listY + 9, trimText(t("withdraw_max") .. ": " .. tostring(quote.maxWithdraw), detailW - 4), theme.sub, theme.card)
		writeAt(detailX + 2, listY + 12, t("graph"), theme.text, theme.card)
		drawGraph(detailX + 2, listY + 14, detailW - 4, math.max(5, listH - 17), state.history[quote.id] or {})
		if (state.accountKey ~= nil) then
			local buttonWidth = math.max(14, math.floor((detailW - 8) / 2))
			if (quote.allowDeposit) then
				roundedButton("deposit_asset", detailX + 2, listY + listH - 8, buttonWidth, t("deposit_asset"), theme.success, theme.successText)
			else
				fillRoundedRect(detailX + 2, listY + listH - 8, buttonWidth, 4, theme.muted, 3)
				writeAt(detailX + 2 + math.floor((buttonWidth - #t("deposit_asset")) / 2), listY + listH - 7, t("deposit_asset"), theme.cardDark, nil)
			end
			if (quote.allowWithdraw) then
				roundedButton("withdraw_asset", detailX + 4 + buttonWidth, listY + listH - 8, buttonWidth, t("withdraw_asset"), theme.primary, theme.primaryText)
			else
				fillRoundedRect(detailX + 4 + buttonWidth, listY + listH - 8, buttonWidth, 4, theme.muted, 3)
				writeAt(detailX + 4 + buttonWidth + math.floor((buttonWidth - #t("withdraw_asset")) / 2), listY + listH - 7, t("withdraw_asset"), theme.cardDark, nil)
			end
		end
	else
		writeAt(detailX + 2, listY + 4, trimText(t("select_asset"), detailW - 4), theme.sub, theme.card)
	end
end

local function drawQuantityPage()
	clear()
	state.buttons = {}
	drawHeader()

	local shell = drawMainShell("market", state.pendingOperation == "deposit" and theme.success or theme.primary)
	local quote = selectedQuote()
	local panelX = shell.contentX
	local panelY = shell.contentY
	local panelW = shell.contentW
	local panelH = shell.contentH

	flatPanel(panelX, panelY, panelW, panelH, quote and quote.name or t("select_asset"))
	writeAt(panelX + 3, panelY + 3, trimText((state.pendingOperation == "deposit" and t("deposit_asset") or t("withdraw_asset")) .. " | " .. (quote and quote.name or "-"), panelW - 6), theme.text, theme.card)
	writeAt(panelX + 3, panelY + 6, trimText(t("quantity") .. ": " .. tostring(state.pendingQuantity), panelW - 6), theme.accent, theme.card)

	local keypadX = panelX + 3
	local keypadY = panelY + 10
	local keyW = 8
	local gap = 2
	local labels = {
		{"1", "2", "3"},
		{"4", "5", "6"},
		{"7", "8", "9"},
		{t("clear"), "0", t("confirm")}
	}

	for row = 1, #labels do
		for col = 1, #labels[row] do
			local label = labels[row][col]
			local id = "qty:" .. label
			local bg = theme.cardDark
			local fg = theme.text
			if (label == t("confirm")) then
				bg = theme.success
				fg = theme.successText
			elseif (label == t("clear")) then
				bg = theme.warning
				fg = theme.warningText
			end
			roundedButton(id, keypadX + ((col - 1) * (keyW + gap)), keypadY + ((row - 1) * 5), keyW, label, bg, fg)
		end
	end

	roundedButton("market", 4, height - 4, 13, t("back"), theme.primary, theme.primaryText)
end

local function drawHelpPage()
	clear()
	state.buttons = {}
	drawHeader()

	local shell = drawMainShell("help", theme.warning)
	local panelX = shell.contentX
	local panelY = shell.contentY
	local panelW = shell.contentW
	local panelH = shell.contentH

	local y = panelY + 3
	for _, lineText in ipairs(localization[lang].help_lines) do
		if (y >= panelY + panelH - 4) then
			break
		end
		writeAt(panelX + 2, y, trimText(lineText, panelW - 4), theme.text, theme.card)
		y = y + 2
	end

	roundedButton("home", 4, height - 4, 13, t("back"), theme.primary, theme.primaryText)
	roundedButton("sleep", width - 16, height - 4, 13, t("sleep"), theme.danger, theme.dangerText)
end

local function redraw()
	if (state.page == "sleep") then
		drawSleepPage()
	elseif (state.page == "register") then
		drawRegisterPage()
	elseif (state.page == "account") then
		drawAccountPage()
	elseif (state.page == "market") then
		drawMarketPage()
	elseif (state.page == "quantity") then
		drawQuantityPage()
	elseif (state.page == "help") then
		drawHelpPage()
	else
		drawHomePage()
	end
	box.render()
end

local function createAccount()
	if (state.currentPlayer == nil) then
		return
	end
	local ok, success, response = pcall(bankapi.newAccountForPlayer, state.currentPlayer, state.currentPlayer, colorFromName(state.currentPlayer))
	if (ok and success and response ~= nil) then
		sendPlayerMessage(state.currentPlayer, t("register_chat_1") .. tostring(response.key) .. t("register_chat_2"))
		refreshPlayerAndAccount()
		state.page = "account"
	end
	redraw()
end

local function resetFlashMessage()
	state.flashMessage = nil
end

local function setFlashMessage(text, success)
	state.flashMessage = {
		text = text,
		success = success == true
	}
end

local function executeDepositOperation(quote, quantity)
	local depositInventory = getInventory(inventoryConfig.depositPeripheral)
	local vaultInventory = getInventory(inventoryConfig.vaultPeripheral)
	local depositName = getInventoryName(inventoryConfig.depositPeripheral)
	local vaultName = getInventoryName(inventoryConfig.vaultPeripheral)

	if (depositInventory == nil or vaultInventory == nil or depositName == nil or vaultName == nil) then
		return false, t("error_missing_inventory")
	end

	local moved = moveMatchingItems(depositInventory, vaultName, quote, quantity)
	if (moved <= 0) then
		return false, t("error_missing_items")
	end

	local success, message = bankapi.depositAsset(state.accountKey, quote.id, moved)
	if (not success) then
		moveMatchingItems(vaultInventory, depositName, quote, moved)
		return false, message or t("operation_error")
	end

	return true, (message or t("operation_done")) .. " x" .. tostring(moved)
end

local function executeWithdrawOperation(quote, quantity)
	local vaultInventory = getInventory(inventoryConfig.vaultPeripheral)
	local outputInventory = getInventory(inventoryConfig.outputPeripheral)
	local vaultName = getInventoryName(inventoryConfig.vaultPeripheral)
	local outputName = getInventoryName(inventoryConfig.outputPeripheral)

	if (vaultInventory == nil or outputInventory == nil or vaultName == nil or outputName == nil) then
		return false, t("error_missing_inventory")
	end
	if (quantity > (quote.maxWithdraw or 0)) then
		return false, t("error_asset_stock")
	end
	if (state.account == nil or tonumber(state.account.balance or 0) < (tonumber(quote.withdrawPrice or 0) * quantity)) then
		return false, t("error_notenoughbalance")
	end
	if (countMatchingItems(vaultInventory, quote) < quantity) then
		return false, t("error_vault_blocked")
	end

	local moved = moveMatchingItems(vaultInventory, outputName, quote, quantity)
	if (moved <= 0) then
		return false, t("error_output_blocked")
	end
	if (moved < quantity) then
		moveMatchingItems(outputInventory, vaultName, quote, moved)
		return false, t("error_partial_move")
	end

	local success, message = bankapi.withdrawAsset(state.accountKey, quote.id, quantity)
	if (not success) then
		moveMatchingItems(outputInventory, vaultName, quote, quantity)
		return false, message or t("operation_error")
	end

	return true, (message or t("operation_done")) .. " x" .. tostring(quantity)
end

local function performPendingOperation()
	local quote = selectedQuote()
	local quantity = tonumber(state.pendingQuantity)
	if (state.accountKey == nil or quote == nil or quantity == nil or quantity <= 0) then
		setFlashMessage(t("operation_error"), false)
		state.page = "market"
		redraw()
		return
	end

	local success, message
	if (state.pendingOperation == "deposit") then
		success, message = executeDepositOperation(quote, quantity)
	else
		success, message = executeWithdrawOperation(quote, quantity)
	end

	refreshPlayerAndAccount()
	refreshQuotes()
	setFlashMessage(message or (success and t("operation_done") or t("operation_error")), success)
	state.pendingOperation = nil
	state.pendingQuantity = "1"
	state.page = "market"
	redraw()
end

local function handleAction(action)
	if (action == nil) then
		return
	end
	resetFlashMessage()
	if (action == "wake") then
		state.page = "home"
	elseif (action == "sleep") then
		state.page = "sleep"
	elseif (action == "home") then
		state.page = "home"
	elseif (action == "register") then
		state.page = "register"
	elseif (action == "register_confirm") then
		createAccount()
		return
	elseif (action == "account") then
		state.page = "account"
	elseif (action == "market") then
		state.page = "market"
	elseif (action == "help") then
		state.page = "help"
	elseif (action == "deposit_asset") then
		state.pendingOperation = "deposit"
		state.pendingQuantity = "1"
		state.page = "quantity"
	elseif (action == "withdraw_asset") then
		state.pendingOperation = "withdraw"
		state.pendingQuantity = "1"
		state.page = "quantity"
	elseif (string.sub(action, 1, 6) == "asset:") then
		state.selectedAsset = string.sub(action, 7)
		state.page = "market"
	elseif (string.sub(action, 1, 4) == "qty:") then
		local value = string.sub(action, 5)
		if (value == t("clear")) then
			state.pendingQuantity = "1"
		elseif (value == t("confirm")) then
			performPendingOperation()
			return
		else
			if (state.pendingQuantity == "1") then
				state.pendingQuantity = value
			else
				state.pendingQuantity = string.sub(state.pendingQuantity .. value, 1, 4)
			end
		end
	end
	redraw()
end

refreshPlayerAndAccount()
refreshQuotes()
redraw()

local playerTimer = os.startTimer(2)
local quoteTimer = os.startTimer(8)

while true do
	local eventData = {os.pullEvent()}
	local event = eventData[1]

	if (event == "monitor_touch" and eventData[2] == monitorSide) then
		handleAction(hitButton(eventData[3], eventData[4]))
	elseif (event == "timer") then
		if (eventData[2] == playerTimer) then
			refreshPlayerAndAccount()
			if (state.page ~= "sleep") then
				redraw()
			end
			playerTimer = os.startTimer(2)
		elseif (eventData[2] == quoteTimer) then
			refreshQuotes()
			if (state.page == "market" or state.page == "home" or state.page == "account") then
				redraw()
			end
			quoteTimer = os.startTimer(8)
		end
	end
end
