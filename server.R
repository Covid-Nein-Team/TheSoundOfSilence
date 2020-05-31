# thesoundofsilence server
# ========================
# Created by: Covid Nein Team

range01 <- function(x){(x-min(x))/(max(x)-min(x))}

data <- read_csv('./resources/accumulated_data.csv') %>%
  drop_na() %>%
  mutate(date=lubridate::ymd(date)) %>%
  group_by(country, dataset) %>%
  mutate(normalized_value = range01(value)) %>%
  ungroup()

# Define server logic ----
server <- function(input, output, session) {
  shinyjs::disable("currentDay")

  observeEvent(once = TRUE, ignoreNULL = FALSE, ignoreInit = FALSE, eventExpr = TRUE, {
    showModal(modalDialog(
      easyClose = TRUE,
      title = "The Sound Of Silence --- SpaceApps COVID-19 Challenge 2020",
      div(
        id = 'logocontainer',
        actionButton(inputId = "enterButton", label = NULL, style = "
          margin: auto;
          width: 100%; height: 100%;
          background: url('logo_small-fs8.png');
          background-size: cover; background-position: center;
        ")
        # img(src='./logo_small-fs8.png')
      )
    ))
  })

  observeEvent(input$enterButton, {
    removeModal()
  })

  observeEvent(input$hoverCountry, {
    cat("\nhovering over country: ", input$hoverCountry)
  })

  output$sidebarPlot <- renderPlot({
    req(input$hoverCountry)
    # render country data in plot
    cdata <- data %>% filter(country == input$hoverCountry)
    ggplot(cdata, aes(x = date, y = normalized_value)) +
      # geom_line(color = "#FA5F70FF") +
      geom_line(aes(color = dataset)) +
      labs(title = "Normalized Country Data") +
      new_retro(
        legend.position = "bottom"
      ) +
      theme(
        axis.title.y = element_blank(),
        axis.text.y = element_blank(),
        plot.background = element_rect(color = "#222D32", fill = "#222D32"),
        legend.position = "bottom",
        legend.box = "vertical",
        legend.margin=margin()
      ) +
      guides(
        color = guide_legend(
          nrow = 5,
          byrow = TRUE,
        )
      ) +
      NULL
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

  observeEvent(input$mapPlayBackEnabled, {
    if (input$mapPlayBackEnabled) {
      cat("\nmap playback enabled")
      shinyjs::runjs("try { window.tileLayerPlayback.play(); } catch {};")
    } else {
      cat("\nmap playback disabled")
      shinyjs::runjs("try { window.tileLayerPlayback.stop(); } catch {};")
    }
  })

}
