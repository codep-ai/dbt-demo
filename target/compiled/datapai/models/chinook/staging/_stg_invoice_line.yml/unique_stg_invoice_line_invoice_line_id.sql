
    
    

select
    invoice_line_id as unique_field,
    count(*) as n_records

from DATAPAI.DATAPAI.stg_invoice_line
where invoice_line_id is not null
group by invoice_line_id
having count(*) > 1


