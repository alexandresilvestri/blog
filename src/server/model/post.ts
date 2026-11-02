import type { UUID, post } from '@types'

export class Post {
  id?: UUID
  title: string
  body: string
  createdAt?: Date

  constructor(post: post) {
    this.id = post.id
    this.title = post.title
    this.body = post.body
    this.createdAt = post.createdAt
  }

  create(post: post): post { 

  }

  getAll(): post[] {

  }

  getById(id: UUID): post {

  }
}
