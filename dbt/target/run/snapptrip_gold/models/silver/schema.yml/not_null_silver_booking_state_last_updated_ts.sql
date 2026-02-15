select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select last_updated_ts
from silver.silver_booking_state
where last_updated_ts is null



      
    ) dbt_internal_test