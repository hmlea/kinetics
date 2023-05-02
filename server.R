# load the drc library and the function files
library(drc)
source("rate_core.R")

shinyServer(function(input, output, session){
  # ------------------------------------------------------------------------------
  # RATE CALCULATIONS
  # ------------------------------------------------------------------------------
  # reactive value for current plot index
  cur_plt_index = reactiveVal(0)
  
  # reactive value for imported data
  all_data = reactiveVal(NULL)
  
  # current number of clicks
  cur_num_clicks = reactiveVal(0)
  
  # reactive for where the plot is clicked
  first_click = reactiveVal(NULL)
  second_click = reactiveVal(NULL)
  
  # starts, containing everything needed to get the rate
  starts = reactiveVal(list())
  
  # regression and rates reactive value
  last_regs = reactiveVal(NULL)
  last_rates = reactiveVal(data.frame())
  
  # observe file input
  observe({
    # read sheets in and sanitize all reactive values
    cur_sheet = input$sheets1
    if(!is.null(cur_sheet)) {
      isolate(all_data(NULL))
      all_data(import_data(cur_sheet$datapath, basename(cur_sheet$name)))
      isolate(cur_plt_index(cur_plt_index() + 1))
      isolate(cur_num_clicks(0))
      isolate(first_click(NULL))
      isolate(second_click(NULL))
      isolate(starts(NULL))
      isolate(last_regs(NULL))
      isolate(last_rates(data.frame()))
    }
  })
  
  # observe the plot click
  observeEvent(input$plot_click, {
    # get the first and the second points
    if(cur_num_clicks() == 0) {
      first_click(c(input$plot_click$x, input$plot_click$y))
      cur_num_clicks(cur_num_clicks() + 1)
    } else if(cur_num_clicks() == 1) {
      second_click(c(input$plot_click$x, input$plot_click$y))
      cur_num_clicks(cur_num_clicks() + 1)
    }
    
    # if 2 points are gathered, calculate starts and move to the next
    if(cur_num_clicks() == 2 && cur_plt_index() != 0) {
      cur_num_clicks(0)
      new_start = select_shiny(all_data()[[cur_plt_index()]],
                               list(x=c(first_click()[[1]], second_click()[[1]]),
                                    y=c(first_click()[[2]], second_click()[[2]])))
      isolate(starts(append(starts(), list(new_start))))
      cur_plt_index(cur_plt_index() + 1)
    }
  })
  
  # render the plot
  output$plt_out1 = renderPlot({
    # don't plot if there is no more data
    if(cur_plt_index() == isolate(length(all_data()))+1) {
      cur_plt_index(0)
      
      # get the regressions
      last_regs(get_regressions(isolate(all_data()), isolate(starts())))
      
      # get the rates and put them into a reactive val
      rates = lapply(last_regs(), function(r) {
        abs(r$coefficients[[2]])
      })
      rate_list = list("name"=c(), "rate"=c())
      for(i in 1:length(rates)) {
        rate_list$name = append(rate_list$name, names(rates)[[i]])
        rate_list$rate = append(rate_list$rate, rates[[i]])
      }
      last_rates(data.frame("Name"=rate_list$name, "Rate"=rate_list$rate))
    }
    
    if(cur_plt_index() != 0) {
      # plot the mm fit and points
      cur_data = isolate(all_data())[[cur_plt_index()]]
      plot(cur_data$time_sec, cur_data$nadh_conc_uM, type="l",
           main=attr(cur_data, "file_name"),
           xlab="Time (s)", ylab="[NADH] (uM)")
    } else {
      # plot "no file chosen"
      plot(0, 0, xaxt="n", yaxt="n", xlab=NA, ylab=NA, type="n")
      text(0, 0, "no file chosen")
    }
  })
  
  # render the rate table when possible
  output$rate_out = renderTable({
    last_rates()
  }, digits=8, width="80%")
  
  # handle downloads
  output$dl_plt1 = downloadHandler(
    filename="plots.zip",
    content=function(file) {
      # reset the wd to temp
      old_wd = setwd(tempdir())
      on.exit(setwd(old_wd))
      
      # get all the data needed
      iso_data = isolate(all_data())
      iso_regs = isolate(last_regs())
      iso_starts = isolate(starts())
      
      # loop through and save each plot to be zipped
      plot_files = c()
      for(i in 1:length(iso_data)) {
        # get and append the file name
        file_name = paste0("plot_", i, ".png")
        plot_files = append(plot_files, file_name)
        
        # save the recorded plot as a png
        png(file_name, width=input$width1*3, height=input$height1*3, res=300, units="px")
        plot_shiny_reg(iso_data[[i]], iso_regs[[i]], iso_starts[[i]], input$show_lm)
        dev.off()
      }
      
      #create the zip file
      zip(file, plot_files)
    }
  )
  
  # the about button in the top right hand corner
  observeEvent(input$about, {
    # change the modal message based on the tab selected
    body_html = NULL
    if(input$tabselected == 1) {
      body_html = HTML("
                  <p style='margin-bottom:20px;'>This web application allows for 
                  the quick and easy calculation of rate from absorbance data 
                  and the creation of Michaelis-Menten plots with rate and 
                  substrate concentration data. These plots can then be 
                  downloaded as images with a given size for your own use.</p>
                  <h5>Help</h5>
                  <p style='margin-bottom:10px;'>To use the rate calculation 
                  feature of this app, upload CSV files that have two header 
                  rows time in the first column and absorbance in the second. 
                  You can choose as many CSV files as you want to calculate the 
                  rate for.</p>
                  <p style='margin-bottom:10px;'>After uploading the files, you 
                  will be prompted to click twice on each plot. On the first 
                  click, click on an x value where the concentration is at 
                  baseline before the substrate is added. For the second click, 
                  click on the x value where the concentration is at the 
                  highest point right after the substrate is added. The app 
                  will then use 10% of the data following the second click to 
                  calculate the rate of the reaction.</p>
                  <p style='margin-bottom:10px;'>After selecting these two 
                  points on all of the plots, a table containing the names of 
                  the files and their respective rates will be generated below 
                  the plot window. Once this table is seen, these plots can be 
                  exported either with or without the linear regression included 
                  on the plot. The \"Download Plots\" button will always 
                  download the plots used to calculate the rates shown in the 
                  table.</p>
                  <p style='margin-bottom:0px;'><i>More features to come.</i>
                  </p>")
    } else if(input$tabselected == 2) {
      body_html = HTML("
                  <p style='margin-bottom:20px;'>This web application allows for 
                  the quick and easy calculation of rate from absorbance data 
                  and the creation of Michaelis-Menten plots with rate and 
                  substrate concentration data. These plots can then be 
                  downloaded as images with a given size for your own use.</p>
                  <h5>Help</h5>
                  <p style='margin-bottom:10px;'>To use the Michaelis-Menten 
                  plot creation feature of this app, upload a single CSV file of 
                  the data you want to plot. The CSV file must have the 
                  substrate concentrations in the first column and the rates in 
                  the second column; it does not matter if the spreadsheet has a 
                  header. Once uploaded, a Michaelis-Menten plot will be 
                  generated and displayed in the plot window. The \"Download 
                  Plot\" button can then be used to download the generated 
                  Michaelis-Menten plot as an image.</p>
                  <p style='margin-bottom:0px;'><i>More features to come.</i>
                  </p>")
    }
    
    # show the modal message
    showModal(
      modalDialog(title="About",
                  body_html,
                  footer=span(div(HTML("<p>Hayden Leatherwood 2022 - built in R with <a href='https://github.com/DoseResponse/drc' target='_blank'>drc</a> and <a href='https://shiny.rstudio.com/' target='_blank'>Shiny</a></p>"),
                                  style="float:left; margin-bottom:-10px;"),
                              div(HTML("<a href='https://github.com/hmlea/kinetics' target='_blank'>Source</a>"),
                                  style="float:right;")),
                  easyClose=T))
  })
  
  # ------------------------------------------------------------------------------
  # MICHAELIS-MENTEN PLOTS
  # ------------------------------------------------------------------------------
  # reactive value for input data frame, current mm fit, and current plot
  kin_data = reactiveVal(NULL)
  cur_fit = reactiveVal(NULL)
  cur_plt = reactiveVal(NULL)
  kin_plot_text = reactiveVal("no file chosen")
  
  # observe file input
  observe({
    cur_sheet = input$sheets2
    if(!is.null(cur_sheet)) {
      kin_data(read.csv(cur_sheet$datapath))
      if(nrow(kin_data()) <= 1) {
        kin_plot_text("bad file chosen\nfile must have at least two rows to fit a curve")
        cur_fit(NULL)
      } else if(!is.numeric(kin_data()[[1]]) && !is.numeric(kin_data()[[2]])) {
        kin_plot_text("bad file chosen\nfile must contain substrate concentrations in the first column and rates in the second")
      } else {
        cur_fit(drm(kin_data()[[2]] ~ kin_data()[[1]], fct=MM.2()))
      }
    }
  })
  
  # render the plot
  output$plt_out2 = renderPlot({
    if(!is.null(kin_data()) && !is.null(cur_fit())) {
      # plot the mm fit and points
      plot(cur_fit(), log="", type="none",
           main=ifelse(input$title=="", NA, input$title),
           xlab=ifelse(input$x_label=="", NA, input$x_label),
           ylab=ifelse(input$y_label=="", NA, input$y_label))
      points(kin_data())
      
      # get the km and vmax values and set default to hide
      coeffs = coef(cur_fit())
      vmax = ""
      km = ""
      
      # show the lines for vmax and km if desired
      if(input$show_vmax) {
        abline(h=coeffs[[1]], col="#DC5340", lty=2, lwd=2)
        vmax = as.expression(bquote(V[max] ~ " = " ~ .(coeffs[[1]])))
      }
      if(input$show_km) {
        segments(x0=-1, x1=coeffs[[2]],
                 y0=coeffs[[1]]/2, y1=coeffs[[1]]/2,
                 col="#DC5340", lty=2, lwd=2)
        segments(x0=coeffs[[2]], x1=coeffs[[2]],
                 y0=coeffs[[1]]/2, y1=-1,
                 col="#DC5340", lty=2, lwd=2)
        km = as.expression(bquote(K[M] ~ " = " ~ .(coeffs[[2]])))
      }
      
      # add values to the plot
      tmp_leg = legend("topright", legend=c(" ", " "),
                       text.width=strwidth("1,000,000"),
                       xjust=1, yjust=1, bty="n", y.intersp=1.2)
      text(tmp_leg$rect$left+tmp_leg$rect$w, tmp_leg$text$y,
           c(vmax, km), pos=2, bty="n")
    } else {
      # plot "no file chosen"
      plot(0, 0, xaxt="n", yaxt="n", xlab=NA, ylab=NA, type="n")
      text(0, 0, kin_plot_text())
    }
    
    # record the plot for downloading
    cur_plt(recordPlot())
  })
  
  # render the table with km and vmax when possible
  output$mm_out = renderTable({
    coeffs = coef(cur_fit())
    if(is.null(coeffs)) {
      cur_vals = data.frame()
    } else {
      cur_vals = data.frame("Variable"=c("Vmax", "Km"),
                            "Value"=c(coeffs[[1]], coeffs[[2]]),
                            "Std. Error"=as.data.frame(summary(cur_fit())[[3]])[["Std. Error"]],
                            check.names=FALSE)
    }
    cur_vals
  }, digits=8, width="80%")
  
  # handle download press
  output$dl_plt2 = downloadHandler(
    filename="plot.png",
    content=function(file) {
      # save the recorded plot as a png
      png(file, width=input$width2*3, height=input$height2*3, res=300, units="px")
      replayPlot(cur_plt())
      dev.off()
    }
  )
})

