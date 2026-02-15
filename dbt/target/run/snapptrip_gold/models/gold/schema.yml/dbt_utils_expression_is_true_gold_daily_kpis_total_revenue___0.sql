select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      



select
    1
from gold.gold_daily_kpis

where not(total_revenue >= 0)


      
    ) dbt_internal_test