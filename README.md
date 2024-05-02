# Quilibrium Mining Guide

Ce guide vous permettra de configurer un noeud de minage pour le réseau Quilibrium.
voir [Resources](#resources) pour plus d'informations.

## Prérequis

Dans ce guide, nous utiliserons WSL (Windows Subsystem for Linux) [guide](https://docs.microsoft.com/en-us/windows/wsl/install) pour installer notre noeud de minage. Vous pouvez également utiliser un système d'exploitation Linux.

## Configuration Minimale

| Configuration Minimale               |
| ------------------------------------ |
| 16-32Go RAM                          |
| 250Go SSD                            |
| Processeur 12Coeurs - 3.0GHz         |
| Bande passante symétrique de 50 Mo/s |

## Installation

Avant de continuer, assurez-vous d'avoir rempli les [prérequis](#prérequis).

## Mise en place de l'environnement

Avant de commencer, nous allons installer quelques outils nécessaires pour la configuration de notre noeud de minage, à savoir :

- `Git` pour cloner le dépôt de Quilibrium
- `Go` pour compiler le code source de Quilibrium

### Installation de Git

Pour installer Git, vous pouvez suivre les instructions suivantes:

```bash
sudo apt install git -y
git --version
```

### Installation de Go

Pour installer Go, vous pouvez suivre les instructions suivantes:

```bash
sudo apt -q update
wget https://go.dev/dl/go1.20.14.linux-amd64.tar.gz
sudo tar -xvf go1.20.14.linux-amd64.tar.gz
```

On peut déplacer le répertoire `go` dans le répertoire `/usr/local`:

```bash
sudo mv go /usr/local
```

et supprimer l'archive:

```bash
sudo rm go1.20.14.linux-amd64.tar.gz
```

Ensuite, on peut ajouter les variables d'environnement dans le fichier `.bashrc`:

```bash
GOROOT=/usr/local/go
GOPATH=$HOME/go
PATH=$GOPATH/bin:$GOROOT/bin:$PATH
```

> **NOTE** \
> Le fichier `.bashrc` est un fichier caché dans votre répertoire personnel. \
> Il est situé dans `~/.bashrc`. Vous pouvez l'éditer avec votre éditeur de texte préféré.

On peut maintenant recharger le fichier `.bashrc`:

```bash
source ~/.bashrc
```

Pour vérifier que Go a bien été installé, vous pouvez exécuter la commande suivante:

```bash
go version
```

### Installation du client Quilibrium

On commence par cloner le dépôt de Quilibrium et ce placer dans le répertoire `node`:

```bash
git clone https://github.com/QuilibriumNetwork/ceremonyclient.git
cd ceremonyclient/node
```

On peut maintenant lancez notre noeud de minage:

```bash
GOEXPERIMENT=arenas go run ./...
```

Après quelques minutes, une fois que les clés ont été générées, vous pouvez tuer le processus avec `Ctrl+C` et redémarrer votre machine.

> **ATTENTION** \
> Ne pas oublier de sauvegarder les clés générées dans un endroit sûr. \
> Les clés sont stockées dans le répertoire `/ceremonyclient/node/.config/`. \
> Copier les fichiers `config.yml` et `keys.yml` dans un dossier sécurisé.

Votre clé publique a du être générée et affichée dans la console (c'est le Peer-ID).
Copiez cette clé et sauvegardez-la dans un fichier.

### Création d'un Service _systemd_

Nous allons avoir besoin de générer le binaire du noeud de minage pour pouvoir le lancer en tant que service.

```bash
cd ~/ceremonyclient/node
GOEXPERIMENT=arenas go install ./...
```

Cette commande devrait créer un répertoire `~/go/bin/`. Vérifiez cela avec la commande suivante, et le message `node` devrait apparaître dans la console.

```bash
ls /root/go/bin
```

Nous allons maintenant créer un fichier de configuration pour notre service _systemd_.

```bash
touch /lib/systemd/system/ceremonyclient.service
```

Cela va créer un fichier vide dans le répertoire `/lib/systemd/system/`.
Vous pouvez maintenant éditer ce fichier avec votre éditeur de texte préféré et y ajouter le contenu suivant:

```bash
[Unit]
Description=Ceremony Client Go App Service

[Service]
CPUQuota=720%
Type=simple
Restart=always
RestartSec=5s
WorkingDirectory=/root/ceremonyclient/node
Environment=GOEXPERIMENT=arenas
ExecStart=/root/go/bin/node ./...

[Install]
WantedBy=multi-user.target
```

Dans ce script, le paramètre `CPUQuota` est défini à 720% pour limiter l'utilisation du CPU.
Cette valeur est appliquée à un processeur 8 coeurs. Si vous avez plus de coeurs, vous pouvez changer cette valeur en conséquence.
Cette valeur est calculée de cette manière: `720% = 8 * 90%`.
avec 8 le nombre de coeurs et 90% la limite de CPU par coeur.

Ce script va également redémarrer le service en cas d'arrêt (utile en cas de crash).

Maintenant, pour activer le service, vous pouvez exécuter les commandes suivantes:

```bash
systemctl daemon-reload
systemctl enable ceremonyclient
systemctl start ceremonyclient
```

Pour ouvrir le journal du service, vous pouvez utiliser la commande suivante:

```bash
sudo journalctl -u ceremonyclient.service -f --no-hostname -o cat
```

Rien ne devrait s'afficher pour le moment, car nous n'avons pas encore lancé le service.
Sur une autre fenêtre de terminal, vous pouvez lancer le service avec la commande suivante:

```bash
service ceremonyclient start
```

Vous pouvez maintenant vérifier le journal du service pour voir si tout fonctionne correctement.

## Commandes du Service

Pour arrêter le service, vous pouvez utiliser la commande suivante:

```bash
service ceremonyclient stop
```

Pour redémarrer le service, vous pouvez utiliser la commande suivante:

```bash
service ceremonyclient start
```

## Resources

- [Official Website Quilibrium](https://quilibrium.com/)
- [Official Documentation Quilibrium](https://quilibrium.com/docs)
- [PDF tutorial](./resources/documentation.pdf)
- [Github Demipoet Tutorial](https://github.com/demipoet/quilibrium-guide)
