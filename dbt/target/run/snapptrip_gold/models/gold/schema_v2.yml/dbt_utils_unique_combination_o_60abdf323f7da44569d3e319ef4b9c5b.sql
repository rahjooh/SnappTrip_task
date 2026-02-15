select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      





with validation_errors as (

    select
        booking_date, city
    from gold.gold_daily_kpis_v2
    group by booking_date, city
    having count(*) > 1

)

select *
from validation_errors



      
    ) dbt_internal_test