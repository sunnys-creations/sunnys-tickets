// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { FormFieldAdditionalProps } from '#shared/components/Form/types.ts'
import type { FieldResolverModule } from '#shared/entities/object-attributes/types/resolver.ts'

import FieldResolver from '../FieldResolver.ts'

export class FieldResolverInput extends FieldResolver {
  fieldType = () => {
    switch (this.attributeConfig.type) {
      case 'password':
        return 'password'
      case 'tel':
        return 'tel'
      case 'email':
        return 'email'
      case 'url':
        return 'url'
      default:
        return 'text'
    }
  }

  public fieldTypeAttributes() {
    const props: FormFieldAdditionalProps = {
      maxlength: this.attributeConfig.maxlength,
    }

    const valiadtion = this.validation()
    if (valiadtion) {
      props.validation = valiadtion
    }

    return {
      props,
    }
  }

  private validation() {
    switch (this.attributeConfig.type) {
      case 'email':
        return 'email'
      case 'url':
        return 'url'
      default:
        return null
    }
  }
}

export default <FieldResolverModule>{
  type: 'input',
  resolver: FieldResolverInput,
}
