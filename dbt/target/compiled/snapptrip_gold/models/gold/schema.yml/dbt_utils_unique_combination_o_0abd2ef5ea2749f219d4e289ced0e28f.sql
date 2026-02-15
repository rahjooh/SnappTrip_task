





with validation_errors as (

    select
        booking_date, city
    from gold.gold_daily_kpis
    group by booking_date, city
    having count(*) > 1

)

select *
from validation_errors


