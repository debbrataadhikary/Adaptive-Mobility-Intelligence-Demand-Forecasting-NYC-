-- DROP IF EXISTS (SAFE RE-RUN)
DROP MATERIALIZED VIEW IF EXISTS view_nyc_ride_intelligence;

-- FINAL HYBRID INTELLIGENCE MATERIALIZED VIEW
CREATE MATERIALIZED VIEW view_nyc_ride_intelligence AS

WITH raw_combined AS (
    -- PHASE 1: Unified Schema Across Providers
    SELECT pickup_datetime AS pickup_ts, pickup_datetime::DATE AS trip_date,
           'Uber' AS company_name, base_code::TEXT, lat, lon, location_id
    FROM uber_master
    UNION ALL
    SELECT time_of_trip, time_of_trip::DATE, 'Lyft', base_code::TEXT, 
           NULL::NUMERIC, NULL::NUMERIC, NULL::INTEGER
    FROM trips_lyft
    UNION ALL
    SELECT pickup_date + pickup_time, (pickup_date + pickup_time)::DATE, 'Dial 7', 
           base_code::TEXT, NULL::NUMERIC, NULL::NUMERIC, NULL::INTEGER
    FROM trips_dial7
    UNION ALL
    SELECT pickup_date + pickup_time, (pickup_date + pickup_time)::DATE, 
           CASE
               WHEN base_code = 'B00256' THEN 'Carmel'
               WHEN base_code = 'B01536' THEN 'FirstClass'
               ELSE 'Other'
           END,
           base_code::TEXT, NULL::NUMERIC, NULL::NUMERIC, NULL::INTEGER
    FROM trips_address_based
),

temporal_features AS (
    -- PHASE 2: Feature Engineering
    SELECT *,
           EXTRACT(YEAR  FROM pickup_ts) AS trip_year,
           EXTRACT(MONTH FROM pickup_ts) AS trip_month_num,
           EXTRACT(HOUR  FROM pickup_ts) AS trip_hour,
           INITCAP(TRIM(TO_CHAR(pickup_ts, 'Day'))) AS trip_day,
           CASE
               WHEN (EXTRACT(MONTH FROM pickup_ts) = 12 AND EXTRACT(DAY FROM pickup_ts) BETWEEN 24 AND 31) OR
                    (EXTRACT(MONTH FROM pickup_ts) = 1 AND EXTRACT(DAY FROM pickup_ts) = 1) THEN 'Holiday_Season'
               WHEN EXTRACT(ISODOW FROM pickup_ts) IN (6, 7) THEN 'Weekend'
               ELSE 'Regular_Workday'
           END AS context_type
    FROM raw_combined
),

daily_hour_summary AS (
    -- PHASE 3: Aggregate Hourly Volume
    SELECT trip_date, trip_day, trip_hour, context_type,
           COUNT(*) AS hourly_volume
    FROM temporal_features
    GROUP BY trip_date, trip_day, trip_hour, context_type
),

hybrid_stats_engine AS (
    -- PHASE 4: Dual-Engine Statistics
    SELECT *,
           -- Global Baseline (long-term)
           AVG(hourly_volume) OVER (PARTITION BY trip_day, trip_hour, context_type) AS global_avg,
           STDDEV(hourly_volume) OVER (PARTITION BY trip_day, trip_hour, context_type) AS global_std,
           -- Moving Window (short-term, last 30 days)
           AVG(hourly_volume) OVER (
               PARTITION BY trip_day, trip_hour, context_type
               ORDER BY trip_date
               ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING
           ) AS moving_avg_30d,
           COUNT(*) OVER (
               PARTITION BY trip_day, trip_hour, context_type
               ORDER BY trip_date
               ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING
           ) AS history_depth
    FROM daily_hour_summary
),

inference_layer AS (
    -- PHASE 5: Adaptive Z-Score + Trend Divergence
    SELECT t.*,
           s.global_avg, s.global_std,
           COALESCE(s.moving_avg_30d, s.global_avg) AS trend_baseline,
           s.history_depth,
           -- Adaptive Z-Score
           CASE WHEN s.global_std > 0 
                THEN ROUND((COUNT(*) OVER (PARTITION BY t.trip_date, t.trip_hour) - s.global_avg) / s.global_std, 2)
                ELSE 0 END AS adaptive_z_score,
           -- Trend Divergence % vs recent moving trend
           ROUND(
               (COUNT(*) OVER (PARTITION BY t.trip_date, t.trip_hour) - COALESCE(s.moving_avg_30d, s.global_avg))
               / NULLIF(COALESCE(s.moving_avg_30d, s.global_avg), 0) * 100, 2
           ) AS trend_divergence_pct
    FROM temporal_features t
    LEFT JOIN hybrid_stats_engine s 
        ON t.trip_date = s.trip_date 
       AND t.trip_hour = s.trip_hour
),

metrics_governance AS (
    -- PHASE 6: KPI & Governance Layer
    SELECT *,
           COUNT(*) OVER (PARTITION BY trip_year, trip_month_num) AS total_monthly_trips,
           COUNT(*) OVER (PARTITION BY company_name, trip_year, trip_month_num) AS company_monthly_trips,
           CASE WHEN history_depth >= 30 THEN 'High_Reliability' ELSE 'Learning_Phase' END AS model_trust_index
    FROM inference_layer
)

-- PHASE 7: Final Decision-Grade Output (BI & Ops Ready)
SELECT trip_date, pickup_ts, company_name, base_code, trip_year, trip_day, trip_hour, context_type,
       adaptive_z_score,
       trend_baseline,
       trend_divergence_pct,
	   history_depth, 
       model_trust_index,
       -- Demand Intelligence Label
       CASE 
           WHEN adaptive_z_score >= 2.0 AND trend_divergence_pct > 15 THEN 'Critical Systemic Peak'
           WHEN adaptive_z_score >= 1.0 THEN 'High Demand'
           WHEN trend_divergence_pct > 25 THEN 'Abnormal Momentum'
           ELSE 'Baseline Normal'
       END AS demand_intelligence_label,
       -- Dynamic Surge Score (0–100)
       LEAST(100, GREATEST(0, ROUND((adaptive_z_score * 20) + 50))) AS dynamic_surge_score,
       -- Market Share %
       ROUND(company_monthly_trips::NUMERIC / NULLIF(total_monthly_trips, 0) * 100, 2) AS market_share_pct,
       -- Spatial Key for BI Visuals
       CASE
           WHEN lat IS NOT NULL AND lon IS NOT NULL THEN CONCAT(FLOOR(lat*100), '_', FLOOR(lon*100))
           WHEN location_id IS NOT NULL THEN location_id::TEXT
           ELSE 'UNKNOWN'
       END AS spatial_key
FROM metrics_governance;
