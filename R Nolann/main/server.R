
source("ui.R")

# chargement de l'asset adresses-69.csv et memorisation code postaux

getwd()
setwd("../")
getwd()
adr_69 = read.csv2("adresses-69.csv")
liste_CP = unique(adr_69["code_postal"])
setwd("./main")

# creation du dataframe
df_result = data.frame()

# annee actuelle afin d'assurer la pérennité de l'application (la requette selectionnera les donnees du 01/01/2021 jusqu'au 31/12/annee de compilation du code)
annee_actuelle = as.integer(format.Date(Sys.Date(), format = "%Y"))

for (cp in liste_CP$code_postal) {
  print(cp)
  
  base_url <- "https://data.ademe.fr/data-fair/api/v1/datasets/dpe-v2-logements-existants/lines"
  # Paramètres de la requête
  
  
  params = list(
    select = "N°DPE,Coordonnée_cartographique_X_(BAN),Coordonnée_cartographique_Y_(BAN),Etiquette_GES,Etiquette_DPE,Type_bâtiment,Code_postal_(BAN),Conso_5_usages_é_finale,Conso_5_usages/m²_é_finale",
    size = 10000,
    q = cp,
    q_fields = "Code_postal_(BAN)",
    qs = paste("Date_réception_DPE:[2021-01-01 TO ", annee_actuelle, "-12-31]",sep="") # prise en compte de l'annee actuelle
    )
  
  # Encodage des paramètres
  url_encoded <- modify_url(base_url, query = params)
  #print(url_encoded)
  
  # Effectuer la requête
  response <- GET(url_encoded)
  
  # Afficher le statut de la réponse
  print(status_code(response))
  
  # On convertit le contenu brut (octets) en une chaîne de caractères (texte). Cela permet de transformer les données reçues de l'API, qui sont généralement au format JSON, en une chaîne lisible par R
  content = fromJSON(rawToChar(response$content), flatten = FALSE)
  
  
  # optimisation si le résultat de la requete est trop volumineux
  len_df = content$total
  
  if(len_df > 9999) {
    years = seq(2021, annee_actuelle, 1)
    for (year in years) {
      
      base_url = "https://data.ademe.fr/data-fair/api/v1/datasets/dpe-v2-logements-existants/lines"

      params = list(
      select = "N°DPE,Coordonnée_cartographique_X_(BAN),Coordonnée_cartographique_Y_(BAN),Etiquette_GES,Etiquette_DPE,Type_bâtiment,Code_postal_(BAN),Conso_5_usages_é_finale,Conso_5_usages/m²_é_finale",
      size = 10000,
      q = cp,
      q_fields = "Code_postal_(BAN)",
      qs = paste("Date_réception_DPE:[",year,"-01-01 TO ",year,"-12-31]",sep = ""))
      
      # Encodage des paramètres
      url_encoded = modify_url(base_url, query = params)
      
      # Effectuer la requête
      response = GET(url_encoded)
      
      # Afficher le statut de la réponse
      print(year)
      print(status_code(response))
      
      # On convertit le contenu brut (octets) en une chaîne de caractères (texte). Cela permet de transformer les données reçues de l'API, qui sont généralement au format JSON, en une chaîne lisible par R
      content = fromJSON(rawToChar(response$content), flatten = FALSE)
      df_result = rbind(df_result, content$results)
      
    }
  } else { df_result = rbind(df_result,content$result) }
}


#######################################################
# FORMATTER LE DATAFRAME POUR FACILITER L'UTILISATION #
#######################################################

colnames(df_result)[colnames(df_result) == "Coordonnée_cartographique_X_(BAN)"] = "CoordX"
colnames(df_result)[colnames(df_result) == "Coordonnée_cartographique_Y_(BAN)"] = "CoordY"
colnames(df_result)[colnames(df_result) == "Code_postal_(BAN)"] = "Code_postal"
colnames(df_result)[colnames(df_result) == "Conso_5_usages/m²_é_finale"] = "Conso_5_usages_m2"
df_result[df_result$Type_bâtiment == "immeuble", "Type_bâtiment"] = "appartement"
dim(df_result)



get_postal_code_summary <- function(df) {
  df_summary <- df %>%
    group_by(Code_postal) %>%
    summarize(
      count = n(),
      avg_gas = mean(Conso_5_usages_é_finale, na.rm = TRUE),
      avg_X = mean(CoordX, na.rm = T),
      avg_Y = mean(CoordY, na.rm = T)
    ) %>%
    ungroup()
  
  return(df_summary)
}
df_map = get_postal_code_summary(df_result)


##############################################
# ALGORITHME DE LAMBERT POUR LES COORDONNEES #
##############################################

lambert_vers_wgs <- function(X, Y) {
  
n = 0.7256077650532670
C = 11754255.426096
E = 0.08248325676
Xs = 700000.0
Ys = 12655612.049876
lambda = 3 * pi / 180

R = sqrt((X - Xs)^2 + (Ys - Y)^2)
gamma = atan((X - Xs) / (Ys - Y))
lon = lambda + gamma / n

isometric_latitude = -log(R / C) / n
lat = 2 * atan(exp(isometric_latitude)) - pi / 2


lat_old <- 0
while (abs(lat - lat_old) > 1e-11) {
  lat_old <- lat
  lat <- 2 * atan(((1 + E * sin(lat)) / (1 - E * sin(lat)))^(E / 2) * exp(isometric_latitude)) - pi / 2
}

lat <- lat * 180 / pi
lon <- lon * 180 / pi


return(c(lat, lon))
}

coords <- t(apply(df_result[, c("CoordX", "CoordY")], 1, function(row) lambert_vers_wgs(row[1], row[2])))
df_result$latitude <- coords[, 1]
df_result$longitude <- coords[, 2]

coords <- t(apply(df_map[, c("avg_X", "avg_Y")], 1, function(row) lambert_vers_wgs(row[1], row[2])))
df_map$latitude <- coords[, 1]
df_map$longitude <- coords[, 2]
# View(df_result)
# View(df_map)

##########################################################################################
# REGLER LES VALEURS LAT-LONG DANS LE RESULTAT A CAUSES DE VALEURS ABHERANTES DANS L'API #
##########################################################################################

df_map[df_map$Code_postal == "69001", "longitude"] = 4.8343
df_map[df_map$Code_postal == "69001", "latitude"] = 45.7673

df_map[df_map$Code_postal == "69002", "longitude"] = 4.8296
df_map[df_map$Code_postal == "69002", "latitude"] = 45.7528

df_map[df_map$Code_postal == "69003", "longitude"] = 4.8671
df_map[df_map$Code_postal == "69003", "latitude"] = 45.7531

df_map[df_map$Code_postal == "69004", "longitude"] = 4.8275
df_map[df_map$Code_postal == "69004", "latitude"] = 45.7799

df_map[df_map$Code_postal == "69005", "longitude"] = 4.8045
df_map[df_map$Code_postal == "69005", "latitude"] = 45.7561

df_map[df_map$Code_postal == "69006", "longitude"] = 4.8500
df_map[df_map$Code_postal == "69006", "latitude"] = 45.7716

df_map[df_map$Code_postal == "69007", "longitude"] = 4.8356
df_map[df_map$Code_postal == "69007", "latitude"] = 45.7349

df_map[df_map$Code_postal == "69008", "longitude"] = 4.8712
df_map[df_map$Code_postal == "69008", "latitude"] = 45.7339

df_map[df_map$Code_postal == "69009", "longitude"] = 4.8045
df_map[df_map$Code_postal == "69009", "latitude"] = 45.7797

df_map[df_map$Code_postal == "69100", "longitude"] = 4.8897
df_map[df_map$Code_postal == "69100", "latitude"] = 45.7695

df_map[df_map$Code_postal == "69110", "longitude"] = 4.7952
df_map[df_map$Code_postal == "69110", "latitude"] = 45.7357

df_map[df_map$Code_postal == "69115", "longitude"] = 4.6563
df_map[df_map$Code_postal == "69115", "latitude"] = 46.1862

df_map[df_map$Code_postal == "69120", "longitude"] = 4.9288
df_map[df_map$Code_postal == "69120", "latitude"] = 45.7856

df_map[df_map$Code_postal == "69124", "longitude"] = 5.1184
df_map[df_map$Code_postal == "69124", "latitude"] = 45.7193

df_map[df_map$Code_postal == "69126", "longitude"] = 4.7036
df_map[df_map$Code_postal == "69126", "latitude"] = 45.7212

df_map[df_map$Code_postal == "69130", "longitude"] = 4.7735
df_map[df_map$Code_postal == "69130", "latitude"] = 45.7826

df_map[df_map$Code_postal == "69140", "longitude"] = 4.9031
df_map[df_map$Code_postal == "69140", "latitude"] = 45.8184

df_map[df_map$Code_postal == "69150", "longitude"] = 4.9645
df_map[df_map$Code_postal == "69150", "latitude"] = 45.7673

df_map[df_map$Code_postal == "69160", "longitude"] = 4.7599
df_map[df_map$Code_postal == "69160", "latitude"] = 45.7612

df_map[df_map$Code_postal == "69170", "longitude"] = 4.4154
df_map[df_map$Code_postal == "69170", "latitude"] = 45.9180

df_map[df_map$Code_postal == "69190", "longitude"] = 4.8535
df_map[df_map$Code_postal == "69190", "latitude"] = 45.7000

df_map[df_map$Code_postal == "69200", "longitude"] = 4.8835
df_map[df_map$Code_postal == "69200", "latitude"] = 45.7047

df_map[df_map$Code_postal == "69210", "longitude"] = 4.5944
df_map[df_map$Code_postal == "69210", "latitude"] = 45.8319

df_map[df_map$Code_postal == "69220", "longitude"] = 4.7454
df_map[df_map$Code_postal == "69220", "latitude"] = 46.1106

df_map[df_map$Code_postal == "69230", "longitude"] = 4.7927
df_map[df_map$Code_postal == "69230", "latitude"] = 45.6946

df_map[df_map$Code_postal == "69240", "longitude"] = 4.3306
df_map[df_map$Code_postal == "69240", "latitude"] = 46.0554

df_map[df_map$Code_postal == "69250", "longitude"] = 4.8294
df_map[df_map$Code_postal == "69250", "latitude"] = 45.8720

df_map[df_map$Code_postal == "69260", "longitude"] = 4.7424
df_map[df_map$Code_postal == "69260", "latitude"] = 45.7788

df_map[df_map$Code_postal == "69270", "longitude"] = 4.8552
df_map[df_map$Code_postal == "69270", "latitude"] = 45.8432

df_map[df_map$Code_postal == "69280", "longitude"] = 4.7027
df_map[df_map$Code_postal == "69280", "latitude"] = 45.7800

df_map[df_map$Code_postal == "69290", "longitude"] = 4.6846
df_map[df_map$Code_postal == "69290", "latitude"] = 45.7562

df_map[df_map$Code_postal == "69300", "longitude"] = 4.8514
df_map[df_map$Code_postal == "69300", "latitude"] = 45.7980

df_map[df_map$Code_postal == "69310", "longitude"] = 4.8276
df_map[df_map$Code_postal == "69310", "latitude"] = 45.7011

df_map[df_map$Code_postal == "69320", "longitude"] = 4.8576
df_map[df_map$Code_postal == "69320", "latitude"] = 45.6727

df_map[df_map$Code_postal == "69330", "longitude"] = 5.0397
df_map[df_map$Code_postal == "69330", "latitude"] = 45.7799

df_map[df_map$Code_postal == "69340", "longitude"] = 4.7562
df_map[df_map$Code_postal == "69340", "latitude"] = 45.7392

df_map[df_map$Code_postal == "69350", "longitude"] = 4.8125
df_map[df_map$Code_postal == "69350", "latitude"] = 45.7300

df_map[df_map$Code_postal == "69360", "longitude"] = 4.8492
df_map[df_map$Code_postal == "69360", "latitude"] = 45.6255

df_map[df_map$Code_postal == "69370", "longitude"] = 4.7974
df_map[df_map$Code_postal == "69370", "latitude"] = 45.8135

df_map[df_map$Code_postal == "69380", "longitude"] = 4.7087
df_map[df_map$Code_postal == "69380", "latitude"] = 45.8649

df_map[df_map$Code_postal == "69390", "longitude"] = 4.7858
df_map[df_map$Code_postal == "69390", "latitude"] = 45.6453

df_map[df_map$Code_postal == "69400", "longitude"] = 4.7179
df_map[df_map$Code_postal == "69400", "latitude"] = 45.9885

df_map[df_map$Code_postal == "69410", "longitude"] = 4.7861
df_map[df_map$Code_postal == "69410", "latitude"] = 45.7992

df_map[df_map$Code_postal == "69420", "longitude"] = 4.7450
df_map[df_map$Code_postal == "69420", "latitude"] = 45.5053

df_map[df_map$Code_postal == "69430", "longitude"] = 4.5798
df_map[df_map$Code_postal == "69430", "latitude"] = 46.1590

df_map[df_map$Code_postal == "69440", "longitude"] = 4.6393
df_map[df_map$Code_postal == "69440", "latitude"] = 45.6108

df_map[df_map$Code_postal == "69450", "longitude"] = 4.8195
df_map[df_map$Code_postal == "69450", "latitude"] = 45.8184

df_map[df_map$Code_postal == "69460", "longitude"] = 4.6146
df_map[df_map$Code_postal == "69460", "latitude"] = 46.0593

df_map[df_map$Code_postal == "69470", "longitude"] = 4.3735
df_map[df_map$Code_postal == "69470", "latitude"] = 46.1167

df_map[df_map$Code_postal == "69480", "longitude"] = 4.7084
df_map[df_map$Code_postal == "69480", "latitude"] = 45.9263

df_map[df_map$Code_postal == "69490", "longitude"] = 4.5053
df_map[df_map$Code_postal == "69490", "latitude"] = 45.8676

df_map[df_map$Code_postal == "69500", "longitude"] = 4.9119
df_map[df_map$Code_postal == "69500", "latitude"] = 45.7356

df_map[df_map$Code_postal == "69510", "longitude"] = 4.6470
df_map[df_map$Code_postal == "69510", "latitude"] = 45.6808

df_map[df_map$Code_postal == "69520", "longitude"] = 4.7888
df_map[df_map$Code_postal == "69520", "latitude"] = 45.6084

df_map[df_map$Code_postal == "69530", "longitude"] = 4.7384
df_map[df_map$Code_postal == "69530", "latitude"] = 45.6680

df_map[df_map$Code_postal == "69540", "longitude"] = 4.8184
df_map[df_map$Code_postal == "69540", "latitude"] = 45.6763

df_map[df_map$Code_postal == "69550", "longitude"] = 4.3704
df_map[df_map$Code_postal == "69550", "latitude"] = 45.9932

df_map[df_map$Code_postal == "69560", "longitude"] = 4.8307
df_map[df_map$Code_postal == "69560", "latitude"] = 45.5277

df_map[df_map$Code_postal == "69570", "longitude"] = 4.7489
df_map[df_map$Code_postal == "69570", "latitude"] = 45.8127

df_map[df_map$Code_postal == "69580", "longitude"] = 4.8818
df_map[df_map$Code_postal == "69580", "latitude"] = 45.8355

df_map[df_map$Code_postal == "69590", "longitude"] = 4.4949
df_map[df_map$Code_postal == "69590", "latitude"] = 45.7373

df_map[df_map$Code_postal == "69600", "longitude"] = 4.8048
df_map[df_map$Code_postal == "69600", "latitude"] = 45.7156

df_map[df_map$Code_postal == "69610", "longitude"] = 4.4617
df_map[df_map$Code_postal == "69610", "latitude"] = 45.6930

df_map[df_map$Code_postal == "69620", "longitude"] = 4.5559
df_map[df_map$Code_postal == "69620", "latitude"] = 45.9443

df_map[df_map$Code_postal == "69630", "longitude"] = 4.7458
df_map[df_map$Code_postal == "69630", "latitude"] = 45.7090

df_map[df_map$Code_postal == "69640", "longitude"] = 4.6176
df_map[df_map$Code_postal == "69640", "latitude"] = 45.9963

df_map[df_map$Code_postal == "69650", "longitude"] = 4.7868
df_map[df_map$Code_postal == "69650", "latitude"] = 45.9050

df_map[df_map$Code_postal == "69660", "longitude"] = 4.8451
df_map[df_map$Code_postal == "69660", "latitude"] = 45.8223

df_map[df_map$Code_postal == "69670", "longitude"] = 4.6463
df_map[df_map$Code_postal == "69670", "latitude"] = 45.7308

df_map[df_map$Code_postal == "69680", "longitude"] = 4.9621
df_map[df_map$Code_postal == "69680", "latitude"] = 45.7379

df_map[df_map$Code_postal == "69690", "longitude"] = 4.5410
df_map[df_map$Code_postal == "69690", "latitude"] = 45.7654

df_map[df_map$Code_postal == "69700", "longitude"] = 4.7435
df_map[df_map$Code_postal == "69700", "latitude"] = 45.5712

df_map[df_map$Code_postal == "69720", "longitude"] = 5.0444
df_map[df_map$Code_postal == "69720", "latitude"] = 45.6883

df_map[df_map$Code_postal == "69730", "longitude"] = 4.8407
df_map[df_map$Code_postal == "69730", "latitude"] = 45.8978

df_map[df_map$Code_postal == "69740", "longitude"] = 5.0166
df_map[df_map$Code_postal == "69740", "latitude"] = 45.7314

df_map[df_map$Code_postal == "69760", "longitude"] = 4.7724
df_map[df_map$Code_postal == "69760", "latitude"] = 45.8339

df_map[df_map$Code_postal == "69770", "longitude"] = 4.4304
df_map[df_map$Code_postal == "69770", "latitude"] = 45.7955

df_map[df_map$Code_postal == "69780", "longitude"] = 4.9930
df_map[df_map$Code_postal == "69780", "latitude"] = 45.6531

df_map[df_map$Code_postal == "69790", "longitude"] = 4.4467
df_map[df_map$Code_postal == "69790", "latitude"] = 46.2391

df_map[df_map$Code_postal == "69800", "longitude"] = 4.9485
df_map[df_map$Code_postal == "69800", "latitude"] = 45.7012

df_map[df_map$Code_postal == "69820", "longitude"] = 4.6693
df_map[df_map$Code_postal == "69820", "latitude"] = 46.2050

df_map[df_map$Code_postal == "69830", "longitude"] = 4.7273
df_map[df_map$Code_postal == "69830", "latitude"] = 46.0577

df_map[df_map$Code_postal == "69840", "longitude"] = 4.6734
df_map[df_map$Code_postal == "69840", "latitude"] = 46.2476

df_map[df_map$Code_postal == "69850", "longitude"] = 4.5564
df_map[df_map$Code_postal == "69850", "latitude"] = 45.6641

df_map[df_map$Code_postal == "69860", "longitude"] = 4.5616
df_map[df_map$Code_postal == "69860", "latitude"] = 46.2411

df_map[df_map$Code_postal == "69870", "longitude"] = 4.4899
df_map[df_map$Code_postal == "69870", "latitude"] = 46.0736

df_map[df_map$Code_postal == "69890", "longitude"] = 4.7135
df_map[df_map$Code_postal == "69890", "latitude"] = 45.8107

df_map[df_map$Code_postal == "69910", "longitude"] = 4.6739
df_map[df_map$Code_postal == "69910", "latitude"] = 46.1589

df_map[df_map$Code_postal == "69930", "longitude"] = 4.4549
df_map[df_map$Code_postal == "69930", "latitude"] = 45.7455

df_map[df_map$Code_postal == "69960", "longitude"] = 4.9126
df_map[df_map$Code_postal == "69960", "latitude"] = 45.6701

df_map[df_map$Code_postal == "69970", "longitude"] = 4.9271
df_map[df_map$Code_postal == "69970", "latitude"] = 45.6295


# df_map[df_map$Code_postal == "69970", "longitude"] = 4.927128
# df_map[df_map$Code_postal == "69970", "latitude"] = 45.629545



##########################
# FONCTIONNEMENT SERVEUR #
##########################

server = function(input, output, session) {
  
  # FLITRAGE DES DONNEES
  filtered_data = reactive({
    if(is.null(input$appliquer_changements) || input$appliquer_changements == 0) {
      return(df_result)
    } else {
      df_result[df_result$Code_postal %in% input$code_postal_filtre & df_result$Type_bâtiment %in% input$type_logement_filtre, ]
    }
  })
  
  
  # POUR LA CARTE
  output$map = renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      addMarkers(data = filtered_data(), lng= ~longitude, lat= ~latitude, popup = ~Etiquette_GES)
  })
  
  
  # CARTE CODE POSTAUX
  quartiles = quantile(df_map$avg_gas, probs = c(0.25, 0.5, 0.75))
  
  df_map <- df_map %>%
    mutate(
      color = case_when(
        avg_gas <= quartiles[1] ~ "chartreuse",
        avg_gas <= quartiles[2] ~ "skyblue",
        avg_gas <= quartiles[3] ~ "yellow",
        TRUE ~ "orange"
      )
    )
  
  
  output$map_cp <- renderLeaflet({
    leaflet(data = df_map) %>%
      addTiles() %>%
      addCircleMarkers(
        ~longitude, ~latitude,
        color = ~color,
        stroke = T,
        popup = ~paste(
          "<b>Code Postal:</b>", Code_postal, "<br>",
          "<b>Nombre de données:</b>", count, "<br>",
          "<b>Consommation moyenne:</b>", round(avg_gas, 2)
        ),
        radius = 9,
        fillOpacity = 0.9
      )
  })
  

  
  
  
  
  # CONSO MOYENNE
  avg_conso <- mean(df_result$Conso_5_usages_é_finale, na.rm = TRUE)
  output$moyenne_conso <- renderText({
    paste("La moyenne globale de consommation 5 usages est de", round(avg_conso, 2))
  })
  
  # CONSO MOYENNE /M2
  avg_conso_m2 <- mean(df_result$Conso_5_usages_m2, na.rm = TRUE)
  output$moyenne_conso_m2 <- renderText({
    paste("La moyenne globale de consommation 5 usages /m² est de", round(avg_conso_m2, 2))
  })
  
  
  # AFFICHER DATAFRAME
  output$raw_data <- renderDT({
    datatable(df_result, options = list(pageLength = 30))
  })
  

  
  
  
  
  # GESTION DU LOGIN
  user_logged_in <- reactiveVal(FALSE)
  
  observeEvent(input$login, {
    username <- input$username
    password <- input$password
    
    # DETECTION DU LOGIN ADMIN
    if (input$username == "admin") {
      user_logged_in(TRUE)
      output$login_status <- renderText("dev version")
      
    } else if (username != "" && password != "") {
      user_logged_in(TRUE)
      output$login_status <- renderText(paste("Welcome", username))
      
    } else {
      output$login_status <- renderText("Identifiant ou mot de passe non valide!")
    }
  })
  
  
# AFFICHE LA PAGE MAIN SI LE LOGIN + MDP SONT ACCEPTABLES
  output$main_ui <- renderUI({
    getwd()
    # source("ui.R")
    if (user_logged_in()) {
      main_page()
    } else {
      login_page()
    }
  })
  
  

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  # HISTOS CUSTOMS
  
  # BARPLOT AVEC DONNEES API NON FILTREES
  output$barplot = renderPlot({
    plot1()
    })
  
  
  plot1 <- reactive({
    req(input$varX)
    qual_data <- df_result[[input$varX]]
    bar_data <- table(qual_data)
    
    barplot_heights <- barplot(bar_data, main = paste("Répartition de la variable", input$varX,"\nsur l'ensemble de la base de données"),
                               xlab = "", ylab = "", col = "blue",
                               ylim = c(0, max(bar_data) * 1.2),
                               axes = FALSE)  # Ajouter de l'espace en haut pour les valeurs
    
    # Ajouter les valeurs au-dessus de chaque barre
    text(x = barplot_heights, y = bar_data, label = bar_data, pos = 3, cex = 0.8, col = "black")
  })
  
  
  
  # BARPLOT AVEC DONNEES API FILTRE
  output$barplot_filtre <- renderPlot({
    req(input$varX)
    
    qual_data <- filtered_data()[[input$varX]]
    bar_data <- table(qual_data)
    
    barplot_heights <- barplot(bar_data, main = paste("Répartition de la variable", input$varX,"\ndans la base de données filtrée"),
                               xlab = "", ylab = "", col = "lightblue",
                               ylim = c(0, max(bar_data) * 1.2),
                               axes = FALSE)  # Ajouter de l'espace en haut pour les valeurs
    
    # Ajouter les valeurs au-dessus de chaque barre
    text(x = barplot_heights, y = bar_data, label = bar_data, pos = 3, cex = 0.8, col = "black")
  })
  
  
  output$telecharger_graph1 <- downloadHandler(
    filename = function() {paste("GreenTech-graph_dynamique.png")},
    content = function(file) {
      ggsave(file, plot = plot1(), device = "png")
    })
  
  output$telecharger_graph2 <- downloadHandler(
    filename = "GreenTech-graph_dynamique.png",
    content = function(file) {
      ggsave(file, plot = last_plot(), device = "png")
    })


}



