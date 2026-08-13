import { drizzle } from "drizzle-orm/node-postgres";
import { Pool } from "pg";
import * as schema from "./schema/auth";

const globalForDatabase = globalThis as unknown as {
  databasePool: Pool | undefined;
};

const pool =
  globalForDatabase.databasePool ??
  new Pool({
    connectionString:
      process.env.DATABASE_URL ??
      "postgresql://closedai:closedai@127.0.0.1:54329/closedai",
    max: Number(process.env.DATABASE_POOL_MAX ?? 5),
    idleTimeoutMillis: 30_000,
    connectionTimeoutMillis: 10_000,
  });

if (process.env.NODE_ENV !== "production") {
  globalForDatabase.databasePool = pool;
}

export const db = drizzle(pool, { schema });
