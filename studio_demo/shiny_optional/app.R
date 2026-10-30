# OPTIONAL lightweight Shiny interface, using only Shiny plus the included R source.
# The dependency-free Python application is the primary fully tested interface.
if (!requireNamespace('shiny',quietly=TRUE))
  stop('Install with install.packages("shiny")')
source('../R_package_candidate/lmmRRinsight/R/insight.R')
library(shiny)
input_dir <- Sys.getenv('RR_INSIGHT_DATA',unset='../examples/demo')
x <- rr_insight_bundle(utils::read.csv(file.path(input_dir,'traces.csv'),
                                    stringsAsFactors=FALSE),
                       utils::read.csv(file.path(input_dir,'evidence.csv'),
                                    stringsAsFactors=FALSE))
models <- unique(as.character(x$evidence$model))
ui <- fluidPage(
  tags$head(tags$style(HTML('
    body{background:#f4f7fc;color:#223958;font-family:-apple-system,BlinkMacSystemFont,sans-serif}
    .well{background:#fff;border:1px solid #dfe8f5;border-radius:15px}
    h2{color:#1b426c}.callout{background:#fff4df;border-left:4px solid #d9a33c;padding:14px;border-radius:9px}
    .card{background:#fff;border:1px solid #dfe8f5;border-radius:15px;padding:22px;margin:16px 0}
  '))),
  titlePanel('LMM RR | Insight Studio (Shiny experimental)'),
  div(class='callout','Statistical guardrail: Only imported calibrated p-values support inferential signals. Demo is illustrative.'),
  sidebarLayout(sidebarPanel(
    selectInput('model','Model',choices=models),
    uiOutput('processUI'),
    selectInput('alpha','Holm familywise alpha',choices=c('0.01'=.01,'0.05'=.05,'0.10'=.10),selected=.05)
  ),mainPanel(
    div(class='card',h3('Indexed process'),plotOutput('trace',height='350px')),
    div(class='card',h3('Evidence table'),tableOutput('summary')),
    div(class='card',h3('Suggested checks'),verbatimTextOutput('nextStep'))
  ))
)
server <- function(input,output,session){
  output$processUI <- renderUI({
    selectInput('process','Process',choices=unique(as.character(
      x$evidence$process[x$evidence$model==input$model])))
  })
  output$trace <- renderPlot({req(input$process);plot(x,model=input$model,process=input$process)})
  output$summary <- renderTable({req(input$model);tab<-rr_insight_report_table(x,as.numeric(input$alpha));
    tab[tab$model==input$model,c('process','p_value','holm_p','status'),drop=FALSE]})
  output$nextStep <- renderText({
    req(input$process)
    switch(input$process,
      mean_indexed='Check fixed-effect functional form and ordering.',
      cluster_indexed='Check grouping, cluster-level covariates and influence.',
      blup_indexed='Review random-effect structure and sensitivity.',
      serial_indexed='Review within-cluster serial correlation.',
      scale_indexed='Review variance heterogeneity.',
      'Review the scientific meaning of this index; no type classification is established.')
  })
}
shinyApp(ui,server)
