-- The merge key must be unique, or the next MERGE fails and consumers double-count.

select ticker, exchange, trade_date, count(*) as n
from "awsdatacatalog"."stock_common"."common_price_daily"
group by 1, 2, 3
having count(*) > 1