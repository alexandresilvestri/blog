import { Elysia } from 'elysia'
import { postRoutes } from './post'

export const routes = new Elysia()
  .use(postRoutes)
