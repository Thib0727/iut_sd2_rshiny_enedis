Architecture du projet :

Projet R
│
├── main
│ ├── ui.R
│ └── server.R
│
├── www
│ └──custom.css
│
├── app.R
├── adresses-69.csv
├── Readme.md
│
├── RData
├── .RData
├── Rhistory
└── .Rhistory

Le fichier server.R servira à requêter les données de l'API publique de l'ADEME "DPE Logements existants (depuis juillet 2021)" (sources en bas de page) et ainsi construire le dataframe que l'on utilisera tout au long de ce projet. C'est sur ce fichier que l'on spécifiera le comportement du server pour l'affichage de la carte interactive ou encore des histogrammes. C'est le fichier traitant du "back-end" de ce projet.

Le fichier ui.R nous permets de construire l'interface utilisateur et ainsi paramétrer l'ordre, le style ou encore les clefs d'identification de chaque élément et ainsi assurer l'accessibilité du Projet aussi bien à un utilisateur expérimenté qu'à un utilisateur moins chevronné. C'est le fichier "front-end" du projet.

Le fichier app.R nous permets de mettre en place l'environnement de travail avec l'installation des bibliothèques nécessaires à l'exécution du code mais il nous permet aussi de mettre en commun les fichiers server.R et ui.R afin d'assembler le projet.

Le fichier custom.css nous permets d'appliquer un style à l'ensemble du projet

Le fichier adresse-69.csv est un fichier donné au début du projet afin de lister les départements du Rhône.

Sources: API utilisée : https://data.ademe.fr/datasets/dpe-v2-logements-existants/api-doc


DOCUMENTATION TECHNIQUE
Cette partie a pour but de documenter techniquement notre projet afin de mieux le comprendre.
Pour la conception de ce projet, nous avons eu pour missions de réaliser une application, grâce au langage de programmation RShiny, pour observer sur une carte les différents
logements d'une région en fonction de la classe de chacun dans le Diagnostic de Performance Energétique (DPE).
Pour installer l'application sur votre poste, il vous suffit d'installer le fichier ZIP disponible et de l'extraire là où vous le souhaitez. Ainsi il ne vous restera plus qu'à changer
correctement les chemins d'accès dans les programmes au niveau des "setwd", dans les 3 fichiers R.
Pour réaliser l'application nous avons requêter les données de l'API publique de l'ADEME afin de construire une base de données utilisable tout le long du projet.

Pour mener à bien ce projet nous avons, dans la partie app.R, eu recourt à différents "packages" qui contiennent des fonctions qui ne sont pas installées dans R par défaut et qui nous
permet de réaliser toute sorte de programmes : - "shiny" : pour créer l'applications interactive avec R
- "httr" : pour faire des requêtes HTTP et interagir avec l'application
- "jsonlite" : pour manipuler les données statistiquement dans une application
- "RMySQL" : pour faire des requêtes SQL dans R
- "tidygeocoder" : pour utiliser les données dans un système géographique facilement
- "leaflet" : pour créer une carte interactive
- "readr" : pour lire des données rectangulaire
- "shinyjs" : pour pratiquer du JavaScript sans pour autant connaître le JavaScript
- "shinydashboard" : pour créer des tableaux de bords
- "dplyr" : pour faire des analyses des données facilement
- "sp" : pour utiliser les données spatials et les modéliser facilement
- "DT" : pour filtrer facilement

Dans la partie server.R du projet, nous avons codé toutes sortes de programmes afin d'alimenter au mieux l'application. On y retrouve particulièrement la requête afin de récolter les données de l'API, mais aussi différents calculs, la création de la carte interactive et de graphiques. C'est ce qu'on appelle la partie "back-end" de l'application car celle-ci n'interagit pas directement sur le premier plan de l'application.

Dans la partie ui.R, nous avons codé toutes sortes de programmes afin d'alimenter l'application avec une interface. En effet c'est dans cette partie que l'on définit l'interface de son application ce qui vient à définir le type de pages utilisées, le titre, le nombre d'onglets et leurs noms, ainsi que le nombre d'endroits disponible à l'accueil de données (appelé "box"). C'est ce qu'on appelle la partie "front-end" du projet car c'est la partie que l'on voit en premier lors de l'ouverture d'une application. Dans l'application, on y retrouve 2 pages distinctes l'une de l'autre :

- La page de connexion : dans celle-ci vous devez renseignez un nom d'utilisateur et un mot de passe pour avoir accès à l'application. Aucune importance sur les valeurs que vous entrez dans cette page cependant, il faut absolument renseignez quelques choses sinon l'accès vous sera refusez.

- La page de l'application avec 5 onglets différents :
- L'onglet Carte Rhône, où on y retrouve la carte du Rhône avec les points de chaque code postal. En sélectionnant un point, vous pouvez retrouvez les infos principales sur le code postal concernant la consommation. Nous avons décidé de ne pas afficher tous les points de chaque logement car nous ne voyons pas l'intérêt de naviguer sur une carte si elle est illisible.
- L'onglet Filtrage, où l'on peut faire des filtres reliés au 2ème graphiques de l'onglet Graphiques.
- L'onglet Graphiques, où l'on retrouve différents graphiques avec différentes corrélation afin de mieux comprendre les données que nous utilisons.
- L'onglet Dataframe, où l'on retrouve l'intégralité des données sous forme de tableau. Vous pouvez appliquer plusieurs filtres comme par exemple, trier chaque colonne par ordre croissant ou décroissant ou encore faire une recherche de la valeur que vous souhaitée recherchez.
- L'onglet Mode d'emplois, où l'on retrouve principalement du texte afin d'expliquer le principe de ce projet, comment l'utiliser et ce qui le compose.
