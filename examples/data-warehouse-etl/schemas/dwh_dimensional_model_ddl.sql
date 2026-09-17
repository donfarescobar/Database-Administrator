-- ============================================================================
-- DWH — Dimensional Model DDL (generic, no real data)
-- ============================================================================
-- Tujuan    : Skema dimensional (star schema) yang dipakai seluruh contoh ETL
--             di folder ini (fact_orders + dim_*), mengikuti docs/11 §3.
--             Data platform target: PostgreSQL. Bahan porting mudah ke
--             SQL Server/Oracle/Snowflake.
-- Aturan    :
--   - Kunci surrogate (*_key) SELF; business key tetap disimpan sebagai atribut.
--   - dim_customer memakai SCD Type-2 (valid_from/valid_to/is_current).
--   - fact_orders append-only, ber-partisi per bulan (opsional, lihat catatan).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. DIMENSI DATE (grain: 1 baris per hari)
-- ----------------------------------------------------------------------------
CREATE TABLE dwh.dim_date (
    date_key        INT          PRIMARY KEY,      -- format YYYYMMDD
    full_date       DATE         NOT NULL,
    day_of_month    SMALLINT     NOT NULL,
    month_number    SMALLINT     NOT NULL,
    month_name      VARCHAR(20)  NOT NULL,
    year_number     SMALLINT     NOT NULL,
    is_weekend      BOOLEAN      NOT NULL DEFAULT FALSE,
    is_holiday      BOOLEAN      NOT NULL DEFAULT FALSE,
    UNIQUE (full_date)
);

-- ----------------------------------------------------------------------------
-- 2. DIMENSI CUSTOMER (SCD Type-2)
-- ----------------------------------------------------------------------------
CREATE TABLE dwh.dim_customer (
    customer_key    BIGSERIAL    PRIMARY KEY,
    customer_id     BIGINT       NOT NULL,             -- business key dari source
    customer_name   VARCHAR(255) NOT NULL,
    segment_code    VARCHAR(20)  NOT NULL,
    branch_code     VARCHAR(10)  NOT NULL,
    valid_from      TIMESTAMP    NOT NULL,
    valid_to        TIMESTAMP,                          -- NULL = baris aktif
    is_current      BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (customer_id, valid_from)
);
CREATE INDEX ix_dim_customer_current ON dwh.dim_customer (customer_id) WHERE is_current;

-- ----------------------------------------------------------------------------
-- 3. DIMENSI ACCOUNT
-- ----------------------------------------------------------------------------
CREATE TABLE dwh.dim_account (
    account_key      BIGSERIAL    PRIMARY KEY,
    account_no       VARCHAR(30)  NOT NULL UNIQUE,     -- nomor rekening (masked di mart)
    account_type     VARCHAR(20)  NOT NULL,            -- SAVINGS / CURRENT / DEPOSITO
    currency         CHAR(3)      NOT NULL DEFAULT 'IDR',
    opened_date      DATE         NOT NULL,
    status           VARCHAR(15)  NOT NULL DEFAULT 'ACTIVE'
);

-- ----------------------------------------------------------------------------
-- 4. DIMENSI BRANCH
-- ----------------------------------------------------------------------------
CREATE TABLE dwh.dim_branch (
    branch_key   SMALLSERIAL  PRIMARY KEY,
    branch_code  VARCHAR(10)  NOT NULL UNIQUE,
    branch_name  VARCHAR(150) NOT NULL,
    region_code  VARCHAR(10)  NOT NULL,
    city         VARCHAR(100) NOT NULL
);

-- ----------------------------------------------------------------------------
-- 5. DIMENSI PRODUCT
-- ----------------------------------------------------------------------------
CREATE TABLE dwh.dim_product (
    product_key      SMALLSERIAL  PRIMARY KEY,
    product_code     VARCHAR(30)  NOT NULL UNIQUE,
    product_name     VARCHAR(150) NOT NULL,
    product_category VARCHAR(50)  NOT NULL
);

-- ----------------------------------------------------------------------------
-- 6. FACT ORDERS (grain: 1 baris = 1 transaksi order)
-- ----------------------------------------------------------------------------
CREATE TABLE dwh.fact_orders (
    transaction_id  BIGSERIAL    PRIMARY KEY,
    order_id        BIGINT       NOT NULL,             -- business key transaksi
    order_date_key  INT          NOT NULL REFERENCES dwh.dim_date (date_key),
    customer_key    BIGINT       NOT NULL REFERENCES dwh.dim_customer (customer_key),
    account_key     BIGINT       NOT NULL REFERENCES dwh.dim_account (account_key),
    branch_key      SMALLINT     NOT NULL REFERENCES dwh.dim_branch (branch_key),
    product_key     SMALLINT     NOT NULL REFERENCES dwh.dim_product (product_key),
    amount          NUMERIC(19,2) NOT NULL,
    currency        CHAR(3)      NOT NULL DEFAULT 'IDR',
    channel_code    VARCHAR(20)  NOT NULL,
    status          VARCHAR(15)  NOT NULL,
    batch_id        UUID         NOT NULL,             -- navigasi ke etl_batch_log
    UNIQUE (order_id)
);
-- Partisi per bulan (PostgreSQL 10+):
--   ALTER TABLE dwh.fact_orders DETACH PARTITION ...
--   CREATE TABLE dwh.fact_orders_202609 PARTITION OF dwh.fact_orders
--       FOR VALUES FROM (20260901) TO (20261001);

-- ----------------------------------------------------------------------------
-- 7. INDEX ANALYTICAL (columnar bila platform mendukung)
-- ----------------------------------------------------------------------------
CREATE INDEX ix_fact_orders_date ON dwh.fact_orders (order_date_key);
CREATE INDEX ix_fact_orders_cust ON dwh.fact_orders (customer_key);