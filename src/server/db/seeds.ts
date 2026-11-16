import { db } from './index'
import { posts } from '@schemadb'

const POSTS = [
  { title: 'Hello world', body: 'First post on the blog.' },
  { title: 'Learning Drizzle', body: 'Migrations, push, and seeds.' },
]

await db.insert(posts).values(POSTS).onConflictDoNothing({ target: posts.title }) 
await db.$client.end()

