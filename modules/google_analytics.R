# GA helper
# =========
# Created by: Andreas Poehlmann <andreas@poehlmann.io>

google_analytics_read_token_file <- function(file) {
  if (!file.exists(file)) {
    warning("Google Analytics token file not found. Disabling GA.")
    return(NULL)
  }
  stringr::str_trim(readr::read_file(file))
}

google_analytics_tag_html <- function(token) {
  if (is.null(token)) {
    return(shiny::HTML(""))
  }
  shiny::HTML(stringr::str_glue(
    "<!-- Global site tag (gtag.js) - Google Analytics -->
    <script async src=\"https://www.googletagmanager.com/gtag/js?id={token}\"></script>
    <script>
      window.dataLayer = window.dataLayer || [];
      function gtag(){{dataLayer.push(arguments);}}
      gtag('js', new Date());
      gtag('config', '{token}');
    </script>",
    token = token
  ))
}
