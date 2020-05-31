# thesoundofsilence server
# ========================
# Created by: Covid Nein Team

# Define server logic ----
server <- function(input, output, session) {
  shinyjs::disable("currentDay")

  observeEvent(input$hoverCountry, {
     cat("\nyou clicked on a pie with pie slice data: ", input$hoverCountry)
  })

  observeEvent(input$audioEnabled, {
    cat("\nyou changed Audio Playback: ", input$audioEnabled)
    if (input$audioEnabled) {
      shinyjs::runjs("try { window.audioLooper.mute(false); } catch {};")
    } else {
      shinyjs::runjs("try { window.audioLooper.mute(true); } catch {};")
    }
  })
}
