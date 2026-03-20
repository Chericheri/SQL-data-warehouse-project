============================================
   Loading Bronze Layer                     
   Batch Start Time : 2026-03-20 05:01:59
============================================
--------------------------------------------
   Truncating CRM Tables                    
--------------------------------------------
>> Truncating Table : bronze_crm_cust_info
>> Truncate Duration: 1 seconds
>> Truncating Table : bronze_crm_prd_info
>> Truncate Duration: 0 seconds
>> Truncating Table : bronze_crm_sales_details
>> Truncate Duration: 0 seconds
--------------------------------------------
   Truncating ERP Tables                    
--------------------------------------------
>> Truncating Table : bronze_erp_cust_az12
>> Truncate Duration: 0 seconds
>> Truncating Table : bronze_erp_loc_a101
>> Truncate Duration: 0 seconds
>> Truncating Table : bronze_erp_px_cat_g1v2
>> Truncate Duration: 0 seconds
============================================
   Bronze Layer Truncation Completed ✅     
   Batch End Time   : 2026-03-20 05:02:00
   Total Batch Duration : 1 seconds
============================================
   Now run the LOAD DATA script below  ⬇️  
============================================

============================================
   Bronze Layer Load Results                 
============================================
--------------------------------------------
   CRM Tables                               
--------------------------------------------
>> bronze_crm_cust_info     | Rows: 18494 | Duration: 0 seconds
>> bronze_crm_prd_info      | Rows: 397 | Duration: 0 seconds
>> bronze_crm_sales_details | Rows: 60398 | Duration: 0 seconds
--------------------------------------------
   ERP Tables                               
--------------------------------------------
>> bronze_erp_cust_az12     | Rows: 18484 | Duration: 0 seconds
>> bronze_erp_loc_a101      | Rows: 18484 | Duration: 0 seconds
>> bronze_erp_px_cat_g1v2   | Rows: 37 | Duration: 0 seconds
============================================
   Total Batch Duration : 0 seconds
   Bronze Layer Loaded Successfully! 🎉     
============================================
