# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class BackgroundServices
  class Service
    class ProcessScheduledJobs
      class RetryLimitReachedError < StandardError
      end
    end
  end
end
