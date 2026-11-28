import { Elysia, t } from 'elysia'
import { PostController } from '@controller'
import { Post } from '@schemas'

const controller = new PostController()

export const postRoutes = new Elysia({ prefix: '/posts'})

  .get('/:id', ({ params: { id } } ) => controller.getById(id), {
    params: t.Object({
      id: t.String()
    }),  
    response: Post.Entity,
    detail: {
      summary: "Get post by ID",
      tags: ['Posts']
    }
  })

  .get('/', () => controller.getAll(), {
    response: t.Array(Post.Entity),
    detail: {
      summary: "Get all posts",
      tags: ["Posts"]
    }
  })

  .post('/', ({ body }) => controller.create(body), {
    body: Post.Create,
    response: Post.Entity,
    detail: {
      summary: "Create post",
      tags: ["Posts"]
    }
  })
 
