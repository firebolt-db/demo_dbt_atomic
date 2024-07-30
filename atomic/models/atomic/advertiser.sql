   --This confg statement tells dbt how to materialize the resulting table.
   --In this case, since advertiser is going to be fairly small and used for 
   --lookups, we define it as a dimension table.  We set the primary index for performance
   --data will be persisted and indexed by advertiser_id.  We also set the default load strategy
   --to incremental, increasing ingest performance.
   
   {{
    
        config(
            materialized='incremental',
            unique_key=['advertiser_id'],
            incremental_strategy='delete+insert',
            table_type =  "dimension",
            primary_index = ['advertiser_id']
        )
    }}



--first, we want to find any data from any files created after our most recent batch
--we're materializing this CTE as we'll be refrencing it multiple times in the final query
--we'll use the source_file_timestamp metadata field to find new or updated rows
with
  src as (
    select
      advertiser_id,
      advertiser_name,
      $source_file_name as source_file_name,
      $source_file_timestamp::timestampntz as source_file_timestamp
    from
      {{ source ('atomic_adtech', 'ext_advertiser') }}
    
--this next piece changes the query depending if it's a normal incremental load, 
--or a full refresh.  On full refresh, we can't join to the destination table
--as it doesn't exist.  On incremental loads, we don't want to go through all
--the files in object storage, only those that have been created since the last
--load.  This will improve performance dramatically.

      {%- if is_incremental()  %}
    where
      $source_file_timestamp > (
        select
          coalesce(max(source_file_timestamp), '1980-01-01')
        from
          {{ this }}
      )

{%- endif %}
    
  )
  
--finally, from that CTE, we find the most recent state of every entity by key
select
  advertiser_id, advertiser_name, source_file_name, source_file_timestamp
from
  src
where
  (advertiser_id, source_file_timestamp) in (
    select
      advertiser_id,
      max(source_file_timestamp)
    from
      src
    group by all
    
  )
