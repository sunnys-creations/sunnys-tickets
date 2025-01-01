# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sessions::Event::TicketOverviewList < Sessions::Event::Base
  database_connection_required

  def run
    return if !valid_session?

    Sessions::Backend::TicketOverviewList.reset(@session['id'])
  end

end
