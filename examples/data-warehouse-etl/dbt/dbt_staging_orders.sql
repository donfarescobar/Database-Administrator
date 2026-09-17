{# =========================================================================
   dbt staging model — generic, no real data
   Tujuan   : Layer staging 1:1 dengan source. Tipe data dinormalisasi,
              nama kolom diseragamkan (snake_case), dan baris yang
              tidak valid ditandai untuk quarantine downstream.
   Lokasi   : models/staging/stg_orders.sql
   ========================================================================= #}

{{ config(materialized='incremental', unique_key='order_id', on_schema_change='append_new_columns') }}

WITH source AS (

    SELECT
        order_id,
        customer_id,
        order_date,
        amount,
        UPPER(TRIM(currency))        AS currency,
        LOWER(TRIM(status))          AS status,
        updated_at,
        is_deleted
    FROM {{ source('raw', 'orders') }}

    -- Hanya muat baris baru/berubah (incremental)
    {% if is_incremental() %}
        WHERE updated_at > (SELECT COALESCE(MAX(source_updated_at), '1900-01-01') FROM {{ this }})
    {% endif %}

),

renamed AS (

    SELECT
        order_id,
        customer_id,
        CAST(order_date AS DATE)     AS order_date,
        CAST(amount    AS NUMERIC(18,2)) AS amount,
        currency,
        status,
        updated_at                   AS source_updated_at,
        is_deleted,
        -- Validasi sederhana: tandai baris suspect untuk quarantine
        CASE
            WHEN amount IS NULL          THEN TRUE
            WHEN amount < 0             THEN TRUE
            WHEN currency NOT IN ('IDR','USD','SGD','EUR') THEN TRUE
            ELSE FALSE
        END                          AS is_quarantined,
        CURRENT_TIMESTAMP            AS dbt_loaded_at
    FROM source

)

SELECT * FROM renamed
