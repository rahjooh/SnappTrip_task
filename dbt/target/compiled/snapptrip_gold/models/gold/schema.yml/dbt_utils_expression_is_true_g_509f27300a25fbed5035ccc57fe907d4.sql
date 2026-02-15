



select
    1
from gold.gold_daily_kpis

where not(confirmed_bookings >= 0)

