# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Idoit

=begin

get list ob types

  result = Idoit.verify(api_token, endpoint, client_id)

returns

  array with cmdb.object_types or an exeption if no data was able to retrive

=end

  def self.verify(api_token, endpoint, _client_id = nil, verify_ssl: false)
    raise 'api_token required' if api_token.blank?
    raise 'endpoint required' if endpoint.blank?

    params = {
      apikey: api_token,
    }

    _query('cmdb.object_types', params, _url_cleanup(endpoint), verify_ssl: verify_ssl)
  end

=begin

get list ob types

  result = Idoit.query(method, filter)

  result = Idoit.query(method, { type: '59' })

returns

  result = [
    {
      "id": "1",
      "title": "System service",
      "container": "0",
      "const": "C__OBJTYPE__SERVICE",
      "color": "987384",
      "image": "https://demo.example.com/i-doit/images/objecttypes/service.jpg",
      "icon": "images/icons/silk/application_osx_terminal.png",
      "cats": "4",
      "tree_group": "1",
      "status": "2",
      "type_group": "1",
      "type_group_title": "Software"
    },
    {
      "id": "2",
      "title": "Application",
      "container": "0",
      "const": "C__OBJTYPE__APPLICATION",
      "color": "E4B9D7",
      "image": "https://demo.example.com/i-doit/images/objecttypes/application.jpg",
      "icon": "images/icons/silk/application_xp.png",
      "cats": "20",
      "tree_group": "1",
      "status": "2",
      "type_group": "1",
      "type_group_title": "Software"
    },
  ]

or with filter:

  "result": [
    {
      "id": "26",
      "title": "demo.example.com",
      "sysid": "SYSID_1485512390",
      "type": "59",
      "created": "2017-01-27 11:19:24",
      "updated": "2017-01-27 11:19:49",
      "type_title": "Virtual server",
      "type_group_title": "Infrastructure",
      "status": "2",
      "cmdb_status": "6",
      "cmdb_status_title": "in operation",
      "image": "https://demo.example.com/i-doit/images/objecttypes/empty.png"
    },
  ],

=end

  def self.query(method, filter = {})
    setting = Setting.get('idoit_config')
    raise __("The required field 'api_token' is missing from the config.") if setting[:api_token].blank?
    raise __("The required field 'endpoint' is missing from the config.") if setting[:endpoint].blank?

    params = {
      apikey: setting[:api_token],
    }
    if filter.present?
      params[:filter] = filter
    end
    _query(method, params, _url_cleanup(setting[:endpoint]), verify_ssl: setting[:verify_ssl])
  end

  def self._query(method, params, url, verify_ssl: false)
    result = UserAgent.post(
      url,
      {
        method:  method,
        params:  params,
        version: '2.0',
        # the id attribute is required by the JSON-RPC standard
        # but i-doit doesn't actually use it so we send a hard coded id
        # see issue #2412 and community topic for further information
        id:      42,
      },
      {
        verify_ssl:   verify_ssl,
        json:         true,
        open_timeout: 6,
        read_timeout: 16,
        log:          {
          facility: 'idoit',
        },
      },
    )

    raise "Can't fetch objects from #{url}: Unable to parse response from server. Invalid JSON response." if !result.success? && result.error =~ %r{JSON::ParserError:.+?\s+unexpected\s+token\s+at\s+'<!DOCTYPE\s+html}i
    raise "Can't fetch objects from #{url}: #{result.error}" if !result.success?

    # add link to idoit
    if result.data['result'].instance_of?(Array)
      result.data['result'].each do |item|
        next if !item['id']

        item['link'] = "#{_url_cleanup_baseurl(url)}/?objID=#{item['id']}"
        item['link'].gsub!(%r{([^:])//+}, '\\1/')
      end
    end
    result.data
  end

  def self._url_cleanup(url)
    url.strip!
    raise "Invalid endpoint '#{url}', need to start with http:// or https://" if !url.match?(%r{^http(s|)://}i)

    url = _url_cleanup_baseurl(url)
    url = "#{url}/src/jsonrpc.php"
    url.gsub(%r{([^:])//+}, '\\1/')
  end

  def self._url_cleanup_baseurl(url)
    url.strip!
    raise "Invalid endpoint '#{url}', need to start with http:// or https://" if !url.match?(%r{^http(s|)://}i)

    url.gsub!(%r{src/jsonrpc.php}, '')
    url.gsub(%r{([^:])//+}, '\\1/')
  end
end
