const databaseName = process.env.MONGODB_DATABASE || "citytech_demo";
const citytech = db.getSiblingDB(databaseName);
const snapshotVersao = ISODate("2026-11-17T12:00:00Z");

const categories = [
  ["11111111-1111-1111-1111-111111111111", "VIAS", "Vias e buracos", "Pavimento, calcadas e sinalizacao viaria"],
  ["22222222-2222-2222-2222-222222222222", "ILUMINACAO", "Iluminacao publica", "Postes, lampadas e pontos sem iluminacao"],
  ["33333333-3333-3333-3333-333333333333", "ACESSIBILIDADE", "Acessibilidade", "Barreiras de acesso e mobilidade urbana"],
  ["44444444-4444-4444-4444-444444444444", "DESCARTE", "Descarte irregular", "Residuos e descarte em local inadequado"],
  ["55555555-5555-5555-5555-555555555555", "AGUA", "Agua e vazamentos", "Vazamentos e problemas de drenagem urbana"],
  ["66666666-6666-6666-6666-666666666666", "OUTROS", "Outros servicos", "Demandas urbanas sem categoria especifica"]
].map(([id, code, name, description]) => ({
  _id: id,
  oracleId: id,
  origem: "oracle",
  snapshotVersao,
  code,
  name,
  description,
  active: true,
  createdAt: ISODate("2026-11-01T09:00:00Z"),
  updatedAt: snapshotVersao
}));

const categoryByCode = Object.fromEntries(categories.map(category => [category.code, category]));
const categorySummary = code => {
  const category = categoryByCode[code];
  return { id: category._id, code: category.code, name: category.name };
};

const occurrenceRows = [
  ["1", "VIAS", "Buraco na faixa de onibus", "Buraco profundo proximo ao ponto de embarque.", "MEDIA", "ABERTA", "Avenida Paulista", "1000", null, "Bela Vista", "Sao Paulo", "SP", "01310-100", 0, "2026-11-10T08:15:00Z", "2026-11-10T08:15:00Z", null, null],
  ["2", "ILUMINACAO", "Poste apagado na praca", "Tres luminarias estao apagadas no acesso principal.", "ALTA", "EM_TRIAGEM", "Praca da Se", "10", null, "Se", "Sao Paulo", "SP", "01001-000", 1, "2026-11-10T19:40:00Z", "2026-11-11T09:20:00Z", null, null],
  ["3", "ACESSIBILIDADE", "Rampa bloqueada", "Veiculos ocupam a unica rampa de acesso da quadra.", "CRITICA", "EM_ANDAMENTO", "Rua Vergueiro", "1200", "Entrada lateral", "Vila Mariana", "Sao Paulo", "SP", "04102-000", 2, "2026-11-11T10:00:00Z", "2026-11-12T14:30:00Z", null, null],
  ["4", "DESCARTE", "Entulho em area publica", "Materiais de obra foram deixados ao lado da escola.", "ALTA", "RESOLVIDA", "Rua das Flores", "85", null, "Centro", "Osasco", "SP", "06010-020", 3, "2026-11-08T12:10:00Z", "2026-11-13T16:45:00Z", null, null],
  ["5", "AGUA", "Vazamento na calcada", "Vazamento reparado pela equipe de manutencao.", "MEDIA", "ENCERRADA", "Avenida Dom Pedro I", "420", null, "Ipiranga", "Sao Paulo", "SP", "01552-000", 4, "2026-11-05T07:30:00Z", "2026-11-09T18:00:00Z", null, null],
  ["6", "OUTROS", "Placa com informacao incorreta", "Registro duplicado confirmado durante a analise.", "BAIXA", "CANCELADA", "Rua da Consolacao", "300", null, "Consolacao", "Sao Paulo", "SP", "01302-000", 1, "2026-11-12T11:20:00Z", "2026-11-12T11:40:00Z", "2026-11-12T11:40:00Z", "Registro duplicado pelo cidadao"],
  ["7", "VIAS", "Sinalizacao horizontal apagada", "Faixa de pedestres precisa de nova pintura.", "ALTA", "EM_ANDAMENTO", "Avenida Faria Lima", "2100", null, "Itaim Bibi", "Sao Paulo", "SP", "01451-000", 2, "2026-11-09T13:00:00Z", "2026-11-14T08:30:00Z", null, null],
  ["8", "ILUMINACAO", "Iluminacao intermitente", "Lampada acende e apaga durante toda a noite.", "MEDIA", "ABERTA", "Rua Harmonia", "77", null, "Vila Madalena", "Sao Paulo", "SP", "05435-000", 0, "2026-11-15T22:10:00Z", "2026-11-15T22:10:00Z", null, null],
  ["9", "ACESSIBILIDADE", "Piso tatil danificado", "Trecho foi reparado e aguarda confirmacao do cidadao.", "CRITICA", "RESOLVIDA", "Avenida Cruzeiro do Sul", "1500", "Proximo ao metro", "Santana", "Sao Paulo", "SP", "02030-100", 3, "2026-11-06T09:25:00Z", "2026-11-15T15:00:00Z", null, null],
  ["a", "DESCARTE", "Lixo acumulado no canteiro", "Sacos se acumulam no canteiro central ha dois dias.", "MEDIA", "EM_TRIAGEM", "Avenida Jabaquara", "900", null, "Saude", "Sao Paulo", "SP", "04046-000", 1, "2026-11-14T17:50:00Z", "2026-11-15T08:10:00Z", null, null],
  ["b", "AGUA", "Bueiro transbordando", "Agua retorna para a rua depois de chuva leve.", "ALTA", "ABERTA", "Rua Tito", "640", null, "Lapa", "Sao Paulo", "SP", "05051-000", 0, "2026-11-16T06:45:00Z", "2026-11-16T06:45:00Z", null, null],
  ["c", "OUTROS", "Banco quebrado na praca", "Banco substituido e atendimento confirmado.", "BAIXA", "ENCERRADA", "Praca Buenos Aires", "1", null, "Higienopolis", "Sao Paulo", "SP", "01237-010", 4, "2026-11-03T14:15:00Z", "2026-11-10T10:30:00Z", null, null]
];

const occurrenceId = suffix => `a0000000-0000-0000-0000-00000000000${suffix}`;
const citizenId = suffix => `c0000000-0000-0000-0000-00000000000${suffix}`;
const historyId = suffix => `b0000000-0000-0000-0000-00000000000${suffix}`;

const historyRows = [
  ["1", "CRIACAO", null, "ABERTA", citizenId("1"), "CIDADAO", "Registro inicial", "2026-11-10T08:15:00Z"],
  ["2", "TRIAGEM", "ABERTA", "EM_TRIAGEM", "d0000000-0000-0000-0000-000000000001", "GESTOR", "Equipe de iluminacao acionada", "2026-11-11T09:20:00Z"],
  ["3", "TRANSICAO", "EM_TRIAGEM", "EM_ANDAMENTO", "d0000000-0000-0000-0000-000000000001", "GESTOR", "Fiscalizacao em andamento", "2026-11-12T14:30:00Z"],
  ["4", "TRANSICAO", "EM_ANDAMENTO", "RESOLVIDA", "d0000000-0000-0000-0000-000000000002", "GESTOR", "Entulho recolhido", "2026-11-13T16:45:00Z"],
  ["5", "TRANSICAO", "RESOLVIDA", "ENCERRADA", citizenId("5"), "CIDADAO", "Reparo confirmado", "2026-11-09T18:00:00Z"],
  ["6", "CANCELAMENTO", "ABERTA", "CANCELADA", citizenId("6"), "CIDADAO", "Registro duplicado pelo cidadao", "2026-11-12T11:40:00Z"],
  ["7", "TRANSICAO", "EM_TRIAGEM", "EM_ANDAMENTO", "d0000000-0000-0000-0000-000000000002", "GESTOR", "Servico de pintura agendado", "2026-11-14T08:30:00Z"],
  ["8", "CRIACAO", null, "ABERTA", citizenId("8"), "CIDADAO", "Registro inicial", "2026-11-15T22:10:00Z"],
  ["9", "TRANSICAO", "EM_ANDAMENTO", "RESOLVIDA", "d0000000-0000-0000-0000-000000000001", "GESTOR", "Piso tatil substituido", "2026-11-15T15:00:00Z"],
  ["a", "TRIAGEM", "ABERTA", "EM_TRIAGEM", "d0000000-0000-0000-0000-000000000002", "GESTOR", "Coleta solicitada", "2026-11-15T08:10:00Z"],
  ["b", "CRIACAO", null, "ABERTA", citizenId("b"), "CIDADAO", "Registro inicial", "2026-11-16T06:45:00Z"],
  ["c", "TRANSICAO", "RESOLVIDA", "ENCERRADA", citizenId("c"), "CIDADAO", "Atendimento confirmado", "2026-11-10T10:30:00Z"]
];

const historyByOccurrence = Object.fromEntries(historyRows.map(row => {
  const [suffix, action, fromStatus, toStatus, actorId, actorRole, note, createdAt] = row;
  return [occurrenceId(suffix), [{
    id: historyId(suffix),
    action,
    fromStatus,
    toStatus,
    actorId,
    actorRole,
    note,
    createdAt: ISODate(createdAt)
  }]];
}));

const aiByOccurrence = {
  [occurrenceId("1")]: {
    id: "e0000000-0000-0000-0000-000000000001",
    status: "PRONTA",
    suggestedCategory: categorySummary("VIAS"),
    suggestedPriority: "ALTA",
    summary: "Possivel risco viario em corredor de onibus.",
    justification: "Descricao indica buraco profundo em area de embarque.",
    sources: ["mobilidade-urbana.md#vias"],
    model: "demo-controlled-model",
    promptVersion: "v1",
    errorCode: null,
    createdAt: ISODate("2026-11-10T08:16:00Z"),
    reviewedAt: null,
    reviewedBy: null,
    decision: null,
    reviewNote: null
  },
  [occurrenceId("2")]: {
    id: "e0000000-0000-0000-0000-000000000002",
    status: "ACEITA",
    suggestedCategory: categorySummary("ILUMINACAO"),
    suggestedPriority: "ALTA",
    summary: "Falha de iluminacao em area de circulacao noturna.",
    justification: "Multiplas luminarias apagadas elevam o risco no local.",
    sources: ["zeladoria.md#iluminacao"],
    model: "demo-controlled-model",
    promptVersion: "v1",
    errorCode: null,
    createdAt: ISODate("2026-11-10T19:41:00Z"),
    reviewedAt: ISODate("2026-11-11T09:20:00Z"),
    reviewedBy: "d0000000-0000-0000-0000-000000000001",
    decision: "ACEITAR",
    reviewNote: "Sugestao coerente com a vistoria"
  },
  [occurrenceId("b")]: {
    id: "e0000000-0000-0000-0000-00000000000b",
    status: "FALHOU",
    suggestedCategory: null,
    suggestedPriority: null,
    summary: null,
    justification: null,
    sources: null,
    model: null,
    promptVersion: null,
    errorCode: "MODEL_NOT_CONFIGURED",
    createdAt: ISODate("2026-11-16T06:46:00Z"),
    reviewedAt: null,
    reviewedBy: null,
    decision: null,
    reviewNote: null
  }
};

const occurrences = occurrenceRows.map(row => {
  const [
    suffix, categoryCode, title, description, priority, status, street, number, complement,
    district, city, state, postalCode, version, createdAt, updatedAt, cancelledAt, cancellationReason
  ] = row;
  const id = occurrenceId(suffix);
  return {
    _id: id,
    oracleId: id,
    origem: "oracle",
    snapshotVersao,
    citizenId: citizenId(suffix),
    title,
    description,
    category: categorySummary(categoryCode),
    priority,
    status,
    address: { street, number, complement, district, city, state, postalCode },
    version: NumberLong(String(version)),
    createdAt: ISODate(createdAt),
    updatedAt: ISODate(updatedAt),
    cancelledAt: cancelledAt ? ISODate(cancelledAt) : null,
    cancellationReason,
    history: historyByOccurrence[id],
    aiSuggestion: aiByOccurrence[id] || null
  };
});

const occurrenceById = Object.fromEntries(occurrences.map(occurrence => [occurrence._id, occurrence]));
const triageEvents = historyRows.map(row => {
  const [suffix, action, fromStatus, toStatus, actorId, actorRole, note, createdAt] = row;
  const occurrence = occurrenceById[occurrenceId(suffix)];
  const id = historyId(suffix);
  return {
    _id: id,
    oracleId: id,
    origem: "oracle",
    snapshotVersao,
    occurrenceId: occurrence._id,
    categoryCode: occurrence.category.code,
    district: occurrence.address.district,
    action,
    fromStatus,
    toStatus,
    actorId,
    actorRole,
    note,
    createdAt: ISODate(createdAt)
  };
});

function synchronizeSeed(collectionName, documents) {
  const collection = citytech.getCollection(collectionName);
  const ids = documents.map(document => document._id);
  const existingIds = new Set(collection.find({ _id: { $in: ids } }, { _id: 1 }).toArray().map(document => document._id));
  const missing = documents.filter(document => !existingIds.has(document._id));
  const existing = documents.filter(document => existingIds.has(document._id));

  if (missing.length > 0) collection.insertMany(missing, { ordered: true });
  if (existing.length > 0) {
    collection.bulkWrite(
      existing.map(document => ({ replaceOne: { filter: { _id: document._id }, replacement: document } })),
      { ordered: true }
    );
  }
  print(`${collectionName}: ${missing.length} inseridos, ${existing.length} sincronizados.`);
}

synchronizeSeed("categorias", categories);
synchronizeSeed("ocorrencias", occurrences);
synchronizeSeed("eventos_triagem", triageEvents);

print(`Seed aplicado em ${databaseName}: 6 categorias, 12 ocorrencias e 12 eventos de triagem.`);
