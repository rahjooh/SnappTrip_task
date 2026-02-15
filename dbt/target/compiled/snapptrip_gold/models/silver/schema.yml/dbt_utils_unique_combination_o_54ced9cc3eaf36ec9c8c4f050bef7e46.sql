





with validation_errors as (

    select
        booking_id
    from silver.silver_booking_state
    group by booking_id
    having count(*) > 1

)

select *
from validation_errors


