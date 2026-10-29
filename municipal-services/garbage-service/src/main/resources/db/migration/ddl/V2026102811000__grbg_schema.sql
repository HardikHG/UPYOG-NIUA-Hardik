-- ----------------------------------------------------------------------------
-- SEQUENCE for ug_gc_application.id
-- ----------------------------------------------------------------------------
CREATE SEQUENCE IF NOT EXISTS seq_ug_gc_application_id
    START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;


-- ----------------------------------------------------------------------------
-- 11.1  ug_gc_application  (primary application table)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ug_gc_application (
    id                  BIGINT         PRIMARY KEY,
    owner_uuid          VARCHAR(64)    NOT NULL,
    tenant_uuid         VARCHAR(64),
    application_no      VARCHAR(64)    NOT NULL,
    old_garbage_no      VARCHAR(64),
    garbage_no          VARCHAR(64)    NOT NULL,
    property_id         VARCHAR(64)    NOT NULL,
    status              VARCHAR(50)    NOT NULL,
    tenant              VARCHAR(100)   NOT NULL,
    business_service    VARCHAR(100)   NOT NULL,
    channel             VARCHAR(50),
    due_date            DATE,
    payment_status      VARCHAR(50),
    payment_amount      NUMERIC(12,2)  NOT NULL,
    created_by          VARCHAR(64)    NOT NULL,
    last_modified_by    VARCHAR(64)    NOT NULL,
    created_time        BIGINT         NOT NULL,
    last_modified_time  BIGINT         NOT NULL,
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_ug_gc_app_no       ON ug_gc_application (application_no);
CREATE UNIQUE INDEX IF NOT EXISTS idx_ug_gc_no           ON ug_gc_application (garbage_no);
CREATE INDEX        IF NOT EXISTS idx_ug_gc_prop_id      ON ug_gc_application (property_id);
CREATE INDEX        IF NOT EXISTS idx_ug_gc_owner        ON ug_gc_application (owner_uuid);
CREATE INDEX        IF NOT EXISTS idx_ug_gc_tenant_uuid  ON ug_gc_application (tenant_uuid);
CREATE INDEX        IF NOT EXISTS idx_ug_gc_status       ON ug_gc_application (status);
CREATE INDEX        IF NOT EXISTS idx_ug_gc_tenant       ON ug_gc_application (tenant);


-- ----------------------------------------------------------------------------
-- 11.2  ug_gc_connection_log  (disconnection / reconnection records)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ug_gc_connection_log (
    id                  VARCHAR(64)    PRIMARY KEY,
    garbage_id          BIGINT         NOT NULL,
    application_no      VARCHAR(64)    NOT NULL,
    request_no          VARCHAR(64)    NOT NULL,
    status              VARCHAR(50)    NOT NULL,
    reason              VARCHAR(255)   NOT NULL,
    request_type        VARCHAR(30)    NOT NULL,  -- DISCONNECTION | RECONNECTION | PERMANENT_DISCONNECTION
    reason_details      VARCHAR(500),
    effective_from      DATE           NOT NULL,
    effective_to        DATE,
    fee_charged         NUMERIC(12,2),
    created_by          VARCHAR(64)    NOT NULL,
    last_modified_by    VARCHAR(64)    NOT NULL,
    created_time        BIGINT         NOT NULL,
    last_modified_time  BIGINT         NOT NULL,
    CONSTRAINT uq_ug_gc_conn_log_request_no UNIQUE (request_no),
    CONSTRAINT fk_ug_gc_conn_log_garbage_id FOREIGN KEY (garbage_id) REFERENCES ug_gc_application (id)
);

CREATE INDEX IF NOT EXISTS idx_ug_gc_conn_garbage_id ON ug_gc_connection_log (garbage_id);
CREATE INDEX IF NOT EXISTS idx_ug_gc_conn_app_no     ON ug_gc_connection_log (application_no);
CREATE INDEX IF NOT EXISTS idx_ug_gc_conn_type       ON ug_gc_connection_log (request_type);


-- ----------------------------------------------------------------------------
-- 11.3  ug_gc_specification  (collection parameters)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ug_gc_specification (
    id                  VARCHAR(64)    PRIMARY KEY,
    garbage_id          BIGINT         NOT NULL,
    old_garbage_no      VARCHAR(64),
    collection_type     VARCHAR(100)   NOT NULL,
    property_type       VARCHAR(50)    NOT NULL,  -- OWNER | TENANT
    sub_category        VARCHAR(100)   NOT NULL,
    sub_category_type   VARCHAR(100),
    category            VARCHAR(100)   NOT NULL,
    no_of_units         INTEGER        NOT NULL,
    special_category    VARCHAR(100),
    floor_no            VARCHAR(30),
    is_inheritance      BOOLEAN,
    created_by          VARCHAR(64)    NOT NULL,
    last_modified_by    VARCHAR(64)    NOT NULL,
    created_time        BIGINT         NOT NULL,
    last_modified_time  BIGINT         NOT NULL,
    CONSTRAINT fk_ug_gc_spec_garbage_id FOREIGN KEY (garbage_id) REFERENCES ug_gc_application (id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_ug_gc_spec_garbage_id ON ug_gc_specification (garbage_id);


-- ----------------------------------------------------------------------------
-- 11.4  ug_gc_document  (supporting documents)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ug_gc_document (
    document_detail_id  VARCHAR(64)    PRIMARY KEY,
    garbage_id          BIGINT         NOT NULL,
    document_type       VARCHAR(100)   NOT NULL,
    filestore_id       VARCHAR(64)     NOT NULL,
    created_by          VARCHAR(64)    NOT NULL,
    last_modified_by    VARCHAR(64)    NOT NULL,
    created_time        BIGINT         NOT NULL,
    last_modified_time  BIGINT         NOT NULL,
    CONSTRAINT fk_ug_gc_doc_garbage_id FOREIGN KEY (garbage_id) REFERENCES ug_gc_application (id)
);

CREATE INDEX IF NOT EXISTS idx_ug_gc_doc_garbage_id ON ug_gc_document (garbage_id);


-- ----------------------------------------------------------------------------
-- 11.5  ug_gc_monthly_rent_payment  (monthly payment / bill logs)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ug_gc_monthly_rent_payment (
    id                  VARCHAR(64)    PRIMARY KEY,
    garbage_id          BIGINT         NOT NULL,
    garbage_no          VARCHAR(64)    NOT NULL,
    bill_no             VARCHAR(64)    NOT NULL,
    demand_id           VARCHAR(64),
    bill_date           DATE           NOT NULL,
    period_from         DATE           NOT NULL,
    period_to           DATE           NOT NULL,
    bill_amount         NUMERIC(12,2)  NOT NULL,
    payment_status      VARCHAR(50)    DEFAULT 'PENDING',  -- PAID | PENDING | WAIVED
    tenant              VARCHAR(100)   NOT NULL,
    created_by          VARCHAR(64)    NOT NULL,
    last_modified_by    VARCHAR(64)    NOT NULL,
    created_time        BIGINT         NOT NULL,
    last_modified_time  BIGINT         NOT NULL,
    CONSTRAINT uq_ug_gc_monthly_bill_no UNIQUE (bill_no),
    CONSTRAINT fk_ug_gc_monthly_bill_garbage_id FOREIGN KEY (garbage_id) REFERENCES ug_gc_application (id)
);

CREATE INDEX IF NOT EXISTS idx_ug_gc_bill_garbage_id ON ug_gc_monthly_rent_payment (garbage_id);
CREATE INDEX IF NOT EXISTS idx_ug_gc_bill_app_no     ON ug_gc_monthly_rent_payment (garbage_no);


-- ----------------------------------------------------------------------------
-- 11.6  ug_gc_bill_generate  (billing scheduler execution log)
--       garbage_id is VARCHAR(64) and has no FK, exactly as specified in 11.6.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ug_gc_bill_generate (
    id                    VARCHAR(64)    PRIMARY KEY,
    garbage_no            VARCHAR(64)    NOT NULL,
    tenant_id             VARCHAR(100)   NOT NULL,
    billing_date          DATE           NOT NULL,
    billing_period_from   BIGINT         NOT NULL,
    billing_period_to     BIGINT         NOT NULL,
    amount                NUMERIC(12,2)  NOT NULL,
    penalty_amount        NUMERIC(12,2)  NOT NULL,
    payment_type          VARCHAR(20)    NOT NULL,   -- MONTHLY | ADVANCE
    status                VARCHAR(20),  -- PENDING | GENERATED | FAILED
    created_by            VARCHAR(64)    NOT NULL,
    created_time          BIGINT         NOT NULL,
    last_modified_by      VARCHAR(64)    NOT NULL,
    last_modified_time    BIGINT         NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_ug_gc_sched_tenant  ON ug_gc_bill_generate (tenant_id);
CREATE INDEX IF NOT EXISTS idx_ug_gc_sched_garbage ON ug_gc_bill_generate (garbage_no);
