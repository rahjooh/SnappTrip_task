select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      



select
    1
from gold.gold_daily_kpis_v2

where not(cancelled_bookings >= 0)


      
    ) dbt_internal_test