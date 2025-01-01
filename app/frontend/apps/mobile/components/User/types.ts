// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

export interface UserItemData {
  id: string
  firstname?: Maybe<string>
  lastname?: Maybe<string>
  image?: Maybe<string>
  ticketsCount?: {
    open: number
    closed: number
  }
  organization?: {
    name: string
  }
  updatedAt?: string
  updatedBy?: {
    id: string
    fullname?: Maybe<string>
  }
}
