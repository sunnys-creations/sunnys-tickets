// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import channelIconsMap from './channelIconsMap.json'

export const getArticleChannelIcon = (
  articleType: string,
): string | undefined => {
  const typeGroup = articleType.split(' ')[0]
  return (channelIconsMap as Record<string, string>)[typeGroup]
}
