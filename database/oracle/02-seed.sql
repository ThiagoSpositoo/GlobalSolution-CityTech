WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SET DEFINE OFF
ALTER SESSION SET TIME_ZONE = '+00:00';

MERGE INTO categories c
USING (
    SELECT HEXTORAW('11111111111111111111111111111111') id, 'VIAS' code,
           'Vias e buracos' name, 'Pavimento, calcadas e sinalizacao viaria' description FROM dual
    UNION ALL SELECT HEXTORAW('22222222222222222222222222222222'), 'ILUMINACAO',
           'Iluminacao publica', 'Postes, lampadas e pontos sem iluminacao' FROM dual
    UNION ALL SELECT HEXTORAW('33333333333333333333333333333333'), 'ACESSIBILIDADE',
           'Acessibilidade', 'Barreiras de acesso e mobilidade urbana' FROM dual
    UNION ALL SELECT HEXTORAW('44444444444444444444444444444444'), 'DESCARTE',
           'Descarte irregular', 'Residuos e descarte em local inadequado' FROM dual
    UNION ALL SELECT HEXTORAW('55555555555555555555555555555555'), 'AGUA',
           'Agua e vazamentos', 'Vazamentos e problemas de drenagem urbana' FROM dual
    UNION ALL SELECT HEXTORAW('66666666666666666666666666666666'), 'OUTROS',
           'Outros servicos', 'Demandas urbanas sem categoria especifica' FROM dual
) s
ON (c.id = s.id)
WHEN MATCHED THEN UPDATE SET
    c.code = s.code, c.name = s.name, c.description = s.description,
    c.active = 1,
    c.updated_at = TO_TIMESTAMP_TZ('2026-11-17 12:00:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM')
WHEN NOT MATCHED THEN INSERT (
    id, code, name, description, active, created_at, updated_at
) VALUES (
    s.id, s.code, s.name, s.description, 1,
    TO_TIMESTAMP_TZ('2026-11-01 09:00:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'),
    TO_TIMESTAMP_TZ('2026-11-17 12:00:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM')
);

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM occurrences;
    IF v_count = 0 THEN
        INSERT ALL
            INTO occurrences VALUES (
                HEXTORAW('A0000000000000000000000000000001'), HEXTORAW('C0000000000000000000000000000001'),
                HEXTORAW('11111111111111111111111111111111'), 'Buraco na faixa de onibus',
                'Buraco profundo proximo ao ponto de embarque.', 'MEDIA', 'ABERTA',
                'Avenida Paulista', '1000', NULL, 'Bela Vista', 'Sao Paulo', 'SP', '01310-100', 0,
                TO_TIMESTAMP_TZ('2026-11-10 08:15:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'),
                TO_TIMESTAMP_TZ('2026-11-10 08:15:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'), NULL, NULL)
            INTO occurrences VALUES (
                HEXTORAW('A0000000000000000000000000000002'), HEXTORAW('C0000000000000000000000000000002'),
                HEXTORAW('22222222222222222222222222222222'), 'Poste apagado na praca',
                'Tres luminarias estao apagadas no acesso principal.', 'ALTA', 'EM_TRIAGEM',
                'Praca da Se', '10', NULL, 'Se', 'Sao Paulo', 'SP', '01001-000', 1,
                TO_TIMESTAMP_TZ('2026-11-10 19:40:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'),
                TO_TIMESTAMP_TZ('2026-11-11 09:20:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'), NULL, NULL)
            INTO occurrences VALUES (
                HEXTORAW('A0000000000000000000000000000003'), HEXTORAW('C0000000000000000000000000000003'),
                HEXTORAW('33333333333333333333333333333333'), 'Rampa bloqueada',
                'Veiculos ocupam a unica rampa de acesso da quadra.', 'CRITICA', 'EM_ANDAMENTO',
                'Rua Vergueiro', '1200', 'Entrada lateral', 'Vila Mariana', 'Sao Paulo', 'SP', '04102-000', 2,
                TO_TIMESTAMP_TZ('2026-11-11 10:00:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'),
                TO_TIMESTAMP_TZ('2026-11-12 14:30:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'), NULL, NULL)
            INTO occurrences VALUES (
                HEXTORAW('A0000000000000000000000000000004'), HEXTORAW('C0000000000000000000000000000004'),
                HEXTORAW('44444444444444444444444444444444'), 'Entulho em area publica',
                'Materiais de obra foram deixados ao lado da escola.', 'ALTA', 'RESOLVIDA',
                'Rua das Flores', '85', NULL, 'Centro', 'Osasco', 'SP', '06010-020', 3,
                TO_TIMESTAMP_TZ('2026-11-08 12:10:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'),
                TO_TIMESTAMP_TZ('2026-11-13 16:45:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'), NULL, NULL)
            INTO occurrences VALUES (
                HEXTORAW('A0000000000000000000000000000005'), HEXTORAW('C0000000000000000000000000000005'),
                HEXTORAW('55555555555555555555555555555555'), 'Vazamento na calcada',
                'Vazamento reparado pela equipe de manutencao.', 'MEDIA', 'ENCERRADA',
                'Avenida Dom Pedro I', '420', NULL, 'Ipiranga', 'Sao Paulo', 'SP', '01552-000', 4,
                TO_TIMESTAMP_TZ('2026-11-05 07:30:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'),
                TO_TIMESTAMP_TZ('2026-11-09 18:00:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'), NULL, NULL)
            INTO occurrences VALUES (
                HEXTORAW('A0000000000000000000000000000006'), HEXTORAW('C0000000000000000000000000000006'),
                HEXTORAW('66666666666666666666666666666666'), 'Placa com informacao incorreta',
                'Registro duplicado confirmado durante a analise.', 'BAIXA', 'CANCELADA',
                'Rua da Consolacao', '300', NULL, 'Consolacao', 'Sao Paulo', 'SP', '01302-000', 1,
                TO_TIMESTAMP_TZ('2026-11-12 11:20:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'),
                TO_TIMESTAMP_TZ('2026-11-12 11:40:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'),
                TO_TIMESTAMP_TZ('2026-11-12 11:40:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'),
                'Registro duplicado pelo cidadao')
            INTO occurrences VALUES (
                HEXTORAW('A0000000000000000000000000000007'), HEXTORAW('C0000000000000000000000000000007'),
                HEXTORAW('11111111111111111111111111111111'), 'Sinalizacao horizontal apagada',
                'Faixa de pedestres precisa de nova pintura.', 'ALTA', 'EM_ANDAMENTO',
                'Avenida Faria Lima', '2100', NULL, 'Itaim Bibi', 'Sao Paulo', 'SP', '01451-000', 2,
                TO_TIMESTAMP_TZ('2026-11-09 13:00:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'),
                TO_TIMESTAMP_TZ('2026-11-14 08:30:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'), NULL, NULL)
            INTO occurrences VALUES (
                HEXTORAW('A0000000000000000000000000000008'), HEXTORAW('C0000000000000000000000000000008'),
                HEXTORAW('22222222222222222222222222222222'), 'Iluminacao intermitente',
                'Lampada acende e apaga durante toda a noite.', 'MEDIA', 'ABERTA',
                'Rua Harmonia', '77', NULL, 'Vila Madalena', 'Sao Paulo', 'SP', '05435-000', 0,
                TO_TIMESTAMP_TZ('2026-11-15 22:10:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'),
                TO_TIMESTAMP_TZ('2026-11-15 22:10:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'), NULL, NULL)
            INTO occurrences VALUES (
                HEXTORAW('A0000000000000000000000000000009'), HEXTORAW('C0000000000000000000000000000009'),
                HEXTORAW('33333333333333333333333333333333'), 'Piso tatil danificado',
                'Trecho foi reparado e aguarda confirmacao do cidadao.', 'CRITICA', 'RESOLVIDA',
                'Avenida Cruzeiro do Sul', '1500', 'Proximo ao metro', 'Santana', 'Sao Paulo', 'SP', '02030-100', 3,
                TO_TIMESTAMP_TZ('2026-11-06 09:25:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'),
                TO_TIMESTAMP_TZ('2026-11-15 15:00:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'), NULL, NULL)
            INTO occurrences VALUES (
                HEXTORAW('A000000000000000000000000000000A'), HEXTORAW('C000000000000000000000000000000A'),
                HEXTORAW('44444444444444444444444444444444'), 'Lixo acumulado no canteiro',
                'Sacos se acumulam no canteiro central ha dois dias.', 'MEDIA', 'EM_TRIAGEM',
                'Avenida Jabaquara', '900', NULL, 'Saude', 'Sao Paulo', 'SP', '04046-000', 1,
                TO_TIMESTAMP_TZ('2026-11-14 17:50:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'),
                TO_TIMESTAMP_TZ('2026-11-15 08:10:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'), NULL, NULL)
            INTO occurrences VALUES (
                HEXTORAW('A000000000000000000000000000000B'), HEXTORAW('C000000000000000000000000000000B'),
                HEXTORAW('55555555555555555555555555555555'), 'Bueiro transbordando',
                'Agua retorna para a rua depois de chuva leve.', 'ALTA', 'ABERTA',
                'Rua Tito', '640', NULL, 'Lapa', 'Sao Paulo', 'SP', '05051-000', 0,
                TO_TIMESTAMP_TZ('2026-11-16 06:45:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'),
                TO_TIMESTAMP_TZ('2026-11-16 06:45:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'), NULL, NULL)
            INTO occurrences VALUES (
                HEXTORAW('A000000000000000000000000000000C'), HEXTORAW('C000000000000000000000000000000C'),
                HEXTORAW('66666666666666666666666666666666'), 'Banco quebrado na praca',
                'Banco substituido e atendimento confirmado.', 'BAIXA', 'ENCERRADA',
                'Praca Buenos Aires', '1', NULL, 'Higienopolis', 'Sao Paulo', 'SP', '01237-010', 4,
                TO_TIMESTAMP_TZ('2026-11-03 14:15:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'),
                TO_TIMESTAMP_TZ('2026-11-10 10:30:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'), NULL, NULL)
        SELECT 1 FROM dual;
    END IF;
END;
/

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM status_history;
    IF v_count = 0 THEN
        INSERT ALL
            INTO status_history VALUES (HEXTORAW('B0000000000000000000000000000001'), HEXTORAW('A0000000000000000000000000000001'), 'CRIACAO', NULL, 'ABERTA', HEXTORAW('C0000000000000000000000000000001'), 'CIDADAO', 'Registro inicial', TO_TIMESTAMP_TZ('2026-11-10 08:15:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'))
            INTO status_history VALUES (HEXTORAW('B0000000000000000000000000000002'), HEXTORAW('A0000000000000000000000000000002'), 'TRIAGEM', 'ABERTA', 'EM_TRIAGEM', HEXTORAW('D0000000000000000000000000000001'), 'GESTOR', 'Equipe de iluminacao acionada', TO_TIMESTAMP_TZ('2026-11-11 09:20:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'))
            INTO status_history VALUES (HEXTORAW('B0000000000000000000000000000003'), HEXTORAW('A0000000000000000000000000000003'), 'TRANSICAO', 'EM_TRIAGEM', 'EM_ANDAMENTO', HEXTORAW('D0000000000000000000000000000001'), 'GESTOR', 'Fiscalizacao em andamento', TO_TIMESTAMP_TZ('2026-11-12 14:30:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'))
            INTO status_history VALUES (HEXTORAW('B0000000000000000000000000000004'), HEXTORAW('A0000000000000000000000000000004'), 'TRANSICAO', 'EM_ANDAMENTO', 'RESOLVIDA', HEXTORAW('D0000000000000000000000000000002'), 'GESTOR', 'Entulho recolhido', TO_TIMESTAMP_TZ('2026-11-13 16:45:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'))
            INTO status_history VALUES (HEXTORAW('B0000000000000000000000000000005'), HEXTORAW('A0000000000000000000000000000005'), 'TRANSICAO', 'RESOLVIDA', 'ENCERRADA', HEXTORAW('C0000000000000000000000000000005'), 'CIDADAO', 'Reparo confirmado', TO_TIMESTAMP_TZ('2026-11-09 18:00:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'))
            INTO status_history VALUES (HEXTORAW('B0000000000000000000000000000006'), HEXTORAW('A0000000000000000000000000000006'), 'CANCELAMENTO', 'ABERTA', 'CANCELADA', HEXTORAW('C0000000000000000000000000000006'), 'CIDADAO', 'Registro duplicado pelo cidadao', TO_TIMESTAMP_TZ('2026-11-12 11:40:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'))
            INTO status_history VALUES (HEXTORAW('B0000000000000000000000000000007'), HEXTORAW('A0000000000000000000000000000007'), 'TRANSICAO', 'EM_TRIAGEM', 'EM_ANDAMENTO', HEXTORAW('D0000000000000000000000000000002'), 'GESTOR', 'Servico de pintura agendado', TO_TIMESTAMP_TZ('2026-11-14 08:30:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'))
            INTO status_history VALUES (HEXTORAW('B0000000000000000000000000000008'), HEXTORAW('A0000000000000000000000000000008'), 'CRIACAO', NULL, 'ABERTA', HEXTORAW('C0000000000000000000000000000008'), 'CIDADAO', 'Registro inicial', TO_TIMESTAMP_TZ('2026-11-15 22:10:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'))
            INTO status_history VALUES (HEXTORAW('B0000000000000000000000000000009'), HEXTORAW('A0000000000000000000000000000009'), 'TRANSICAO', 'EM_ANDAMENTO', 'RESOLVIDA', HEXTORAW('D0000000000000000000000000000001'), 'GESTOR', 'Piso tatil substituido', TO_TIMESTAMP_TZ('2026-11-15 15:00:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'))
            INTO status_history VALUES (HEXTORAW('B000000000000000000000000000000A'), HEXTORAW('A000000000000000000000000000000A'), 'TRIAGEM', 'ABERTA', 'EM_TRIAGEM', HEXTORAW('D0000000000000000000000000000002'), 'GESTOR', 'Coleta solicitada', TO_TIMESTAMP_TZ('2026-11-15 08:10:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'))
            INTO status_history VALUES (HEXTORAW('B000000000000000000000000000000B'), HEXTORAW('A000000000000000000000000000000B'), 'CRIACAO', NULL, 'ABERTA', HEXTORAW('C000000000000000000000000000000B'), 'CIDADAO', 'Registro inicial', TO_TIMESTAMP_TZ('2026-11-16 06:45:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'))
            INTO status_history VALUES (HEXTORAW('B000000000000000000000000000000C'), HEXTORAW('A000000000000000000000000000000C'), 'TRANSICAO', 'RESOLVIDA', 'ENCERRADA', HEXTORAW('C000000000000000000000000000000C'), 'CIDADAO', 'Atendimento confirmado', TO_TIMESTAMP_TZ('2026-11-10 10:30:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'))
        SELECT 1 FROM dual;
    END IF;
END;
/

INSERT INTO ai_suggestions (
    id, occurrence_id, status, suggested_category_id, suggested_priority, summary,
    justification, sources_json, model, prompt_version, error_code, created_at,
    reviewed_at, reviewed_by, decision, review_note
)
SELECT HEXTORAW('E0000000000000000000000000000001'), HEXTORAW('A0000000000000000000000000000001'),
       'PRONTA', HEXTORAW('11111111111111111111111111111111'), 'ALTA',
       'Possivel risco viario em corredor de onibus.',
       'Descricao indica buraco profundo em area de embarque.',
       TO_CLOB('["mobilidade-urbana.md#vias"]'), 'demo-controlled-model', 'v1', NULL,
       TO_TIMESTAMP_TZ('2026-11-10 08:16:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'),
       NULL, NULL, NULL, NULL
FROM dual WHERE NOT EXISTS (
    SELECT 1 FROM ai_suggestions WHERE id = HEXTORAW('E0000000000000000000000000000001')
);

INSERT INTO ai_suggestions (
    id, occurrence_id, status, suggested_category_id, suggested_priority, summary,
    justification, sources_json, model, prompt_version, error_code, created_at,
    reviewed_at, reviewed_by, decision, review_note
)
SELECT HEXTORAW('E0000000000000000000000000000002'), HEXTORAW('A0000000000000000000000000000002'),
       'ACEITA', HEXTORAW('22222222222222222222222222222222'), 'ALTA',
       'Falha de iluminacao em area de circulacao noturna.',
       'Multiplas luminarias apagadas elevam o risco no local.',
       TO_CLOB('["zeladoria.md#iluminacao"]'), 'demo-controlled-model', 'v1', NULL,
       TO_TIMESTAMP_TZ('2026-11-10 19:41:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'),
       TO_TIMESTAMP_TZ('2026-11-11 09:20:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'),
       HEXTORAW('D0000000000000000000000000000001'), 'ACEITAR', 'Sugestao coerente com a vistoria'
FROM dual WHERE NOT EXISTS (
    SELECT 1 FROM ai_suggestions WHERE id = HEXTORAW('E0000000000000000000000000000002')
);

INSERT INTO ai_suggestions (
    id, occurrence_id, status, suggested_category_id, suggested_priority, summary,
    justification, sources_json, model, prompt_version, error_code, created_at,
    reviewed_at, reviewed_by, decision, review_note
)
SELECT HEXTORAW('E000000000000000000000000000000B'), HEXTORAW('A000000000000000000000000000000B'),
       'FALHOU', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'MODEL_NOT_CONFIGURED',
       TO_TIMESTAMP_TZ('2026-11-16 06:46:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'),
       NULL, NULL, NULL, NULL
FROM dual WHERE NOT EXISTS (
    SELECT 1 FROM ai_suggestions WHERE id = HEXTORAW('E000000000000000000000000000000B')
);

INSERT INTO outbox_events (
    id, aggregate_id, event_type, schema_version, payload, occurred_at, published_at, attempts, last_error
)
SELECT HEXTORAW('F0000000000000000000000000000001'), HEXTORAW('A0000000000000000000000000000001'),
       'OccurrenceCreated.v1', 1, TO_CLOB('{"eventId":"f0000000-0000-0000-0000-000000000001"}'),
       TO_TIMESTAMP_TZ('2026-11-10 08:15:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'),
       TO_TIMESTAMP_TZ('2026-11-10 08:15:05 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'), 1, NULL
FROM dual WHERE NOT EXISTS (
    SELECT 1 FROM outbox_events WHERE id = HEXTORAW('F0000000000000000000000000000001')
);

INSERT INTO outbox_events (
    id, aggregate_id, event_type, schema_version, payload, occurred_at, published_at, attempts, last_error
)
SELECT HEXTORAW('F0000000000000000000000000000002'), HEXTORAW('A0000000000000000000000000000002'),
       'OccurrenceCreated.v1', 1, TO_CLOB('{"eventId":"f0000000-0000-0000-0000-000000000002"}'),
       TO_TIMESTAMP_TZ('2026-11-10 19:40:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'),
       TO_TIMESTAMP_TZ('2026-11-10 19:40:06 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'), 1, NULL
FROM dual WHERE NOT EXISTS (
    SELECT 1 FROM outbox_events WHERE id = HEXTORAW('F0000000000000000000000000000002')
);

INSERT INTO outbox_events (
    id, aggregate_id, event_type, schema_version, payload, occurred_at, published_at, attempts, last_error
)
SELECT HEXTORAW('F000000000000000000000000000000B'), HEXTORAW('A000000000000000000000000000000B'),
       'OccurrenceCreated.v1', 1, TO_CLOB('{"eventId":"f0000000-0000-0000-0000-00000000000b"}'),
       TO_TIMESTAMP_TZ('2026-11-16 06:45:00 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM'),
       NULL, 0, NULL
FROM dual WHERE NOT EXISTS (
    SELECT 1 FROM outbox_events WHERE id = HEXTORAW('F000000000000000000000000000000B')
);

INSERT INTO processed_events (id, processed_at)
SELECT HEXTORAW('F0000000000000000000000000000001'),
       TO_TIMESTAMP_TZ('2026-11-10 08:15:06 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM')
FROM dual WHERE NOT EXISTS (
    SELECT 1 FROM processed_events WHERE id = HEXTORAW('F0000000000000000000000000000001')
);

INSERT INTO processed_events (id, processed_at)
SELECT HEXTORAW('F0000000000000000000000000000002'),
       TO_TIMESTAMP_TZ('2026-11-10 19:40:07 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM')
FROM dual WHERE NOT EXISTS (
    SELECT 1 FROM processed_events WHERE id = HEXTORAW('F0000000000000000000000000000002')
);

COMMIT;
PROMPT Carga inicial aplicada: 6 categorias e 12 ocorrencias de demonstracao.
