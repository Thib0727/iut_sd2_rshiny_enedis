#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)
library(bslib)

# Define UI for application that draws a histogram
ui <- page_sidebar(
  title = "title panel",
  sidebar = sidebar("sidebar"),
  "main contents"
)


shinyApp(ui = ui, server = server)
