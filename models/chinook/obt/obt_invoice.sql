{{ config(materialized="table", tags="obt") }}

    SELECT date_key,
           invoice_id,
           customer_id,
           invoice_billing_address,
           invoice_billing_city,
           invoice_billing_state,
           invoice_billing_country,
           invoice_billing_postal_code,
           invoice_total,
           customer_first_name,
           customer_last_name,
           customer_company,
           customer_address,
           customer_city,
           customer_state,
           customer_country,
           customer_postal_code,
           customer_phone,
           customer_fax,
           customer_email,
           employee_id,
           support_rep_first_name,
           support_rep_last_name,
           day_of_year,
           day_of_month,
           day_of_week,
      FROM {{ ref('fct_invoice') }} invoice
 LEFT JOIN {{ ref('dim_date') }} dim_date 
        ON invoice.invoice_date = dim_date.date_key
 LEFT JOIN {{ ref('dim_customer') }} customer USING (customer_id)
