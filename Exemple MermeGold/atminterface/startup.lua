-- Atlas Bank Kiosk Monitor

os.loadAPI("bankapi.lua")

local monitor = peripheral.find("monitor")
local chatBox = peripheral.wrap("left")
local playerDetector = peripheral.wrap("right")

local function hasMethod(object, methodName)
	return object ~= nil and type(object[methodName]) == "function"
end

if (monitor == nil) then
	error("Un monitor est requis pour utiliser le kiosque Atlas Bank.")
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
		term.setCursorPos(1,1)
		print("Modem requis. Connectez un modem pour continuer...")
		os.pullEvent("peripheral")
	end
end

peripheral.find("modem", rednet.open)
monitor.setTextScale(0.5)

local monitorSide = peripheral.getName(monitor)
local serverData = bankapi.getServerData()
local lang = serverData.lang or "fr"

local localization = {
	fr = {
		sleep_title = "ATLAS BANK",
		sleep_hint = "Clic droit pour utiliser ou sortir de veille",
		detect = "Approchez-vous du detecteur joueur a droite",
		no_account = "Aucun compte Atlas Bank detecte",
		create_account = "Creer mon compte",
		my_account = "Mon compte",
		market = "Marche",
		help = "Aide",
		sleep = "Veille",
		back = "Retour",
		register_title = "Creation de compte",
		register_desc = "Le kiosque utilise le player detector a droite pour reconnaitre automatiquement le joueur proche.",
		register_ready = "Joueur detecte",
		register_button = "Ouvrir mon compte",
		register_success = "Compte cree avec succes",
		register_chat = "Votre compte Atlas Bank a ete cree. Cle du compte : ",
		register_chat_2 = " Approchez-vous du kiosque pour consulter votre solde.",
		register_error = "Impossible de creer le compte",
		account_title = "Tableau de bord",
		player = "Joueur",
		account_key = "Cle",
		balance = "Solde",
		status = "Statut",
		status_online = "Connecte au kiosque",
		status_idle = "En attente",
		refresh = "Actualiser",
		account_missing = "Aucun joueur unique detecte a droite",
		market_title = "Cours du marche",
		market_live = "Flux en direct",
		market_empty = "Aucun actif charge",
		buy_price = "Achat banque",
		sell_price = "Retrait banque",
		stock = "Reserve",
		withdraw_max = "Retrait max",
		detail = "Detail actif",
		help_title = "Guide du kiosque",
		help_lines = {
			"1. Placez-vous a droite du kiosque pour etre detecte.",
			"2. Si vous n'avez pas de compte, utilisez le bouton de creation.",
			"3. Le kiosque affiche ensuite votre solde et les cours du marche.",
			"4. Utilisez la page Marche pour consulter les actifs et leur evolution.",
			"5. Utilisez le bouton Veille pour revenir a l'ecran d'accueil."
		},
		nearby = "Joueur detecte",
		no_player = "Aucun joueur detecte",
		market_sub = "Selectionnez un actif pour voir son detail",
		graph = "Graphique",
		wait = "Connexion au serveur bancaire...",
		assist = "Besoin d'aide ? Ouvrez la page Aide.",
		chat_prefix = "Atlas Bank"
	},
	en = {
		sleep_title = "ATLAS BANK",
		sleep_hint = "Right click to use or leave standby",
		detect = "Stand near the player detector on the right",
		no_account = "No Atlas Bank account detected",
		create_account = "Create my account",
		my_account = "My account",
		market = "Market",
		help = "Help",
		sleep = "Sleep",
		back = "Back",
		register_title = "Account creation",
		register_desc = "The kiosk uses the player detector on the right to identify the nearby player automatically.",
		register_ready = "Detected player",
		register_button = "Open my account",
		register_success = "Account created successfully",
		register_chat = "Your Atlas Bank account has been created. Account key: ",
		register_chat_2 = " Walk up to the kiosk to see your balance.",
		register_error = "Unable to create account",
		account_title = "Dashboard",
		player = "Player",
		account_key = "Key",
		balance = "Balance",
		status = "Status",
		status_online = "Connected to kiosk",
		status_idle = "Idle",
		refresh = "Refresh",
		account_missing = "No single player detected on the right",
		market_title = "Market rates",
		market_live = "Live feed",
		market_empty = "No assets loaded",
		buy_price = "Bank buy",
		sell_price = "Withdrawal",
		stock = "Reserve",
		withdraw_max = "Max withdraw",
		detail = "Asset detail",
		help_title = "Kiosk guide",
		help_lines = {
			"1. Stand on the right side of the kiosk to be detected.",
			"2. If you do not have an account yet, use account creation.",
			"3. The kiosk then shows your balance and the market rates.",
			"4. Use the Market page to inspect assets and their live movement.",
			"5. Use the Sleep button to return to the standby screen."
		},
		nearby = "Detected player",
		no_player = "No detected player",
		market_sub = "Select an asset to see details",
		graph = "Graph",
		wait = "Connecting to bank server...",
		assist = "Need help? Open the Help page.",
		chat_prefix = "Atlas Bank"
	}
}

local palette = {
	bg = colors.black,
	header = colors.lightGray,
	panel = colors.gray,
	panel2 = colors.white,
	text = colors.white,
	sub = colors.lightGray,
	darkText = colors.black,
	accent = colors.lightBlue,
	success = colors.lime,
	danger = colors.red,
	card = colors.gray,
	cardAlt = colors.black,
	cardHeader = colors.lightGray,
	muted = colors.gray
}

local state = {
	page = "sleep",
	currentPlayer = nil,
	accountKey = nil,
	account = nil,
	quotes = {},
	selectedAsset = nil,
	buttons = {},
	history = {},
	lastMessage = nil,
	lastMessageAt = 0
}

local function t(key)
	return localization[lang][key] or key
end

local function mSize()
	return monitor.getSize()
end

local function clear(color)
	monitor.setBackgroundColor(color or palette.bg)
	monitor.clear()
	monitor.setCursorPos(1,1)
end

local function fill(x, y, w, h, color)
	monitor.setBackgroundColor(color)
	for row=y, y+h-1 do
		monitor.setCursorPos(x, row)
		monitor.write(string.rep(" ", math.max(0, w)))
	end
end

local function line(x, y, w, color)
	fill(x, y, w, 1, color)
end

local function centerText(y, text, textColor, bgColor)
	local w = select(1, mSize())
	monitor.setBackgroundColor(bgColor or palette.bg)
	monitor.setTextColor(textColor or palette.text)
	monitor.setCursorPos(math.max(1, math.floor((w - #text) / 2) + 1), y)
	monitor.write(text)
end

local function writeAt(x, y, text, textColor, bgColor)
	monitor.setBackgroundColor(bgColor or palette.bg)
	monitor.setTextColor(textColor or palette.text)
	monitor.setCursorPos(x, y)
	monitor.write(text)
end

local function drawCard(x, y, w, h, title, subtitle)
	fill(x, y, w, h, palette.card)
	line(x, y, w, palette.cardHeader)
	if (title ~= nil and title ~= "") then
		writeAt(x + 2, y, title, palette.darkText, palette.cardHeader)
	end
	if (subtitle ~= nil and subtitle ~= "") then
		writeAt(x + 2, y + 1, subtitle, palette.sub, palette.card)
	end
end

local function drawPill(x, y, w, label, bg, fg, id)
	w = math.max(8, w)
	fill(x + 1, y, w - 2, 1, bg)
	fill(x, y + 1, w, 1, bg)
	fill(x + 1, y + 2, w - 2, 1, bg)
	writeAt(math.floor(x + (w - #label) / 2), y + 1, label, fg, bg)
	if (id ~= nil) then
		table.insert(state.buttons, {id=id, x=x, y=y, w=w, h=3})
	end
end

local function drawHeader(title, subtitle)
	local w = select(1, mSize())
	fill(1, 1, w, 4, palette.bg)
	fill(3, 2, w - 4, 1, palette.header)
	centerText(2, title, palette.darkText, palette.header)
	if (subtitle ~= nil and subtitle ~= "") then
		centerText(3, subtitle, palette.sub, palette.bg)
	end
	line(3, 4, w - 4, palette.muted)
end

local function drawPanel(x, y, w, h, title)
	drawCard(x, y, w, h, title)
end

local function sendPlayerMessage(playerName, text)
	if (playerName == nil) then return end
	pcall(function()
		chatBox.sendMessageToPlayer(text, playerName, t("chat_prefix"), "<>")
	end)
end

local function listLength(tbl)
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
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
	if (not ok or result == nil) then
		return nil
	end
	if (#result ~= 1) then
		return nil
	end
	return normalizePlayerEntry(result[1])
end

local function colorFromName(name)
	local colorsList = {colors.cyan, colors.blue, colors.green, colors.orange, colors.magenta, colors.yellow}
	local sum = 0
	for i=1, string.len(name) do
		sum = sum + string.byte(name, i)
	end
	return colorsList[(sum % #colorsList)+1]
end

local function updatePlayerAccount()
	state.currentPlayer = detectPlayer()
	state.account = nil
	state.accountKey = nil
	if (state.currentPlayer ~= nil) then
		local success, response = bankapi.getAccountByPlayer(state.currentPlayer)
		if (success and response ~= nil) then
			state.accountKey = response.key
			state.account = response.account
		end
	end
end

local function updateQuotes()
	local quotes = bankapi.getAssetQuotes()
	state.quotes = quotes or {}
	for _, quote in ipairs(state.quotes) do
		state.history[quote.id] = state.history[quote.id] or {}
		local history = state.history[quote.id]
		table.insert(history, quote.depositPrice)
		if (#history > 24) then
			table.remove(history, 1)
		end
	end
	if (state.selectedAsset == nil and #state.quotes > 0) then
		state.selectedAsset = state.quotes[1].id
	end
end

local function getSelectedQuote()
	for _, quote in ipairs(state.quotes) do
		if (quote.id == state.selectedAsset) then
			return quote
		end
	end
	if (#state.quotes > 0) then
		return state.quotes[1]
	end
	return nil
end

local function sparkline(x, y, w, values)
	if (values == nil or #values <= 1) then
		writeAt(x, y, "-", palette.sub, palette.panel)
		return
	end

	local minV = values[1]
	local maxV = values[1]
	for _, v in ipairs(values) do
		if (v < minV) then minV = v end
		if (v > maxV) then maxV = v end
	end

	local chars = {"_", ".", "-", "*", "#"}
	local text = ""
	for i=1, math.min(w, #values) do
		local v = values[#values - math.min(w, #values) + i]
		local index = 1
		if (maxV > minV) then
			index = math.floor(((v-minV) / (maxV-minV)) * (#chars-1)) + 1
		end
		text = text .. chars[index]
	end
	writeAt(x, y, text, palette.accent, palette.card)
end

local function drawSleep()
	clear(palette.bg)
	local w, h = mSize()
	drawCard(math.max(3, math.floor(w / 2) - 18), math.max(4, math.floor(h / 2) - 5), 36, 10, "", "")
	centerText(math.max(5, math.floor(h/2)-2), t("sleep_title"), palette.text, palette.card)
	centerText(math.max(7, math.floor(h/2)), t("sleep_hint"), palette.sub, palette.card)
	centerText(math.max(9, math.floor(h/2)+2), t("detect"), palette.accent, palette.card)
	state.buttons = {
		{id="wake", x=1, y=1, w=w, h=h}
	}
end

local function drawHome()
	clear(palette.bg)
	state.buttons = {}
	local subtitle = state.currentPlayer and (t("nearby")..": "..state.currentPlayer) or t("no_player")
	drawHeader(serverData.bankName or "Atlas Bank", subtitle)

	local w, h = mSize()
	drawPanel(3, 6, w-4, 7, serverData.bankName or "Atlas Bank")
	if (state.account ~= nil) then
		writeAt(6, 8, t("balance")..": "..tostring(state.account.balance).." "..(serverData.currencyLabel or "Credits"), palette.text, palette.card)
		writeAt(6, 9, t("account_key")..": "..state.accountKey, palette.sub, palette.card)
		writeAt(6, 10, t("assist"), palette.sub, palette.card)
		local primaryWidth = math.max(18, math.floor((w - 16) / 2))
		drawPill(6, 15, primaryWidth, t("my_account"), palette.success, colors.black, "account")
		drawPill(8 + primaryWidth, 15, primaryWidth, t("market"), palette.panel2, colors.black, "market")
	else
		writeAt(6, 8, t("no_account"), palette.text, palette.card)
		writeAt(6, 9, t("register_desc"), palette.sub, palette.card)
		writeAt(6, 10, t("assist"), palette.sub, palette.card)
		local primaryWidth = math.max(18, math.floor((w - 16) / 2))
		drawPill(6, 15, primaryWidth, t("create_account"), palette.success, colors.black, "register")
		drawPill(8 + primaryWidth, 15, primaryWidth, t("market"), palette.panel2, colors.black, "market")
	end

	drawPill(4, h-4, 12, t("help"), palette.panel2, colors.black, "help")
	drawPill(w-15, h-4, 12, t("sleep"), palette.danger, colors.white, "sleep")
end

local function drawRegister()
	clear(palette.bg)
	state.buttons = {}
	drawHeader(t("register_title"), state.currentPlayer or t("no_player"))
	local w, h = mSize()
	drawPanel(3, 6, w-4, 9, t("register_title"))
	writeAt(6, 8, t("register_desc"), palette.text, palette.card)
	if (state.currentPlayer ~= nil) then
		writeAt(6, 10, t("register_ready")..": "..state.currentPlayer, palette.accent, palette.card)
		drawPill(6, 15, w-12, t("register_button"), palette.success, colors.black, "register_confirm")
	else
		writeAt(6, 10, t("account_missing"), palette.sub, palette.card)
	end
	drawPill(4, h-4, 12, t("back"), palette.panel2, colors.black, "home")
	drawPill(w-15, h-4, 12, t("help"), palette.panel2, colors.black, "help")
end

local function drawAccount()
	clear(palette.bg)
	state.buttons = {}
	drawHeader(t("account_title"), state.currentPlayer or "")
	local w, h = mSize()
	drawPanel(3, 6, w-4, 10, t("my_account"))
	if (state.account == nil) then
		writeAt(6, 9, t("account_missing"), palette.sub, palette.card)
	else
		writeAt(6, 8, t("player")..": "..(state.account.playerName or state.currentPlayer or "?"), palette.text, palette.card)
		writeAt(6, 9, t("account_key")..": "..state.accountKey, palette.text, palette.card)
		writeAt(6, 10, t("balance")..": "..tostring(state.account.balance).." "..(serverData.currencyLabel or "Credits"), palette.accent, palette.card)
		writeAt(6, 11, t("status")..": "..t("status_online"), palette.sub, palette.card)
		writeAt(6, 12, serverData.bankName or "Atlas Bank", palette.sub, palette.card)
	end
	drawPill(4, h-4, 12, t("back"), palette.panel2, colors.black, "home")
	drawPill(18, h-4, 14, t("market"), palette.success, colors.black, "market")
	drawPill(w-15, h-4, 12, t("help"), palette.panel2, colors.black, "help")
end

local function drawMarket()
	clear(palette.bg)
	state.buttons = {}
	drawHeader(t("market_title"), t("market_live"))
	local w, h = mSize()
	drawPanel(3, 6, w-4, h-11, t("market_sub"))
	if (#state.quotes == 0) then
		writeAt(6, 9, t("market_empty"), palette.sub, palette.card)
	else
		local y = 8
		for _, quote in ipairs(state.quotes) do
			if (y > h-8) then break end
			local bg = (quote.id == state.selectedAsset) and palette.panel2 or palette.card
			fill(6, y, w-10, 3, bg)
			writeAt(8, y, quote.name, (quote.id == state.selectedAsset) and colors.black or palette.text, bg)
			writeAt(8, y + 1, t("buy_price")..": "..quote.depositPrice, (quote.id == state.selectedAsset) and colors.black or palette.sub, bg)
			writeAt(math.floor(w / 2), y + 1, t("sell_price")..": "..quote.withdrawPrice, (quote.id == state.selectedAsset) and colors.black or palette.sub, bg)
			table.insert(state.buttons, {id="asset:"..quote.id, x=6, y=y, w=w-10, h=3})
			y = y + 4
		end
	end
	drawPill(4, h-4, 12, t("back"), palette.panel2, colors.black, "home")
	drawPill(w-15, h-4, 12, t("detail"), palette.success, colors.black, "asset_detail")
end

local function drawAssetDetail()
	clear(palette.bg)
	state.buttons = {}
	local quote = getSelectedQuote()
	drawHeader(t("detail"), quote and quote.name or "")
	local w, h = mSize()
	drawPanel(3, 6, w-4, h-11, quote and quote.name or t("market_empty"))
	if (quote ~= nil) then
		writeAt(6, 8, t("buy_price")..": "..quote.depositPrice.." "..(serverData.currencyLabel or "Credits"), palette.text, palette.card)
		writeAt(6, 9, t("sell_price")..": "..quote.withdrawPrice.." "..(serverData.currencyLabel or "Credits"), palette.text, palette.card)
		writeAt(6, 10, t("stock")..": "..quote.stock, palette.sub, palette.card)
		writeAt(6, 11, t("withdraw_max")..": "..quote.maxWithdraw, palette.sub, palette.card)
		writeAt(6, 13, t("graph"), palette.text, palette.card)
		sparkline(6, 14, math.max(10, w-12), state.history[quote.id] or {})
	end
	drawPill(4, h-4, 12, t("back"), palette.panel2, colors.black, "market")
	drawPill(w-15, h-4, 12, t("help"), palette.panel2, colors.black, "help")
end

local function drawHelp()
	clear(palette.bg)
	state.buttons = {}
	drawHeader(t("help_title"), serverData.bankName or "Atlas Bank")
	local w, h = mSize()
	drawPanel(3, 6, w-4, h-11, t("help_title"))
	local y = 8
	for _, line in ipairs(localization[lang].help_lines) do
		if (y > h-8) then break end
		writeAt(6, y, line, palette.text, palette.card)
		y = y + 2
	end
	drawPill(4, h-4, 12, t("back"), palette.panel2, colors.black, "home")
	drawPill(w-15, h-4, 12, t("sleep"), palette.danger, colors.white, "sleep")
end

local function drawCurrentPage()
	if (state.page == "sleep") then
		drawSleep()
	elseif (state.page == "register") then
		drawRegister()
	elseif (state.page == "account") then
		drawAccount()
	elseif (state.page == "market") then
		drawMarket()
	elseif (state.page == "asset_detail") then
		drawAssetDetail()
	elseif (state.page == "help") then
		drawHelp()
	else
		drawHome()
	end
end

local function hitButton(x, y)
	for _, button in ipairs(state.buttons) do
		if (x >= button.x and x < button.x + button.w and y >= button.y and y < button.y + button.h) then
			return button.id
		end
	end
	return nil
end

local function createAccountForCurrentPlayer()
	if (state.currentPlayer == nil) then
		state.lastMessage = t("account_missing")
		state.lastMessageAt = os.clock()
		return
	end

	local success, response = bankapi.newAccountForPlayer(state.currentPlayer, state.currentPlayer, colorFromName(state.currentPlayer))
	if (success and response ~= nil) then
		sendPlayerMessage(state.currentPlayer, t("register_chat")..response.key..t("register_chat_2"))
		updatePlayerAccount()
		state.page = "account"
	else
		state.lastMessage = t("register_error")
		state.lastMessageAt = os.clock()
	end
end

local function handleAction(action)
	if (action == nil) then return end
	if (action == "wake") then
		state.page = "home"
	elseif (action == "sleep") then
		state.page = "sleep"
	elseif (action == "home") then
		state.page = "home"
	elseif (action == "register") then
		state.page = "register"
	elseif (action == "register_confirm") then
		createAccountForCurrentPlayer()
	elseif (action == "account") then
		state.page = "account"
	elseif (action == "market") then
		state.page = "market"
	elseif (action == "asset_detail") then
		state.page = "asset_detail"
	elseif (action == "help") then
		state.page = "help"
	elseif (string.sub(action, 1, 6) == "asset:") then
		state.selectedAsset = string.sub(action, 7)
		state.page = "asset_detail"
	end
end

local function bootScreen()
	clear(palette.bg)
	centerText(3, t("wait"), palette.text, palette.bg)
	sleep(1)
end

bootScreen()
updatePlayerAccount()
updateQuotes()
drawCurrentPage()

local playerTimer = os.startTimer(2)
local quoteTimer = os.startTimer(8)

while true do
	local eventData = {os.pullEvent()}
	local event = eventData[1]

	if (event == "monitor_touch" and eventData[2] == monitorSide) then
		local x = eventData[3]
		local y = eventData[4]
		local action = hitButton(x, y)
		handleAction(action)
		drawCurrentPage()
	elseif (event == "timer") then
		if (eventData[2] == playerTimer) then
			updatePlayerAccount()
			if (state.page == "home" or state.page == "register" or state.page == "account") then
				drawCurrentPage()
			end
			playerTimer = os.startTimer(2)
		elseif (eventData[2] == quoteTimer) then
			updateQuotes()
			if (state.page == "market" or state.page == "asset_detail" or state.page == "home") then
				drawCurrentPage()
			end
			quoteTimer = os.startTimer(8)
		end
	elseif (event == "peripheral" or event == "peripheral_detach") then
		if (state.page ~= "sleep") then
			drawCurrentPage()
		end
	end
end
