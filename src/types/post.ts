import type { UUID } from './index'

export type post = {
  id?: UUID,
  title: string,
  body: string,
  createdAt?: Date,
}
