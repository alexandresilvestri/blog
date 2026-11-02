import type { UUID, post } from '@types'
import { Post } from '@models'

const post = new Post()

export class PostController {
  async getById(id: UUID): Promise<post> {
    return await post.getById(id)
  }
}
