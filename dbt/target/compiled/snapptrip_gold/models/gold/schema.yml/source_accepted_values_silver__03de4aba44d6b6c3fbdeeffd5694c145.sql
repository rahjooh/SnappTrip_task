
    
    

with all_values as (

    select
        status as value_field,
        count(*) as n_records

    from silver.bookings
    group by status

)

select *
from all_values
where value_field not in (
    'created','confirmed','cancelled'
)


