WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SET DEFINE OFF

ALTER SESSION SET TIME_ZONE = '+00:00';

CREATE TABLE categories (
    id RAW(16) NOT NULL,
    code VARCHAR2(40 CHAR) NOT NULL,
    name VARCHAR2(80 CHAR) NOT NULL,
    description VARCHAR2(255 CHAR),
    active NUMBER(1, 0) NOT NULL,
    created_at TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    CONSTRAINT pk_categories PRIMARY KEY (id),
    CONSTRAINT uq_categories_code UNIQUE (code),
    CONSTRAINT ck_categories_active CHECK (active IN (0, 1))
);

CREATE TABLE occurrences (
    id RAW(16) NOT NULL,
    citizen_id RAW(16) NOT NULL,
    category_id RAW(16) NOT NULL,
    title VARCHAR2(120 CHAR) NOT NULL,
    description VARCHAR2(2000 CHAR) NOT NULL,
    priority VARCHAR2(10 CHAR) NOT NULL,
    status VARCHAR2(20 CHAR) NOT NULL,
    address_street VARCHAR2(160 CHAR) NOT NULL,
    address_number VARCHAR2(20 CHAR) NOT NULL,
    address_complement VARCHAR2(80 CHAR),
    address_district VARCHAR2(100 CHAR) NOT NULL,
    address_city VARCHAR2(100 CHAR) NOT NULL,
    address_state VARCHAR2(2 CHAR) NOT NULL,
    address_postal_code VARCHAR2(9 CHAR),
    version NUMBER(19, 0) NOT NULL,
    created_at TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    cancelled_at TIMESTAMP(6) WITH TIME ZONE,
    cancellation_reason VARCHAR2(255 CHAR),
    CONSTRAINT pk_occurrences PRIMARY KEY (id),
    CONSTRAINT fk_occ_category FOREIGN KEY (category_id) REFERENCES categories (id),
    CONSTRAINT ck_occ_priority CHECK (priority IN ('BAIXA', 'MEDIA', 'ALTA', 'CRITICA')),
    CONSTRAINT ck_occ_status CHECK (status IN (
        'ABERTA', 'EM_TRIAGEM', 'EM_ANDAMENTO', 'RESOLVIDA', 'ENCERRADA', 'CANCELADA'
    )),
    CONSTRAINT ck_occ_state CHECK (address_state = UPPER(address_state)),
    CONSTRAINT ck_occ_version CHECK (version >= 0),
    CONSTRAINT ck_occ_cancellation CHECK (
        (status = 'CANCELADA' AND cancelled_at IS NOT NULL AND cancellation_reason IS NOT NULL)
        OR
        (status <> 'CANCELADA' AND cancelled_at IS NULL AND cancellation_reason IS NULL)
    )
);

CREATE INDEX idx_occ_citizen ON occurrences (citizen_id);
CREATE INDEX idx_occ_category ON occurrences (category_id);
CREATE INDEX idx_occ_status ON occurrences (status);
CREATE INDEX idx_occ_priority ON occurrences (priority);
CREATE INDEX idx_occ_created_at ON occurrences (created_at);
CREATE INDEX idx_occ_status_category ON occurrences (status, category_id);

CREATE TABLE status_history (
    id RAW(16) NOT NULL,
    occurrence_id RAW(16) NOT NULL,
    action VARCHAR2(20 CHAR) NOT NULL,
    from_status VARCHAR2(20 CHAR),
    to_status VARCHAR2(20 CHAR),
    actor_id RAW(16) NOT NULL,
    actor_role VARCHAR2(10 CHAR) NOT NULL,
    note VARCHAR2(500 CHAR),
    created_at TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    CONSTRAINT pk_status_history PRIMARY KEY (id),
    CONSTRAINT fk_hist_occurrence FOREIGN KEY (occurrence_id) REFERENCES occurrences (id),
    CONSTRAINT ck_hist_action CHECK (action IN (
        'CRIACAO', 'EDICAO', 'TRIAGEM', 'TRANSICAO', 'CANCELAMENTO', 'REVISAO_IA'
    )),
    CONSTRAINT ck_hist_from_status CHECK (from_status IS NULL OR from_status IN (
        'ABERTA', 'EM_TRIAGEM', 'EM_ANDAMENTO', 'RESOLVIDA', 'ENCERRADA', 'CANCELADA'
    )),
    CONSTRAINT ck_hist_to_status CHECK (to_status IS NULL OR to_status IN (
        'ABERTA', 'EM_TRIAGEM', 'EM_ANDAMENTO', 'RESOLVIDA', 'ENCERRADA', 'CANCELADA'
    )),
    CONSTRAINT ck_hist_actor_role CHECK (actor_role IN ('CIDADAO', 'GESTOR'))
);

CREATE INDEX idx_hist_occ_created ON status_history (occurrence_id, created_at);

CREATE TABLE ai_suggestions (
    id RAW(16) NOT NULL,
    occurrence_id RAW(16) NOT NULL,
    status VARCHAR2(12 CHAR) NOT NULL,
    suggested_category_id RAW(16),
    suggested_priority VARCHAR2(10 CHAR),
    summary VARCHAR2(500 CHAR),
    justification VARCHAR2(2000 CHAR),
    sources_json CLOB,
    model VARCHAR2(100 CHAR),
    prompt_version VARCHAR2(40 CHAR),
    error_code VARCHAR2(60 CHAR),
    created_at TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    reviewed_at TIMESTAMP(6) WITH TIME ZONE,
    reviewed_by RAW(16),
    decision VARCHAR2(10 CHAR),
    review_note VARCHAR2(500 CHAR),
    CONSTRAINT pk_ai_suggestions PRIMARY KEY (id),
    CONSTRAINT uq_ai_sugg_occurrence UNIQUE (occurrence_id),
    CONSTRAINT fk_ai_occurrence FOREIGN KEY (occurrence_id) REFERENCES occurrences (id),
    CONSTRAINT fk_ai_category FOREIGN KEY (suggested_category_id) REFERENCES categories (id),
    CONSTRAINT ck_ai_status CHECK (status IN ('PENDENTE', 'PRONTA', 'ACEITA', 'REJEITADA', 'FALHOU')),
    CONSTRAINT ck_ai_priority CHECK (suggested_priority IS NULL OR suggested_priority IN (
        'BAIXA', 'MEDIA', 'ALTA', 'CRITICA'
    )),
    CONSTRAINT ck_ai_decision CHECK (decision IS NULL OR decision IN ('ACEITAR', 'REJEITAR')),
    CONSTRAINT ck_ai_review CHECK (
        (status IN ('PENDENTE', 'PRONTA', 'FALHOU')
            AND reviewed_at IS NULL AND reviewed_by IS NULL AND decision IS NULL)
        OR
        (status = 'ACEITA' AND reviewed_at IS NOT NULL AND reviewed_by IS NOT NULL AND decision = 'ACEITAR')
        OR
        (status = 'REJEITADA' AND reviewed_at IS NOT NULL AND reviewed_by IS NOT NULL AND decision = 'REJEITAR')
    ),
    CONSTRAINT ck_ai_error CHECK (
        (status = 'FALHOU' AND error_code IS NOT NULL)
        OR (status <> 'FALHOU' AND error_code IS NULL)
    )
);

CREATE INDEX idx_ai_sugg_category ON ai_suggestions (suggested_category_id);

CREATE TABLE processed_events (
    id RAW(16) NOT NULL,
    processed_at TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    CONSTRAINT pk_processed_events PRIMARY KEY (id)
);

CREATE TABLE outbox_events (
    id RAW(16) NOT NULL,
    aggregate_id RAW(16) NOT NULL,
    event_type VARCHAR2(80 CHAR) NOT NULL,
    schema_version NUMBER(10, 0) NOT NULL,
    payload CLOB NOT NULL,
    occurred_at TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    published_at TIMESTAMP(6) WITH TIME ZONE,
    attempts NUMBER(10, 0) NOT NULL,
    last_error VARCHAR2(120 CHAR),
    CONSTRAINT pk_outbox_events PRIMARY KEY (id),
    CONSTRAINT ck_outbox_schema_ver CHECK (schema_version > 0),
    CONSTRAINT ck_outbox_attempts CHECK (attempts >= 0)
);

CREATE INDEX idx_outbox_pending ON outbox_events (published_at, occurred_at);
CREATE INDEX idx_outbox_aggregate ON outbox_events (aggregate_id);

CREATE TABLE occurrence_audit (
    id NUMBER(19, 0) NOT NULL,
    occurrence_id RAW(16) NOT NULL,
    operation VARCHAR2(10 CHAR) NOT NULL,
    old_category_id RAW(16),
    new_category_id RAW(16),
    old_priority VARCHAR2(10 CHAR),
    new_priority VARCHAR2(10 CHAR),
    old_status VARCHAR2(20 CHAR),
    new_status VARCHAR2(20 CHAR),
    old_version NUMBER(19, 0),
    new_version NUMBER(19, 0),
    changed_at TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    changed_by VARCHAR2(128 CHAR) NOT NULL,
    CONSTRAINT pk_occurrence_audit PRIMARY KEY (id),
    CONSTRAINT ck_occ_audit_operation CHECK (operation IN ('UPDATE', 'DELETE'))
);

CREATE INDEX idx_occ_audit_occurrence ON occurrence_audit (occurrence_id, changed_at);

CREATE SEQUENCE seq_occurrence_audit
    START WITH 1
    INCREMENT BY 1
    NOMAXVALUE
    NOCYCLE
    CACHE 20;

PROMPT Schema CityTech criado com sucesso.
