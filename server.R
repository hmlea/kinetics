# load the library for the mm plots
library(drc)

shinyServer(function(input, output, session){
  # reactive value for input data frame, current mm fit, and current plot
  kin_data = reactiveVal(NULL)
  cur_fit = reactiveVal(NULL)
  cur_plt = reactiveVal(NULL)
  
  # observe file input
  observe({
    cur_sheet = input$sheets
    if(!is.null(cur_sheet)) {
      kin_data(read.csv(cur_sheet$datapath))
      cur_fit(drm(kin_data()[[2]] ~ kin_data()[[1]], fct=MM.2()))
    }
  })
  
  # render the plot
  output$plt_out = renderPlot({
    if(!is.null(kin_data())) {
      # plot the mm fit and points
      plot(cur_fit(), log="", type="none",
           main=ifelse(input$title=="", NA, input$title),
           xlab=ifelse(input$x_label=="", NA, input$x_label),
           ylab=ifelse(input$y_label=="", NA, input$y_label))
      points(kin_data())
    } else {
      # plot "no file chosen"
      plot(0, 0, xaxt="n", yaxt="n", xlab=NA, ylab=NA, type="n")
      text(0, 0, "no file chosen")
    }
    
    # record the plot for downloading
    cur_plt(recordPlot())
  })
  
  # handle download press
  output$dl_plt = downloadHandler(
    filename="plot.png",
    content=function(file) {
      # save the recorded plot as a png
      png(file, width=input$width*3, height=input$height*3, res=300, units="px")
      replayPlot(cur_plt())
      dev.off()
    }
  )
  
  # the about button in the top right hand corner
  observeEvent(input$about, {
    showModal(
      modalDialog(title="About",
                  HTML("<h5>Help</h5>
                  <p style='margin-bottom:10px;'>This web application allows for 
                  the quick and easy creation of Michaelis-Menten plots with 
                  rate and substrate concentration data. To use this app, export 
                  or compile your rate and substrate concentration data in a CSV 
                  file. Make sure that the substrate concentrations are in the 
                  first column and the rates are in the second column; it does 
                  not matter if the spreadsheet has a header. Once uploaded, a 
                  Michaelis-Menten plot will be generated using that data. This 
                  plot can then be exported to a certain size using the 
                  \"Download Plot\" button.</p>
                  <p style='margin-bottom:10px'><i>More features to come.</i>
                  </p>"),
                  footer=span(div(HTML("<p>Hayden Leatherwood 2022 - built in R with <a href='https://github.com/DoseResponse/drc'>drc</a> and <a href='https://shiny.rstudio.com/'>Shiny</a></p>"),
                                  style="float:left;"),
                              div(HTML("<a href='https://github.com/hmlea/kinetics'>Source</a>"),
                                  style="float:right;")),
                  easyClose=T))
  })
})

