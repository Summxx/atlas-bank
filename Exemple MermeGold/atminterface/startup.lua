-- Atlas Bank PixelUI Kiosk

os.loadAPI("bankapi.lua")

local pixelui = require("pixelui")

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

local width, height = monitor.getSize()
local viewport = window.create(monitor, 1, 1, width, height, true)

local serverData = bankapi.getServerData()
local lang = serverData.lang or "fr"

local localization = {
	fr = {
		sleep_title = "ATLAS BANK",
		sleep_subtitle = "Kiosque bancaire prive",
		sleep_hint = "Clic droit sur l'ecran pour utiliser le kiosque",
		sleep_detail = "Touchez l'ecran pour sortir du mode veille",
		home_title = "Tableau de bord",
		no_player = "Aucun joueur detecte",
		detected = "Joueur detecte",
		no_account = "Aucun compte bancaire detecte",
		account_found = "Compte Atlas Bank actif",
		create_account = "Creer mon compte",
		open_account = "Mon compte",
		market = "Marche",
		help = "Aide",
		sleep = "Veille",
		back = "Retour",
		register_title = "Creation de compte",
		register_text = "Le Player Detector a droite reconnait automatiquement le joueur proche.",
		register_ready = "Pret a ouvrir votre compte",
		register_button = "Ouvrir mon compte",
		register_success = "Compte cree avec succes",
		register_error = "Impossible de creer le compte",
		register_chat_1 = "Votre compte Atlas Bank a ete cree. Cle : ",
		register_chat_2 = " Revenez au kiosque pour consulter votre solde.",
		account_title = "Mon compte",
		player = "Joueur",
		key = "Cle",
		balance = "Solde",
		status = "Statut",
		status_online = "Connecte au kiosque",
		market_title = "Cours du marche",
		market_live = "Flux live",
		market_empty = "Aucun actif disponible",
		buy_price = "Achat banque",
		sell_price = "Retrait banque",
		stock = "Reserve",
		withdraw_max = "Retrait max",
		graph = "Graphique live",
		help_title = "Aide du kiosque",
		help_lines = {
			"1. Placez-vous a droite du kiosque pour etre detecte.",
			"2. Ouvrez un compte si vous n'en avez pas encore.",
			"3. Consultez votre solde depuis la page Mon compte.",
			"4. Ouvrez Marche pour voir les cours et le graphique live.",
			"5. Utilisez Veille pour revenir a l'ecran d'accueil."
		},
		wait = "Connexion au serveur bancaire...",
		chat_prefix = "Atlas Bank",
		need_player = "Approchez-vous du detecteur joueur a droite.",
		select_asset = "Selectionnez un actif pour voir le detail.",
		bank_name = serverData.bankName or "Atlas Bank"
	},
	en = {
		sleep_title = "ATLAS BANK",
		sleep_subtitle = "Private banking kiosk",
		sleep_hint = "Right click the screen to use the kiosk",
		sleep_detail = "Touch the screen to leave standby",
		home_title = "Dashboard",
		no_player = "No player detected",
		detected = "Detected player",
		no_account = "No bank account detected",
		account_found = "Atlas Bank account active",
		create_account = "Create account",
		open_account = "My account",
		market = "Market",
		help = "Help",
		sleep = "Sleep",
		back = "Back",
		register_title = "Account creation",
		register_text = "The player detector on the right automatically identifies the nearby player.",
		register_ready = "Ready to open your account",
		register_button = "Open my account",
		register_success = "Account created successfully",
		register_error = "Unable to create account",
		register_chat_1 = "Your Atlas Bank account has been created. Key: ",
		register_chat_2 = " Return to the kiosk to check your balance.",
		account_title = "My account",
		player = "Player",
		key = "Key",
		balance = "Balance",
		status = "Status",
		status_online = "Connected to kiosk",
		market_title = "Market rates",
		market_live = "Live feed",
		market_empty = "No assets available",
		buy_price = "Bank buy",
		sell_price = "Withdraw",
		stock = "Reserve",
		withdraw_max = "Max withdraw",
		graph = "Live chart",
		help_title = "Kiosk help",
		help_lines = {
			"1. Stand on the right side of the kiosk to be detected.",
			"2. Create your account if you do not already have one.",
			"3. Check your balance on the My account page.",
			"4. Open Market to view prices and live chart.",
			"5. Use Sleep to return to the standby screen."
		},
		wait = "Connecting to bank server...",
		chat_prefix = "Atlas Bank",
		need_player = "Stand near the player detector on the right.",
		select_asset = "Select an asset to see details.",
		bank_name = serverData.bankName or "Atlas Bank"
	}
}

local function t(key)
	return (localization[lang] and localization[lang][key]) or key
end

local theme = {
	bg = colors.black,
	header = colors.white,
	headerText = colors.black,
	card = colors.gray,
	cardAlt = colors.lightGray,
	text = colors.white,
	sub = colors.lightGray,
	accent = colors.lightBlue,
	success = colors.lime,
	successText = colors.black,
	danger = colors.red,
	border = colors.gray
}

local state = {
	page = "sleep",
	currentPlayer = nil,
	accountKey = nil,
	account = nil,
	quotes = {},
	history = {},
	selectedAsset = nil
}

local app = pixelui.create({
	window = viewport,
	background = theme.bg,
	animationInterval = 0.05
})

local root = app:getRoot()

local pages = {}
local widgets = {}
local marketButtons = {}

local function add(parent, widget)
	parent:addChild(widget)
	return widget
end

local function makeFrame(parent, config)
	return add(parent, app:createFrame(config))
end

local function makeLabel(parent, config)
	return add(parent, app:createLabel(config))
end

local function makeButton(parent, config)
	config.clickEffect = true
	return add(parent, app:createButton(config))
end

local function hideAllPages()
	for _, frame in pairs(pages) do
		frame.visible = false
	end
end

local function showPage(name)
	state.page = name
	hideAllPages()
	if (pages[name] ~= nil) then
		pages[name].visible = true
	end
	app:render()
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
		chatBox.sendMessageToPlayer(text, playerName, t("chat_prefix"), "<>")
	end)
end

local function colorFromName(name)
	local colorsList = {colors.cyan, colors.blue, colors.green, colors.orange, colors.magenta, colors.yellow}
	local sum = 0
	for i = 1, #name do
		sum = sum + string.byte(name, i)
	end
	return colorsList[(sum % #colorsList) + 1]
end

local function refreshSelectedQuote()
	if (state.selectedAsset ~= nil) then
		for _, quote in ipairs(state.quotes) do
			if (quote.id == state.selectedAsset) then
				return quote
			end
		end
	end
	state.selectedAsset = state.quotes[1] and state.quotes[1].id or nil
	return state.quotes[1]
end

local function updateHeader()
	local subtitle
	if (state.currentPlayer ~= nil) then
		subtitle = t("detected") .. ": " .. state.currentPlayer
	else
		subtitle = t("no_player")
	end
	widgets.headerSubtitle:setText(subtitle)
end

local function updateHome()
	updateHeader()
	if (state.currentPlayer ~= nil) then
		widgets.homePlayer:setText(t("detected") .. ": " .. state.currentPlayer)
	else
		widgets.homePlayer:setText(t("need_player"))
	end

	if (state.account ~= nil) then
		widgets.homeStatus:setText(t("account_found"))
		widgets.homeBalance:setText(t("balance") .. ": " .. tostring(state.account.balance) .. " " .. (serverData.currencyLabel or "Credits"))
		widgets.homePrimary:setLabel(t("open_account"))
		widgets.homePrimary.onClick = function()
			showPage("account")
		end
	else
		widgets.homeStatus:setText(t("no_account"))
		widgets.homeBalance:setText(t("register_title"))
		widgets.homePrimary:setLabel(t("create_account"))
		widgets.homePrimary.onClick = function()
			showPage("register")
		end
	end
end

local function updateRegister()
	if (state.currentPlayer ~= nil) then
		widgets.registerDetected:setText(t("register_ready") .. ": " .. state.currentPlayer)
	else
		widgets.registerDetected:setText(t("need_player"))
	end
end

local function updateAccount()
	if (state.account ~= nil) then
		widgets.accountPlayer:setText(t("player") .. ": " .. (state.account.playerName or state.currentPlayer or "?"))
		widgets.accountKey:setText(t("key") .. ": " .. tostring(state.accountKey))
		widgets.accountBalance:setText(t("balance") .. ": " .. tostring(state.account.balance) .. " " .. (serverData.currencyLabel or "Credits"))
		widgets.accountStatus:setText(t("status") .. ": " .. t("status_online"))
	else
		widgets.accountPlayer:setText(t("need_player"))
		widgets.accountKey:setText(t("key") .. ": -")
		widgets.accountBalance:setText(t("balance") .. ": -")
		widgets.accountStatus:setText(t("no_account"))
	end
end

local function updateMarketList()
	for _, button in ipairs(marketButtons) do
		pages.marketContent:removeChild(button)
	end
	marketButtons = {}

	local listX = 3
	local listY = 3
	local listWidth = math.max(24, math.floor(width * 0.34))
	local maxButtons = math.max(3, math.floor((height - 18) / 3))

	if (#state.quotes == 0) then
		widgets.marketPlaceholder.visible = true
	else
		widgets.marketPlaceholder.visible = false
	end

	for index, quote in ipairs(state.quotes) do
		if (index > maxButtons) then
			break
		end
		local isSelected = quote.id == state.selectedAsset
		local button = app:createButton({
			x = listX,
			y = listY + ((index - 1) * 3),
			width = listWidth,
			height = 3,
			label = quote.name,
			bg = isSelected and theme.header or theme.cardAlt,
			fg = isSelected and theme.headerText or theme.text,
			border = { color = isSelected and theme.accent or theme.border },
			onClick = function()
				state.selectedAsset = quote.id
				updateMarketWidgets()
				app:render()
			end
		})
		pages.marketContent:addChild(button)
		table.insert(marketButtons, button)
	end
end

function updateMarketWidgets()
	local quote = refreshSelectedQuote()
	updateMarketList()
	if (quote == nil) then
		widgets.marketName:setText(t("market_empty"))
		widgets.marketBuy:setText("-")
		widgets.marketSell:setText("-")
		widgets.marketStock:setText("-")
		widgets.marketWithdraw:setText("-")
		widgets.marketChart:setData({})
		widgets.marketChart:setLabels({})
		return
	end

	widgets.marketName:setText(quote.name)
	widgets.marketBuy:setText(t("buy_price") .. ": " .. tostring(quote.depositPrice) .. " " .. (serverData.currencyLabel or "Credits"))
	widgets.marketSell:setText(t("sell_price") .. ": " .. tostring(quote.withdrawPrice) .. " " .. (serverData.currencyLabel or "Credits"))
	widgets.marketStock:setText(t("stock") .. ": " .. tostring(quote.stock))
	widgets.marketWithdraw:setText(t("withdraw_max") .. ": " .. tostring(quote.maxWithdraw))

	local history = state.history[quote.id] or {}
	local labels = {}
	for i = 1, #history do
		labels[i] = tostring(i)
	end
	widgets.marketChart:setData(history)
	widgets.marketChart:setLabels(labels)
end

local function refreshAll()
	updateHome()
	updateRegister()
	updateAccount()
	updateMarketWidgets()
	app:render()
end

local function loadAccountForCurrentPlayer()
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

local function loadQuotes()
	local ok, quotes = pcall(bankapi.getAssetQuotes)
	if (not ok or type(quotes) ~= "table") then
		return
	end
	state.quotes = quotes
	for _, quote in ipairs(state.quotes) do
		state.history[quote.id] = state.history[quote.id] or {}
		table.insert(state.history[quote.id], quote.depositPrice)
		if (#state.history[quote.id] > 24) then
			table.remove(state.history[quote.id], 1)
		end
	end
	if (state.selectedAsset == nil and #state.quotes > 0) then
		state.selectedAsset = state.quotes[1].id
	end
end

local function createAccountForCurrentPlayer()
	if (state.currentPlayer == nil) then
		widgets.registerDetected:setText(t("need_player"))
		app:render()
		return
	end

	local ok, success, response = pcall(bankapi.newAccountForPlayer, state.currentPlayer, state.currentPlayer, colorFromName(state.currentPlayer))
	if (ok and success and response ~= nil) then
		sendPlayerMessage(state.currentPlayer, t("register_chat_1") .. tostring(response.key) .. t("register_chat_2"))
		loadAccountForCurrentPlayer()
		refreshAll()
		showPage("account")
	else
		widgets.registerDetected:setText(t("register_error"))
		app:render()
	end
end

widgets.header = makeFrame(root, {
	x = 1,
	y = 1,
	width = width,
	height = 4,
	bg = theme.bg,
	border = { color = theme.bg }
})

widgets.headerBar = makeLabel(widgets.header, {
	x = 3,
	y = 1,
	width = width - 4,
	height = 1,
	text = t("bank_name"),
	align = "center",
	bg = theme.header,
	fg = theme.headerText
})

widgets.headerSubtitle = makeLabel(widgets.header, {
	x = 1,
	y = 3,
	width = width,
	height = 1,
	text = t("wait"),
	align = "center",
	bg = theme.bg,
	fg = theme.sub
})

pages.sleep = makeFrame(root, {
	x = 1,
	y = 5,
	width = width,
	height = height - 4,
	bg = theme.bg
})

makeFrame(pages.sleep, {
	x = math.max(4, math.floor(width / 2) - 20),
	y = math.max(3, math.floor((height - 4) / 2) - 5),
	width = 40,
	height = 11,
	bg = theme.card,
	border = { color = theme.header }
})

makeLabel(pages.sleep, {
	x = math.max(2, math.floor(width / 2) - 12),
	y = math.max(5, math.floor((height - 4) / 2) - 2),
	width = 24,
	height = 1,
	text = t("sleep_title"),
	align = "center",
	bg = theme.bg,
	fg = theme.text
})

makeLabel(pages.sleep, {
	x = math.max(2, math.floor(width / 2) - 18),
	y = math.max(7, math.floor((height - 4) / 2)),
	width = 36,
	height = 1,
	text = t("sleep_subtitle"),
	align = "center",
	bg = theme.bg,
	fg = theme.sub
})

makeButton(pages.sleep, {
	x = math.max(6, math.floor(width / 2) - 18),
	y = math.max(10, math.floor((height - 4) / 2) + 2),
	width = 36,
	height = 3,
	label = t("sleep_hint"),
	bg = theme.success,
	fg = theme.successText,
	border = { color = theme.success },
	onClick = function()
		showPage("home")
	end
})

makeLabel(pages.sleep, {
	x = 1,
	y = height - 7,
	width = width,
	height = 1,
	text = t("sleep_detail"),
	align = "center",
	bg = theme.bg,
	fg = theme.sub
})

local contentHeight = height - 6

pages.home = makeFrame(root, {
	x = 1,
	y = 5,
	width = width,
	height = contentHeight,
	bg = theme.bg,
	visible = false
})

makeFrame(pages.home, {
	x = 4,
	y = 2,
	width = width - 8,
	height = 9,
	bg = theme.card,
	border = { color = theme.header }
})

widgets.homePlayer = makeLabel(pages.home, {
	x = 6,
	y = 4,
	width = width - 12,
	height = 1,
	text = "",
	bg = theme.bg,
	fg = theme.accent
})

widgets.homeStatus = makeLabel(pages.home, {
	x = 6,
	y = 6,
	width = width - 12,
	height = 1,
	text = "",
	bg = theme.bg,
	fg = theme.text
})

widgets.homeBalance = makeLabel(pages.home, {
	x = 6,
	y = 8,
	width = width - 12,
	height = 1,
	text = "",
	bg = theme.bg,
	fg = theme.sub
})

local homePrimaryWidth = math.max(18, math.floor((width - 18) / 2))
widgets.homePrimary = makeButton(pages.home, {
	x = 6,
	y = 14,
	width = homePrimaryWidth,
	height = 3,
	label = t("create_account"),
	bg = theme.success,
	fg = theme.successText,
	border = { color = theme.success }
})

makeButton(pages.home, {
	x = 8 + homePrimaryWidth,
	y = 14,
	width = homePrimaryWidth,
	height = 3,
	label = t("market"),
	bg = theme.header,
	fg = theme.headerText,
	border = { color = theme.header },
	onClick = function()
		showPage("market")
	end
})

makeButton(pages.home, {
	x = 4,
	y = contentHeight - 4,
	width = 12,
	height = 3,
	label = t("help"),
	bg = theme.cardAlt,
	fg = theme.text,
	border = { color = theme.border },
	onClick = function()
		showPage("help")
	end
})

makeButton(pages.home, {
	x = width - 15,
	y = contentHeight - 4,
	width = 12,
	height = 3,
	label = t("sleep"),
	bg = theme.danger,
	fg = colors.white,
	border = { color = theme.danger },
	onClick = function()
		showPage("sleep")
	end
})

pages.register = makeFrame(root, {
	x = 1,
	y = 5,
	width = width,
	height = contentHeight,
	bg = theme.bg,
	visible = false
})

makeFrame(pages.register, {
	x = 4,
	y = 2,
	width = width - 8,
	height = 11,
	bg = theme.card,
	border = { color = theme.header }
})

makeLabel(pages.register, {
	x = 6,
	y = 4,
	width = width - 12,
	height = 1,
	text = t("register_title"),
	bg = theme.bg,
	fg = theme.text
})

makeLabel(pages.register, {
	x = 6,
	y = 6,
	width = width - 12,
	height = 2,
	text = t("register_text"),
	bg = theme.bg,
	fg = theme.sub
})

widgets.registerDetected = makeLabel(pages.register, {
	x = 6,
	y = 9,
	width = width - 12,
	height = 1,
	text = "",
	bg = theme.bg,
	fg = theme.accent
})

makeButton(pages.register, {
	x = 6,
	y = 14,
	width = width - 12,
	height = 3,
	label = t("register_button"),
	bg = theme.success,
	fg = theme.successText,
	border = { color = theme.success },
	onClick = createAccountForCurrentPlayer
})

makeButton(pages.register, {
	x = 4,
	y = contentHeight - 4,
	width = 12,
	height = 3,
	label = t("back"),
	bg = theme.cardAlt,
	fg = theme.text,
	border = { color = theme.border },
	onClick = function()
		showPage("home")
	end
})

makeButton(pages.register, {
	x = width - 15,
	y = contentHeight - 4,
	width = 12,
	height = 3,
	label = t("help"),
	bg = theme.cardAlt,
	fg = theme.text,
	border = { color = theme.border },
	onClick = function()
		showPage("help")
	end
})

pages.account = makeFrame(root, {
	x = 1,
	y = 5,
	width = width,
	height = contentHeight,
	bg = theme.bg,
	visible = false
})

makeFrame(pages.account, {
	x = 4,
	y = 2,
	width = width - 8,
	height = 12,
	bg = theme.card,
	border = { color = theme.header }
})

widgets.accountPlayer = makeLabel(pages.account, {
	x = 6,
	y = 4,
	width = width - 12,
	height = 1,
	text = "",
	bg = theme.bg,
	fg = theme.text
})

widgets.accountKey = makeLabel(pages.account, {
	x = 6,
	y = 6,
	width = width - 12,
	height = 1,
	text = "",
	bg = theme.bg,
	fg = theme.sub
})

widgets.accountBalance = makeLabel(pages.account, {
	x = 6,
	y = 8,
	width = width - 12,
	height = 1,
	text = "",
	bg = theme.bg,
	fg = theme.accent
})

widgets.accountStatus = makeLabel(pages.account, {
	x = 6,
	y = 10,
	width = width - 12,
	height = 1,
	text = "",
	bg = theme.bg,
	fg = theme.sub
})

makeButton(pages.account, {
	x = 4,
	y = contentHeight - 4,
	width = 12,
	height = 3,
	label = t("back"),
	bg = theme.cardAlt,
	fg = theme.text,
	border = { color = theme.border },
	onClick = function()
		showPage("home")
	end
})

makeButton(pages.account, {
	x = 18,
	y = contentHeight - 4,
	width = 14,
	height = 3,
	label = t("market"),
	bg = theme.success,
	fg = theme.successText,
	border = { color = theme.success },
	onClick = function()
		showPage("market")
	end
})

makeButton(pages.account, {
	x = width - 15,
	y = contentHeight - 4,
	width = 12,
	height = 3,
	label = t("help"),
	bg = theme.cardAlt,
	fg = theme.text,
	border = { color = theme.border },
	onClick = function()
		showPage("help")
	end
})

pages.market = makeFrame(root, {
	x = 1,
	y = 5,
	width = width,
	height = contentHeight,
	bg = theme.bg,
	visible = false
})

pages.marketContent = makeFrame(pages.market, {
	x = 2,
	y = 1,
	width = width - 2,
	height = contentHeight - 1,
	bg = theme.bg
})

local listWidth = math.max(24, math.floor(width * 0.34))
makeFrame(pages.marketContent, {
	x = 2,
	y = 2,
	width = listWidth + 4,
	height = contentHeight - 8,
	bg = theme.card,
	border = { color = theme.header }
})

widgets.marketPlaceholder = makeLabel(pages.marketContent, {
	x = 4,
	y = 4,
	width = listWidth,
	height = 1,
	text = t("market_empty"),
	bg = theme.bg,
	fg = theme.sub
})

local detailX = listWidth + 8
local detailWidth = width - detailX - 2

makeFrame(pages.marketContent, {
	x = detailX,
	y = 2,
	width = detailWidth,
	height = contentHeight - 8,
	bg = theme.card,
	border = { color = theme.header }
})

widgets.marketName = makeLabel(pages.marketContent, {
	x = detailX + 2,
	y = 4,
	width = detailWidth - 4,
	height = 1,
	text = t("select_asset"),
	bg = theme.bg,
	fg = theme.text
})

widgets.marketBuy = makeLabel(pages.marketContent, {
	x = detailX + 2,
	y = 6,
	width = detailWidth - 4,
	height = 1,
	text = "-",
	bg = theme.bg,
	fg = theme.accent
})

widgets.marketSell = makeLabel(pages.marketContent, {
	x = detailX + 2,
	y = 8,
	width = detailWidth - 4,
	height = 1,
	text = "-",
	bg = theme.bg,
	fg = theme.text
})

widgets.marketStock = makeLabel(pages.marketContent, {
	x = detailX + 2,
	y = 10,
	width = detailWidth - 4,
	height = 1,
	text = "-",
	bg = theme.bg,
	fg = theme.sub
})

widgets.marketWithdraw = makeLabel(pages.marketContent, {
	x = detailX + 2,
	y = 12,
	width = detailWidth - 4,
	height = 1,
	text = "-",
	bg = theme.bg,
	fg = theme.sub
})

makeLabel(pages.marketContent, {
	x = detailX + 2,
	y = 14,
	width = detailWidth - 4,
	height = 1,
	text = t("graph"),
	bg = theme.bg,
	fg = theme.text
})

widgets.marketChart = add(pages.marketContent, app:createChart({
	x = detailX + 2,
	y = 16,
	width = detailWidth - 4,
	height = math.max(6, contentHeight - 25),
	data = {},
	labels = {},
	chartType = "line",
	showAxis = true,
	showLabels = false,
	placeholder = t("market_empty"),
	lineColor = theme.accent,
	barColor = theme.accent,
	axisColor = theme.sub,
	bg = theme.bg,
	fg = theme.text
}))

makeButton(pages.market, {
	x = 4,
	y = contentHeight - 4,
	width = 12,
	height = 3,
	label = t("back"),
	bg = theme.cardAlt,
	fg = theme.text,
	border = { color = theme.border },
	onClick = function()
		showPage("home")
	end
})

makeButton(pages.market, {
	x = width - 15,
	y = contentHeight - 4,
	width = 12,
	height = 3,
	label = t("help"),
	bg = theme.cardAlt,
	fg = theme.text,
	border = { color = theme.border },
	onClick = function()
		showPage("help")
	end
})

pages.help = makeFrame(root, {
	x = 1,
	y = 5,
	width = width,
	height = contentHeight,
	bg = theme.bg,
	visible = false
})

makeFrame(pages.help, {
	x = 4,
	y = 2,
	width = width - 8,
	height = contentHeight - 8,
	bg = theme.card,
	border = { color = theme.header }
})

makeLabel(pages.help, {
	x = 6,
	y = 4,
	width = width - 12,
	height = 1,
	text = t("help_title"),
	bg = theme.bg,
	fg = theme.text
})

for index, line in ipairs(localization[lang].help_lines) do
	makeLabel(pages.help, {
		x = 6,
		y = 6 + ((index - 1) * 2),
		width = width - 12,
		height = 1,
		text = line,
		bg = theme.bg,
		fg = theme.sub
	})
end

makeButton(pages.help, {
	x = 4,
	y = contentHeight - 4,
	width = 12,
	height = 3,
	label = t("back"),
	bg = theme.cardAlt,
	fg = theme.text,
	border = { color = theme.border },
	onClick = function()
		showPage("home")
	end
})

makeButton(pages.help, {
	x = width - 15,
	y = contentHeight - 4,
	width = 12,
	height = 3,
	label = t("sleep"),
	bg = theme.danger,
	fg = colors.white,
	border = { color = theme.danger },
	onClick = function()
		showPage("sleep")
	end
})

loadAccountForCurrentPlayer()
loadQuotes()
refreshAll()
showPage("sleep")

app:spawnThread(function(ctx)
	while true do
		loadAccountForCurrentPlayer()
		refreshAll()
		ctx:sleep(2)
	end
end, {
	name = "AtlasBankPlayerPoll"
})

app:spawnThread(function(ctx)
	while true do
		loadQuotes()
		refreshAll()
		ctx:sleep(8)
	end
end, {
	name = "AtlasBankMarketPoll"
})

app:run()
