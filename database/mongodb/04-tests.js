const databaseName = process.env.MONGODB_DATABASE || "citytech_demo";
const citytech = db.getSiblingDB(databaseName);
let assertions = 0;

function assertCondition(condition, message) {
  if (!condition) throw new Error(`ASSERTION FAILED: ${message}`);
  assertions += 1;
  print(`PASS ${assertions}: ${message}`);
}

function occurrenceId(suffix) {
  return `a0000000-0000-0000-0000-00000000000${suffix}`;
}

function historyId(suffix) {
  return `b0000000-0000-0000-0000-00000000000${suffix}`;
}

const suffixes = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c"];
const categoryIds = ["1", "2", "3", "4", "5", "6"].map(value => `${value.repeat(8)}-${value.repeat(4)}-${value.repeat(4)}-${value.repeat(4)}-${value.repeat(12)}`);
const occurrenceIds = suffixes.map(occurrenceId);
const eventIds = suffixes.map(historyId);

assertCondition(citytech.getCollectionInfos({ name: "categorias" }).length === 1, "collection categorias existe");
assertCondition(citytech.getCollectionInfos({ name: "ocorrencias" }).length === 1, "collection ocorrencias existe");
assertCondition(citytech.getCollectionInfos({ name: "eventos_triagem" }).length === 1, "collection eventos_triagem existe");

for (const name of ["categorias", "ocorrencias", "eventos_triagem"]) {
  const info = citytech.getCollectionInfos({ name })[0];
  assertCondition(info.options.validationLevel === "strict", `${name} usa validationLevel strict`);
  assertCondition(info.options.validationAction === "error", `${name} rejeita documento invalido`);
  assertCondition(Boolean(info.options.validator && info.options.validator.$jsonSchema), `${name} possui $jsonSchema`);
}

assertCondition(citytech.categorias.countDocuments({ _id: { $in: categoryIds } }) === 6, "seed possui as 6 categorias Oracle");
assertCondition(citytech.ocorrencias.countDocuments({ _id: { $in: occurrenceIds } }) === 12, "seed possui as 12 ocorrencias Oracle");
assertCondition(citytech.eventos_triagem.countDocuments({ _id: { $in: eventIds } }) === 12, "seed possui os 12 eventos equivalentes ao historico Oracle");
assertCondition(citytech.ocorrencias.countDocuments({ origem: "oracle", oracleId: { $in: occurrenceIds } }) === 12, "oracleId e origem preservam a rastreabilidade");

const categoryCounts = citytech.ocorrencias.aggregate([
  { $match: { _id: { $in: occurrenceIds } } },
  { $group: { _id: "$category.code", count: { $sum: 1 } } },
  { $sort: { _id: 1 } }
]).toArray();
assertCondition(
  categoryCounts.length === 6 && categoryCounts.every(item => item.count === 2),
  "relatorio por categoria coincide com Oracle: 2 ocorrencias em cada categoria"
);

const priorityCounts = Object.fromEntries(citytech.ocorrencias.aggregate([
  { $match: { _id: { $in: occurrenceIds }, status: { $nin: ["ENCERRADA", "CANCELADA"] } } },
  { $group: { _id: "$priority", count: { $sum: 1 } } }
]).toArray().map(item => [item._id, item.count]));
assertCondition(
  priorityCounts.CRITICA === 2 && priorityCounts.ALTA === 4 && priorityCounts.MEDIA === 3 && priorityCounts.BAIXA === undefined,
  "fila nao terminal coincide com Oracle: CRITICA=2, ALTA=4, MEDIA=3"
);

const categoryStatusCounts = citytech.ocorrencias.aggregate([
  { $match: { _id: { $in: occurrenceIds } } },
  { $group: { _id: { category: "$category.code", status: "$status" }, count: { $sum: 1 } } }
]).toArray();
assertCondition(
  categoryStatusCounts.length === 12 && categoryStatusCounts.every(item => item.count === 1),
  "relatorio categoria/status coincide com as 12 combinacoes do Oracle"
);

const embeddedHistoryCount = citytech.ocorrencias.aggregate([
  { $match: { _id: { $in: occurrenceIds } } },
  { $project: { count: { $size: "$history" } } },
  { $group: { _id: null, total: { $sum: "$count" } } }
]).toArray()[0].total;
assertCondition(embeddedHistoryCount === 12, "historico incorporado preserva os 12 registros Oracle");

const aiCounts = Object.fromEntries(citytech.ocorrencias.aggregate([
  { $match: { _id: { $in: occurrenceIds }, aiSuggestion: { $type: "object" } } },
  { $group: { _id: "$aiSuggestion.status", count: { $sum: 1 } } }
]).toArray().map(item => [item._id, item.count]));
assertCondition(
  aiCounts.PRONTA === 1 && aiCounts.ACEITA === 1 && aiCounts.FALHOU === 1,
  "sugestoes de IA coincidem com Oracle: PRONTA=1, ACEITA=1, FALHOU=1"
);

const requiredIndexes = {
  categorias: ["ux_categorias_oracle_id", "ux_categorias_code", "ix_categorias_active_name"],
  ocorrencias: [
    "ux_ocorrencias_oracle_id", "ix_ocorrencias_category_status", "ix_ocorrencias_status_priority",
    "ix_ocorrencias_district", "ix_ocorrencias_created_at", "ix_ocorrencias_ai_status"
  ],
  eventos_triagem: ["ux_eventos_oracle_id", "ix_eventos_occurrence_created_at", "ix_eventos_action_category_created_at"]
};
for (const [collectionName, indexNames] of Object.entries(requiredIndexes)) {
  const actual = new Set(citytech.getCollection(collectionName).getIndexes().map(index => index.name));
  assertCondition(indexNames.every(name => actual.has(name)), `${collectionName} possui todos os indices planejados`);
}

const invalidId = "invalid-validator-probe";
let validationRejected = false;
try {
  citytech.categorias.insertOne({ _id: invalidId });
} catch (error) {
  validationRejected = error.code === 121 || String(error).includes("Document failed validation");
}
if (!validationRejected) citytech.categorias.deleteOne({ _id: invalidId });
assertCondition(validationRejected, "$jsonSchema rejeita documento de categoria invalido");

print(`MongoDB validado com ${assertions} assertions em ${databaseName}.`);
