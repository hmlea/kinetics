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
                   }
                   .checkbox {
                     margin-bottom:-13px;
                   }")),
  
  # script to change the browser tab title on tab change
  tags$script(HTML('Shiny.addCustomMessageHandler("changetitle", function(x) {document.title=x});')),
  
  # icon and title
  tags$head(tags$link(rel="shortcut icon",
                      href=knitr::image_uri("kinetics.ico"),
                      type="image/x-icon")),
  titlePanel(div(span("Kinetics",
                      div(actionButton("about", "About"), style="float:right;")),
                 style="padding-bottom:0.8rem;"),
             windowTitle="Kinetics"),
  
  # sidebar panels for each tab
  sidebarPanel(
    # sidebar for rate calculations
    conditionalPanel(condition="input.tabselected==1",
                     fileInput("sheets1", "Upload CSV files here:", multiple=TRUE,
                               accept = c("text/csv",
                                          "text/comma-separated-values,text/plain",
                                          ".csv")),
                     
                     tags$hr(),
                     
                     fluidRow(
                       column(6, numericInput("width1", "Width", value=650, min=100)),
                       column(6, numericInput("height1", "Height", value=475, min=100))
                     ),
                     plainDLButton("dl_plt1", "Download Plots"),
                     checkboxInput("show_lm", label="Show Rate Line", value=FALSE)
    ),
    
    # sidebar for michaelis-menten plots
    conditionalPanel(condition="input.tabselected==2",
                     fileInput("sheets2", "Upload CSV file here:", multiple=FALSE,
                               accept = c("text/csv",
                                          "text/comma-separated-values,text/plain",
                                          ".csv")),
                     
                     tags$hr(),
                     
                     textInput("title", "Title:", value="LDHA Mutant Michaelis-Menten Plot"),
                     textInput("x_label", "X-axis label:", value="[Pyruvate] (mM)"),
                     textInput("y_label", "Y-axis label:", value="Rate (uM/s)"),
                     
                     tags$hr(),
                     
                     fluidRow(
                       column(6, numericInput("width2", "Width", value=650, min=100)),
                       column(6, numericInput("height2", "Height", value=475, min=100))
                     ),
                     plainDLButton("dl_plt2", "Download Plot"),
                     fluidRow(
                       column(6, checkboxInput("show_vmax", label=HTML("Show V<sub>max</sub>"), value=FALSE)),
                       column(6, checkboxInput("show_km", label=HTML("Show K<sub>M</sub>"), value=FALSE))
                     )
    ),
  ),
  
  mainPanel(
    align="center",
    tabsetPanel(id="tabselected", type="tabs",
                # determining rates
                tabPanel("Rates", value=1,
                         plotOutput("plt_out1", click="plot_click"),
                         tableOutput("rate_out"),
                         tableOutput("rate_summary")
                ),
                # creating michaelis-menten plots
                tabPanel("Michaelis-Menten", value=2,
                         plotOutput("plt_out2"),
                         tableOutput("mm_out"),
                         tableOutput("mm_summary")
                )
    )
  )
)

