---
name: mongodb-patterns
description: MongoDB schema design patterns — validation rules, index-query alignment, embedding vs referencing, connection pooling, and aggregation basics. Use when designing MongoDB collections, indexes, or aggregation pipelines, or reviewing document schema evolution.
license: MIT
---

# MongoDB Patterns

MongoDB's flexibility is the trap: a schema nobody validated drifts into a
shape no index serves. Design the document around the queries, then enforce it
with validation rules. For detailed review, use the `database-reviewer` agent.

## When to Activate

- Designing MongoDB collections or document schemas
- Choosing between embedding and referencing
- Reviewing index coverage for a query pattern
- Setting up schema validation or connection pooling (especially serverless)
- Writing or debugging aggregation pipelines

## Schema Validation Rules

Every production collection carries a JSON Schema validator. Unvalidated
collections accept any shape — the database cannot tell you the app is broken.

```javascript
db.createCollection("orders", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["customerId", "status", "totalCents", "createdAt"],
      properties: {
        customerId:   { bsonType: "string" },
        status:       { enum: ["pending", "shipped", "delivered"] },
        totalCents:   { bsonType: "long" },
        items:        { bsonType: "array", maxItems: 500 },
        createdAt:    { bsonType: "date" }
      }
    }
  },
  validationLevel: "moderate"   // strict on inserts, warn on updates during migration
})
```

Use `validationLevel: "moderate"` when introducing validation to an existing
collection (existing docs pass, new writes enforce), then tighten to `strict`.

## Embedding vs Referencing

| Signal | Choose |
|--------|--------|
| Child data is read with the parent, always | **Embed** |
| Child data is bounded (no unbounded array growth) | **Embed** |
| Child is queried independently / joined across parents | **Reference** |
| Child array could exceed ~1000 elements | **Reference** (or bucket by parent-partition) |
| Child is shared by many parents (e.g. a tag) | **Reference** |

The classic unbounded-array failure: embedding `reviews[]` on a product — a
popular product grows the document past the 16 MB limit and every read pulls
every review. Use the **subset pattern**: embed only the recent N, reference
the rest (`db.reviews.find({ productId }).sort({ createdAt: -1 })`).

## Index–Query Alignment

Every query shape needs a matching index or it collscans.

```javascript
// Query: orders for a customer, newest first
db.orders.find({ customerId: "c_123" }).sort({ createdAt: -1 })
// Required index:
db.orders.createIndex({ customerId: 1, createdAt: -1 })
```

Rules:
- **ESR rule** for compound indexes: Equality fields first, then Sort fields, then Range fields.
- Verify with `explain("executionStats")` — `COLLSCAN` on a production query path is a defect. `IXSCAN` with `totalDocsExamined` far above `nReturned` means the index is not selective enough.
- Multikey indexes (on array fields) cannot be covered and can duplicate index keys — cap array fields at what the query needs.
- TTL index for expiring data: `db.sessions.createIndex({ createdAt: 1 }, { expireAfterSeconds: 86400 })`.
- Text indexes are one per collection — plan search carefully or delegate to Atlas Search.

## Anti-Patterns

- **Unnecessary collections** — one collection per entity is not required; but a collection that holds one document type per record "just in case" (hybrid schemas) defeats validation. Split when the shapes diverge.
- **Unbounded arrays** — see the subset pattern above.
- **Lookup-heavy reads** — a `$lookup` in the hot read path usually means the embed/reference decision was wrong for that access pattern.
- **Unindexed sort** — `.sort()` on a non-indexed field fails past 32 MB of sorted results; always pair sorts with an index.
- **`find()` without projection** — pulling whole documents to use 3 fields wastes IOPS; use explicit projections.
- **Writes without write concern in financial paths** — `w: "majority"` when the write must survive a primary failover.
- **Skipping validation "for speed"** — the drift cost appears months later, not at insert time.

## Connection Pooling and Serverless

- A standalone deployment is one connection per client process; MongoDB Atlas enforces a connection limit — always pool.
- **Serverless (Lambda / Cloud Functions)**: each cold start opens a new connection and the pool dies with the function. Cache the client at module scope (outside the handler) so warm invocations reuse it:

```javascript
let client;
export async function handler(event) {
  client ??= await MongoClient.connect(process.env.MONGODB_URI);
  const db = client.db("app");
  // ...
}
```

- Set `maxPoolSize` deliberately (default 100); serverless functions should use small pools (5–10) to stay under the Atlas total.

## Aggregation Basics

- Pipelines stage in order; put `$match` and `$project` early to shrink the working set before `$lookup`/`$group`.
- `$group` needs memory headroom: 100 MB default, `allowDiskUse: true` beyond that — a sign the pipeline should be pre-aggregated into a summary collection.
- `$merge`/`$out` write results to a collection — the standard way to maintain rollup collections for dashboards.

## References

Adapted (not copied) from publicly documented practices:
- MongoDB Documentation, "Schema Validation" and "Data Model Design" (mongodb.com/docs)
- MongoDB official agent-skills (mongodb-schema-design, antipattern-unnecessary-collections, query-optimizer)
- William Zola, "6 Rules of Thumb for MongoDB Schema Design" (MongoDB blog series)

## Related Skills

- `postgres-patterns` — when the document model is the wrong fit and relational constraints matter
- `database-migrations` — MongoDB "migrations" are backfill scripts + dual writes, not DDL
- `database-reviewer` agent — routes MongoDB reviews to this skill
