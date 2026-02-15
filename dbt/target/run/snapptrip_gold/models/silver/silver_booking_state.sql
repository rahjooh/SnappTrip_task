
    -- back compat for old kwarg name
  
  
  
      
          
          
      
  

  

  merge into silver.silver_booking_state as DBT_INTERNAL_DEST
      using silver_booking_state__dbt_tmp as DBT_INTERNAL_SOURCE
      on 
              DBT_INTERNAL_SOURCE.booking_id = DBT_INTERNAL_DEST.booking_id
          

      when matched then update set
         * 

      when not matched then insert *
