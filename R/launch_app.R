#' Launch the SYNTHESIS Interactive Dashboard
#' 
#' Starts a Shiny application that allows users to upload datasets, 
#' perform audits, and generate reports without writing code.
#' @export
launch_synthesis_app <- function() {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("The 'shiny' package is required to run the dashboard. Please install it.")
  }
  shiny::runApp(system.file("R/app.R", package = "SYNTHESIS"))
}
