import type { Post as postSchema } from '@schemas'
import { Post } from '@models'

const post = new Post()

export class PostController {
  async getById(id: string): Promise<postSchema> {
    return await post.getById(id)
  }

  async getAll(): Promise<postSchema[]> {
    return await post.getAll()
  }

}
