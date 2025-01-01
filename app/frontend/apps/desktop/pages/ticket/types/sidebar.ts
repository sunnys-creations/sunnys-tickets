// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { FormRef, FormValues } from '#shared/components/Form/types.ts'

import type { TicketSidebarPlugin } from '../components/TicketSidebar/plugins/types.ts'
import type { Ref } from 'vue'

export enum TicketSidebarScreenType {
  TicketCreate = 'ticket-create',
  TicketDetailView = 'ticket-detail-view',
}

export interface TicketSidebarContext {
  screenType: TicketSidebarScreenType
  form?: FormRef
  formValues: FormValues
}

export enum TicketSidebarButtonBadgeType {
  Info = 'info',
  Warning = 'warning',
  Danger = 'danger',
}

export type TicketSidebarButtonBadgeDetails = {
  label: string
  type?: TicketSidebarButtonBadgeType
  value: string | number
}

export interface TicketSidebarContentProps {
  context: TicketSidebarContext
  sidebarPlugin: TicketSidebarPlugin
}

export interface TicketSidebarProps extends TicketSidebarContentProps {
  sidebar: string
  selected?: boolean
}

export interface TicketSidebarWrapperProps
  extends Omit<TicketSidebarProps, 'context'> {
  badge?: TicketSidebarButtonBadgeDetails
  updateIndicator?: boolean
}

export type TicketSidebarEmits = {
  show: []
  hide: []
}

export interface TicketSidebarInformation {
  shownSidebars: Ref<Record<string, boolean>>
  activeSidebar: Ref<string | null>
  availableSidebarPlugins: Ref<Record<string, TicketSidebarPlugin>>
  sidebarPlugins: Record<string, TicketSidebarPlugin>
  hasSidebar: Ref<boolean>
  showSidebar: (sidebar: string) => void
  hideSidebar: (sidebar: string) => void
  switchSidebar: (newSidebar: string) => void
}
