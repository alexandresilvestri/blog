import './server/instrument'
import { Elysia } from 'elysia'
import { openapi } from '@elysia/openapi'
import { routes } from './server/routes'
import index from '../client/index.html'

new Elysia()
  .use(openapi())
  .use(routes)
  .listen(3000)

