



select
    1
from gold.gold_daily_kpis_v2

where not(booking_date <= CURRENT_DATE())

