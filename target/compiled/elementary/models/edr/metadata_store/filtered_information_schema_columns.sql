



with filtered_information_schema_columns as (
        with empty_table as (
            select
            
                
        cast('dummy_string' as varchar) as full_table_name

,
                
        cast('dummy_string' as varchar) as database_name

,
                
        cast('dummy_string' as varchar) as schema_name

,
                
        cast('dummy_string' as varchar) as table_name

,
                
        cast('dummy_string' as varchar) as column_name

,
                
        cast('dummy_string' as varchar) as data_type


            )
        select * from empty_table
        where 1 = 0

)

select *
from filtered_information_schema_columns
where full_table_name is not null