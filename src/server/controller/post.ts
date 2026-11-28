import type { Post } from '@schemas'
import { PostModel } from '@models'

const post = new PostModel()

export class PostController {
  async getById(id: string): Promise<Post.Entity> {
    return await post.getById(id)
  }

  async getAll(): Promise<Post.Entity[]> {
    return await post.getAll()
  }

  async create(newPost: Post.Create): Promise<Post.Entity> {
    return await post.create(newPost)
  }
}
