# Atlas Bank

Projet bancaire RP base sur la structure Mermegold, adapte pour Atlas Bank.

## Contenu

- `Exemple MermeGold/bankapi.lua`
- `Exemple MermeGold/bankserver/startup.lua`
- `Exemple MermeGold/adminterminal/startup.lua`
- `Exemple MermeGold/atminterface/startup.lua`
- `Exemple MermeGold/storeclerk/startup.lua`
- `Exemple MermeGold/installer.lua`
- `Exemple MermeGold/installer disk.lua`

## Installation

Le flux d'installation utilise `GitHub Raw` via `wget`.

Pour creer une disquette d'installation Atlas Bank :

```lua
wget "https://raw.githubusercontent.com/Summxx/atlas-bank/main/Exemple%20MermeGold/installer.lua" installer.lua
installer
```

L'installateur permet ensuite de deployer :

- le serveur bancaire
- le terminal admin
- le terminal public ATM
- la boutique `storeclerk`

## Modules

- `bankserver` : coeur de la banque, comptes, historique, reserves et marche.
- `adminterminal` : gestion des comptes, cartes, journaux et actifs.
- `atminterface` : terminal public monitor avec ouverture de compte et marche d'actifs.
- `storeclerk` : boutique basee sur turtle avec paiement Atlas Bank.

## Statut

Base Mermegold conservee, avec adaptation Atlas Bank, theme sombre moderne, marche d'actifs et flux d'installation unifie.
