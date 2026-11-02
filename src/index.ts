import { Elysia } from 'elysia'
import { openapi } from '@elysia/openapi'
import index from './index.html'

new Elysia()
  .use(openapi())
  .listen(3000)

