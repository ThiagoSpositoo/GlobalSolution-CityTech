const databaseName = process.env.MONGODB_DATABASE || "citytech_demo";
const citytech = db.getSiblingDB(databaseName);

function show(title, cursor) {
  print(`\n=== ${title} ===`);
  cursor.forEach(document => print(EJSON.stringify(document, null, 2, { relaxed: true })));
}

show(
  "Consulta 1 - find: ocorrencias de iluminacao em aberto",
  citytech.ocorrencias.find(
    { "category.code": "ILUMINACAO", status: { $nin: ["ENCERRADA", "CANCELADA"] } },
    { _id: 0, oracleId: 1, title: 1, status: 1, priority: 1, "address.district": 1 }
  ).sort({ createdAt: -1 })
);

show(
  "Consulta 2 - find: fila critica ou alta",
  citytech.ocorrencias.find(
    {
      status: { $nin: ["ENCERRADA", "CANCELADA"] },
      priority: { $in: ["CRITICA", "ALTA"] }
    },
    { _id: 0, title: 1, "category.code": 1, priority: 1, status: 1, "address.district": 1 }
  ).sort({ priority: 1, createdAt: 1 })
);

show(
  "Agregacao 1 - ocorrencias por categoria (comparavel ao Oracle)",
  citytech.ocorrencias.aggregate([
    { $group: { _id: { code: "$category.code", name: "$category.name" }, occurrenceCount: { $sum: 1 } } },
    { $project: { _id: 0, categoryCode: "$_id.code", categoryName: "$_id.name", occurrenceCount: 1 } },
    { $sort: { categoryCode: 1 } }
  ])
);

show(
  "Agregacao 2 - fila nao terminal por prioridade (comparavel ao Oracle)",
  citytech.ocorrencias.aggregate([
    { $match: { status: { $nin: ["ENCERRADA", "CANCELADA"] } } },
    { $group: { _id: "$priority", occurrenceCount: { $sum: 1 } } },
    { $addFields: { order: { $indexOfArray: [["CRITICA", "ALTA", "MEDIA", "BAIXA"], "$_id"] } } },
    { $project: { _id: 0, priority: "$_id", occurrenceCount: 1, order: 1 } },
    { $sort: { order: 1 } },
    { $unset: "order" }
  ])
);

show(
  "Agregacao 3 - categoria e status (comparavel ao Oracle)",
  citytech.ocorrencias.aggregate([
    { $group: { _id: { categoryCode: "$category.code", status: "$status" }, occurrenceCount: { $sum: 1 } } },
    { $project: { _id: 0, categoryCode: "$_id.categoryCode", status: "$_id.status", occurrenceCount: 1 } },
    { $sort: { categoryCode: 1, status: 1 } }
  ])
);

show(
  "Agregacao 4 - distribuicao por bairro e status",
  citytech.ocorrencias.aggregate([
    { $group: { _id: { district: "$address.district", status: "$status" }, occurrenceCount: { $sum: 1 } } },
    { $project: { _id: 0, district: "$_id.district", status: "$_id.status", occurrenceCount: 1 } },
    { $sort: { district: 1, status: 1 } }
  ])
);

show(
  "Agregacao 5 - situacao das sugestoes de IA",
  citytech.ocorrencias.aggregate([
    { $match: { aiSuggestion: { $type: "object" } } },
    {
      $group: {
        _id: "$aiSuggestion.status",
        suggestionCount: { $sum: 1 },
        categories: { $addToSet: "$category.code" },
        errorCodes: { $addToSet: "$aiSuggestion.errorCode" }
      }
    },
    { $project: { _id: 0, aiStatus: "$_id", suggestionCount: 1, categories: 1, errorCodes: 1 } },
    { $sort: { aiStatus: 1 } }
  ])
);

show(
  "Agregacao 6 - eventos operacionais por acao e papel",
  citytech.eventos_triagem.aggregate([
    { $group: { _id: { action: "$action", actorRole: "$actorRole" }, eventCount: { $sum: 1 } } },
    { $project: { _id: 0, action: "$_id.action", actorRole: "$_id.actorRole", eventCount: 1 } },
    { $sort: { action: 1, actorRole: 1 } }
  ])
);
