// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { setupView } from '#tests/support/mock-user.ts'

import { EnumTicketArticleSenderName } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  createTicketArticle,
  createTestArticleActions,
  createTestArticleTypes,
  createTicket,
} from './utils.ts'

const createAgentUpdatableTicket = () => {
  return createTicket({
    policy: { update: true, agentReadAccess: true },
  })
}

const createEmailTicketArticle = () => {
  return createTicketArticle({
    type: { name: 'email' },
    attachmentsWithoutInline: [
      {
        id: convertToGraphQLId('Store', 123),
        preferences: {
          'original-format': true,
        },
        internalId: 123,
        name: 'test.txt',
      },
    ],
  })
}

describe('email permissions', () => {
  const types = ['email-reply', 'email-all', 'email-forward']

  it.each(['email-reply', 'email-forward'])(
    '%s reply is available for agent and email article',
    (type) => {
      setupView('agent')
      const ticket = createAgentUpdatableTicket()
      const article = createTicketArticle()
      article.type = {
        __typename: 'TicketArticleType',
        name: 'email',
      }
      const actions = createTestArticleActions(ticket, article)
      expect(
        actions.find((action) => action.name === type),
        `${type} is defined`,
      ).toBeDefined()
    },
  )

  it.each(['email-reply', 'email-forward'])(
    '%s reply is available for agent and phone article sent by Customer',
    (type) => {
      setupView('agent')
      const ticket = createAgentUpdatableTicket()
      const article = createTicketArticle()
      article.type = {
        __typename: 'TicketArticleType',
        name: 'phone',
      }
      article.sender = {
        __typename: 'TicketArticleSender',
        name: EnumTicketArticleSenderName.Customer,
      }
      const actions = createTestArticleActions(ticket, article)
      expect(actions.find((action) => action.name === type)).toBeDefined()
    },
  )

  it.each(['email-reply', 'email-forward'])(
    '%s reply is available for agent and phone article sent by Agent',
    (type) => {
      setupView('agent')
      const ticket = createAgentUpdatableTicket()
      const article = createTicketArticle()
      article.type = {
        __typename: 'TicketArticleType',
        name: 'phone',
      }
      article.sender = {
        __typename: 'TicketArticleSender',
        name: EnumTicketArticleSenderName.Agent,
      }
      const actions = createTestArticleActions(ticket, article)
      expect(actions.find((action) => action.name === type)).toBeDefined()
    },
  )

  describe('reply-all action', () => {
    const setupAction = () => {
      setupView('agent')
      const ticket = createAgentUpdatableTicket()
      const article = createTicketArticle()
      article.type = {
        __typename: 'TicketArticleType',
        name: 'email',
      }
      article.sender = {
        __typename: 'TicketArticleSender',
        name: EnumTicketArticleSenderName.Agent,
      }
      return {
        ticket,
        article,
      }
    }

    it('reply-all action is available for agent with email article and multiple unique emails', () => {
      const { ticket, article } = setupAction()
      article.to = {
        raw: '',
        parsed: [
          { emailAddress: 'zammad1@example.com', isSystemAddress: false },
        ],
      }
      article.cc = {
        raw: '',
        parsed: [
          { emailAddress: 'zammad2@example.com', isSystemAddress: false },
        ],
      }
      const actions = createTestArticleActions(ticket, article)
      expect(
        actions.find((action) => action.name === 'email-reply-all'),
      ).toBeDefined()
    })

    it('reply-all action is not available for agent with email article and multiple non-unique emails', () => {
      const { ticket, article } = setupAction()
      article.to = {
        raw: '',
        parsed: [
          { emailAddress: 'zammad1@example.com', isSystemAddress: false },
        ],
      }
      article.cc = {
        raw: '',
        parsed: [
          { emailAddress: 'zammad1@example.com', isSystemAddress: false },
        ],
      }
      const actions = createTestArticleActions(ticket, article)
      expect(
        actions.find((action) => action.name === 'email-reply-all'),
      ).toBeUndefined()
    })

    it('reply-all action is available for agent with email article from customer and multiple unique emails', () => {
      const { ticket, article } = setupAction()
      article.sender = {
        __typename: 'TicketArticleSender',
        name: EnumTicketArticleSenderName.Customer,
      }
      article.to = {
        raw: '',
        parsed: [
          { emailAddress: 'zammad1@example.com', isSystemAddress: false },
        ],
      }
      article.from = {
        raw: '',
        parsed: [
          { emailAddress: 'zammad2@example.com', isSystemAddress: false },
        ],
      }
      const actions = createTestArticleActions(ticket, article)
      expect(
        actions.find((action) => action.name === 'email-reply-all'),
      ).toBeDefined()
    })

    it('reply-all action is not available for agent with email article from agent and multiple unique emails', () => {
      const { ticket, article } = setupAction()
      article.sender = {
        __typename: 'TicketArticleSender',
        name: EnumTicketArticleSenderName.Agent,
      }
      article.to = {
        raw: 'zammad1@example.com',
        parsed: [
          { emailAddress: 'zammad1@example.com', isSystemAddress: false },
        ],
      }
      article.from = {
        raw: 'zammad2@example.com',
        parsed: [
          { emailAddress: 'zammad2@example.com', isSystemAddress: false },
        ],
      }
      article.cc = null
      article.replyTo = null
      const actions = createTestArticleActions(ticket, article)
      expect(
        actions.find((action) => action.name === 'email-reply-all'),
      ).toBeUndefined()
    })

    it('reply-all action is not available for agent with multiple non-unique system addresses', () => {
      const { ticket, article } = setupAction()
      article.sender = {
        __typename: 'TicketArticleSender',
        name: EnumTicketArticleSenderName.Agent,
      }
      article.to = {
        raw: '',
        parsed: [
          { emailAddress: 'zammad1@example.com', isSystemAddress: false },
        ],
      }
      article.cc = {
        raw: '',
        parsed: [
          { emailAddress: 'zammad2@example.com', isSystemAddress: true },
        ],
      }
      const actions = createTestArticleActions(ticket, article)
      expect(
        actions.find((action) => action.name === 'email-reply-all'),
      ).toBeUndefined()
    })

    it('reply-all action is available for agent with multiple unique addresses inside to', () => {
      const { ticket, article } = setupAction()
      article.sender = {
        __typename: 'TicketArticleSender',
        name: EnumTicketArticleSenderName.Agent,
      }
      article.to = {
        raw: '',
        parsed: [
          { emailAddress: 'zammad1@example.com', isSystemAddress: false },
          { emailAddress: 'zammad2@example.com', isSystemAddress: false },
        ],
      }
      const actions = createTestArticleActions(ticket, article)
      expect(
        actions.find((action) => action.name === 'email-reply-all'),
      ).toBeDefined()
    })
  })

  it.each(types)(`%s action is not available for customer`, (type) => {
    setupView('customer')
    const ticket = createTicket({
      policy: { update: true, agentReadAccess: false },
    })
    const article = createTicketArticle()
    ticket.policy.update = true
    ticket.policy.agentReadAccess = false
    const actions = createTestArticleActions(ticket, article)
    expect(actions.find((action) => action.name === type)).toBeUndefined()
  })

  it.each(types)(
    `%s action is not available for agent without change permissions`,
    (type) => {
      setupView('agent')
      const ticket = createTicket({ policy: { update: false } })
      const article = createTicketArticle()
      const actions = createTestArticleActions(ticket, article)
      expect(actions.find((action) => action.name === type)).toBeUndefined()
    },
  )

  it.each(types)(
    `%s action is not available if there is no email address in the ticket group`,
    (type) => {
      setupView('agent')
      const ticket = createAgentUpdatableTicket()
      const article = createTicketArticle()
      ticket.group.emailAddress = null
      article.type = {
        __typename: 'TicketArticleType',
        name: 'email',
      }
      const actions = createTestArticleActions(ticket, article)
      expect(actions.find((action) => action.name === type)).toBeUndefined()
    },
  )

  it('email type is available for agent with change permissions', () => {
    setupView('agent')
    const ticket = createAgentUpdatableTicket()
    const types = createTestArticleTypes(ticket)
    expect(types.find((type) => type.value === 'email')).toBeDefined()
  })
  it('email type is not available for customer', () => {
    setupView('customer')
    const ticket = createTicket({
      policy: { update: true, agentReadAccess: false },
    })
    const types = createTestArticleTypes(ticket)
    expect(types.find((type) => type.value === 'email')).toBeUndefined()
  })
  it('email type is not available for agent without change permissions', () => {
    setupView('agent')
    const ticket = createTicket({ policy: { update: false } })
    const types = createTestArticleTypes(ticket)
    expect(types.find((type) => type.value === 'email')).toBeUndefined()
  })

  it('email type is not available if there is no email address in the ticket group', () => {
    setupView('agent')
    const ticket = createTicket({ policy: { update: true } })
    ticket.group.emailAddress = null
    const types = createTestArticleTypes(ticket)
    expect(types.find((type) => type.value === 'email')).toBeUndefined()
  })

  describe.each(['email-download-original-email', 'email-download-raw-email'])(
    '%s action',
    (type) => {
      it('available for agent on desktop', () => {
        setupView('agent')
        const ticket = createTicket({ policy: { update: true } })
        const article = createEmailTicketArticle()
        const actions = createTestArticleActions(ticket, article, 'desktop')

        expect(actions).toEqual(
          expect.arrayContaining([expect.objectContaining({ name: type })]),
        )
      })

      it('not available for agent on desktop if article is not email', () => {
        setupView('agent')
        const ticket = createTicket({ policy: { update: true } })
        const article = createTicketArticle({ type: { name: 'phone' } })
        const actions = createTestArticleActions(ticket, article, 'desktop')

        expect(actions).toEqual(
          expect.not.arrayContaining([expect.objectContaining({ name: type })]),
        )
      })

      it('not available for customer', () => {
        setupView('customer')
        const ticket = createTicket({ policy: { update: true } })
        const article = createEmailTicketArticle()
        const actions = createTestArticleActions(ticket, article, 'desktop')

        expect(actions).toEqual(
          expect.not.arrayContaining([expect.objectContaining({ name: type })]),
        )
      })

      it('not available for agent on mobile', () => {
        setupView('agent')
        const ticket = createTicket({ policy: { update: true } })
        const article = createEmailTicketArticle()
        const actions = createTestArticleActions(ticket, article, 'mobile')

        expect(actions).toEqual(
          expect.not.arrayContaining([expect.objectContaining({ name: type })]),
        )
      })
    },
  )
})
