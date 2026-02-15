



select
    1
from gold.gold_daily_kpis

where not(avg_booking_price > 0)

