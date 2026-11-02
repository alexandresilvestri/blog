import type { UUID, post } from '@types'
import { db } from '@db'

export class Post {
  async getById(id: UUID): Promise<post > {
      const requestedPost = await db.query.postSchema.findFirst({
      where: (table, { eq }) => eq(table.id, id)
      })

      if (requestedPost) {
        return requestedPost
      } else {
        throw new Error('Post not found')
      }
  }
}
