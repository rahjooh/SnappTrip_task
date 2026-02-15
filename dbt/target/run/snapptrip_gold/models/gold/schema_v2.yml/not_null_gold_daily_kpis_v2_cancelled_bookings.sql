select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select cancelled_bookings
from gold.gold_daily_kpis_v2
where cancelled_bookings is null



      
    ) dbt_internal_test