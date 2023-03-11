library(shiny)
library(shinyWidgets)
library(shinycssloaders)
library(shinyjs)
library(bigrquery)
library(dplyr)
library(tidyr)
library(stringr)
library(httr)
library(jsonlite)
library(paletteer)
library(gt)
library(gtExtras)
library(glue)
library(IRdisplay)
library(ggplot2)

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
# hrv_model <- 4989337476242866176
strain_model <- 3482320450934013952

recovery_url <- str_glue("https://us-east1-aiplatform.googleapis.com/v1/projects/msds434-whoop-app/locations/us-east1/endpoints/{recovery_model}:predict")
workout_url <- str_glue("https://us-east1-aiplatform.googleapis.com/v1/projects/msds434-whoop-app/locations/us-east1/endpoints/{strain_model}:predict")

workout_cols = c('acute_chronic_strain', 'workout_strain', 'workout_average_heart_rate','workout_max_heart_rate','workout_kilojoule','zone_one','zone_two','zone_thee','zone_four','zone_five',
'y_workout_strain', 'y_workout_average_heart_rate','y_workout_max_heart_rate','y_workout_kilojoule','y_zone_one','y_zone_two','y_zone_thee','y_zone_four','y_zone_five')
same_day_sleep_cols = c('sleep_start_time','light_sleep_time', 'slow_wave_sleep_time','rem_sleep_time','sleep_cycle_count','disturbance_count','respiratory_rate')
yesterday_sleep_cols = c('y_total_sleep_time', 'y_light_sleep_time', 'y_slow_wave_sleep_time','y_rem_sleep_time','y_sleep_cycle_count','y_disturbance_count','y_respiratory_rate', 'y_sleep_performance_perc', 'y_sleep_consistency_perc','y_sleep_efficiency_perc')
yesterday_strain_cols = c('y_kilojoule','y_strain', 'y_avg_heart_rate','y_max_heart_rate')
yesterday_workout_cols = c('y_workout_start_time','y_workout_max_heart_rate', 'y_workout_max_heart_rate','y_workout_kilojoule','y_zone_one','y_zone_two','y_zone_thee','y_zone_four','y_zone_five')
weekly_avgs = c('acute_chronic_strain', 'w_strain','w_sleep_start_time_sd','w_slow_wave_sleep_time','w_light_sleep_time','w_rem_sleep_time','w_recovery_score','w_hrv_milli','w_resting_heart_rate')
other_cols_recovery = c('week_of_year','day_of_week','na_acr','na_workout', 'sleep_start_time')
other_cols_workout = c('recovery_score','hrv_milli', 'day_of_week', 'na_workout')
other_cols_hrv = c('recovery_score', 'week_of_year','day_of_week','na_acr','na_workout', 'sleep_start_time')

df <- bq_project_query(project_id, sql)
df <- bq_table_download(df)
df<- df %>% 
  mutate(
    na_workout = ifelse(is.na(y_workout_strain),1,0),
    na_acr = ifelse(is.na(acute_chronic_strain),1,0)
    )

recovery_df <- df %>%
  group_by(day_of_week) %>%
  mutate(
    across(all_of(workout_cols),~coalesce(.,min(.,na.rm=T))),
    across(starts_with('y_'),~ifelse(is.numeric(.),coalesce(.,median(.,na.rm=T)),.)),
    across(c(starts_with('w_')),~ifelse(is.numeric(.),coalesce(.,median(.,na.rm=T)),.))
  )

features_recovery <- c('y_sleep_performance_perc', 'na_workout', 'w_slow_wave_sleep_time',
                       'y_max_heart_rate', 'y_slow_wave_sleep_time', 'y_zone_thee',
                       'y_zone_two', 'y_kilojoule', 'y_respiratory_rate',
                       'slow_wave_sleep_time', 'y_zone_four', 'w_rem_sleep_time',
                       'y_light_sleep_time', 'disturbance_count', 'y_zone_one',
                       'y_total_sleep_time', 'na_acr', 'day_of_week', 'sleep_start_time',
                       'y_sleep_consistency_perc', 'w_recovery_score',
                       'y_workout_max_heart_rate', 'y_sleep_efficiency_perc', 'y_zone_five',
                       'w_sleep_start_time_sd', 'y_workout_kilojoule', 'y_rem_sleep_time',
                       'light_sleep_time', 'acute_chronic_strain', 'respiratory_rate',
                       'y_workout_start_time', 'w_light_sleep_time', 'week_of_year',
                       'w_hrv_milli', 'rem_sleep_time', 'y_disturbance_count',
                       'y_avg_heart_rate', 'w_strain', 'y_strain', 'sleep_cycle_count',
                       'y_sleep_cycle_count', 'w_resting_heart_rate')

main_input_data <- recovery_df %>%
  dplyr::select(all_of(features_recovery)) %>%
  as.matrix(dimnames = "colnames")


workout_df <- df %>%
  group_by(day_of_week) %>%
  mutate(
    across(all_of(workout_cols),~coalesce(.,min(.,na.rm=T))),
    across(starts_with('y_'),~ifelse(is.numeric(.),coalesce(.,median(.,na.rm=T)),.)),
    across(c(starts_with('w_')),~ifelse(is.numeric(.),coalesce(.,median(.,na.rm=T)),.))
  )

features_workout <- c(
  'y_sleep_performance_perc', 'w_slow_wave_sleep_time',
  'y_max_heart_rate', 'y_slow_wave_sleep_time', 'y_zone_thee',
  'y_zone_two', 'y_kilojoule', 'y_respiratory_rate',
  'slow_wave_sleep_time', 'y_zone_four', 'w_rem_sleep_time',
  'y_light_sleep_time', 'disturbance_count', 'y_zone_one',
  'y_total_sleep_time', 'day_of_week', 'sleep_start_time',
  'y_sleep_consistency_perc', 'w_recovery_score',
  'y_workout_max_heart_rate', 'y_sleep_efficiency_perc',
  'y_zone_five', 'w_sleep_start_time_sd', 'y_workout_kilojoule',
  'y_rem_sleep_time', 'light_sleep_time', 'hrv_milli',
  'acute_chronic_strain', 'respiratory_rate', 'recovery_score',
  'y_workout_start_time', 'w_light_sleep_time', 'w_hrv_milli',
  'rem_sleep_time', 'y_disturbance_count', 'y_avg_heart_rate',
  'w_strain', 'y_strain', 'sleep_cycle_count', 'y_sleep_cycle_count',
  'w_resting_heart_rate'
)

main_input_data_workouts <- workout_df %>%
  dplyr::select(all_of(features_workout)) %>%
  as.matrix(dimnames = "colnames")

main_resp <- httr::POST(
  url = recovery_url,
  body = jsonlite::toJSON(list(instances = main_input_data)),
  add_headers(Authorization = paste("Bearer", access_token),
              content_type="application/json")
)

workout_resp <- httr::POST(
  url = workout_url,
  body = jsonlite::toJSON(list(instances = main_input_data_workouts)),
  add_headers(Authorization = paste("Bearer", access_token),
              content_type="application/json")
)

recovery_df$pred_recovery_score <- jsonlite::fromJSON(rawToChar(main_resp$content))$predictions
workout_df$pred_workout_strain <- jsonlite::fromJSON(rawToChar(workout_resp$content))$predictions

main_table <- function(){
  recovery_df %>%
    ungroup() %>%
    mutate(y_workout_strain = ifelse(na_workout == 1, as.numeric(NA),y_workout_strain)) %>%
    dplyr::select(recovery_date, day_of_week,
                  recovery_score, w_recovery_score, w_resting_heart_rate,
                  sleep_start_time, total_sleep_time, light_sleep_time, slow_wave_sleep_time, rem_sleep_time,
                  respiratory_rate,
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
    tab_header(title = md("**Daily Recovery**")) %>%
    tab_source_note(md("*last 30 days*")) %>%
    gt::tab_style(
      style = list(
        cell_text(weight = "bold")
      ),
      locations = list(
        cells_column_labels(gt::everything())
      )
    ) %>%
    gt::tab_style(
      style = list(
        cell_text(size = "x-large")
      ),
      locations = list(
        cells_title()
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
      palette = paletteer::paletteer_c(palette = "grDevices::RdYlGn",n=9,direction=1)%>% as.character(),
      width = 100
    )
}

main_workout_table <- function(){
  workout_df %>%
    ungroup() %>%
    arrange(recovery_date) %>%
    mutate(
      across(c(y_workout_strain, y_workout_start_time, y_workout_max_heart_rate, y_zone_four, y_zone_five),
             ~ifelse(na_workout == 1, as.numeric(NA),.)),
      workout_strain = ifelse(lead(na_workout)==1,as.numeric(NA),workout_strain)
      ) %>%
    dplyr::select(recovery_date, day_of_week,strain, workout_strain, w_strain, acute_chronic_strain,
                  na_workout,
                  y_kilojoule, y_workout_start_time, y_workout_max_heart_rate, y_zone_four, y_zone_five,
                  y_sleep_performance_perc, y_sleep_efficiency_perc,
                  pred_workout_strain) %>%
    mutate(
      recovery_date = as.Date(recovery_date),
      day_of_week = weekdays(recovery_date),
      across(c(contains("sleep_time")),~./(3.6*10**6)),
      `+/- strain` = workout_strain - pred_workout_strain
    ) %>%
    mutate_if(is.numeric,~round(.,1)) %>%
    arrange(desc(recovery_date)) %>%
    slice_head(n=14) %>%
    gt::gt() %>%
    gtExtras::gt_theme_538() %>%
    tab_header(title = md("**Daily Workouts**")) %>%
    tab_source_note(md("*last 14 days*")) %>%
    gt::tab_style(
      style = list(
        cell_text(weight = "bold")
      ),
      locations = list(
        cells_column_labels(gt::everything())
      )
    ) %>%
    gt::tab_style(
      style = list(
        cell_text(size = "x-large")
      ),
      locations = list(
        cells_title()
      )
    ) %>%
    cols_align(
      align = "center",
      columns = gt::everything()
    )%>%
    sub_missing(columns = gt::everything(),missing_text = "") %>%
    gtExtras::gt_color_box(
      columns = c(strain, workout_strain, w_strain),
      domain = c(0,20),
      palette = paletteer::paletteer_c(palette = "grDevices::YlOrRd",n=6,direction=-1)%>% as.character(),
      width = 100
    )
}

main_recovery_plot <- function(interval=30){
  recovery_df %>%
    ungroup() %>%
    mutate(
      recovery_date = as.Date(recovery_date),
      day_of_week = weekdays(recovery_date),
      across(c(contains("sleep_time")),~./(3.6*10**6)),
      `+/- recovery` = recovery_score - pred_recovery_score
    ) %>%
    arrange(desc(recovery_date)) %>%
    slice_head(n=interval) %>%
    ggplot() +
    geom_bar(aes(x = recovery_date, y= recovery_score, fill = recovery_score), stat = "identity") +
    geom_point(aes(x=recovery_date, y = pred_recovery_score), color = 'red', size = 2) +
    scale_fill_paletteer_c("grDevices::RdYlGn") +
    theme_bw()
}

ui <- navbarPage(
  id = "main_content",
  "MyWhoopStats",
  br(),
  selected = "Home",
  useShinyjs(),
  
  tabPanel(
    "Home",
    fluidRow(
      align = "center",
      gt::gt_output("main_table"),
      width = 10
    ),
    fluidRow(
      align = "center",
      gt::gt_output("main_workout_table"),
      width = 10
    ),
    br(),
    fluidRow(
      column(
        2,
        align = 'left',
        numericInput('main_recovery_plot_interval','Interval (days)',value = 30, min = 7, max = 365*3),
      )
    ),
    fluidRow(
      align = "center",
      plotOutput("main_recovery_plot"),
      width = 10
    ),
    
  )
  
  # tabPanel(
  # )
  
)

server <- function(input,output,session){
  
  output$main_table <- render_gt(
    main_table()
  )
  
  output$main_workout_table <- render_gt(
    main_workout_table()
  )
  
  output$main_recovery_plot <- renderPlot({
    main_recovery_plot(input$main_recovery_plot_interval)
  })
  
}

shinyApp(ui = ui, server = server)