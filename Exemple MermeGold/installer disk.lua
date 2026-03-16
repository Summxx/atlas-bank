-- Atlas Bank Installer Disk

local githubBaseUrl = "https://raw.githubusercontent.com/Summxx/atlas-bank/main/Exemple%20MermeGold"

local files = {
	bankapi = githubBaseUrl.."/bankapi.lua",
	pixelui = githubBaseUrl.."/pixelui.lua",
	shrekbox = githubBaseUrl.."/shrekbox.lua",
	bankserver = githubBaseUrl.."/bankserver/startup.lua",
	adminterminal = githubBaseUrl.."/adminterminal/startup.lua",
	atminterface = githubBaseUrl.."/atminterface/startup.lua"
}

local function downloadFile(url, path)
	if (fs.exists(path)) then
		fs.delete(path)
	end
	shell.run("wget "..url.." "..path)
end

function quit()
	local diskdrive = peripheral.find("drive")
	if (diskdrive.isDiskPresent()) then
		diskdrive.ejectDisk()
	end
	print("Disquette ejectee")
	print("Redemarrage...")
	sleep(1)
	os.reboot()
end

function optionsMenu(title, description, options)
	local selectedOption = 1
	while true do
		term.clear()
		term.setCursorPos(1,1)

		print("=== "..title.." ===")
		print()

		for k, v in pairs(description) do
			print(v)
		end
		print()

		for k, v in pairs(options) do
			local text = v
			if (selectedOption == k) then
				text = "-> "..v.." <-"
			else
				text = "   "..v
			end
			print(text)
		end

		local event, key = os.pullEvent("key")
		local keyName = keys.getName(key)
		if (keyName == "w" or keyName == "up") then
			selectedOption = selectedOption - 1
			if (selectedOption <= 0) then
				selectedOption = #options
			end
		elseif (keyName == "s" or keyName == "down") then
			selectedOption = selectedOption + 1
			if (selectedOption > #options) then
				selectedOption = 1
			end
		elseif (keyName == "d" or keyName == "right" or keyName == "enter" or keyName == "space") then
			return selectedOption
		end
	end
end

function installBankServer()
	print("Installation du serveur Atlas Bank...")
	downloadFile(files.bankapi, "bankapi.lua")
	downloadFile(files.bankserver, "startup.lua")
	quit()
end

function installAdminTerminal()
	print("Installation du terminal admin Atlas Bank...")
	downloadFile(files.bankapi, "bankapi.lua")
	downloadFile(files.adminterminal, "startup.lua")
	quit()
end

function installATMInterface()
	print("Installation du terminal public Atlas Bank...")
	downloadFile(files.bankapi, "bankapi.lua")
	downloadFile(files.pixelui, "pixelui.lua")
	downloadFile(files.shrekbox, "shrekbox.lua")
	downloadFile(files.atminterface, "startup.lua")
	quit()
end

function showHelp()
	term.clear()
	term.setCursorPos(1,1)
	while (true) do
		local selectedOption = optionsMenu("Aide", {"Atlas Bank a besoin de plusieurs ordinateurs pour fonctionner."},
		{
			"Serveur bancaire",
			"Terminal admin",
			"Terminal public",
			"[Retour]"
		})
		term.clear()
		term.setCursorPos(1,1)
		if (selectedOption == 1) then
			print("=== Serveur bancaire ===")
			print("")
			print("Un ordinateur avance avec modem, dans une zone toujours chargee.")
			print("C'est le coeur de la banque: comptes, historique, reserves et marche.")
			print("")
			print("Appuyez sur une touche pour revenir...")
			os.pullEvent("key")
		elseif (selectedOption == 2) then
			print("=== Terminal admin ===")
			print("")
			print("Utilise pour creer les comptes, voir les historiques,")
			print("lier les cartes et ajuster les reserves des actifs.")
			print("")
			print("Appuyez sur une touche pour revenir...")
			os.pullEvent("key")
		elseif (selectedOption == 3) then
			print("=== Terminal public ===")
			print("")
			print("Permet aux joueurs de consulter leur solde, faire des virements")
			print("et consulter les cours du marche avec leur carte ou telephone.")
			print("")
			print("Appuyez sur une touche pour revenir...")
			os.pullEvent("key")
		elseif (selectedOption == 4) then
			mainMenu()
			break
		end
	end
end

function mainMenu()
	local selectedOption = optionsMenu("Installer un programme Atlas Bank", {"Pour ordinateur"}, {
		"Aide",
		"Installer le serveur bancaire",
		"Installer le terminal admin",
		"Installer le terminal public",
		"Annuler et ejecter"
	})
	if (selectedOption == 1) then
		showHelp()
	elseif (selectedOption == 2) then
		installBankServer()
	elseif (selectedOption == 3) then
		installAdminTerminal()
	elseif (selectedOption == 4) then
		installATMInterface()
	else
		quit()
	end
end

mainMenu()
