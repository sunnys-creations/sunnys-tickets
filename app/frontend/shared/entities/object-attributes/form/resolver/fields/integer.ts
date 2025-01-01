// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '#shared/entities/object-attributes/types/resolver.ts'

import FieldResolver from '../FieldResolver.ts'

export class FieldResolverInteger extends FieldResolver {
  fieldType = 'number'

  public fieldTypeAttributes() {
    return {
      props: {
        min: this.attributeConfig.min,
        max: this.attributeConfig.max,
      },
    }
  }
}

export default <FieldResolverModule>{
  type: 'integer',
  resolver: FieldResolverInteger,
}
