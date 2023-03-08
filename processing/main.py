import pandas as pd
import pandas_gbq
from google.cloud import bigquery
from google.oauth2 import service_account
# credentials = service_account.Credentials.from_service_account_file("../../msds434-whoop-app-44384939c1f4.json")

def main():

    project_id = 'msds434-whoop-app'
    client = bigquery.Client(project=project_id)

    # daily data
    query_job1 = client.query(
        """ 
        SELECT

    r.cycle_id
    , r.sleep_id
    , date(r.created_at) recovery_date
    , extract(week from r.created_at at TIME ZONE 'America/Chicago') as week_of_year
    , extract(dayofweek from r.created_at at TIME ZONE 'America/Chicago') as day_of_week
    , r.score_state
    , r.score_recovery_score as recovery_score
    , r.score_resting_heart_rate as resting_heart_rate
    , r.score_hrv_rmssd_milli as hrv_milli
    , r.score_spo2_percentage as spo2_perc
    , r.score_skin_temp_celsius as skin_temp_celsius
    , s.score_state
    , s.start as sleep_start
    , s.end as sleep_end
    , case when extract(hour from s.start AT TIME ZONE 'America/Chicago') < 12
    then extract(hour from s.start AT TIME ZONE 'America/Chicago') + 24
    else extract(hour from s.start AT TIME ZONE 'America/Chicago' ) end +
    extract(minute from s.start AT TIME ZONE 'America/Chicago')/60.0 as sleep_start_time
    , s.score_stage_summary_total_in_bed_time_milli as in_bed_time
    , s.score_stage_summary_total_no_data_time_milli as no_data_time
    , s.score_stage_summary_total_light_sleep_time_milli as light_sleep_time
    , s.score_stage_summary_total_slow_wave_sleep_time_milli as slow_wave_sleep_time
    , s.score_stage_summary_total_rem_sleep_time_milli as rem_sleep_time
    , s.score_stage_summary_sleep_cycle_count as sleep_cycle_count
    , s.score_stage_summary_disturbance_count as disturbance_count
    , s.score_sleep_needed_baseline_milli as sleep_need
    , s.score_sleep_needed_need_from_sleep_debt_milli as sleep_need_from_debt
    , s.score_sleep_needed_need_from_recent_strain_milli as sleep_need_from_strain
    , s.score_respiratory_rate as respiratory_rate
    , s.score_sleep_performance_percentage as sleep_performance_perc
    , s.score_sleep_consistency_percentage as sleep_consistency_perc
    , s.score_sleep_efficiency_percentage as sleep_efficiency_perc
    , s.score sleep_score

    , c.score_average_heart_rate as avg_heart_rate
    , c.score_max_heart_rate as max_heart_rate
    , c.score_kilojoule as kilojoule
    , c.score_strain as strain

    , sy.score_state as y_score_state
    , sy.score_stage_summary_total_in_bed_time_milli as y_in_bed_time
    , sy.score_stage_summary_total_no_data_time_milli as y_no_data_time
    , sy.score_stage_summary_total_light_sleep_time_milli as y_light_sleep_time
    , sy.score_stage_summary_total_slow_wave_sleep_time_milli as y_slow_wave_sleep_time
    , sy.score_stage_summary_total_rem_sleep_time_milli as y_rem_sleep_time
    , sy.score_stage_summary_sleep_cycle_count as y_sleep_cycle_count
    , sy.score_stage_summary_disturbance_count as y_disturbance_count
    , sy.score_sleep_needed_baseline_milli as y_sleep_need
    , sy.score_sleep_needed_need_from_sleep_debt_milli as y_sleep_need_from_debt
    , sy.score_sleep_needed_need_from_recent_strain_milli as y_sleep_need_from_strain
    , sy.score_respiratory_rate as y_respiratory_rate
    , sy.score_sleep_performance_percentage as y_sleep_performance_perc
    , sy.score_sleep_consistency_percentage as y_sleep_consistency_perc
    , sy.score_sleep_efficiency_percentage as y_sleep_efficiency_perc
    , sy.score y_sleep_score

    , cy.score_average_heart_rate as y_avg_heart_rate
    , cy.score_max_heart_rate as y_max_heart_rate
    , cy.score_kilojoule as y_kilojoule
    , cy.score_strain as y_strain

    FROM `msds434-whoop-app.whoopdataset.recovery` r
    left join `msds434-whoop-app.whoopdataset.sleep` s on s.id = r.sleep_id
    left join `msds434-whoop-app.whoopdataset.cycles` c on c.id = r.cycle_id
    left join `msds434-whoop-app.whoopdataset.sleep` sy on date(sy.created_at, "America/Chicago") = date(r.created_at, "America/Chicago") - 1
    left join `msds434-whoop-app.whoopdataset.cycles` cy on date(cy.created_at, "America/Chicago") = date(r.created_at, "America/Chicago") - 1
    where s.nap = FALSE
    and sy.nap = FALSE
        """
    )

    whoop_daily = query_job1.to_dataframe()

    # add workouts
    # daily data
    query_job2 = client.query(
        """ 
        select 
    date(created_at) workout_date
    , date(created_at) + 1 tomorrow
    , max(extract(hour from created_at AT TIME ZONE 'America/Chicago')*1.0 +
    extract(minute from created_at AT TIME ZONE 'America/Chicago')/60.0) as workout_start_time
    , max(score_strain) as workout_strain
    , max(score_average_heart_rate) as workout_average_heart_rate
    , max(score_max_heart_rate) as workout_max_heart_rate
    , max(score_kilojoule) as workout_kilojoule
    , max(score_percent_recorded) as percent_recorded
    , max(score_zone_duration_zone_one_milli) as zone_one
    , max(score_zone_duration_zone_two_milli) as zone_two
    , max(score_zone_duration_zone_three_milli) as zone_thee
    , max(score_zone_duration_zone_four_milli) as zone_four
    , max(score_zone_duration_zone_five_milli) as zone_five
    from `whoopdataset.workouts`
    group by created_at, date(created_at), date(created_at) + 1, date(created_at) - 1
        """
    )

    workouts = query_job2.to_dataframe()

    # totals
    whoop_daily['total_sleep_time'] = whoop_daily['slow_wave_sleep_time'] + whoop_daily['light_sleep_time'] + whoop_daily['rem_sleep_time']
    whoop_daily['y_total_sleep_time'] = whoop_daily['y_slow_wave_sleep_time'] + whoop_daily['y_light_sleep_time'] + whoop_daily['y_rem_sleep_time']

    # ACR
    whoop_daily['acute_chronic_strain'] = whoop_daily['y_strain'].rolling(window = 7, min_periods=0).mean() / whoop_daily['y_strain'].rolling(window = 30, min_periods=14).mean() # acr

    # weekly avgs
    whoop_daily['w_strain'] = whoop_daily['y_strain'].rolling(window = 7, min_periods=5).mean() # strain
    whoop_daily['w_rtotal_sleep_time'] = whoop_daily['y_rem_sleep_time'].rolling(window = 7, min_periods=5).mean() # total sleep
    whoop_daily['w_sleep_start_time_sd'] = whoop_daily['sleep_start_time'].rolling(window = 7, min_periods=5).std().shift(1) # bedtime consitency
    whoop_daily['w_slow_wave_sleep_time'] = whoop_daily['y_slow_wave_sleep_time'].rolling(window = 7, min_periods=5).mean()
    whoop_daily['w_light_sleep_time'] = whoop_daily['y_light_sleep_time'].rolling(window = 7, min_periods=5).mean()
    whoop_daily['w_rem_sleep_time'] = whoop_daily['y_rem_sleep_time'].rolling(window = 7, min_periods=5).mean()
    whoop_daily['w_recovery_score'] = whoop_daily['recovery_score'].rolling(window = 7, min_periods=5).mean().shift(1)
    whoop_daily['w_hrv_milli'] = whoop_daily['hrv_milli'].rolling(window = 7, min_periods=5).mean().shift(1)
    whoop_daily['w_resting_heart_rate'] = whoop_daily['resting_heart_rate'].rolling(window = 7, min_periods=5).mean().shift(1)

    whoop_daily_with_workouts = whoop_daily.drop_duplicates("recovery_date").merge(
        workouts.drop_duplicates("workout_date").drop(columns="tomorrow"), 
        left_on="recovery_date",
        right_on= "workout_date",
        how="left"
    ).merge(
        workouts.add_prefix('y_').drop_duplicates('y_workout_date').drop(columns="y_workout_date"),
        left_on="recovery_date",
        right_on= "y_tomorrow",
        how="left"
    )

    try:
        pandas_gbq.to_gbq(whoop_daily_with_workouts, 'whoopdataset.whoopmerge', project_id=project_id, if_exists='replace')
        print("success")

    except Exception as e:
        print(f"error writing to gbq: {e}")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"job failed with error: {e}")