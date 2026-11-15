import { t, type Static } from 'elysia'

export const postSchema = t.Object({
  id: t.String(),
  title: t.String(),
  body: t.String(),
  createdAt: t.Date()
})

export type Post = Static<typeof postSchema>

