select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) >0 as should_error
    from (
      



select
    1
from silver.silver_booking_state

where not(created_at <= updated_at)


      
    ) dbt_internal_test