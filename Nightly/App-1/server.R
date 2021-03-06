#load packages - not sure if necessary
library(shiny) 
library(rmarkdown) 
library(ggplot2)
library(knitr)
library(pander)
library(dplyr)
library(tidyr)
library(rcompanion)
library(suncalc)
library(ggforce)
library(janitor)

shinyServer(function(input, output) {

  output$contents <- renderTable({
    
    # input$file1 will be NULL initially. After the user selects and uploads a 
    # file, it will be a data frame with 'name', 'size', 'type', and 'datapath' 
    # columns. The 'datapath' column will contain the local filenames where the 
    # data can be found.
    
    data1 <- input$file #grabs uploaded file
    
    if (is.null(data1)) #if no data has been uploaded, main panel is empty
      return(NULL)
    
    data2 <- read.csv(data1$datapath, header=TRUE)
    data2 #if data has been uploaded, it reads it and then displays in the main panel
  })
  
  # this reactive output tells Shiny that once data has been uploaded it should display a   download button for the
  # Rmd report. If no data has been uploaded then the button will not appear.
  output$ui.download <- renderUI({
    if (is.null(input$file)) return() #if no data uploaded button is not present
    downloadButton("report", "Generate report")}) #if data uploaded button appears
  
  output$ui.download.helper <- renderUI({
    if (is.null(input$file)) return() #if no data uploaded, helper text associated with      the download button not present
    h5(helpText("Report may take a few minutes to generate; please be patient."))})
  #if data uploaded, helper text associated with the download button appears
  
  output$report <- downloadHandler(
    filename = "Ecobat Nightly Report.doc", #we want word document output
    
    content = function(file) {
      
      withProgress(message = 'Collating data...', value = 0, {
        
        # Copy the report file and Style file to a temporary directory before processing it, in
        # case we don't have write permissions to the current working dir (which
        # can happen when deployed).
        for(file_to_move in c("Nightly.Rmd", "stylesdoc.docx")){
          temp <- file.path(tempdir(), file_to_move) 
          file.copy(file_to_move, temp, overwrite = TRUE)
        }
  
        #**CRUCIAL CODE
        # this code is responsible for passing the data to Rmd.
        dataa <- input$file #tells R Markdown where it can find data
        datab <- read.csv(dataa$datapath, header=TRUE) #tells Rmd where to read the data from
        author <- input$Author #tells Rmd what to use as Author
        #**END CRUCIAL CODE
        
        print(str(datab))
        
        # Set up parameters to pass to Rmd document
        params <- list(n = datab, Author = author)
        
        incProgress(0.3, "Building report, this may take a minute...")
        
        # Knit the document, passing in the `params` list, and eval it in a
        # child of the global environment (this isolates the code in the document
        # from the code in this app).
        rmarkdown::render(file.path(tempdir(), "Nightly.Rmd"),
                          output_file = file,
                          params = params,
                          envir = new.env(parent = globalenv()))
        
        incProgress(1, "Report complete")
                          
      })
    })  
  
})

