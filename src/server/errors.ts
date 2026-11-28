export const ErrorCode = {
  UNAUTHORIZED: "UNAUTHORIZED",
  FORBIDDEN: "FORBIDDEN",
  NOT_FOUND: "NOT_FOUND",
  CONFLICT: "CONFLICT",
} as const
export type ErrorCode = (typeof ErrorCode)[keyof typeof ErrorCode]

export const Status = {
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
}
export type Status = (typeof Status)[keyof typeof Status]

export class AppError extends Error {
  readonly code: ErrorCode
  readonly status: Status 

  constructor(
    code: ErrorCode,
    message: string,
  ) {
    super(message)
    this.name = "AppError"
    this.code = code
    this.status = Status[code]
  }
}

