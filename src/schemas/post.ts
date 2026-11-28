import { t, type Static } from 'elysia'

const post = t.Object({
  id: t.String(),
  title: t.String(),
  body: t.String(),
  createdAt: t.Date()
})

export const Post = {
  Entity: post,
  Create: t.Omit(post, ['id', 'createdAt'])
}

export namespace Post {
  export type Entity = Static<typeof Post.Entity>
  export type Create = Static<typeof Post.Create>
}



