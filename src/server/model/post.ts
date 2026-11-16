import type { Post as post } from '@schemas'
import { db } from '@db'

export class Post {
  async getById(id: string): Promise<post> {
      const requestedPost = await db.query.posts.findFirst({
      where: (table, { eq }) => eq(table.id, id)
      })

      if (requestedPost) {
        return requestedPost
      } else {
        throw new Error('Post not found')
      }

  }
  async getAll(): Promise<post[]> {
    return await db.query.posts.findMany()
  }
}
