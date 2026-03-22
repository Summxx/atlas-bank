-- Pour creer une disquette d'installation, utilisez cette commande
-- wget "https://raw.githubusercontent.com/Summxx/atlas-bank/main/Exemple%20MermeGold/installer.lua" installer.lua
-- puis lancez : installer

local installerDiskUrl = "https://raw.githubusercontent.com/Summxx/atlas-bank/main/Exemple%20MermeGold/installer%20disk.lua"
local installPath = "disk/startup.lua"

local function ensureDrive()
	local diskdrive = peripheral.find("drive")
	while (diskdrive == nil or not diskdrive.isDiskPresent()) do
		term.clear()
		term.setCursorPos(1,1)
		print("Veuillez inserer une disquette dans le lecteur pour creer la disquette d'installation...")
		os.pullEvent("disk")
		diskdrive = peripheral.find("drive")
	end
	return diskdrive
end

local function download(url, path)
	if (fs.exists(path)) then
		fs.delete(path)
	end
	return shell.run("wget", url, path)
end

local diskdrive = ensureDrive()

local success = download(installerDiskUrl, installPath)
if (not success) then
	term.clear()
	term.setCursorPos(1, 1)
	print("Echec du telechargement de l'installateur.")
	print("Verifiez la connexion Internet/HTTP puis reessayez.")
	sleep(3)
	return
end

diskdrive.setDiskLabel("Atlas Bank Installer Disk")
print("Disquette d'installation creee")
sleep(2)
os.reboot()
