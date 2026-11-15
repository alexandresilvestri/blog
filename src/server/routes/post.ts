import { Elysia, t } from 'elysia'
import { PostController } from '@controller'
import { postSchema } from '@schemas'

const controller = new PostController()

export const postRoutes = new Elysia({ prefix: '/post'})

  .get('/:id', ({ params: { id } } ) => controller.getById(id), {
    params: t.Object({
      id: t.String()
    }),  
    response: postSchema,
    detail: {
      summary: "Get post by ID",
      tags: ['Posts']
    }
  })

  .get('/', () => controller.getAll(), {
    response: t.Array(postSchema),
    detail: {
      summary: "Get all posts",
      tags: ["Posts"]
    }
  })
 
