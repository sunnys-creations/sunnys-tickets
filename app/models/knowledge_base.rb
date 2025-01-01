# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase < ApplicationModel
  include HasTranslations
  include HasAgentAllowedParams
  include ChecksKbClientNotification

  AGENT_ALLOWED_NESTED_RELATIONS = %i[translations].freeze

  LAYOUTS = %w[grid list].freeze
  ICONSETS = %w[FontAwesome anticon material ionicons Simple-Line-Icons].freeze

  has_many                      :kb_locales, class_name: 'KnowledgeBase::Locale',
                                             inverse_of: :knowledge_base,
                                             dependent:  :destroy

  accepts_nested_attributes_for :kb_locales, allow_destroy: true
  validates                     :kb_locales, presence: true
  validates                     :kb_locales, length: { maximum: 1, message: __('System supports only one locale for knowledge base. Upgrade your plan to use more locales.') }, unless: :multi_lingual_support?

  has_many :categories, class_name: 'KnowledgeBase::Category',
                        inverse_of: :knowledge_base,
                        dependent:  :restrict_with_exception

  has_many :answers, through: :categories

  has_many :permissions, class_name: 'KnowledgeBase::Permission',
                         as:         :permissionable,
                         autosave:   true,
                         dependent:  :destroy

  validates :category_layout, inclusion: { in: KnowledgeBase::LAYOUTS }
  validates :homepage_layout, inclusion: { in: KnowledgeBase::LAYOUTS }

  validates :color_highlight,   presence: true, 'validations/color': true
  validates :color_header,      presence: true, 'validations/color': true
  validates :color_header_link, presence: true, 'validations/color': true

  validates :iconset, inclusion: { in: KnowledgeBase::ICONSETS }

  validate :validate_custom_address

  before_validation :patch_custom_address

  after_create  :set_defaults
  after_destroy :set_kb_active_setting
  after_save    :set_kb_active_setting

  scope :active, -> { where(active: true) }

  alias assets_essential assets

  def assets(data)
    return data if assets_added_to?(data)

    data = super
    ApplicationModel::CanAssets.reduce(kb_locales + translations, data)
  end

  # assets without unnecessary bits
  def assets_public(data)
    data = assets_essential(data)

    data[:KnowledgeBase].each_value do |elem|
      elem.delete_if do |k, _|
        k.end_with?('_ids')
      end
    end

    data
  end

  def custom_address_uri
    return nil if custom_address.blank?

    scheme = Setting.get('http_type') || 'http'

    URI("#{scheme}://#{custom_address}")
  rescue URI::InvalidURIError
    nil
  end

  def custom_address_matches?(request)
    uri = custom_address_uri

    return false if uri.blank?

    given_fqdn = request.headers.env['SERVER_NAME']&.downcase
    given_path = request.headers.env['HTTP_X_ORIGINAL_URL']&.downcase

    # original url header not present, server not configured
    return false if given_path.nil?

    # path doesn't match
    return false if uri.path.downcase != given_path[0, uri.path.length]

    # domain present, but doesn't match
    return false if uri.host.present? && uri.host.downcase != given_fqdn

    true
  rescue URI::InvalidURIError
    false
  end

  def custom_address_prefix(request)
    host        = custom_address_uri.host.presence || request.headers.env['SERVER_NAME']
    port        = request.headers.env['SERVER_PORT']
    port_silent = (request.ssl? && port == '443') || (!request.ssl? && port == '80')
    port_string = port_silent ? '' : ":#{port}"

    "#{custom_address_uri.scheme}://#{host}#{port_string}"
  end

  def custom_address_path(path)
    uri = custom_address_uri

    return path if !uri

    custom_path  = custom_address_uri.path || ''
    applied_path = path.gsub(%r{^/help}, custom_path)

    applied_path.presence || '/'
  end

  def canonical_host
    custom_address_uri&.host.presence || Setting.get('fqdn')
  end

  def canonical_scheme_host
    "#{Setting.get('http_type')}://#{canonical_host}"
  end

  def canonical_url(path)
    "#{canonical_scheme_host}#{custom_address_path(path)}"
  end

  def full_destroy!
    ChecksKbClientNotification.disable_in_all_classes!

    transaction do
      # get all categories with their children and reverse to delete children first
      categories.root.map(&:self_with_children).flatten.reverse.each(&:full_destroy!)
      translations.each(&:destroy!)
      kb_locales.each(&:destroy!)
      destroy!
    end
  ensure
    ChecksKbClientNotification.enable_in_all_classes!
  end

  def visible?
    active?
  end

  def api_url
    Rails.application.routes.url_helpers.knowledge_base_path(self)
  end

  def load_category(locale, id)
    categories.localed(locale).find_by(id: id)
  end

  def self.with_multiple_locales_exists?
    KnowledgeBase
      .active
      .joins(:kb_locales)
      .group('knowledge_bases.id')
      .pluck(Arel.sql('COUNT(knowledge_base_locales.id) as locales_count'))
      .any? { |e| e > 1 }
  end

  def permissions_effective
    cache_key = KnowledgeBase::Permission.cache_key self

    Rails.cache.fetch cache_key do
      permissions
    end
  end

  def attributes_with_association_ids
    attrs = super
    attrs[:permissions_effective] = permissions_effective
    attrs
  end

  def self.granular_permissions?
    KnowledgeBase::Permission.any?
  end

  def public_content?(kb_locale = nil)
    scope = answers.published

    scope = scope.localed(kb_locale.system_locale) if kb_locale

    scope.any?
  end

  private

  def set_defaults
    self.translations = kb_locales.map do |kb_locale|
      name      = Setting.get('organization').presence || Setting.get('product_name').presence || 'Zammad'
      kb_suffix = ::Translation.translate kb_locale.system_locale.locale, 'Knowledge Base'

      KnowledgeBase::Translation.new(
        title:       "#{name} #{kb_suffix}",
        footer_note: "© #{name}",
        kb_locale:   kb_locale
      )
    end
  end

  def validate_custom_address
    return if custom_address.nil?

    # not domain, but no leading slash
    if custom_address.exclude?('.') && custom_address[0] != '/'
      errors.add(:custom_address, __('must begin with a slash ("/")'))
    end

    if custom_address.include?('://')
      errors.add(:custom_address, __('must not include a protocol (e.g., "http://" or "https://")'))
    end

    if custom_address.last == '/'
      errors.add(:custom_address, __('must not end with a slash ("/")'))
    end

    if custom_address == '/' # rubocop:disable Style/GuardClause
      errors.add(:custom_address, __('must be a valid path or domain'))
    end
  end

  def patch_custom_address
    self.custom_address = nil if custom_address == ''
  end

  def multi_lingual_support?
    Setting.get 'kb_multi_lingual_support'
  end

  def set_kb_active_setting
    Setting.set 'kb_active', KnowledgeBase.active.exists?
    CanBePublished.update_active_publicly!
  end
end
