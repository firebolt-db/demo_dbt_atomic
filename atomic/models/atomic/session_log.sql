   {{
        config(
            materialized='incremental',
            unique_key=['userid', 'session_id', 'event_times'],
            incremental_strategy='append',
			table_type = "fact",
			primary_index = ['session_time', 'session_id']
        )
    }}



WITH src
AS (
	SELECT *
		,source_file_name
		,source_file_timestamp:: timestampntz as source_file_timestamp
	FROM {{ source ('atomic_adtech', 'ext_session_log') }}
	{%- if is_incremental()  %}
    where
      source_file_timestamp > (
        select
          coalesce(max(source_file_timestamp), '2000-01-01')
        from
          {{ this }}
      )

{%- endif %}
	)
SELECT userid as userid
	,NEST(event_name) AS events
	,NEST(revenue) AS revenues
	,session_id
	,campaign_id
	,COALESCE(publisher_channel.publisher_channel_id, '-1') AS publisher_channel_id
	,page_url
	,NEST(event_time) AS event_times
	,coalesce(MIN(event_time), '2000-01-01') AS session_time
	,date_trunc('month', MIN(event_time)) AS session_month
	,COALESCE(MIN(event_time)::DATE, '2000-01-01') AS event_date
	,user_demographics
	,MAX(src.source_file_name) AS source_file_name
	,MAX(src.source_file_timestamp) AS source_file_timestamp
FROM src
LEFT OUTER JOIN {{ ref('publisher_channel') }} publisher_channel ON publisher_channel.publisher_channel_name = SPLIT('/', page_url) [3]
GROUP BY ALL
