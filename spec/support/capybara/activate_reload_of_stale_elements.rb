# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# This file overwrites `Capybara::Node::Finders#all` to set the default value
# of the `allow_reload` keyword argument to `true` (default: `false`) to enable
# automatic reload of stale elements and avoid
# `Selenium::WebDriver::Error::StaleElementReferenceError` exceptions.

module ZammadActivateReloadOfStaleElements

  def all(*, allow_reload: true, **, &optional_filter_block)
    super
  end
end

Capybara::Node::Base.include(ZammadActivateReloadOfStaleElements)
Capybara::Node::Simple.include(ZammadActivateReloadOfStaleElements)
