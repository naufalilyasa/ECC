---
name: dynamodb-patterns
description: DynamoDB single-table design patterns — access-pattern-first key design (PK/SK, item collections), GSI overloading, hot-partition avoidance, and anti-patterns (Scan, unbounded growth). Use when designing DynamoDB tables, keys, or GSIs, or reviewing DynamoDB data models.
license: MIT
---

# DynamoDB Patterns

DynamoDB is not a relational database with different syntax — it is a key-value
store where **the schema follows the access pattern, not the entity**. Design
backwards from the queries the application will run. For detailed review, use
the `database-reviewer` agent.

## When to Activate

- Designing a DynamoDB table, key schema, or item layout
- Adding a GSI or deciding GSI vs LSI
- Reviewing a DynamoDB data model for hot partitions or Scan usage
- Choosing between single-table and multi-table designs
- Modeling item collections (parent + children in one table)

## Access-Pattern-First Design

Before writing a single key definition, enumerate the access patterns:

| # | Access Pattern | Table | Key Condition |
|---|----------------|-------|---------------|
| 1 | Fetch one user by ID | Main | PK = `USER#<id>` |
| 2 | User's orders newest first | Main | PK = `USER#<id>`, SK begins_with `ORDER#` |
| 3 | Orders by status (dashboard) | GSI1 | GSI1PK = `ORDER#<status>`, SK = `ORDER#<date>` |

If an access pattern cannot be expressed as a `Query` (exact PK, optional SK
condition), it does not belong in DynamoDB — a `Scan` per request is a design
failure, not a workaround.

## Key Design

### PK / SK Composition

```python
# Single-table convention: entity type prefix + ID
# Main table
PK = "USER#u_123"          # partition key
SK = "PROFILE"             # sort key (item collection root)
PK = "USER#u_123"
SK = "ORDER#2024-01-15#o_456"   # child item in the USER#u_123 collection

# GSI1 overloading — same table serves multiple entity queries
GSI1PK = "ORDER#PENDING"
GSI1SK = "2024-01-15#o_456"
```

**Rules:**
- Prefix entity type (`USER#`, `ORDER#`) to prevent type collisions in a shared table
- Zero-pad or use ISO-8601 dates so lexicographic SK order equals chronological order
- Never store the full sort-key path in an attribute you also query separately — duplication is fine, JOINs are impossible

### Item Collections

An item collection is all items sharing the same PK. Keep collections bounded:
a PK with unbounded growth (every event for a user, forever) hits the 10 GB
per-partition limit and throttles writes. Mitigate with time-bucketed keys:

```python
PK = "USER#u_123#2024-01"    # monthly bucket
SK = "ORDER#2024-01-15#o_456"
```

Trade-off: bucketing adds a bucket-selection step to reads.

### GSI vs LSI Decision

| Question | Answer |
|----------|--------|
| Need a different sort order on the same table? | **LSI** (same PK, alternate SK; must be created at table creation; shares table WCU) |
| Need to query by a different partition key? | **GSI** (own PK/SK; can be added later; own WCU/RCU) |
| Query is sparse (few items match)? | GSI with a small projected attribute set |

**GSI overloading** — one GSI serving multiple access patterns by encoding
the query intent in the GSI PK (`ORDER#PENDING`, `ORDER#SHIPPED`) — is the
core single-table technique. Cap the number of overloaded patterns per GSI
(5 is a practical ceiling) before adding GSI2.

## Hot-Partition Avoidance

A hot partition throttles the whole table. Detection: CloudWatch
`ThrottledRequests` spikes on one PK.

| Cause | Fix |
|-------|-----|
| Celebrity item (viral post, top account) | Write sharding: append a random suffix `PK = ITEM#<id>#<shard 0-9>`; scatter-read and merge |
| Time-series burst (all writes at :00 seconds) | Add jitter to the SK timestamp, or bucket by minute |
| Sequential scan of keys | Never design a workflow that enumerates the keyspace |

Sharding cost: reads must query every shard (or keep a shard-map item). Only
shard when measured — cardinality above ~1000 distinct PK values/sec rarely
needs it.

## Anti-Patterns

- **Scan as an access pattern** — `Scan` reads the entire table. If a query runs more than once per minute and uses `Scan`, the model is wrong. (Exception: rare admin/analytics jobs on a small table.)
- **Unbounded item collections** — see bucketing above.
- **LSI created late** — LSIs are immutable at table creation. If you might need an alternate sort order later, design the SK to be overloadable instead.
- **Storing relational JOINs** — there are none. Duplicate the attributes each access pattern needs.
- **Big blobs in items** — 400 KB item limit; large binaries belong in S3 with the key stored in DynamoDB.
- **No TTL on ephemeral data** — sessions, caches, and rate-limit buckets without `ttl` accumulate forever.
- **Overloading one GSI past ~5 patterns** — the sparse-index benefit collapses and the GSI write cost grows.
- **`UpdateItem` with a full-document `SET`** — use targeted `SET attr = :val` updates; full-document rewrites on concurrent writers lose updates.

## Capacity and Cost

- **On-demand vs provisioned**: on-demand for unpredictable/spiky traffic; provisioned + autoscaling for steady baselines. Never run sustained provisioned at 100% utilization.
- **Eventually consistent reads** are half the RCU of strongly consistent reads — use them unless the read-after-write guarantee is required.
- **Project only needed attributes** (`.ProjectionExpression` or sparse GSI projection) — RCU scales with item size, not attribute count read.
- **WCU = ceil(item_size/1KB) × items/second`**; a 5 KB item costs 5 WCU per write. Keep items lean.
- Batch APIs (`BatchGetItem`, `BatchWriteItem`) are capped at 100 items / 16 MB and do NOT provide transactions — use `TransactWriteItems` for atomic multi-item writes (max 100 items).

## References

Adapted (not copied) from publicly documented practices:
- Alex DeBrie, *The DynamoDB Book* (dynobase.dev/dynamodb-book) — single-table design, item collections, GSI overloading, hot-partition sharding
- AWS Documentation, "Global Secondary Indexes" (docs.aws.amazon.com/amazondynamodb/latest/developerguide/GSI.html)
- hidekazu-konishi (aws-samples) — single-table key-design dictionary

## Related Skills

- `redis-patterns` — the other key-value store in this repo
- `database-migrations` — DynamoDB changes are application-level (no DDL); for schema evolution use new tables + dual writes, not `UpdateTable`
- `database-reviewer` agent — routes DynamoDB reviews to this skill
