   {{
        config(
            materialized='incremental',
            unique_key=['publisher_channel_id'],
            incremental_strategy='delete+insert',
            table_type = "dimension",
            primary_index = ['publisher_channel_id']
        )
    }}



--first, we want to find any data from any files created after our most recent batch
--we're materializing this CTE as we'll be refrencing it multiple times in the final query
--we'll use the source_file_timestamp metadata field to find new or updated rows
with
  src as (
    select
      publisher_channel_id, publisher_id, publisher_channel_name, source_file_name, source_file_timestamp::timestampntz as source_file_timestamp
    from
      {{ source ('atomic_adtech', 'ext_publisher_channel') }}
  
  {%- if is_incremental()  %}
    where
      source_file_timestamp > (
        select
          coalesce(max(source_file_timestamp), '1980-01-01')
        from
          {{ this }}
      )

{%- endif %}
  )
  
--finally, from that CTE, we find the most recent state of every entity by key
select
  publisher_channel_id, publisher_id, publisher_channel_name, source_file_name, source_file_timestamp
from
  {{ source ('atomic_adtech', 'ext_publisher_channel') }}
   
    
  