select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select booking_date
from gold.gold_daily_kpis
where booking_date is null



      
    ) dbt_internal_test