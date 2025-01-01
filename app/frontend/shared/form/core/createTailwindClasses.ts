// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { generateClasses } from '@formkit/themes'
import { extend } from '@formkit/utils'

import type {
  FormAppSpecificTheme,
  FormThemeClasses,
  FormThemeExtension,
} from '#shared/types/form.ts'
import type {
  ImportGlobEagerOutput,
  ImportGlobEagerDefault,
} from '#shared/types/utils.ts'

import commonClasses from '../theme/global/index.ts'

const extensionsModules: ImportGlobEagerOutput<FormThemeExtension> =
  import.meta.glob('../theme/global/extensions/*.ts', { eager: true })

const getExtensionsFromModules = (
  extensionsModules: ImportGlobEagerOutput<FormThemeExtension>,
) => {
  const extensions: FormThemeExtension[] = []

  Object.values(extensionsModules).forEach(
    (module: ImportGlobEagerDefault<FormThemeExtension>) => {
      const extension = module.default

      extensions.push(extension)
    },
  )

  return extensions
}
const createTailwindClasses = (additionalTheme: FormAppSpecificTheme = {}) => {
  const themeExtensions: FormThemeExtension[] = [
    ...getExtensionsFromModules(extensionsModules),
  ]

  if (additionalTheme.coreClasses) {
    themeExtensions.push(additionalTheme.coreClasses)
  }

  if (additionalTheme.extensions) {
    themeExtensions.push(
      ...getExtensionsFromModules(additionalTheme.extensions),
    )
  }

  let classes = commonClasses

  themeExtensions.forEach((extension) => {
    const newClasses = extension(classes)
    classes = extend(classes, newClasses) as FormThemeClasses
  })

  return generateClasses(classes)
}

export default createTailwindClasses
