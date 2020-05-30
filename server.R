# thesoundofsilence server
# ========================
# Created by: Covid Nein Team

# Define server logic ----
server <- function(input, output, session) {
  observeEvent(input$hoverCountry, {
     cat("\nyou clicked on a pie with pie slice data: ", input$hoverCountry)
  })
}
