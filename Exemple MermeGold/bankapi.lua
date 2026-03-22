-- Bank API V4
 
local backgroundColor = colors.black
local panelColor = colors.black
local panelEdgeColor = colors.gray
local buttonShadowColor = colors.black
local buttonTextColor = colors.white
local grayedOutColor = colors.lightGray
local specialTextColor = colors.white
local titleTextColor = colors.white

local buttonColor = colors.gray
local secondaryButtonColor = colors.lightGray

local acceptButtonColor = colors.green
local acceptSecondaryColor = colors.lime

local cancelButtonColor = colors.red
local cancelSecondaryColor = colors.brown
 
local bankServerID = 0
local readingPosX = 0
local readingPosY = 0
local readingString = ""
local reading = false
local readingMax = 10
 
local function contrastColor(color)
	if (color == colors.white) then return colors.black end
	if (color == colors.orange) then return colors.black end
	if (color == colors.magenta) then return colors.black end
	if (color == colors.lightBlue) then return colors.black end
	if (color == colors.yellow) then return colors.black end
	if (color == colors.lime) then return colors.black end
	if (color == colors.pink) then return colors.black end
	if (color == colors.gray) then return colors.black end
	if (color == colors.lightGray) then return colors.black end
	if (color == colors.cyan) then return colors.white end
	if (color == colors.purple) then return colors.white end
	if (color == colors.blue) then return colors.white end
	if (color == colors.brown) then return colors.white end
	if (color == colors.green) then return colors.black end
	if (color == colors.red) then return colors.black end
	if (color == colors.black) then return colors.white end
	return colors.black
end
 
local serverData = nil
local lang = "en"
local localization = {
	fr={
		back = "Retour",
		continue = "Continuer",
		sender = "Expediteur",
		recipient = "Destinataire",
		amount = "Montant",
		resulting_balance = "Solde restant",
		date_and_time = "Date et heure",
		description = "Description",
		no_description = "Aucune description",
		click_to_expand = "Cliquez pour voir le detail",
		balance = "Solde",
		name = "Nom",
		key = "Cle",
		deleted = "<supprime>",
		accept = "Valider",
		cancel = "Annuler",
		input_text = "Saisir un texte",
		max_length = "Longueur max",
		input_number = "Saisir un nombre",
		max = "Max",
		product = "Produit",
		quantity = "Quantite",
		price = "Prix",
		item_name = "Objet",
		invalid_value = "Valeur invalide",
		no_accounts = "Aucun compte n'existe pour le moment"
	},
	en={
		back = "Back",
		continue = "Continue",
		sender = "Sender",
		recipient = "Recipient",
		amount = "Amount",
		resulting_balance = "Resulting balance",
		date_and_time = "Date and time",
		description = "Description",
		no_description = "No description",
		click_to_expand = "Click entry for more info",
		balance = "Balance",
		name = "Name",
		key = "Key",
		deleted = "<deleted>",
		accept = "Accept",
		cancel = "Cancel",
		input_text = "Input text",
		max_length = "Max length",
		input_number = "Input number",
		max = "Max",
		product = "Product",
		quantity = "Quantity",
		price = "Price",
		item_name = "Item",
		invalid_value = "Invalid value",
		no_accounts = "There are no accounts at the moment"
	},
	es={
		back = "Volver",
		continue = "Continuar",
		sender = "Remitente",
		recipient = "Destinatario",
		amount = "Monto",
		resulting_balance = "Balance resultante",
		date_and_time = "Fecha y hora",
		description = "Descripcion",
		no_description = "Sin descripcion",
		click_to_expand = "Toca una para mas info",
		balance = "Balance",
		name = "Nombre",
		key = "Clave",
		deleted = "<borrada>",
		accept = "Aceptar",
		cancel = "Cancelar",
		input_text = "Ingresa un texto",
		max_length = "largo maximo",
		input_number = "Ingresa un numero",
		max = "Maximo",
		product = "Producto",
		quantity = "Cantidad",
		price = "Precio",
		item_name = "Articulo",
		invalid_value = "Valor invalido",
		no_accounts = "No hay cuentas por el momento"
	},
	de={
		back = "Zurueck",
		continue = "Weiter",
		sender = "Sender",
		recipient = "Empfaenger",
		amount = "Betrag",
		resulting_balance = "Verbleibender Kontostandt",
		date_and_time = "Datum und Zeit",
		description = "Beschreibung",
		no_description = "Keine Beschreibung",
		click_to_expand = "Klicke führ mehr Infos",
		balance = "Kontostandt",
		name = "Name",
		key = "Schluessel",
		deleted = "<geloescht>",
		accept = "Aktzeptieren",
		cancel = "Abbrechen",
		input_text = "Eingabe Text",
		max_length = "Maximale Laenge",
		input_number = "Zahl eingeben",
		max = "Max",
		product = "Produkt",
		quantity = "Anzahl",
		price = "Preis",
		item_name = "Artikel",
		invalid_value = "Ungültiger Wert",
		no_accounts = "Es gibt im Moment keine Konten"
	}
}
 
function getServerData()
	print("Connecting to server...")
	local message = {
		action = "getServerData"
	}
	while (true) do
		rednet.broadcast(message, "mermegold")
		local sender, message = rednet.receive("mermegold", 3)
		if (message ~= nil and os.computerID() ~= sender and message.response ~= nil) then
			bankServerID = sender
			print("Successfully connected to server [#"..sender.."]")
			lang = message.response.lang
			serverData = message.response
			return message.response
		end
	end
end
 
function getClientData()
	local message = {
		action = "getClientData"
	}
	while(true) do
		rednet.send(bankServerID, message, "mermegold")
		local sender, message = rednet.receive("mermegold", 3)
		if (message ~= nil and os.computerID() ~= sender and message.response ~= nil) then
			return message.response
		end
	end
end
 
local function drawBox(background, foreground, x, y, w, h)
	term.setBackgroundColor(foreground)
	for i=y, y+h-1 do
		term.setCursorPos(x, i)
		term.write(string.rep(" ", w))
	end

	term.setBackgroundColor(background)
	term.setCursorPos(x, y)
	term.write(" ")
	term.write(string.rep(" ", w-2))
	term.write(" ")
	term.setCursorPos(x, y+h-1)
	term.write(" ")
	term.write(string.rep(" ", w-2))
	term.write(" ")

	for i=y+1, y+h-2 do
		term.setCursorPos(x, i)
		term.write(" ")
		term.setCursorPos(x+w-1, i)
		term.write(" ")
	end
end

local function drawBackground()
	term.setBackgroundColor(backgroundColor)
	term.clear()
end

local function fill(x, y, w, h, color)
	term.setBackgroundColor(color)
	for i=y, y+h-1 do
		term.setCursorPos(x, i)
		term.write(string.rep(" ", w))
	end
end

local function drawHeader(title)
	local scrW, scrH = term.getSize()
	fill(1, 1, scrW, 2, colors.black)
	term.setCursorPos(math.floor(scrW/2-string.len(title)/2), 1)
	term.setTextColor(titleTextColor)
	term.write(title)
	term.setCursorPos(2, 2)
	term.setTextColor(grayedOutColor)
	term.write(string.rep("-", math.max(1, scrW-3)))
end

function drawButton(primary, secondary, textColor, x, y, w, text)
	term.setCursorPos(x, y)
	term.setBackgroundColor(primary)
	term.setTextColor(primary)
	term.write(" ")
	term.write(string.rep(" ", w-2))
	term.write(" ")
 
	term.setBackgroundColor(backgroundColor)
	term.setTextColor(buttonShadowColor)
	local scrW, scrH = term.getSize()
	if (y < scrH) then
		term.setCursorPos(x, y+1)
		term.write(string.rep(" ", w))
	end
 
	term.setBackgroundColor(primary)
	term.setTextColor(textColor)
 
	term.setCursorPos(math.floor(x+w/2-string.len(text)/2), y)
	term.write(text)
 
	return {x=x, y=y, w=w}
end
 
function mouseInButton(button, mousex, mousey)
	return (mousex >= button.x and mousex <= button.x+button.w and button.y == mousey)
end
 
function drawBackButton()
	local scrW, scrH = term.getSize()
	local text = localization[lang].back
	local x = 2
	local y = scrH-1
 
	local ch = string.char(127)
 
	local width = string.len(text)
 
	return drawButton(cancelButtonColor, cancelSecondaryColor, buttonTextColor, x, y, width+6, text)
end
 
function drawContinueButton()
	local scrW, scrH = term.getSize()
	local text = localization[lang].continue
	local x = 2
	local y = scrH-1
 
	local ch = string.char(127)
 
	local width = string.len(text)
 
	return drawButton(acceptButtonColor, acceptSecondaryColor, buttonTextColor, scrW-width-7, y, width+6, text)
end
 
function drawAcceptButton()
	local scrW, scrH = term.getSize()
	local text = localization[lang].accept
	local x = 2
	local y = scrH-1
 
	local ch = string.char(127)
 
	local width = string.len(text)
 
	return drawButton(acceptButtonColor, acceptSecondaryColor, buttonTextColor, scrW-width-7, y, width+6, text)
end
 
function transaction(from, to, amount, description)
	--local success, response = transaction(from, to, amount, description)
	local message = {
		action = "transaction",
		from = from,
		to = to,
		amount = amount,
		description = description
	}
	rednet.send(bankServerID, message, "mermegold")
	local sender, message = rednet.receive("mermegold")
	return message.success, message.response
end
 
function deposit(key, amount)
	local message = {
		action = "deposit",
		key = key,
		amount = amount
	}
	rednet.send(bankServerID, message, "mermegold")
	local sender, message = rednet.receive("mermegold")
	return message.success, message.response
end
 
function withdraw(key, amount)
	local message = {
		action = "withdraw",
		key = key,
		amount = amount
	}
	rednet.send(bankServerID, message, "mermegold")
	local sender, message = rednet.receive("mermegold")
	return message.success, message.response
end
 
function newAccount(name, balance, color, playerName)
	local message = {
		action = "new",
		name = name,
		balance = balance,
		color = color
	}
	if (playerName ~= nil and playerName ~= "") then
		message.playerName = playerName
	end
	rednet.send(bankServerID, message, "mermegold")
	local sender, message = rednet.receive("mermegold")
	return message.success, message.response
end

function newAccountForPlayer(name, playerName, color)
	local message = {
		action = "new",
		name = name,
		playerName = playerName,
		balance = 0,
		color = color
	}
	rednet.send(bankServerID, message, "mermegold")
	local sender, message = rednet.receive("mermegold")
	return message.success, message.response
end

function deleteAccount(key)
	local message = {
		action = "delete",
		key = key
	}
	rednet.send(bankServerID, message, "mermegold")
	local sender, message = rednet.receive("mermegold")
	return message.success, message.response
end
 
function getTransactionLog(key)
	local message = {
		action = "getTransactionLog",
		key = key
	}
	rednet.send(bankServerID, message, "mermegold")
	local sender, message = rednet.receive("mermegold")
	if (sender == nil) then
		print(text_error_noconnection)
	end
	return message.response
end
 
function transactionInfoScreen(log)
	local tempClientData = getClientData()
	local scrW, scrH = term.getSize()
 
	drawBackground()
	drawHeader(serverData.bankName or "Atlas Bank")
	drawBox(panelEdgeColor, panelColor, 2, 4, scrW-2, math.min(10, scrH-4))
	term.setCursorPos(4,3)
	term.setTextColor(colors.white)
	local amountText
	if (tonumber(log.amount) > 0) then
		print(localization[lang].sender..": "..tempClientData[log.other].name)
		term.write(localization[lang].amount..": ")
		amountText = "+$"..log.amount
		term.setTextColor(colors.green)
	end
	if (tonumber(log.amount) < 0) then
		print(localization[lang].recipient..": "..tempClientData[log.other].name)
		term.write(localization[lang].amount..": ")
		amountText = "-$"..math.abs(log.amount)
		term.setTextColor(colors.red)
	end
	print(amountText)
	term.setTextColor(colors.white)
	print(localization[lang].resulting_balance..": $"..log.balance)
	print(localization[lang].date_and_time..": "..log.time)
	if (string.len(log.description) > 0) then
		print(localization[lang].description..":")
		term.setTextColor(specialTextColor)
		print(log.description)
	else
		term.setTextColor(grayedOutColor)
		print(localization[lang].no_description)
	end
 
	drawBackButton()
	os.pullEvent("mouse_click")
end
 
function transactionLogScreen(key)
	local tempClientData = getClientData()
	local backwardsLogs = getTransactionLog(key)
	local logs = {}
 
	local logCount = #backwardsLogs
	for i=0, logCount do
		logs[logCount-i] = backwardsLogs[i+1] -- Newest first
	end
 
	local scrW, scrH = term.getSize()
	local y = 2
	local floor = 1
	local x = 1
	local w = scrW
 
	if (pocket) then
		floor = 2
	end
 
	local first = 0
	local logHeight = 2
	local max = math.floor((scrH-floor-logHeight)/logHeight)
 
	local scrollButtonY = scrH-1
	local scrollButtonCenterX = math.floor(scrW/2)+10
 
	if (pocket) then
		scrollButtonY = scrH-3
		scrollButtonCenterX = math.floor(scrW/2)+1
	end
 
	while true do
		drawBackground()
 
		local prevPage = drawButton(buttonColor, secondaryButtonColor, buttonTextColor,scrollButtonCenterX-13, scrollButtonY, 7, string.char(27))
		if (first <= 0) then
			drawButton(colors.lightGray, colors.gray, colors.gray, scrollButtonCenterX-13, scrollButtonY, 7, string.char(27))
		end
 
	local totalLogs = 0
	local i = 0
	local buttons = {}
		for k, v in ipairs(logs) do
			if (totalLogs >= first and totalLogs < first+max) then
				local order = #logs-k+1
				local amountText
				if (tonumber(v.amount) > 0) then
					amountText = "+$"..v.amount
				end
				if (tonumber(v.amount) < 0) then
					amountText = "-$"..math.abs(v.amount)
				end
 
				local text = "#"..order.." "..v.description
 
				-- box
				if (i > 0) then
					term.setCursorPos(1,y+i-1)
					term.setBackgroundColor(backgroundColor)
					term.setTextColor(panelEdgeColor)
					print(string.rep(" ", scrW))
					term.setBackgroundColor(colors.gray)
					print(string.rep(" ", scrW))
				else
					term.setCursorPos(1,y+i)
					term.setBackgroundColor(colors.gray)
					print(string.rep(" ", scrW))
				end
 
				-- content
				term.setCursorPos(1,y+i)
				buttons[y+i] = k
 
				local name
				if (tempClientData[v.other] ~= nil) then
					name = tempClientData[v.other].name
				else
					name = localization[lang].deleted
				end
 
				term.setTextColor(colors.lightGray)
				term.write("#"..order.." ")
 
				term.setTextColor(colors.white)
				term.write(name.." ")
 
				term.setCursorPos(scrW*0.3, y+i)
				if (pocket) then
					term.setCursorPos(scrW*0.5, y+i)
				end
				if (tonumber(v.amount) >= 0) then
					term.setTextColor(colors.green)
				else
					term.setTextColor(colors.red)
				end
				term.write(amountText)
 
				if (pocket == nil) then
					term.setCursorPos(scrW*0.5, y+i)
					term.setTextColor(colors.lightGray)
					term.write(" ($"..v.balance..")")
				end
 
				term.setTextColor(colors.lightGray)
				local time = v.time
				if (pocket) then
					time = string.sub(v.time, 1, 5)
				end
				term.setCursorPos(scrW-string.len(time),y+i)
				term.write(" "..time)
 
				i = i+logHeight
			end
			totalLogs = totalLogs+1
		end
 
		local nextPage = drawButton(buttonColor, secondaryButtonColor, buttonTextColor, scrollButtonCenterX+5, scrollButtonY, 7, string.char(26))
		if (first+max >= totalLogs) then
			drawButton(colors.lightGray, colors.gray, colors.gray, scrollButtonCenterX+5, scrollButtonY, 7, string.char(26))
		end
 
		-- page indicator
		local pages = math.ceil(totalLogs/max)
		local pageText = tostring((first/max)+1).."/"..pages
		term.setCursorPos(scrollButtonCenterX-string.len(pageText)/2, scrollButtonY)
		term.setBackgroundColor(backgroundColor)
		term.setTextColor(colors.lightGray)
		term.write(pageText)
 
		local backButton = drawBackButton()
 
		term.setCursorPos(scrW/2-string.len(localization[lang].click_to_expand)/2+1, 1)
 
		term.setBackgroundColor(backgroundColor)
		term.setTextColor(grayedOutColor)
		term.write(localization[lang].click_to_expand)
 
		--local event, button, cx, cy = os.pullEvent("mouse_click")
 
		local eventData = {os.pullEvent()}
		local event = eventData[1]
 
		if event == "mouse_click" then
			local cx = eventData[3]
			local cy = eventData[4]
			if (mouseInButton(prevPage, cx, cy)) then
				if (first > 0) then
					first = first-max
				end
			end
			if (mouseInButton(nextPage, cx, cy)) then
				if (first+max < totalLogs) then
					first = first+max
				end
			end
			if (cx >= x and cx <= x+w and cy >= y) then
				if buttons[cy] ~= nil then
					transactionInfoScreen(logs[buttons[cy]])
				end
			end
			if (mouseInButton(backButton, cx, cy)) then
				return nil
			end
		elseif event == "mouse_scroll" then
			local scroll = eventData[2]
			if (scroll < 0) then
				if (first > 0) then
					first = first-max
				end
			else
				if (first+max < totalLogs) then
					first = first+max
				end
			end
		end
	end
end
 
function optionMenu(title, options, spacing, width)
	if (spacing == nil) then spacing = 2 end
	if (width == nil) then width = 30 end
	drawBackground()
	local buttons = {}
	local scrW, scrH = term.getSize()
	local w = width
	local x = scrW/2-w/2+1
	local y = math.floor(scrH/2-(#options+1)*spacing/2)+3
	local i = 0
	drawHeader(title)
	term.setCursorPos(scrW/2-string.len(title)/2+1, y+i-1)
	term.setTextColor(titleTextColor)
	term.write(title)
	i = i+spacing
 
	for k, v in ipairs(options) do
		local primary = buttonColor
		local secondary = secondaryButtonColor
		if (k == 1 and #options <= 5) then
			primary = acceptButtonColor
			secondary = acceptSecondaryColor
		end
		drawButton(primary, secondary, buttonTextColor, x, y+i, w, v.text)
 
		buttons[y+i] = v.option
		i = i+spacing
	end
 
	while true do
		local event, button, cx, cy = os.pullEvent("mouse_click")
		if (cx >= x-1 and cx <= x+width-1 and cy >= y and cy < y+(#options+1)*spacing) then
			if buttons[cy] ~= nil then
				return buttons[cy]
			end
		end
	end
end
 
local function drawSteps(steps, currentStep)
	term.setCursorPos(1, 2)
	drawBackground()
	drawHeader(serverData and serverData.bankName or "Atlas Bank")
	local stepCount = #steps
	if (stepCount == 1) then
		term.setTextColor(specialTextColor)
		print(steps[1])
	else
		for k, v in ipairs(steps) do
			term.setTextColor(grayedOutColor)
			if (k == currentStep) then
				term.setTextColor(specialTextColor)
				term.write(string.char(16).." "..k..". ")
			else
				term.write(" "..k..". ")
			end
			print(v)
		end
	end
end
 
local function startRead(maxLength)
	local scrW, scrH = term.getSize()
	readingPosX, readingPosY = term.getCursorPos()
	reading = true
	readingString = ""
	readingMax = maxLength
	term.setBackgroundColor(panelColor)
	term.setTextColor(colors.white)
	term.setCursorPos(readingPosX, readingPosY)
	term.write(string.rep(" ", scrW-2))
	term.setCursorBlink(true)
end

function getAccountByPlayer(playerName)
	local message = {
		action = "getAccountByPlayer",
		playerName = playerName
	}
	rednet.send(bankServerID, message, "mermegold")
	local sender, message = rednet.receive("mermegold")
	return message.success, message.response
end
 
local function processChar(char)
	term.setBackgroundColor(panelColor)
	term.setTextColor(colors.white)
	term.setCursorPos(readingPosX, readingPosY)
	readingString = readingString..char
	term.write(readingString)
end
 
local function processKey(key)
	if (key == keys.backspace) then
		readingString = string.sub(readingString, 1, string.len(readingString)-1)
		term.setBackgroundColor(panelColor)
		term.setCursorPos(readingPosX+string.len(readingString), readingPosY)
		term.write(" ")
		term.setCursorPos(readingPosX+string.len(readingString), readingPosY)
	elseif (key == keys.enter) then
		term.setCursorBlink(false)
		return readingString
	end
	return nil
end
 
local function cancelableRead(maxLength, secondaryButtonX)
	startRead(maxLength)
	local back = drawBackButton()
	local accept = drawAcceptButton()
	term.setCursorPos(readingPosX, readingPosY)
	local input = nil
	while input == nil do
		local event, a, b, c = os.pullEvent()
		if (event == "char") then
			processChar(a)
		elseif (event == "key") then
			input = processKey(a)
		elseif (event == "mouse_click") then
			local cx = b
			local cy = c
			if (mouseInButton(back, cx, cy)) then
				term.setCursorBlink(false)
				return nil
			elseif (mouseInButton(accept, cx, cy)) then
				term.setCursorBlink(false)
				input = readingString
				break
			elseif (secondaryButtonX ~= nil) then
				if (cy == back.y and cx >= secondaryButtonX) then
					return true
				end
			end
		end
	end
	term.setCursorBlink(false)
	if (readingMax > 0 and string.len(input) > readingMax) then
		input = string.sub(input, 1, readingMax)
	end
	return input
end
 
function showBalance(key)
	local tempClientData = getClientData()
	drawBackground()
	local scrW, scrH = term.getSize()
 
	local text = localization[lang].balance..":"
	term.setTextColor(specialTextColor)
	term.setCursorPos(scrW/2-string.len(text)/2+2,scrH/2-3)
	term.write(text)
	local currencyLabel = "Credits"
	if (serverData.currencyLabel ~= nil) then
		currencyLabel = serverData.currencyLabel
	end
 
	text = tostring(tempClientData[key].balance).." "..currencyLabel
	drawBox(panelEdgeColor, panelColor, 4, scrH/2-1, scrW-6, 5)
	term.setCursorPos(scrW/2-string.len(text)/2+1,scrH/2)
	term.setBackgroundColor(panelColor)
	term.setTextColor(specialTextColor)
	term.write(text)
 
	text = serverData.bankName or "Atlas Bank"
	term.setCursorPos(scrW/2-string.len(text)/2+1,scrH/2+2)
	term.write(text)
 
	drawBackButton()
 
	while true do
		local event = os.pullEvent()
		if (event == "mouse_click" or event == "key") then
			break
		end
	end
end
 
function selectAccountScreen(steps, currentStep, disabledAccount, overrideClientData)
	local tempClientData
 
	if (overrideClientData == nil) then
		tempClientData = getClientData()
	else
		tempClientData = overrideClientData
	end
 
	local clientCount = 0
	for k, v in pairs(tempClientData) do
		clientCount = clientCount+1
	end
 
	if (clientCount == 0) then
		errorScreen(localization[lang].no_accounts)
		return nil
	end
 
	local scrW, scrH = term.getSize()
	local x, y, w, h = scrW/4, #steps+4, scrW/2+2, scrH-5
 
	local back = drawBackButton()
 
	local first = 0
	local max = scrH-y-2
 
	local upButtonY = y-2
	local downButtonY = y+1+max
 
	while true do
		drawSteps(steps, currentStep)
		drawBackButton()
		local i = 0
		local buttons = {}
 
		if (first > 0) then
			term.setCursorPos(scrW/2-3,upButtonY)
			term.setTextColor(buttonTextColor)
			term.setBackgroundColor(buttonColor)
			term.write("  "..string.char(24).."  ")
		end
 
		local totalAccounts = 0
		local showAccounts = 0
		for k, v in pairs(tempClientData) do
			if (disabledAccount ~= nil and disabledAccount ~= k) then
				if (totalAccounts >= first and showAccounts < first+max) then
					buttons[y+i] = k
					term.setCursorPos(x,y+i)
					term.setTextColor(colors.white)
					term.setBackgroundColor(panelColor)
					term.write(string.rep(" ", w))
					term.setCursorPos(x+w/2-string.len(v.name)/2-1,y+i)
					term.setTextColor(tonumber(v.color))
					term.write(v.name)
					i = i+1
				end
				showAccounts = showAccounts+1
			end
			totalAccounts = totalAccounts+1
		end
 
		if (first+max < showAccounts) then
			term.setCursorPos(scrW/2-3,downButtonY)
			term.setTextColor(buttonTextColor)
			term.setBackgroundColor(buttonColor)
			term.write("  "..string.char(25).."  ")
		end
 
		local event, button, cx, cy = os.pullEvent("mouse_click")
		if (cx >= scrW/2-3 and cx < scrW/2+3 and cy == upButtonY) then
			if (first > 0) then
				first = first-max
			end
		end
		if (cx >= scrW/2-3 and cx < scrW/2+3 and cy == downButtonY) then
			if (first+max < showAccounts) then
				first = first+max
			end
		end
		if (cx >= x and cx <= x+w and cy >= y and cy < y+i) then
			return buttons[cy]
		end
		if (mouseInButton(back, cx, cy)) then
			return nil
		end
	end
end
 
function inputNumberScreen(steps, currentStep, max, maxString)
	if (max == nil) then max = 0 end
	local y = #steps+3
	while true do
		drawSteps(steps, currentStep)
 
		term.setCursorPos(1, y)
		term.setBackgroundColor(backgroundColor)
		term.setTextColor(specialTextColor)
		local text = localization[lang].input_number
		if (maxString ~= nil and maxString ~= "") then
			text = text.." ("..localization[lang].max.." "..maxString..")"
		elseif (max ~= nil and max ~= 0) then
			text = text.." ("..localization[lang].max.." $"..max..")"
		end
		text = text..":"
		print(text)
		local scrW, scrH = term.getSize()
 
		term.setCursorPos(2, y+2)
 
		local result = cancelableRead(max)
 
		if (result == nil) then
			return nil
		end
 
		local numberResult = tonumber(result)
		if (numberResult == nil or numberResult <= 0 or numberResult%1 ~= 0) then
			errorScreen(localization[lang].invalid_value)
		else
			return result
		end
	end
end
 
function inputTextScreen(steps, currentStep, maxLength)
	if (maxLength == nil) then maxLength = 0 end
	drawSteps(steps, currentStep)
	local y = #steps+3
	term.setCursorPos(1, y)
	term.setBackgroundColor(backgroundColor)
	term.setTextColor(specialTextColor)
	local text = localization[lang].input_text
	if (maxLength ~= nil and maxLength ~= 0) then
		text = text.." ("..localization[lang].max_length.." "..maxLength..")"
	end
	text = text..":"
	print(text)
	local scrW, scrH = term.getSize()
	term.setCursorPos(2, y+2)
	return cancelableRead(maxLength)
end
 
function selectColorScreen(steps, currentStep)
	drawSteps(steps, currentStep)
	local y = #steps+3
	local color = 1
	local buttons = {}
	local scrW, scrH = term.getSize()
	local x = scrW/2-10
	local w = 5 --button width
	for _x=0, 3 do
		buttons[_x] = {}
		for _y= 0, 3 do
			term.setCursorPos(x+_x*w+1, y+_y)
			term.setBackgroundColor(color)
			term.setTextColor(contrastColor(color))
			term.write("[")
			term.write(string.rep(" ", w-2))
			term.write("]")
			buttons[_x][_y] = color
			color = color*2
		end
	end
 
	local backx, backy, backw = drawBackButton()
 
	while true do
		local event, button, cx, cy = os.pullEvent("mouse_click")
		if (cx >= x and cx <= x+w*4 and cy >= y and cy < y+4) then
			local _x = math.floor((cx-x)/w)
			local _y = math.floor((cy-y))
			return buttons[_x][_y]
		end
		if (cx >= backx and cx <= backx+backw and cy == backy) then
			return nil
		end
	end
end
 
function responseScreen(success, response)
	if (success) then
		successScreen(response)
	else
		errorScreen(response)
	end
end
 
function errorScreen(message)
	term.setBackgroundColor(backgroundColor)
	term.clear()
	term.setCursorBlink(false)
	local scrW, scrH = term.getSize()
	drawHeader(serverData and serverData.bankName or "Atlas Bank")
	drawBox(panelEdgeColor, cancelButtonColor, 3, math.max(4, scrH/2-2), scrW-4, 5)
	term.setBackgroundColor(cancelButtonColor)
	term.setTextColor(colors.white)
	if (type(message) == 'table') then
		for k, v in pairs(message) do
			term.setCursorPos(scrW/2-string.len(v)/2+1, scrH/2-math.ceil(#message/2)+k)
			term.write(v)
		end
		sleep(1.5 * #message)
	else
		term.setCursorPos(scrW/2-string.len(message)/2+1, scrH/2)
		term.write(message)
		sleep(1.5)
	end
end
 
function successScreen(message)
	term.setBackgroundColor(backgroundColor)
	term.clear()
	term.setCursorBlink(false)
	local scrW, scrH = term.getSize()
	drawHeader(serverData and serverData.bankName or "Atlas Bank")
	drawBox(panelEdgeColor, acceptButtonColor, 3, math.max(4, scrH/2-2), scrW-4, 5)
	term.setBackgroundColor(acceptButtonColor)
	term.setTextColor(colors.white)
	if (type(message) == 'table') then
		for k, v in pairs(message) do
			term.setCursorPos(scrW/2-string.len(v)/2+1, scrH/2-math.ceil(#message/2)+k)
			term.write(v)
		end
		sleep(1.5 * #message)
	else
		term.setCursorPos(scrW/2-string.len(message)/2+1, scrH/2)
		term.write(message)
		sleep(1.5)
	end
end
 
function waitScreen(message)
	drawBackground()
	drawHeader(serverData and serverData.bankName or "Atlas Bank")
	term.setTextColor(colors.white)
	local scrW, scrH = term.getSize()
	if (type(message) == 'table') then
		for k, v in pairs(message) do
			term.setCursorPos(scrW/2-string.len(v)/2+1, scrH/2-math.ceil(#message/2)+k)
			term.write(v)
		end
	else
		term.setCursorPos(scrW/2-string.len(message)/2+1, scrH/2)
		term.write(message)
	end
end
 
function confirmScreen(message, data, steps, currentStep)
	local y = 2
	drawBackground()
	drawHeader(serverData and serverData.bankName or "Atlas Bank")
	if (steps ~= nil) then
		drawSteps(steps, currentStep)
		y = #steps+3
	end
	local scrW, scrH = term.getSize()
	term.setTextColor(specialTextColor)
	for k, v in pairs(message) do
		term.setCursorPos((scrW-string.len(v))/2, y)
		term.write(v)
		y = y+1
	end
	y = y+1
	if (data ~= nil) then
		for k, v in pairs(data) do
			local text = localization[lang][k]..": "..v
			term.setCursorPos((scrW-string.len(text))/2, y)
			term.write(text)
			y = y+1
		end
		y = y+1
	end
 
	local buttonY = math.min(scrH-3, y)
	local buttonW = 20
	local buttonX = scrW/2-buttonW/2
 
	local acceptButton = drawButton(acceptButtonColor, acceptSecondaryColor, buttonTextColor, buttonX, buttonY, buttonW, localization[lang].accept)
 
	local cancelButton = drawButton(cancelButtonColor, cancelSecondaryColor, buttonTextColor, buttonX, buttonY+2, buttonW, localization[lang].cancel)
 
	while true do
		local event, button, cx, cy = os.pullEvent("mouse_click")
		if (mouseInButton(acceptButton, cx, cy)) then
			return true
		end
		if (mouseInButton(cancelButton, cx, cy)) then
			return false
		end
	end
end
 
function textScreen(message)
	local y = 1
	local scrW, scrH = term.getSize()
	drawBackground()
	drawHeader(serverData and serverData.bankName or "Atlas Bank")
	term.setTextColor(colors.white)
	for k, v in pairs(message) do
		term.setCursorPos((scrW-string.len(v))/2+1, y)
		term.write(v)
		y = y+1
	end
 
	drawBackButton()
 
	os.pullEvent("mouse_click")
end

function getAssetQuotes()
	local message = {
		action = "getAssetQuotes"
	}
	while(true) do
		rednet.send(bankServerID, message, "mermegold")
		local sender, message = rednet.receive("mermegold", 3)
		if (message ~= nil and os.computerID() ~= sender and message.response ~= nil) then
			return message.response
		end
	end
end

function adjustAssetStock(assetId, amount)
	local message = {
		action = "adjustAssetStock",
		assetId = assetId,
		amount = amount
	}
	rednet.send(bankServerID, message, "mermegold")
	local sender, message = rednet.receive("mermegold")
	return message.success, message.response
end

function depositAsset(key, assetId, quantity)
	local message = {
		action = "depositAsset",
		key = key,
		assetId = assetId,
		quantity = quantity
	}
	rednet.send(bankServerID, message, "mermegold")
	local sender, message = rednet.receive("mermegold")
	return message.success, message.response
end

function withdrawAsset(key, assetId, quantity)
	local message = {
		action = "withdrawAsset",
		key = key,
		assetId = assetId,
		quantity = quantity
	}
	rednet.send(bankServerID, message, "mermegold")
	local sender, message = rednet.receive("mermegold")
	return message.success, message.response
end

function waitForDisk(message)
	waitScreen(message)
	while (not fs.exists("disk")) do
		local event = os.pullEvent()
		if (event == "disk") then
			break
		end
	end
end

function marketQuotesScreen(title, quotes, currencyLabel)
	drawBackground()
	local scrW, scrH = term.getSize()
	local backButton = drawBackButton()
	local first = 1
	local maxPerPage = math.max(1, math.floor((scrH-6) / 5))

	while true do
		drawBackground()
		drawHeader(title)

		local y = 4
		for i=first, math.min(#quotes, first+maxPerPage-1) do
			local quote = quotes[i]
			drawBox(panelEdgeColor, colors.gray, 2, y-1, scrW-2, 4)
			term.setCursorPos(4, y)
			term.setTextColor(colors.white)
			term.write(quote.name)
			y = y + 1
			term.setCursorPos(4, y)
			term.setTextColor(colors.lightGray)
			term.write("Achat: "..quote.depositPrice.." "..currencyLabel)
			term.setCursorPos(math.max(20, math.floor(scrW*0.45)), y)
			term.write("Retrait: "..quote.withdrawPrice.." "..currencyLabel)
			y = y + 1
			term.setCursorPos(4, y)
			term.write("Stock: "..quote.stock.." | Retrait max: "..quote.maxWithdraw)
			y = y + 1
			y = y + 1
		end

		local eventData = {os.pullEvent()}
		local event = eventData[1]
		if (event == "mouse_click") then
			local cx = eventData[3]
			local cy = eventData[4]
			if (mouseInButton(backButton, cx, cy)) then
				return
			end
		elseif (event == "mouse_scroll") then
			local scroll = eventData[2]
			if (scroll > 0 and first + maxPerPage - 1 < #quotes) then
				first = first + 1
			elseif (scroll < 0 and first > 1) then
				first = first - 1
			end
		end
	end
end
