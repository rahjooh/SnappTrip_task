



select
    1
from gold.gold_daily_kpis

where not(cancelled_bookings >= 0)

