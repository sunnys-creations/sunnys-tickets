// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { onTestFailed } from 'vitest'

const logs: unknown[][] = []

afterEach(() => {
  logs.length = 0
})

const logger = {
  log(...mesages: unknown[]) {
    if (process.env.VITEST_LOG_GQL_FACTORY) {
      console.log(...mesages)
    } else {
      logs.push(mesages)
    }
  },
  printMockerLog() {
    logs.forEach((log) => {
      console.log(...log)
    })
  },
}

beforeEach(() => {
  onTestFailed(() => {
    logger.printMockerLog()
  })
})

export default logger
