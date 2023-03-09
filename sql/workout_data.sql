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