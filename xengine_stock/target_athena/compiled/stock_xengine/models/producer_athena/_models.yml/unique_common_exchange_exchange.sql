
    
    

select
    exchange as unique_field,
    count(*) as n_records

from "awsdatacatalog"."stock_common"."common_exchange"
where exchange is not null
group by exchange
having count(*) > 1


