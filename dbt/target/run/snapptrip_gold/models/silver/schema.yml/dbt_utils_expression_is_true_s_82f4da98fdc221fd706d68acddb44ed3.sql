select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      



select
    1
from silver.silver_booking_state

where not(star_rating BETWEEN 1 AND 5)


      
    ) dbt_internal_test