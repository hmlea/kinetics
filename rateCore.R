# import all data from csv
# extinction coeff in 1/mM*cm; path length in cm
# converts using beer's law to [NADH] in uM
import_data = function(data_files, data_names=NULL,
                       extinction_coeff=6.22,
                       path_length=1) {
  # get list of all dataframes
  all_data = list()
  for(file in data_files) {
    # read and convert the data
    abs_data = read.csv(file)[1:2]
    abs_data = setNames(abs_data[2:(nrow(abs_data)), 1:2],
                        c("time_min", "abs"))
    
    # get the non numeric rows
    non_num = suppressWarnings(which(is.na(as.numeric(abs_data[[1]]))))
    abs_data = abs_data[1:(min(non_num)-1),]
    
    # convert to numeric
    for(i in 1:length(abs_data)) {
      abs_data[[i]] = suppressWarnings(na.omit(as.numeric(abs_data[[i]])))
    }
    
    # calculate the time in seconds
    abs_data$time_sec = abs_data$time_min * 60
    
    # calculate concentration
    abs_data$nadh_conc_uM = abs_data$abs / (extinction_coeff * path_length) * 1000
    
    # add to list
    index = which(data_files == file)
    real_file = ifelse(is.null(data_names), file, data_names[[index]])
    file_name = substring(real_file, 1, nchar(real_file)-4)
    attributes(abs_data)$file_name = file_name
    attributes(abs_data)$index = index
    all_data[[file_name]] = abs_data
  }
  
  # return the list of dataframes
  all_data
}

# select the baseline and the start of the rxn in shiny
select_shiny = function(plot_data, select_pts, baseline_percent=0.9) {
  # get points of the baseline and where to start the linear regression
  baseline_index = which.min(abs(plot_data$time_sec-select_pts$x[[1]]))
  # print(paste("baseline_index", baseline_index))
  start = which.min(abs(plot_data$time_sec-select_pts$x[[2]]))
  # print(paste("start", start))
  
  # get the ending point based off of the baseline percentage
  baseline = plot_data$nadh_conc_uM[[baseline_index]]
  # print(paste("baseline", baseline))
  end_est = baseline * baseline_percent
  # print(paste("end_est", end_est))
  end = which.min(abs(plot_data$nadh_conc_uM[start:length(plot_data$nadh_conc_uM)]-end_est)) + start
  # print(paste("end", end))
  
  # return ten_start
  c(start, end)
}

# calculate one regression from one data frame in shiny
get_regressions = function(all_data, lm_starts, percent_length=0.1) {
  # plot 10% of the plot based on the locator points
  regressions = mapply(FUN=function(plot_data, start, perc_len) {
    # get the start
    start_index = start[[1]]
    end_index = start[[2]]
    
    # get the new data from starts
    new_data = plot_data[start_index:end_index,]
    
    # get the linear regression and return the rate
    lin_reg = lm(new_data$nadh_conc_uM ~ new_data$time_sec)
    # c(abs(lin_reg$coefficients[[2]]))
    list(lin_reg)
  }, all_data, lm_starts, percent_length)
}

# plot the regressions
plot_shiny_reg = function(plot_data, lin_reg, start, show_reg) {
  # get the start
  start_index = start[[1]]
  end_index = start[[2]]
  
  # get the new data from starts
  new_data = plot_data[start_index:end_index,]
  
  # make the first plot
  plot(x=plot_data$time_sec, y=plot_data$nadh_conc_uM,
       type="l", xlab="Time (s)", ylab="[NADH] (uM)",
       main=paste0(attr(plot_data, "file_name"), " - (",
                   round(min(new_data$time_sec), 4), " to ",
                   round(max(new_data$time_sec), 4), " s)"))
  
  # add the number
  mtext(as.expression(bquote(bold(~.(paste0("[", attr(plot_data, "index"), "]"))))),
        adj=0, padj=-0.2)
  
  # plot linear regression
  if(show_reg) abline(lin_reg, col="#DC5340", lwd=2)
  
  # add the line formula and r squared
  eq = paste0("y = ", round(lin_reg$coefficients[[2]], 4),
              "x + ", round(lin_reg$coefficients[[1]], 4))
  r2 = paste0(round(summary(lin_reg)$r.squared, 4))
  rex = as.expression(bquote(R^2 ~ " = " ~ .(r2)))
  
  # add equations to the plot
  tmp_leg = legend("topright", legend=c(" ", " "),
                   text.width=strwidth("1,000,000"),
                   xjust=1, yjust=1, bty="n")
  text(tmp_leg$rect$left+tmp_leg$rect$w, tmp_leg$text$y,
       c(eq, rex), pos = 2, bty="n")
  
  # add attributes to the regression
  attributes(lin_reg)$file_name = attr(plot_data, "file_name")
  attributes(lin_reg)$data_index = attr(plot_data, "index")
  attributes(lin_reg)$plot = recordPlot()
  
  list(recordPlot())
}

