
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Kinetics

<!-- badges: start -->
<!-- badges: end -->

#### [Web application link](https://hmlea.shinyapps.io/kinetics/)

**Kinetics** is a web application that allows the easy creation of
simple and effective Michaelis-Menten plots. This app takes a CSV file
containing substrate concentration data in the first column and rate
data in the second column and fits a Michaelis-Menten curve to the data.

## Usage

This web application creates Michaelis-Menten plots from uploaded data.
These plots can then be customized and downloaded for your own use.

The **Kinetics** web app can be accessed
[here](https://hmlea.shinyapps.io/kinetics/) or you can download and run
it on your machine using the Shiny package with the following code:

    `shiny::runGitHub("hmlea/kinetics")`

## To Do

In the future, I would like to:

- Allow the customization of more plot features
- Add the ability to overlay multiple Michaelis-Menten plots
- Rework the download button and add the ability to lock the aspect
  ratio
- Allow for certain plot features to be selectively hidden or shown
- Add a separate program that calculates rate from absorbance data
