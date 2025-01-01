// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

// eslint-disable-next-line sonarjs/cognitive-complexity
export default function toHaveClasses(
  this: any,
  received: unknown,
  classes: string[],
) {
  if (!received || !(received instanceof HTMLElement)) {
    return {
      message: () => 'received is not an HTMLElement',
      pass: false,
    }
  }

  if (!classes) {
    return {
      message: () => 'no classes passed',
      pass: false,
    }
  }

  let pass = true
  // const errors: string[] = []

  classes.forEach((className) => {
    const localPass = received.classList.contains(className)
    // if (!localPass) {
    //   errors.push(`class ${className} not found`)
    // }
    pass = pass && localPass
  })

  return {
    message: () =>
      `received element ${
        this.isNot ? 'has' : 'does not have'
      } one of the CSS classes: ${classes.join(
        ' ',
      )}\nClass list: ${received.classList.toString()}`,
    pass,
  }
}
