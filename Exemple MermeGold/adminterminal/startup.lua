-- Atlas Bank Admin Terminal

local text_error_noconnection = "Impossible de contacter le serveur"

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

os.loadAPI("bankapi.lua")
local serverData = bankapi.getServerData()
local lang = serverData.lang or "fr"

local localization = {
	fr = {
		create_account = "Creer un compte",
		perform_transaction = "Effectuer un virement",
		check_balance = "Consulter un solde",
		delete_account = "Supprimer un compte",
		record = "Historique d'un compte",
		assign_card = "Lier une carte / un telephone",
		market = "Consulter le marche",
		adjust_stock = "Ajuster les reserves",
		logout = "Quitter",
		new_account_steps = {"Nom du joueur", "Couleur representative"},
		transaction_steps = {"Compte expediteur", "Compte destinataire", "Montant", "Description"},
		delete_account_steps = {"Compte a supprimer"},
		check_log = {"Compte a consulter"},
		account_to_link = {"Compte a lier"},
		linked_to = "Carte liee a ",
		insert_card = "Veuillez inserer une disquette ou un telephone dans le lecteur",
		confirm_deletion = "Voulez-vous vraiment supprimer ce compte ?",
		stock_steps = {"Choisir l'actif", "Quantite a ajouter ou retirer"},
		stock_done = "Reserve mise a jour",
		installed = "Installation terminee"
	},
	en = {
		create_account = "Create account",
		perform_transaction = "Perform transfer",
		check_balance = "Check balance",
		delete_account = "Delete account",
		record = "Account log",
		assign_card = "Link card / phone",
		market = "View market",
		adjust_stock = "Adjust reserves",
		logout = "Exit",
		new_account_steps = {"Player name", "Representative color"},
		transaction_steps = {"Sender account", "Recipient account", "Amount", "Description"},
		delete_account_steps = {"Account to delete"},
		check_log = {"Account to inspect"},
		account_to_link = {"Account to link"},
		linked_to = "Card linked to ",
		insert_card = "Please insert a disk or phone in the drive",
		confirm_deletion = "Are you sure you want to delete this account?",
		stock_steps = {"Choose asset", "Quantity to add or remove"},
		stock_done = "Reserve updated",
		installed = "Install finished"
	}
}

local function assetOptionList()
	local quotes = bankapi.getAssetQuotes()
	local options = {}
	for _, quote in ipairs(quotes) do
		table.insert(options, {
			option = quote.id,
			text = quote.name.." | stock "..quote.stock
		})
	end
	return options, quotes
end

local pass = ""
repeat
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.yellow)
	term.clear()
	local scrW, scrH = term.getSize()
	local title = serverData.bankName or "Atlas Bank"
	term.setCursorPos(scrW/2-string.len(title)/2, scrH/2)
	term.write(title)
	term.setCursorPos(scrW/2-string.len(title)/2, scrH/2+1)
	pass = read("*")
until (pass == serverData.terminalPassword)

while true do
while true do
	local command = bankapi.optionMenu(serverData.bankName or "Atlas Bank", {
		{option = "new", text = localization[lang].create_account},
		{option = "transaction", text = localization[lang].perform_transaction},
		{option = "balance", text = localization[lang].check_balance},
		{option = "log", text = localization[lang].record},
		{option = "market", text = localization[lang].market},
		{option = "stock", text = localization[lang].adjust_stock},
		{option = "assigncard", text = localization[lang].assign_card},
		{option = "delete", text = localization[lang].delete_account},
		{option = "logout", text = localization[lang].logout},
	}, 2, 38)

	if (command == "new") then
		local steps = localization[lang].new_account_steps
		local name = bankapi.inputTextScreen(steps, 1, 25)
		if (name == nil) then break end
		local color = bankapi.selectColorScreen(steps, 2)
		if (color == nil) then break end
		local success, message = bankapi.newAccount(name, 0, color)
		bankapi.responseScreen(success, message)

	elseif (command == "transaction") then
		local tempClientData = bankapi.getClientData()
		local steps = localization[lang].transaction_steps
		local from = bankapi.selectAccountScreen(steps, 1, 0)
		if (from == nil) then break end
		local to = bankapi.selectAccountScreen(steps, 2, from)
		if (to == nil) then break end
		local amount = bankapi.inputNumberScreen(steps, 3, tempClientData[from].balance)
		if (amount == nil) then break end
		local description = bankapi.inputTextScreen(steps, 4, 100)
		if (description == nil) then break end
		local success, message = bankapi.transaction(from, to, amount, description)
		bankapi.responseScreen(success, message)

	elseif (command == "balance") then
		local account = bankapi.selectAccountScreen(localization[lang].check_log, 1, 0)
		if (account == nil) then break end
		bankapi.showBalance(account)

	elseif (command == "log") then
		local account = bankapi.selectAccountScreen(localization[lang].check_log, 1, 0)
		if (account == nil) then break end
		bankapi.transactionLogScreen(account)

	elseif (command == "market") then
		local quotes = bankapi.getAssetQuotes()
		bankapi.marketQuotesScreen(serverData.bankName or "Atlas Bank", quotes, serverData.currencyLabel or "Credits")

	elseif (command == "stock") then
		local options = assetOptionList()
		local assetId = bankapi.optionMenu(localization[lang].adjust_stock, options, 2, 40)
		if (assetId == nil) then break end
		local quantity = bankapi.inputNumberScreen(localization[lang].stock_steps, 2)
		if (quantity == nil) then break end
		local success, message = bankapi.adjustAssetStock(assetId, tonumber(quantity))
		bankapi.responseScreen(success, message)

	elseif (command == "assigncard") then
		if (fs.exists("disk")) then
			local account = bankapi.selectAccountScreen(localization[lang].account_to_link, 1, 0)
			if (account == nil) then break end
			local tempClientData = bankapi.getClientData()
			local name = tempClientData[account].name
			local f = fs.open("disk/atlasbank.txt", "w")
			f.write(account)
			f.close()
			local diskdrive = peripheral.find("drive")
			diskdrive.setDiskLabel("Atlas Bank | "..name)
			bankapi.successScreen(localization[lang].linked_to..name)
		else
			bankapi.errorScreen(localization[lang].insert_card)
		end

	elseif (command == "delete") then
		local steps = localization[lang].delete_account_steps
		local deletion = bankapi.selectAccountScreen(steps, 1, 0)
		if (deletion == nil) then break end
		local tempClientData = bankapi.getClientData()
		local accept = bankapi.confirmScreen({localization[lang].confirm_deletion}, {
			name = tempClientData[deletion].name,
			key = deletion,
			balance = tempClientData[deletion].balance
		})
		if (not accept) then break end
		local success, message = bankapi.deleteAccount(deletion)
		bankapi.responseScreen(success, message)

	elseif (command == "logout") then
		os.reboot()
	end
end
end
