--Product report
select 
id_roll as "Roll ID",
DECODE(type_roll,1,'WR',2,'BR') as "Type",
(select val_name from meta_dom_values@META where dom_id = 81 and val_code = status) as "Status",
status as "status_val",
remainder_tn as "Remainder (before), tn",
remainder_tn-:P23_PLANTN as "Remainder (after), tn"
from V_STOCK_OF_ROLLS_FORECAST 
where remainder_tn > :P23_PLANTN and status < 5
order by status,id_roll;

/

--Set report
select
id_roll as "Roll ID",
DECODE(type_roll,1,'WR',2,'BR') as "Type",
(select val_name from meta_dom_values@META where dom_id = 81 and val_code = status) as "Status",
status as "status_val",
remainder_tn as "Remainder (before), tn",
remainder_tn-(select min(remainder_tn) from V_STOCK_OF_ROLLS_FORECAST where id_roll = :P23_TOP_BACKUPROLL or id_roll = :P23_TOP_WORKROLL or id_roll = :P23_BOTTOM_WORKROLL or id_roll = :P23_BOTTOM_BACKUPROLL) as "Remainder (after), tn",
(select min(remainder_tn) from V_STOCK_OF_ROLLS_FORECAST where id_roll = :P23_TOP_BACKUPROLL or id_roll = :P23_TOP_WORKROLL or id_roll = :P23_BOTTOM_WORKROLL or id_roll = :P23_BOTTOM_BACKUPROLL) as "Max product, tn"
from V_STOCK_OF_ROLLS_FORECAST 
where id_roll = :P23_TOP_BACKUPROLL or id_roll = :P23_TOP_WORKROLL or id_roll = :P23_BOTTOM_WORKROLL or id_roll = :P23_BOTTOM_BACKUPROLL;