import './server/instrument'
import { Elysia } from 'elysia'
import { openapi } from '@elysia/openapi'
import index from '../client/index.html'

new Elysia()
  .use(openapi())
  .listen(3000)

