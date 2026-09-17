-- ============================================================================
-- Liquibase changeSet t001 — core schema (generic, no real data)
-- Dipanggil dari: db.changelog-master.yaml (changeSet id=1)
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS app;

CREATE TABLE app.customer (
    customer_id     BIGSERIAL PRIMARY KEY,
    customer_no     VARCHAR(30)  NOT NULL UNIQUE,
    full_name       VARCHAR(255) NOT NULL,
    segment_code    VARCHAR(20)  NOT NULL,
    branch_code     VARCHAR(10)  NOT NULL,
    created_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE app.transaction (
    transaction_id  BIGSERIAL PRIMARY KEY,
    transaction_no  VARCHAR(40)  NOT NULL UNIQUE,
    customer_id     BIGINT       NOT NULL REFERENCES app.customer (customer_id),
    amount          NUMERIC(19,2) NOT NULL,
    currency        CHAR(3)      NOT NULL DEFAULT 'IDR',
    status          VARCHAR(15)  NOT NULL DEFAULT 'PENDING',
    created_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);