import { Elysia, t } from 'elysia'
import { PostController } from '../controller/post'

const controller = new PostController()

export const postRoutes = new Elysia({ prefix: '/post'})
  .get('/', () => controller.getAll(), {
    detail: {
      summary: 'Buscar todos os posts',
      tags: ['Posts']
    }
  })
  
  .get('/:id', ({ params: { id } } ) => controller.getById(id), {
    params: t.Object({
      id: t.String()
    }),
    detail: {
      summary: "Busca post por ID",
      tags: ['Posts']
    }
  })
