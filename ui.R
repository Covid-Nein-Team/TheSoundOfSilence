# thesoundofsilence ui
# ====================
# Created by: Covid Nein Team

dash_header <- dashboardHeader(
  titleWidth = 350,
  title = APP_NAME,
  tags$li(
    a(
      href = REPO_URL,
      icon("github"),
      title = "Goto Github Repository",
      target="_blank"
    ),
    class = "dropdown"
  )
)

dash_sidebar <- dashboardSidebar(
  width = 350,

  sidebarMenu(
      menuItem("Main", tabName = "main", icon = icon("dashboard"))
  ),
  sliderInput("currentDay",
              "Displayed Date:",
              min = as.Date("2019-12-01", "%Y-%m-%d"),
              max = as.Date("2020-04-30", "%Y-%m-%d"),
              value=as.Date("2019-12-01"),
              timeFormat="%Y-%m-%d"
  ),
  switchInput("audioEnabled",
              label = "Audio",
              value = TRUE),
  plotOutput(
              outputId = "sidebarPlot"
  ) %>% shinycssloaders::withSpinner()
)

dash_body <- dashboardBody(
  id="body-content",

  tags$head(
    # Google Analytics Token, see `modules/google_analytics.R`
    google_analytics_tag_html(GA_TOKEN),
    # include custom.css
    tags$link(rel = "stylesheet", type = "text/css", href = "bundle.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
  ),
  # load shinyjs
  shinyjs::useShinyjs(),
  includeJqueryUI(),

  fillPage(
    div(
      id = "earth-map",
    )
  ),

  tags$script(src = "bundle.js", type="text/javascript"),
)

# The UI main function
ui <- dashboardPage(
  skin = "black",
  dash_header,
  dash_sidebar,
  dash_body,
)
