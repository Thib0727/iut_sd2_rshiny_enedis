getwd()
setwd("../")
getwd()
adr_69 = read.csv2("adresses-69.csv")
liste_CP = unique(adr_69["code_postal"])
setwd("./main")
# UI de l'application


# GESTION DES PAGES
# 1- AFFICHAGE DE LA PAGE login_page
# 2- AFFICHAGE DE LA PAGE main
login_page = function() {
  fluidPage(
  titlePanel("Page de connexion"),
  sidebarLayout(
    sidebarPanel(
      textInput("username", "Identifiant:"),
      passwordInput("password", "Mot de passe:"),
      actionButton("login", "Connexion")
    ),
    mainPanel(
      textOutput("login_status")
    )
  )
)}




main_page = function() {
  dashboardPage(
  dashboardHeader(
    title = "GreenTech"
  ),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Carte Rhône", tabName = "carte_main"),
      menuItem("Filtrage", tabName = "carte_filtre"),
      menuItem("Graphiques", tabName = "graphiques_"),
      menuItem("Dataframe", tabName = "dataframe"),
      menuItem("Mode d'emplois", tabName = "modeemplois_")
    )
  ),
  dashboardBody(
    tabItems(
      tabItem( tabName = "carte_main",
        box(width = 12, leafletOutput("map_cp", height = 850))
      ),
               
      tabItem( tabName = "carte_filtre",
        
        # Ajout de la zone pour entrer un/des codes postaux
        box(height = 200,
          title = "Filtre par Code Postal",
          selectInput(
            inputId = "code_postal_filtre",
            label = "Code Postal :",
            choices = liste_CP,
            selected = "69001",
            multiple = T
            ),
        ),
        # Ajout de la zone pour un type de logement
        checkboxGroupInput(
          inputId = "type_logement_filtre",
          label = "Veuillez cocher vos choix :",
          choices = list("Maison" = "maison","Appartement" = "appartement"),
          selected = "maison"
        ),
        # Valider -> appliquer les filtres
        actionButton("appliquer_changements", "Valider"),
      ),
      
      # GRAPHIQUES DYNAMIQUES
          tabItem(tabName = "graphiques_",
              fluidRow(
                selectInput(
                  inputId = "varX",
                  label = "Variable à analyser : ",
                  choices = list("Indice DPE" = "Etiquette_DPE",
                                 "Indice GES" = "Etiquette_GES",
                                 "Type de bâtiment" = "Type_bâtiment"
                                 )
                )),
                fluidRow (
                box(width = 12, plotOutput("barplot")),
                box(width = 12, downloadButton("telecharger_graph1", "Télécharger le graphique"))
                ),
              fluidRow(
              
                textOutput("moyenne_conso"),
                textOutput("moyenne_conso_m2")
                
                
              ),
              fluidRow(
                
                box(width = 12, plotOutput("barplot_filtre")),
                box(width = 12, downloadButton("telecharger_graph2", "Télécharger le graphique"))
                
                      ),

              ),
      #DATAFRAME
      tabItem( tabName = "dataframe",
               DTOutput("raw_data")
               
      ),
      #MODE D'EMPLOI
      tabItem(tabName = "modeemplois_",
              renderText("Utilisation :"),
              renderText(" _ "),
              renderText("Sur l'onglet Carte vous trouverez représentés tous les départements du Rhône"),
              renderText("facilement analysables avec des données utiles comme le nombre d'enregistrements "),
              renderText("sur ce département, ou encore le code couleur qui vous indiquera à quel "),
              renderText("quartile appartiens ce département en terme de consommation 5 usages."),
              renderText("Ce graphique à pour but une première analyse simplifiée mais néanmoins élémentaire."),
              renderText("L'onglet Filtrage vous permettra comme son nom l'indique de filtrer afin d'affiner "),
              renderText("une recherche et se pencher sur une population réduite à l'aide de critères comme "),
              renderText("le type de logement et le code postal. Ces critères seront utilisés notamment sur "),
              renderText("l'onglet Graphiques"),
              renderText(" _ "),
              renderText("Sur l'onglet graphiques vous trouverez des analyses plus approfondies sur "),
              renderText("l'étude de la consommation d'énergie de la région. En effet des graphiques vous "),
              renderText("permettront de choisir quelle variable étudier et vous pourrez comparer les "),
              renderText("résultats observés entre la population totale et une population cilbée grâce "),
              renderText("aux critères de type de logement et de code postal."),
              renderText(" _ "),
              renderText("Sur l'onglet Dataframe, vous trouverez des informations utiles notamment pour "),
              renderText("la maintenance de l'outil, où des vérifications techniques sur les résultats "),
              renderText("de la requête API."),
              renderText(" _ "),
              renderText("Vous trouverez des informations supplémentaires dans le fichier Readme.md du projet."),
              renderText("Si vous rencontrez un problème, ou si notre projet à piqué votre curiosité,"),
              renderText("n'hésitez pas à faire un tour sur notre page GitHub :"),
              renderText("https://github.com/Thib0727/iut_sd2_rshiny_enedis"),
              renderText(" _ "),
              renderText("Merci,"),
              renderText(" _ "),
              renderText("- L'équipe de développement")
              
          )
    )
    )
  )
}



ui = uiOutput("main_ui")



# Run the application 
# shinyApp(ui = ui, server = server)

