-- Atlas Bank Terminal

local localization = {
	fr = {
		welcome = "Bienvenue !",
		login = "Se connecter",
		info = "Qu'est-ce qu'Atlas Bank ?",
		create_account = "Comment ouvrir un compte ?",
		pricing = "Cours du marche",
		insert_card = {"","","","","","Veuillez inserer votre", "carte ou telephone dans le lecteur"},
		info_screen = {
			"","","",
			"Bienvenue chez Atlas Bank !",
			"",
			"Atlas Bank est une banque privee RP moderne.",
			"Vous pouvez y stocker de la valeur sous forme",
			"numerique, faire des virements a distance et",
			"consulter l'historique de vos mouvements.",
			"",
			"Notre marche accepte plusieurs actifs selon",
			"des prix dynamiques, avec une reserve geree",
			"par la banque."
		},
		create_account_screen = {
			"","","","","","","",
			"Pour ouvrir un compte, rendez-vous a une borne",
			"d'inscription Atlas Bank ou contactez un employe.",
			"Une carte ou un telephone bancaire pourra",
			"ensuite etre lie a votre compte.",
		},
		check_balance = "Consulter le solde",
		perform_transaction = "Faire un virement",
		history = "Historique",
		market = "Voir le marche",
		logout = "Quitter",
		transaction_instructions = {"Compte destinataire", "Montant a envoyer", "Description du virement"},
		succesful_logout = "A bientot !",
		no_card = "Aucune carte detectee",
		refresh_to_login = "Reinserez votre carte puis redemarrez"
	},
	en = {
		welcome = "Welcome!",
		login = "Log In",
		info = "What is Atlas Bank?",
		create_account = "How do I open an account?",
		pricing = "Market rates",
		insert_card = {"","","","","","Please insert your", "card or phone in the disk drive"},
		info_screen = {
			"","","",
			"Welcome to Atlas Bank!",
			"",
			"Atlas Bank is a modern RP private bank.",
			"You can store value digitally, make remote",
			"transfers and review your full transaction log.",
			"",
			"Our market accepts multiple assets with",
			"dynamic pricing and reserve management."
		},
		create_account_screen = {
			"","","","","","","",
			"To open an account, visit an Atlas Bank",
			"registration kiosk or contact an employee.",
			"A card or bank phone can then be linked",
			"to your account.",
		},
		check_balance = "Check balance",
		perform_transaction = "Make transfer",
		history = "Log",
		market = "View market",
		logout = "Exit",
		transaction_instructions = {"Recipient account", "Amount to send", "Transfer description"},
		succesful_logout = "See you later!",
		no_card = "No card detected",
		refresh_to_login = "Reinsert your card and reboot"
	}
}

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

local diskdrive = peripheral.find("drive")
os.loadAPI("bankapi.lua")
local serverData = bankapi.getServerData()
local lang = serverData.lang or "fr"

local currentAccount = 0
if (diskdrive ~= nil and diskdrive.isDiskPresent()) then
	local f = fs.open("disk/atlasbank.txt", "r")
	if (f ~= nil) then
		local value = f.readLine()
		f.close()
		if (value ~= nil) then
			local tempClientData = bankapi.getClientData()
			if (tempClientData[value] ~= nil) then
				currentAccount = value
			end
		end
	end
end

while true do
while true do
	local tempClientData = bankapi.getClientData()
	local command

	if (tempClientData[currentAccount] == nil) then
		command = bankapi.optionMenu(localization[lang].welcome, {
			{option = "login", text = localization[lang].login},
			{option = "info", text = localization[lang].info},
			{option = "createaccount", text = localization[lang].create_account},
			{option = "pricing", text = localization[lang].pricing},
		})

		if (command == "login") then
			if (diskdrive ~= nil and diskdrive.isDiskPresent()) then
				os.reboot()
			end
			local accept = bankapi.confirmScreen(localization[lang].insert_card)
			if (accept) then
				os.reboot()
			end
		elseif (command == "info") then
			bankapi.textScreen(localization[lang].info_screen)
		elseif (command == "createaccount") then
			bankapi.textScreen(localization[lang].create_account_screen)
		elseif (command == "pricing") then
			local quotes = bankapi.getAssetQuotes()
			bankapi.marketQuotesScreen(serverData.bankName or "Atlas Bank", quotes, serverData.currencyLabel or "Credits")
		end
	else
		local line = string.rep(string.char(140), 3)
		command = bankapi.optionMenu(line.." "..tempClientData[currentAccount].name.." "..line, {
			{option = "balance", text = localization[lang].check_balance},
			{option = "transaction", text = localization[lang].perform_transaction},
			{option = "market", text = localization[lang].market},
			{option = "log", text = localization[lang].history},
			{option = "logout", text = localization[lang].logout},
		}, 2)

		if (command == "balance") then
			bankapi.showBalance(currentAccount)

		elseif (command == "transaction") then
			local steps = localization[lang].transaction_instructions
			local to = bankapi.selectAccountScreen(steps, 1, currentAccount)
			if (to == nil) then break end
			local amount = bankapi.inputNumberScreen(steps, 2, tempClientData[currentAccount].balance)
			if (amount == nil) then break end
			local description = bankapi.inputTextScreen(steps, 3, 100)
			if (description == nil) then break end
			local success, message = bankapi.transaction(currentAccount, to, amount, description)
			bankapi.responseScreen(success, message)

		elseif (command == "market") then
			local quotes = bankapi.getAssetQuotes()
			bankapi.marketQuotesScreen(serverData.bankName or "Atlas Bank", quotes, serverData.currencyLabel or "Credits")

		elseif (command == "log") then
			bankapi.transactionLogScreen(currentAccount)

		elseif (command == "logout") then
			if (diskdrive ~= nil and diskdrive.isDiskPresent()) then
				diskdrive.ejectDisk()
			end
			bankapi.successScreen(localization[lang].succesful_logout)
			os.shutdown()
		end
	end
end
end
