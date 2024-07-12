

     WITH customer AS (
        SELECT customer.*,
               employee.employee_first_name AS support_rep_first_name,
               employee.employee_last_name AS support_rep_last_name
          FROM DATAPAI.DATAPAI.stg_customer customer
     LEFT JOIN DATAPAI.DATAPAI.stg_employee employee USING (employee_id)
     )

     SELECT * FROM customer