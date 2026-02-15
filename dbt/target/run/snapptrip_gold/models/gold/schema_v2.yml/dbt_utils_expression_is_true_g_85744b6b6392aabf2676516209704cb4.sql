select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) >0 as should_error
    from (
      



select
    1
from gold.gold_daily_kpis_v2

where not(confirmed_bookings + cancelled_bookings + pending_bookings = total_bookings)


      
    ) dbt_internal_test