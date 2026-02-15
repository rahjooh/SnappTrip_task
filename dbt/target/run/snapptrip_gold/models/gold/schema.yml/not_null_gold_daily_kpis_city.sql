select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select city
from gold.gold_daily_kpis
where city is null



      
    ) dbt_internal_test