library(shiny)
library(shinyWidgets)
library(shinycssloaders)
library(shinyjs)
library(googleCloudRunner)
library(googleAuthR)
library(bigrquery)
library(dplyr)
library(tidyr)
library(stringr)
library(httr)
library(jsonlite)
library(reticulate)
library(paletteer)
library(gt)
library(gtExtras)
library(glue)
library(IRdisplay)

sh <- function(cmd, args = c(), intern = FALSE) {
  if (is.null(args)) {
    cmd <- glue(cmd)
    s <- strsplit(cmd, " ")[[1]]
    cmd <- s[1]
    args <- s[2:length(s)]
  }
  ret <- system2(cmd, args, stdout = TRUE, stderr = TRUE)
  if ("errmsg" %in% attributes(attributes(ret))$names) cat(attr(ret, "errmsg"), "\n")
  if (intern) return(ret) else cat(paste(ret, collapse = "\n"))
}

project_id <- "msds434-whoop-app"
access_token <- sh("gcloud auth print-access-token", intern = TRUE)

sql <- "select * from `whoopdataset.whoopmerge`"

recovery_model <- 5990825443379380224
hrv_model <- 4989337476242866176
strain_model <- 3482320450934013952

recovery_url <- str_glue("https://us-east1-aiplatform.googleapis.com/v1/projects/msds434-whoop-app/locations/us-east1/endpoints/{recovery_model}:predict")

workout_cols = c('acute_chronic_strain', 'workout_strain', 'workout_average_heart_rate','workout_max_heart_rate','workout_kilojoule','zone_one','zone_two','zone_thee','zone_four','zone_five',
'y_workout_strain', 'y_workout_average_heart_rate','y_workout_max_heart_rate','y_workout_kilojoule','y_zone_one','y_zone_two','y_zone_thee','y_zone_four','y_zone_five')

same_day_sleep_cols = c('sleep_start_time','light_sleep_time', 'slow_wave_sleep_time','rem_sleep_time','sleep_cycle_count','disturbance_count','respiratory_rate')
yesterday_sleep_cols = c('y_total_sleep_time', 'y_light_sleep_time', 'y_slow_wave_sleep_time','y_rem_sleep_time','y_sleep_cycle_count','y_disturbance_count','y_respiratory_rate', 'y_sleep_performance_perc', 'y_sleep_consistency_perc','y_sleep_efficiency_perc')
yesterday_strain_cols = c('y_kilojoule','y_strain', 'y_avg_heart_rate','y_max_heart_rate')
yesterday_workout_cols = c('y_workout_start_time','y_workout_max_heart_rate', 'y_workout_max_heart_rate','y_workout_kilojoule','y_zone_one','y_zone_two','y_zone_thee','y_zone_four','y_zone_five')
weekly_avgs = c('acute_chronic_strain', 'w_strain','w_sleep_start_time_sd','w_slow_wave_sleep_time','w_light_sleep_time','w_rem_sleep_time','w_recovery_score','w_hrv_milli','w_resting_heart_rate')

other_cols_recovery = c('week_of_year','day_of_week','na_acr','na_workout', 'sleep_start_time')
other_cols_workout = c('recovery_score', 'week_of_year','day_of_week','na_acr','na_workout', 'sleep_start_time')
other_cols_hrv = c('recovery_score', 'week_of_year','day_of_week','na_acr','na_workout', 'sleep_start_time')

df <- bq_project_query(project_id, sql)
df <- bq_table_download(df)
df<- df %>% mutate(na_workout = ifelse(is.na(y_strain),1,0),
                   na_acr = ifelse(is.na(acute_chronic_strain),1,0))

recovery_df <- df %>%
  group_by(day_of_week) %>%
  mutate(
    across(all_of(workout_cols),~coalesce(.,min(.,na.rm=T))),
    across(starts_with('y_'),~ifelse(is.numeric(.),coalesce(.,median(.,na.rm=T)),.)),
    across(c(starts_with('w_')),~ifelse(is.numeric(.),coalesce(.,median(.,na.rm=T)),.))
  )


main_input_data <- recovery_df %>%
  dplyr::select(all_of(other_cols_recovery),
                all_of(same_day_sleep_cols),
                all_of(yesterday_sleep_cols), 
                all_of(yesterday_strain_cols),
                all_of(yesterday_workout_cols),
                all_of(weekly_avgs)) %>%
  as.matrix(dimnames = "colnames")

  # drop_na(y_zone_five) %>%
  # mutate_if(is.numeric,~coalesce(.,mean(.,na.rm=T))) %>%
  # mutate(recovery_date = as.Date(recovery_date)) %>%
  # arrange(desc(recovery_date)) %>%
  # dplyr::select('week_of_year','day_of_week','na_acr','na_workout', 'sleep_start_time',
  #               all_of(yesterday_sleep_cols), 
  #               all_of(yesterday_strain_cols),
  #               all_of(yesterday_workout_cols),
  #               all_of(weekly_avgs))

main_resp <- httr::POST(
  url = recovery_url,
  body = jsonlite::toJSON(list(instances = main_input_data)),
  add_headers(Authorization = paste("Bearer", access_token),
              content_type="application/json")
)
recovery_df$pred_recovery_score <- jsonlite::fromJSON(rawToChar(main_resp$content))$predictions

main_table <- function(){
  recovery_df %>%
    ungroup() %>%
    dplyr::select(recovery_date, day_of_week,
                  recovery_score, w_recovery_score, w_resting_heart_rate,
                  sleep_start_time, total_sleep_time, light_sleep_time, slow_wave_sleep_time, rem_sleep_time,
                  y_workout_strain, w_strain, acute_chronic_strain,
                  pred_recovery_score) %>%
    mutate(
      recovery_date = as.Date(recovery_date),
      day_of_week = weekdays(recovery_date),
      across(c(contains("sleep_time")),~./(3.6*10**6)),
      `+/- recovery` = recovery_score - pred_recovery_score
    ) %>%
    mutate_if(is.numeric,~round(.,1)) %>%
    arrange(desc(recovery_date)) %>%
    slice_head(n=30) %>%
    gt::gt() %>%
    gtExtras::gt_theme_538() %>%
    gt::tab_style(
      style = list(
        cell_text(weight = "bold")
      ),
      locations = list(
        cells_column_labels(gt::everything())
      )
    ) %>%
    cols_align(
      align = "center",
      columns = gt::everything()
    )%>%
    sub_missing(columns = gt::everything(),missing_text = "") %>%
    gtExtras::gt_color_box(
      columns = c(recovery_score, w_recovery_score),
      domain = c(0,100),
      palette = paletteer::paletteer_c(palette = "grDevices::RdYlGn",n=10,direction=1)%>% as.character(),
      width = 100
    )
}

ui <- navbarPage(
  id = "main_content",
  "MyWhoopStats",
  br(),
  selected = "Home",
  useShinyjs(),
  
  tabPanel(
    "Home",
    # fluidRow(
    #   column(
    #     2,
    #     align = 'left', 
    #     selectInput('draft_year', 'Draft Year',multiple = FALSE, selected = cur_year,
    #                 choices = 2019:cur_year ),
    #   ),
    #   column(
    #     2,
    #     align = 'left', 
    #     selectInput('players', 'Player(s)',multiple = TRUE,
    #                 choices = df_res %>% mutate(player = paste(name,college_gsis_id, sep = " - ")) %>% distinct(player) %>% pull() %>% sort() ),
    #   )
    # ),
    # br(),
    fluidRow(
      align = "center",
      gt::gt_output("main_table"),
      width = 10
    ))
  
  # tabPanel(
  #   "Player Page",
  #   fluidRow(
  #     column(
  #       2,
  #       align = 'left',
  #       selectInput('player','Player',multiple = FALSE,selected="Hill, Daxton (2022) - 325320", selectize = TRUE,
  #                   choices = df_res %>% mutate(player =str_glue("{name} ({year}) - {college_gsis_id}")) %>% distinct(player) %>% pull() %>% sort() ),
  #     )
  #   ),
  #   br(),
  #   fluidRow(
  #     align = "center",
  #     gt::gt_output("player_availabilities"),
  #     width = 12
  #   ),
  #   br(),
  #   fluidRow(
  #     column(
  #       align = 'left',
  #       plotOutput("prob_plot"),
  #       width = 6
  #     ),
  #     column(
  #       align ='right',
  #       plotOutput("avail_plot"),
  #       width = 6
  #     )
  #   )
  # )
  
)

server <- function(input,output,session){
  
  output$main_table <- render_gt(
    main_table()
  )
  
  # output$player_availabilities <- render_gt(
  #   
  #   availabilities(
  #     df_res %>%
  #       mutate(player = str_glue("{name} ({year}) - {college_gsis_id}")) %>%
  #       filter(player == input$player) %>%
  #       distinct(college_gsis_id) %>%
  #       pull()
  #   ) %>%
  #     gt::gt() %>%
  #     gtExtras::gt_theme_espn()
  # )
  # 
  # output$prob_plot <- renderPlot({
  #   
  #   plot_prob(
  #     df_res %>%
  #       mutate(player = str_glue("{name} ({year}) - {college_gsis_id}")) %>%
  #       filter(player == input$player) %>%
  #       distinct(college_gsis_id) %>%
  #       pull()
  #   )
  # })
  # 
  # output$avail_plot <- renderPlot({
  #   
  #   plot_avail(
  #     df_res %>%
  #       mutate(player = str_glue("{name} ({year}) - {college_gsis_id}")) %>%
  #       filter(player == input$player) %>%
  #       distinct(college_gsis_id) %>%
  #       pull()
  #   )
  # })
  
}

shinyApp(ui = ui, server = server)