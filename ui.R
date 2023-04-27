library(shiny)

plainDLButton = function(buttonID, buttonLabel="Download") {
  tags$a(id=buttonID, class="btn btn-default shiny-download-link", href="",
         target="_blank", download=NA, NULL, buttonLabel,
         style="width:100%; padding-right:0.75rem; padding-left:0.75rem;")
}

ui = fluidPage(
  # styles numeric inputs and hr
  tags$style(HTML("input[type=number] {
                     -moz-appearance:textfield;
                   }
                   input[type=number]::{
                     -moz-appearance:textfield;
                   }
                   input[type=number]::-webkit-outer-spin-button,
                   input[type=number]::-webkit-inner-spin-button {
                     -webkit-appearance:none;
                     margin:0;
                   }
                   .progress-bar, .progress, .progress-bar {
                     display:none !important;
                   }
                   hr {
                     margin-top:25px;
                   }")),
  
  tags$head(tags$link(rel="shortcut icon",
                      href=knitr::image_uri("kinetics.ico"),
                      type="image/x-icon")),
  titlePanel(div(span("Kinetics",
                      div(actionButton("about", "About"), style="float:right;")),
                 style="padding-bottom:0.8rem;"),
             windowTitle="Kinetics"),
  
  sidebarPanel(
    fileInput("sheets", "Upload CSV file here:", multiple=FALSE,
              accept = c("text/csv",
                         "text/comma-separated-values,text/plain",
                         ".csv")),
    
    tags$hr(),
    
    textInput("title", "Title:", value="LDHA Mutant Michaelis-Menten Plot"),
    textInput("x_label", "X-axis label:", value="[Pyruvate] (mM)"),
    textInput("y_label", "Y-axis label:", value="Rate (uM/s)"),
    
    tags$hr(),
    
    fluidRow(
      column(6, numericInput("width", "Width", value=775, min=100)),
      column(6, numericInput("height", "Height", value=425, min=100))
    ),
    plainDLButton("dl_plt", "Download Plot")
  ),
  
  mainPanel(
    align = "center",
    
    plotOutput("plt_out")
  )
)

