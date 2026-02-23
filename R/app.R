library(shiny)
# library(SYNTHESIS) # Not needed when part of the package

# Simple Shiny App for SYNTHESIS
# Allows users to upload a CSV and get an instant audit report

ui <- fluidPage(
  theme = bslib::bs_theme(bootswatch = "flatly"),
  titlePanel("SYNTHESIS: Evidence Verification System"),
  
  sidebarLayout(
    sidebarPanel(
      fileInput("file1", "Upload CSV File", accept = ".csv"),
      helpText("Required columns: 'yi' (Effect Size) and 'vi' (Variance)"),
      hr(),
      numericInput("baseline_risk", "Baseline Risk (0-1)", 0.2, min=0, max=1, step=0.05),
      selectInput("lang", "Report Language", choices = c("en", "es", "fr")),
      actionButton("run", "Run Audit", class="btn-primary"),
      hr(),
      downloadButton("downloadReport", "Download PDF Report")
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Dashboard", 
                 h3(textOutput("status_text")),
                 plotOutput("master_plot"),
                 verbatimTextOutput("console_output")
        ),
        tabPanel("Data Preview", tableOutput("contents"))
      )
    )
  )
)

server <- function(input, output) {
  
  data <- reactive({
    req(input$file1)
    read.csv(input$file1$datapath)
  })
  
  audit_res <- eventReactive(input$run, {
    req(data())
    df <- data()
    if(!"yi" %in% names(df) || !"vi" %in% names(df)) {
      showNotification("Error: CSV must contain 'yi' and 'vi' columns.", type="error")
      return(NULL)
    }
    synthesis_audit(df$yi, df$vi, baseline_risk = input$baseline_risk)
  })
  
  output$contents <- renderTable({
    req(data())
    head(data())
  })
  
  output$status_text <- renderText({
    req(audit_res())
    paste("Status:", audit_res()$decision$status)
  })
  
  output$console_output <- renderPrint({
    req(audit_res())
    print(audit_res())
  })
  
  output$master_plot <- renderPlot({
    req(audit_res())
    # Use Viridis/Okabe-Ito colors implicitly via the updated plot.synthesis function
    plot(audit_res()$core, audit = audit_res())
  })
  
  output$downloadReport <- downloadHandler(
    filename = function() {
      paste("SYNTHESIS_Report_", Sys.Date(), ".md", sep="")
    },
    content = function(file) {
      req(audit_res())
      synthesis_report(audit_res(), file, lang=input$lang)
    }
  )
}

shinyApp(ui = ui, server = server)
