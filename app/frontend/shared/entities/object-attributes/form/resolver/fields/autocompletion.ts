// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '#shared/entities/object-attributes/types/resolver.ts'
import { camelize } from '#shared/utils/formatter.ts'

import FieldResolver from '../FieldResolver.ts'

export class FieldResolverAutocompletion extends FieldResolver {
  fieldType = () => {
    switch (this.attributeConfig.relation) {
      case 'Organization':
        return 'organization'
      case 'User':
        return 'customer'
      case 'Group':
      case 'TicketState':
      case 'TicketPriority':
        throw new Error(
          `Relation ${this.attributeConfig.relation} is not implemented yet`,
        )
      // TODO which relation is recipient?
      default:
        throw new Error(`Unknown relation ${this.attributeConfig.relation}`)
    }
  }

  public fieldTypeAttributes() {
    return {
      props: {
        clearable: !!this.attributeConfig.nulloption,
        noOptionsLabelTranslation: !this.attributeConfig.translate,
        belongsToObjectField: camelize(
          (this.attributeConfig.belongs_to as string) || '',
        ),
        multiple: this.attributeConfig.multiple,
      },
    }
  }
}

export default <FieldResolverModule>{
  type: 'autocompletion_ajax',
  resolver: FieldResolverAutocompletion,
}
