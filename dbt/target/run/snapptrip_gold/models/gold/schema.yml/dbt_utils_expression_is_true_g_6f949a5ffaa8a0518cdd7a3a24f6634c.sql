select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      



select
    1
from gold.gold_daily_kpis

where not(avg_booking_price > 0)


      
    ) dbt_internal_test