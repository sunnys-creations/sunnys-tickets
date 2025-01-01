// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

// To update snapshots, run `pnpm cypress:snapshots`
// DO NOT update snapshots, when running with --open flag (Cypress GUI)

import { mountFormField, checkFormMatchesSnapshot } from '#cy/utils.ts'

import { FormValidationVisibility } from '#shared/components/Form/types.ts'

describe('testing visuals for "FieldInput"', () => {
  const inputs = [
    { type: 'text', input: 'Some Text' },
    { type: 'email', input: 'some@mail.com' },
    { type: 'number', input: '100' },
    { type: 'tel', input: '123456789' },
    { type: 'time', input: '12:12' },
  ]

  inputs.forEach(({ type, input }) => {
    it(`renders usual ${type}`, () => {
      mountFormField(type, { label: type })
      checkFormMatchesSnapshot({ type })
      cy.get('input')
        .focus()
        .then(() => {
          checkFormMatchesSnapshot({ subTitle: 'focused', type })
        })
      cy.get('input')
        .type(input)
        .then(() => {
          checkFormMatchesSnapshot({ subTitle: 'filled', type })
        })
    })

    it(`renders required ${type}`, () => {
      mountFormField(type, { label: type, required: true })
      checkFormMatchesSnapshot({ type })
      cy.get('input')
        .focus()
        .then(() => {
          checkFormMatchesSnapshot({ subTitle: 'focused', type })
        })
      cy.get('input')
        .type(input)
        .then(() => {
          checkFormMatchesSnapshot({ subTitle: 'filled', type })
        })
    })

    it(`renders invalid ${type}`, () => {
      mountFormField(type, {
        label: type,
        required: true,
        validationVisibility: FormValidationVisibility.Live,
      })
      checkFormMatchesSnapshot({ type })
    })

    it(`renders ${type} with help`, () => {
      mountFormField(type, {
        label: type,
        help: 'Help message!',
      })
      checkFormMatchesSnapshot({ type })
    })

    it(`renders linked ${type}`, () => {
      mountFormField(type, { label: type, link: '/' })
      checkFormMatchesSnapshot({ type })
      cy.get('input')
        .focus()
        .then(() => {
          checkFormMatchesSnapshot({ subTitle: 'focused', type })
        })
      cy.get('input')
        .type(input)
        .then(() => {
          checkFormMatchesSnapshot({ subTitle: 'filled', type })
        })
    })

    it(`renders disabled ${type}`, () => {
      mountFormField(type, { label: type, disabled: true })
      checkFormMatchesSnapshot({ type })
    })

    it(`renders hidden ${type}`, () => {
      mountFormField(type, { label: type, labelSrOnly: true })
      checkFormMatchesSnapshot({ type })
      cy.get('input')
        .type(input)
        .then(() => {
          checkFormMatchesSnapshot({ subTitle: 'filled', type })
        })
    })
  })
})
