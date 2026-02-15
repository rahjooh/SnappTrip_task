
    -- back compat for old kwarg name
  
  
  
      
          
              
              
          
              
              
          
      
  

  

  merge into gold.gold_daily_kpis_v2 as DBT_INTERNAL_DEST
      using gold_daily_kpis_v2__dbt_tmp as DBT_INTERNAL_SOURCE
      on 
                  DBT_INTERNAL_SOURCE.booking_date = DBT_INTERNAL_DEST.booking_date
               and 
                  DBT_INTERNAL_SOURCE.city = DBT_INTERNAL_DEST.city
              

      when matched then update set
         * 

      when not matched then insert *
