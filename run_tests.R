# thesoundofsilence tests
# =======================
# Created by: Andreas Poehlmann <andreas@poehlmann.io>

library(testthat)
library(shinytest)

if (getOption("browser") == "") {
    # fix R 4.0 not getting default browser...
    options(browser = "xdg-open")
}

test_that("all systems nominal", {
  # by default runs all scripts in ./tests/
  expect_pass(testApp(".", compareImages = FALSE))
})
