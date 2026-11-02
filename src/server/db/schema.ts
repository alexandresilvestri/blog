import { pgTable, varchar, timestamp, text } from 'drizzle-orm/pg-core'

export const post = pgTable(
  'post',
  {
    id: varchar('id')
        .$defaultFn(() => crypto.randomUUID())
        .primaryKey(),
    title: varchar('title', { length: 255 }).notNull().unique(),
    body: text('body').notNull(),
    createAt: timestamp('created_at').defaultNow().notNull()
  }
)

