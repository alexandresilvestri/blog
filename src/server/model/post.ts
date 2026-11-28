import type { Post } from '@schemas'
import { posts } from '@schemadb'
import { db } from '@db'

export class PostModel {
  async getById(id: string): Promise<Post.Entity> {
      const requestedPost = await db.query.posts.findFirst({
      where: (table, { eq }) => eq(table.id, id)
      })

      if (requestedPost) {
        return requestedPost
      } else {
        throw new Error('Post not found')
      }

  }

  async getAll(): Promise<Post.Entity[]> {
    return await db.query.posts.findMany()
  }

  async create(post: Post.Create): Promise<Post.Entity> {
    const [created] = await
      db.insert(posts)
        .values(post).onConflictDoNothing({ target: posts.title }).returning()
    if (!created) throw new Error('Failed to create post')

    return created
  }
}
