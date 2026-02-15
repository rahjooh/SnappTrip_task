



select
    1
from silver.silver_booking_state

where not(created_at <= updated_at)

