-- Atlas Bank Kiosk Monitor

os.loadAPI("bankapi.lua")

local monitor = peripheral.find("monitor")
local chatBox = peripheral.wrap("left")
local playerDetector = peripheral.wrap("right")

local function isPlayerDetector(side)
	local pType = peripheral.getType(side)
	return pType == "playerDetector" or pType == "player_detector"
end

local function isChatBox(side)
	local pType = peripheral.getType(side)
	return pType == "chatBox" or pType == "chat_box"
end

if (monitor == nil) then
	error("Un monitor est requis pour utiliser le kiosque Atlas Bank.")
end
if (chatBox == nil or not isChatBox("left")) then
	error("Une Chat Box Advanced Peripherals doit etre placee a gauche de l'ordinateur.")
end
if (playerDetector == nil or not isPlayerDetector("right")) then
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
	header = colors.black,
	panel = colors.gray,
	panel2 = colors.lightGray,
	text = colors.white,
	sub = colors.lightGray,
	accent = colors.cyan,
	success = colors.green,
	danger = colors.red,
	card = colors.gray,
	cardAlt = colors.black
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

local function drawPill(x, y, w, label, bg, fg, id)
	fill(x, y, w, 1, bg)
	writeAt(math.floor(x + (w - #label) / 2), y, label, fg, bg)
	if (id ~= nil) then
		table.insert(state.buttons, {id=id, x=x, y=y, w=w, h=1})
	end
end

local function drawHeader(title, subtitle)
	local w = select(1, mSize())
	fill(1, 1, w, 3, palette.header)
	centerText(1, title, palette.text, palette.header)
	if (subtitle ~= nil and subtitle ~= "") then
		centerText(2, subtitle, palette.sub, palette.header)
	end
	fill(1, 3, w, 1, colors.gray)
end

local function drawPanel(x, y, w, h, title)
	fill(x, y, w, h, palette.panel)
	fill(x, y, w, 1, palette.panel2)
	writeAt(x+2, y, title or "", colors.black, palette.panel2)
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
	writeAt(x, y, text, palette.accent, palette.panel)
end

local function drawSleep()
	clear(palette.bg)
	local w, h = mSize()
	centerText(math.max(3, math.floor(h/2)-2), t("sleep_title"), palette.text, palette.bg)
	centerText(math.max(4, math.floor(h/2)), t("sleep_hint"), palette.sub, palette.bg)
	centerText(math.max(5, math.floor(h/2)+2), t("detect"), palette.sub, palette.bg)
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
	drawPanel(2, 5, w-2, 6, serverData.bankName or "Atlas Bank")
	if (state.account ~= nil) then
		writeAt(4, 7, t("balance")..": "..tostring(state.account.balance).." "..(serverData.currencyLabel or "Credits"), palette.text, palette.panel)
		writeAt(4, 8, t("account_key")..": "..state.accountKey, palette.sub, palette.panel)
		writeAt(4, 9, t("assist"), palette.sub, palette.panel)
		drawPill(4, 12, math.max(16, math.floor((w-10)/2)), t("my_account"), palette.success, colors.white, "account")
		drawPill(6 + math.max(16, math.floor((w-10)/2)), 12, math.max(16, math.floor((w-10)/2)), t("market"), palette.panel2, colors.black, "market")
	else
		writeAt(4, 7, t("no_account"), palette.text, palette.panel)
		writeAt(4, 8, t("register_desc"), palette.sub, palette.panel)
		writeAt(4, 9, t("assist"), palette.sub, palette.panel)
		drawPill(4, 12, math.max(18, math.floor((w-10)/2)), t("create_account"), palette.success, colors.white, "register")
		drawPill(6 + math.max(18, math.floor((w-10)/2)), 12, math.max(14, math.floor((w-10)/2)-2), t("market"), palette.panel2, colors.black, "market")
	end

	drawPill(4, h-2, 12, t("help"), palette.panel2, colors.black, "help")
	drawPill(w-15, h-2, 12, t("sleep"), palette.danger, colors.white, "sleep")
end

local function drawRegister()
	clear(palette.bg)
	state.buttons = {}
	drawHeader(t("register_title"), state.currentPlayer or t("no_player"))
	local w, h = mSize()
	drawPanel(2, 5, w-2, 8, t("register_title"))
	writeAt(4, 7, t("register_desc"), palette.text, palette.panel)
	if (state.currentPlayer ~= nil) then
		writeAt(4, 9, t("register_ready")..": "..state.currentPlayer, palette.accent, palette.panel)
		drawPill(4, 13, w-8, t("register_button"), palette.success, colors.white, "register_confirm")
	else
		writeAt(4, 9, t("account_missing"), palette.sub, palette.panel)
	end
	drawPill(4, h-2, 12, t("back"), palette.panel2, colors.black, "home")
	drawPill(w-15, h-2, 12, t("help"), palette.panel2, colors.black, "help")
end

local function drawAccount()
	clear(palette.bg)
	state.buttons = {}
	drawHeader(t("account_title"), state.currentPlayer or "")
	local w, h = mSize()
	drawPanel(2, 5, w-2, 9, t("my_account"))
	if (state.account == nil) then
		writeAt(4, 8, t("account_missing"), palette.sub, palette.panel)
	else
		writeAt(4, 7, t("player")..": "..(state.account.playerName or state.currentPlayer or "?"), palette.text, palette.panel)
		writeAt(4, 8, t("account_key")..": "..state.accountKey, palette.text, palette.panel)
		writeAt(4, 9, t("balance")..": "..tostring(state.account.balance).." "..(serverData.currencyLabel or "Credits"), palette.accent, palette.panel)
		writeAt(4, 10, t("status")..": "..t("status_online"), palette.sub, palette.panel)
		writeAt(4, 11, serverData.bankName or "Atlas Bank", palette.sub, palette.panel)
	end
	drawPill(4, 15, 14, t("back"), palette.panel2, colors.black, "home")
	drawPill(20, 15, 16, t("market"), palette.success, colors.white, "market")
	drawPill(w-15, 15, 12, t("help"), palette.panel2, colors.black, "help")
end

local function drawMarket()
	clear(palette.bg)
	state.buttons = {}
	drawHeader(t("market_title"), t("market_live"))
	local w, h = mSize()
	drawPanel(2, 5, w-2, h-8, t("market_sub"))
	if (#state.quotes == 0) then
		writeAt(4, 8, t("market_empty"), palette.sub, palette.panel)
	else
		local y = 7
		for index, quote in ipairs(state.quotes) do
			if (y > h-5) then break end
			local bg = (quote.id == state.selectedAsset) and palette.panel2 or palette.panel
			fill(4, y, w-6, 2, bg)
			writeAt(5, y, quote.name, (quote.id == state.selectedAsset) and colors.black or palette.text, bg)
			writeAt(5, y+1, t("buy_price")..": "..quote.depositPrice.."  "..t("sell_price")..": "..quote.withdrawPrice, (quote.id == state.selectedAsset) and colors.black or palette.sub, bg)
			table.insert(state.buttons, {id="asset:"..quote.id, x=4, y=y, w=w-6, h=2})
			y = y + 3
		end
	end
	drawPill(4, h-2, 12, t("back"), palette.panel2, colors.black, "home")
	drawPill(w-15, h-2, 12, t("detail"), palette.success, colors.white, "asset_detail")
end

local function drawAssetDetail()
	clear(palette.bg)
	state.buttons = {}
	local quote = getSelectedQuote()
	drawHeader(t("detail"), quote and quote.name or "")
	local w, h = mSize()
	drawPanel(2, 5, w-2, h-8, quote and quote.name or t("market_empty"))
	if (quote ~= nil) then
		writeAt(4, 7, t("buy_price")..": "..quote.depositPrice.." "..(serverData.currencyLabel or "Credits"), palette.text, palette.panel)
		writeAt(4, 8, t("sell_price")..": "..quote.withdrawPrice.." "..(serverData.currencyLabel or "Credits"), palette.text, palette.panel)
		writeAt(4, 9, t("stock")..": "..quote.stock, palette.sub, palette.panel)
		writeAt(4, 10, t("withdraw_max")..": "..quote.maxWithdraw, palette.sub, palette.panel)
		writeAt(4, 12, t("graph"), palette.text, palette.panel)
		sparkline(4, 13, math.max(10, w-8), state.history[quote.id] or {})
	end
	drawPill(4, h-2, 12, t("back"), palette.panel2, colors.black, "market")
	drawPill(w-15, h-2, 12, t("help"), palette.panel2, colors.black, "help")
end

local function drawHelp()
	clear(palette.bg)
	state.buttons = {}
	drawHeader(t("help_title"), serverData.bankName or "Atlas Bank")
	local w, h = mSize()
	drawPanel(2, 5, w-2, h-8, t("help_title"))
	local y = 7
	for _, line in ipairs(localization[lang].help_lines) do
		if (y > h-4) then break end
		writeAt(4, y, line, palette.text, palette.panel)
		y = y + 2
	end
	drawPill(4, h-2, 12, t("back"), palette.panel2, colors.black, "home")
	drawPill(w-15, h-2, 12, t("sleep"), palette.danger, colors.white, "sleep")
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
