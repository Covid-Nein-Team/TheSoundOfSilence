# thesoundofsilence server
# ========================
# Created by: Covid Nein Team

data <- read_csv('./data/covid_19_cases.csv') %>%
  pivot_longer(!date, names_to='country') %>%
  mutate(date=lubridate::ymd(date))


# Define server logic ----
server <- function(input, output, session) {
  shinyjs::disable("currentDay")

  observeEvent(input$hoverCountry, {
    cat("\nhovering over country: ", input$hoverCountry)
  })

  output$sidebarPlot <- renderPlot({
    req(input$hoverCountry)
    # render country data in plot
    cdata <- data %>% filter(country == input$hoverCountry)
    ggplot(cdata, aes(x = date, y = value)) +
      geom_line(color = "#FA5F70FF") +
      labs(title = "Country Data") +
      xlab("date") +
      new_retro() +
      guides(size = guide_legend(override.aes = list(colour = "#FA5F70FF"))) +
      scale_y_continuous(position = "right") +
      theme(
        axis.title.y = element_blank(),
        plot.background = element_rect(color = "#222D32", fill = "#222D32")
      )
  })

  observeEvent(input$audioEnabled, {
    if (input$audioEnabled) {
      cat("\naudio playback enabled")
      shinyjs::runjs("try { window.audioLooper.mute(false); } catch {};")
    } else {
      cat("\naudio playback disabled")
      shinyjs::runjs("try { window.audioLooper.mute(true); } catch {};")
    }
  })

}
