select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      



select
    1
from silver.silver_booking_state

where not(price > 0)


      
    ) dbt_internal_test