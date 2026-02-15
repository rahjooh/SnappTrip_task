select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select city
from silver.silver_booking_state
where city is null



      
    ) dbt_internal_test