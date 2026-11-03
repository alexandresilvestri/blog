import { Elysia, t } from 'elysia'
import { PostController } from '@controller'

const controller = new PostController()

export const postRoutes = new Elysia({ prefix: '/post'})

  .get('/:id', ({ params: { id } } ) => controller.getById(id), {
    params: t.Object({
      id: t.String()
    }),  
    response: t.Object({
      id: t.String(),
      title: t.String(),
      body: t.String(),
      createdAt: t.Date()
    }),
    detail: {
      summary: "Get post by ID",
      tags: ['Posts']
    }
  })

  .get('/', () => controller.getAll(), {
    response: t.Array(t.Object({
      id: t.String(),
      title: t.String(),
      body: t.String(),
      createdAt: t.Date()
    })),
    detail: {
      summary: "Get all posts",
      tags: ["Posts"]
    }
  })
 
