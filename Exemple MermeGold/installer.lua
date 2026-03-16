-- Pour creer une disquette d'installation, utilisez cette commande
-- wget URL_DE_INSTALLER installer.lua
-- puis lancez : installer

local installerDiskUrl = "https://raw.githubusercontent.com/VOTRE_USER/VOTRE_REPO/main/Exemple%20MermeGold/installer%20disk.lua"

local diskdrive = peripheral.find("drive")
while (not diskdrive.isDiskPresent()) do
	term.clear()
	term.setCursorPos(1,1)
	print("Veuillez inserer une disquette dans le lecteur pour creer la disquette d'installation...")
	os.pullEvent("disk")
end

fs.delete("disk/startup.lua")
shell.run("wget "..installerDiskUrl.." disk/startup.lua")
diskdrive.setDiskLabel("Atlas Bank Installer Disk")
print("Disquette d'installation creee")
sleep(2)
os.reboot()
