# thesoundofsilence ui
# ====================
# Created by: Covid Nein Team

dash_header <- dashboardHeader(
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
  sidebarMenu(
      menuItem("Main", tabName = "main", icon = icon("dashboard"))
  )
)

dash_body <- dashboardBody(
  tags$head(
    # Google Analytics Token, see `modules/google_analytics.R`
    google_analytics_tag_html(GA_TOKEN),
    # include custom.css
    tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
  ),
  # load shinyjs
  shinyjs::useShinyjs(),

  tabItems(
    # Data Upload Tab ----
    tabItem(
      tabName = "main",

      h2("WIP"),
      # Indicators ----
      fluidRow(
        div(
          class = "earth-map",
        ),
      )
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
