// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

type TableColumnType = 'timestamp' | 'timestamp_absolute'

export interface TableHeader<K = string> {
  key: K
  label: string
  labelPlaceholder?: string[]
  columnClass?: string
  columnSeparator?: boolean
  alignContent?: 'center' | 'right'
  type?: TableColumnType
  truncate?: boolean
  [key: string]: unknown
}
export interface TableItem {
  [key: string]: unknown
  id: string | number
}
