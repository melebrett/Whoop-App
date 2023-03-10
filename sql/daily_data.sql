/*
Model1
- predict recovery/hrv
- yesterday strain
- strain over last week
- acute chronic ratio (strain)
- yesterday sleep
- sleep over past week
- bedtime
- bedtime consistency
- day of week
- week of year

Model2
- predict workout strain/performance
- acute chronic ratio
- yesterday strain
- stain over last week
- yesterday sleep
- sleep over last week
- bedtime
- bedtime consistency
- recovery
- recovery over last week

Model3
- predict sleep performance
- bedtime
- bedtime consistency
- yesterday strain
- yesterday recovery

App
- sleep graph
- recovery graph
- acute chronic graph

- predicted recovery
- predicted sleep
- predicted workout

- strain over expected
- sleep over expected
- recovery over expected

For recovery targets:
- recommended sleep
- recommended strain

For workout performance:
- recommended sleep
- recommended recovery
*/


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

, c.score_average_heart_rate as y_avg_heart_rate
, c.score_max_heart_rate as y_max_heart_rate
, c.score_kilojoule as y_kilojoule
, c.score_strain as y_strain

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