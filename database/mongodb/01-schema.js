const databaseName = process.env.MONGODB_DATABASE || "citytech_demo";
const citytech = db.getSiblingDB(databaseName);

const uuidPattern = "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$";
const statuses = ["ABERTA", "EM_TRIAGEM", "EM_ANDAMENTO", "RESOLVIDA", "ENCERRADA", "CANCELADA"];
const priorities = ["BAIXA", "MEDIA", "ALTA", "CRITICA"];
const actions = ["CRIACAO", "EDICAO", "TRIAGEM", "TRANSICAO", "CANCELAMENTO", "REVISAO_IA"];

const nullableString = { bsonType: ["string", "null"] };
const nullableDate = { bsonType: ["date", "null"] };
const nullableUuid = { bsonType: ["string", "null"], pattern: uuidPattern };

const categorySummarySchema = {
  bsonType: "object",
  additionalProperties: false,
  required: ["id", "code", "name"],
  properties: {
    id: { bsonType: "string", pattern: uuidPattern },
    code: { bsonType: "string", minLength: 2, maxLength: 40 },
    name: { bsonType: "string", minLength: 2, maxLength: 80 }
  }
};

const historySchema = {
  bsonType: "object",
  additionalProperties: false,
  required: ["id", "action", "fromStatus", "toStatus", "actorId", "actorRole", "note", "createdAt"],
  properties: {
    id: { bsonType: "string", pattern: uuidPattern },
    action: { enum: actions },
    fromStatus: { enum: [...statuses, null] },
    toStatus: { enum: [...statuses, null] },
    actorId: { bsonType: "string", pattern: uuidPattern },
    actorRole: { enum: ["CIDADAO", "GESTOR"] },
    note: nullableString,
    createdAt: { bsonType: "date" }
  }
};

const aiSuggestionSchema = {
  bsonType: ["object", "null"],
  additionalProperties: false,
  required: [
    "id", "status", "suggestedCategory", "suggestedPriority", "summary", "justification",
    "sources", "model", "promptVersion", "errorCode", "createdAt", "reviewedAt",
    "reviewedBy", "decision", "reviewNote"
  ],
  properties: {
    id: { bsonType: "string", pattern: uuidPattern },
    status: { enum: ["PENDENTE", "PRONTA", "ACEITA", "REJEITADA", "FALHOU"] },
    suggestedCategory: { anyOf: [categorySummarySchema, { bsonType: "null" }] },
    suggestedPriority: { enum: [...priorities, null] },
    summary: nullableString,
    justification: nullableString,
    sources: { bsonType: ["array", "null"], items: { bsonType: "string" } },
    model: nullableString,
    promptVersion: nullableString,
    errorCode: nullableString,
    createdAt: { bsonType: "date" },
    reviewedAt: nullableDate,
    reviewedBy: nullableUuid,
    decision: { enum: ["ACEITAR", "REJEITAR", null] },
    reviewNote: nullableString
  }
};

const validators = {
  categorias: {
    $jsonSchema: {
      bsonType: "object",
      additionalProperties: false,
      required: [
        "_id", "oracleId", "origem", "snapshotVersao", "code", "name", "description",
        "active", "createdAt", "updatedAt"
      ],
      properties: {
        _id: { bsonType: "string", pattern: uuidPattern },
        oracleId: { bsonType: "string", pattern: uuidPattern },
        origem: { enum: ["oracle"] },
        snapshotVersao: { bsonType: "date" },
        code: { bsonType: "string", minLength: 2, maxLength: 40 },
        name: { bsonType: "string", minLength: 2, maxLength: 80 },
        description: nullableString,
        active: { bsonType: "bool" },
        createdAt: { bsonType: "date" },
        updatedAt: { bsonType: "date" }
      }
    }
  },
  ocorrencias: {
    $jsonSchema: {
      bsonType: "object",
      additionalProperties: false,
      required: [
        "_id", "oracleId", "origem", "snapshotVersao", "citizenId", "title", "description",
        "category", "priority", "status", "address", "version", "createdAt", "updatedAt",
        "cancelledAt", "cancellationReason", "history", "aiSuggestion"
      ],
      properties: {
        _id: { bsonType: "string", pattern: uuidPattern },
        oracleId: { bsonType: "string", pattern: uuidPattern },
        origem: { enum: ["oracle"] },
        snapshotVersao: { bsonType: "date" },
        citizenId: { bsonType: "string", pattern: uuidPattern },
        title: { bsonType: "string", minLength: 5, maxLength: 120 },
        description: { bsonType: "string", minLength: 10, maxLength: 2000 },
        category: categorySummarySchema,
        priority: { enum: priorities },
        status: { enum: statuses },
        address: {
          bsonType: "object",
          additionalProperties: false,
          required: ["street", "number", "complement", "district", "city", "state", "postalCode"],
          properties: {
            street: { bsonType: "string", minLength: 2, maxLength: 160 },
            number: { bsonType: "string", minLength: 1, maxLength: 20 },
            complement: nullableString,
            district: { bsonType: "string", minLength: 2, maxLength: 100 },
            city: { bsonType: "string", minLength: 2, maxLength: 100 },
            state: { bsonType: "string", pattern: "^[A-Z]{2}$" },
            postalCode: { bsonType: ["string", "null"], pattern: "^[0-9]{5}-[0-9]{3}$" }
          }
        },
        version: { bsonType: ["int", "long"], minimum: 0 },
        createdAt: { bsonType: "date" },
        updatedAt: { bsonType: "date" },
        cancelledAt: nullableDate,
        cancellationReason: nullableString,
        history: { bsonType: "array", minItems: 1, items: historySchema },
        aiSuggestion: aiSuggestionSchema
      }
    }
  },
  eventos_triagem: {
    $jsonSchema: {
      bsonType: "object",
      additionalProperties: false,
      required: [
        "_id", "oracleId", "origem", "snapshotVersao", "occurrenceId", "categoryCode",
        "district", "action", "fromStatus", "toStatus", "actorId", "actorRole", "note", "createdAt"
      ],
      properties: {
        _id: { bsonType: "string", pattern: uuidPattern },
        oracleId: { bsonType: "string", pattern: uuidPattern },
        origem: { enum: ["oracle"] },
        snapshotVersao: { bsonType: "date" },
        occurrenceId: { bsonType: "string", pattern: uuidPattern },
        categoryCode: { bsonType: "string", minLength: 2, maxLength: 40 },
        district: { bsonType: "string", minLength: 2, maxLength: 100 },
        action: { enum: actions },
        fromStatus: { enum: [...statuses, null] },
        toStatus: { enum: [...statuses, null] },
        actorId: { bsonType: "string", pattern: uuidPattern },
        actorRole: { enum: ["CIDADAO", "GESTOR"] },
        note: nullableString,
        createdAt: { bsonType: "date" }
      }
    }
  }
};

function ensureCollection(name, validator) {
  if (citytech.getCollectionInfos({ name }).length === 0) {
    const result = citytech.createCollection(name, {
      validator,
      validationLevel: "strict",
      validationAction: "error"
    });
    if (!result.ok) throw new Error(`Falha ao criar ${name}: ${tojson(result)}`);
    print(`Collection criada: ${name}`);
    return;
  }

  const result = citytech.runCommand({
    collMod: name,
    validator,
    validationLevel: "strict",
    validationAction: "error"
  });
  if (!result.ok) throw new Error(`Falha ao atualizar validator de ${name}: ${tojson(result)}`);
  print(`Validator atualizado: ${name}`);
}

Object.entries(validators).forEach(([name, validator]) => ensureCollection(name, validator));

citytech.categorias.createIndex({ oracleId: 1 }, { unique: true, name: "ux_categorias_oracle_id" });
citytech.categorias.createIndex({ code: 1 }, { unique: true, name: "ux_categorias_code" });
citytech.categorias.createIndex({ active: 1, name: 1 }, { name: "ix_categorias_active_name" });

citytech.ocorrencias.createIndex({ oracleId: 1 }, { unique: true, name: "ux_ocorrencias_oracle_id" });
citytech.ocorrencias.createIndex({ "category.code": 1, status: 1 }, { name: "ix_ocorrencias_category_status" });
citytech.ocorrencias.createIndex({ status: 1, priority: 1 }, { name: "ix_ocorrencias_status_priority" });
citytech.ocorrencias.createIndex({ "address.district": 1 }, { name: "ix_ocorrencias_district" });
citytech.ocorrencias.createIndex({ createdAt: -1 }, { name: "ix_ocorrencias_created_at" });
citytech.ocorrencias.createIndex(
  { "aiSuggestion.status": 1 },
  { name: "ix_ocorrencias_ai_status", partialFilterExpression: { aiSuggestion: { $type: "object" } } }
);

citytech.eventos_triagem.createIndex({ oracleId: 1 }, { unique: true, name: "ux_eventos_oracle_id" });
citytech.eventos_triagem.createIndex(
  { occurrenceId: 1, createdAt: 1 },
  { name: "ix_eventos_occurrence_created_at" }
);
citytech.eventos_triagem.createIndex(
  { action: 1, categoryCode: 1, createdAt: -1 },
  { name: "ix_eventos_action_category_created_at" }
);

print(`Schema MongoDB aplicado em ${databaseName}.`);
