   {{
        config(
            materialized='incremental',
            unique_key=['session_day', 'publisher_channel_id'],
            incremental_strategy='delete+insert',
			table_type = "fact",
			primary_index = ['session_day', 'publisher_channel_id']
        )
    }}


--first, we want to find all sessions included in any files imported since the last import
--since there are new rows for them, they need to be summarized and merged into the summary table
with session_filter as (select session_id from session_log 
{%- if is_incremental()  %}
where source_file_timestamp > (select max(max_source_file_timestamp) from daily_publisher_channel_summary)

{%- endif %}
)



--then we consolidate these rows, leveraging nest and flatten
,src as (

SELECT userid as userid
	,ARRAY_FLATTEN(ARRAY_AGG(events)) AS events
	,ARRAY_FLATTEN(array_concat(ARRAY_AGG(revenues))) AS revenues
	,session_id
	,max(campaign_id) as campaign_id
	, publisher_channel_id
	,page_url
	,ARRAY_FLATTEN(array_concat(ARRAY_AGG(event_times))) AS event_times
	,MIN(coalesce(session_time, '2000-01-01')) AS session_time
	,date_trunc('month', MIN(session_month)) AS session_month
	,COALESCE(MIN(event_date)::DATE, '2000-01-01') AS event_date
	,user_demographics
	,MAX(source_file_name) AS source_file_name
	,MAX(source_file_timestamp) AS source_file_timestamp
FROM session_log 
where session_id in (select session_id from session_filter)

GROUP BY ALL
)

--last, we populate the destination summary table

SELECT event_date AS session_day
	,publisher_channel_id
	,SUM(CONTAINS (
			events
			,'Request'
			)::INT) AS Requests
	,SUM(CONTAINS (
			events
			,'impression'
			)::INT) AS impressions
	,SUM(CONTAINS (
			events
			,'click'
			)::INT) AS clicks
	,SUM(CONTAINS (
			events
			,'conversion'
			)::INT) AS conversions
	,SUM((
			CONTAINS (
				events
				,'click'
				)
			AND NOT CONTAINS (
				events
				,'impression'
				)
			)::INT) AS fraudulent_clicks
	,SUM((
			CONTAINS (
				events
				,'conversion'
				)
			AND NOT CONTAINS (
				events
				,'impression'
				)
			)::INT) AS fraudulent_conversions
	,SUM((
			CONTAINS (
				events
				,'impression'
				)
			AND CONTAINS (
				events
				,'conversion'
				)
			AND NOT CONTAINS (
				events
				,'click'
				)
			)::INT) AS latent_conversions
	,SUM(revenues[ INDEX_OF(events, 'impression')]) AS impression_revenue
	,SUM(revenues[ INDEX_OF(events, 'click')]) AS click_revenue
	,SUM(revenues[ INDEX_OF(events, 'conversion')]) AS conversion_revenue
	,SUM(CASE 
			WHEN (
					CONTAINS (
						events
						,'click'
						)
					AND NOT CONTAINS (
						events
						,'impression'
						)
					)
				THEN revenues[INDEX_OF(events, 'impression')] + 
				revenues[ INDEX_OF(events, 'click')] + 
				revenues[ INDEX_OF(events, 'conversion')]
			ELSE 0
			END) AS fraudulent_revenue
	,MAX(source_file_timestamp) AS max_source_file_timestamp
FROM  {{ ref('session_log') }}
GROUP BY ALL



