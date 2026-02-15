



select
    1
from gold.gold_daily_kpis_v2

where not(confirmed_bookings + cancelled_bookings + pending_bookings = total_bookings)

