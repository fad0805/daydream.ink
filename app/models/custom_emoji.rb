# frozen_string_literal: true

# == Schema Information
#
# Table name: custom_emojis
#
#  id                           :bigint(8)        not null, primary key
#  shortcode                    :string           default(""), not null
#  domain                       :string
#  image_file_name              :string
#  image_content_type           :string
#  image_file_size              :integer
#  image_updated_at             :datetime
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  disabled                     :boolean          default(FALSE), not null
#  uri                          :string
#  image_remote_url             :string
#  visible_in_picker            :boolean          default(TRUE), not null
#  category_id                  :bigint(8)
#  image_storage_schema_version :integer
#

class CustomEmoji < ApplicationRecord
  include Attachmentable

  LOCAL_LIMIT = (ENV['MAX_EMOJI_SIZE'] || 256.kilobytes).to_i
  LIMIT       = [LOCAL_LIMIT, (ENV['MAX_REMOTE_EMOJI_SIZE'] || 256.kilobytes).to_i].max
  MINIMUM_SHORTCODE_SIZE = 2

  MAX_EMOJI_RATIO = ENV['MAX_EMOJI_RATIO']&.to_f

  SHORTCODE_RE_FRAGMENT = '[a-zA-Z0-9_]{2,}'

  SCAN_RE = /(?<=[^[:alnum:]:]|\n|^)
    :(#{SHORTCODE_RE_FRAGMENT}):
    (?=[^[:alnum:]:]|$)/x
  SHORTCODE_ONLY_RE = /\A#{SHORTCODE_RE_FRAGMENT}\z/

  IMAGE_MIME_TYPES = %w(image/png image/gif image/webp).freeze

  belongs_to :category, class_name: 'CustomEmojiCategory', optional: true

  has_one :local_counterpart, -> { where(domain: nil) }, class_name: 'CustomEmoji', primary_key: :shortcode, foreign_key: :shortcode, inverse_of: false, dependent: nil

  has_attached_file :image, styles: { static: { format: 'png', convert_options: '-coalesce +profile "!icc,*" +set date:modify +set date:create +set date:timestamp', file_geometry_parser: FastGeometryParser } }, validate_media_type: false, processors: [:lazy_thumbnail]

  normalizes :domain, with: ->(domain) { domain.downcase }

  validates_attachment :image, content_type: { content_type: IMAGE_MIME_TYPES }, presence: true
  validates_attachment_size :image, less_than: LIMIT, unless: :local?
  validates_attachment_size :image, less_than: LOCAL_LIMIT, if: :local?
  validates :shortcode, uniqueness: { scope: :domain }, format: { with: SHORTCODE_ONLY_RE }, length: { minimum: MINIMUM_SHORTCODE_SIZE }
  validate :check_image_ratio if MAX_EMOJI_RATIO.present?

  scope :local, -> { where(domain: nil) }
  scope :remote, -> { where.not(domain: nil) }
  scope :enabled, -> { where(disabled: false) }
  scope :alphabetic, -> { order(domain: :asc, shortcode: :asc) }
  scope :by_domain_and_subdomains, ->(domain) { where(domain: domain).or(where(arel_table[:domain].matches("%.#{domain}"))) }
  scope :listed, -> { local.enabled.where(visible_in_picker: true) }

  remotable_attachment :image, LIMIT

  after_commit :remove_entity_cache

  def local?
    domain.nil?
  end

  def object_type
    :emoji
  end

  def copy!
    copy = self.class.find_or_initialize_by(domain: nil, shortcode: shortcode)
    copy.image = image
    copy.tap(&:save!)
  end

  def to_log_human_identifier
    shortcode
  end

  class << self
    def from_text(text, domain = nil)
      return [] if text.blank?

      shortcodes = text.scan(SCAN_RE).map(&:first).uniq

      return [] if shortcodes.empty?

      EntityCache.instance.emoji(shortcodes, domain)
    end

    def search(shortcode)
      where(arel_table[:shortcode].matches("%#{sanitize_sql_like(shortcode)}%"))
    end
  end

  private

  def remove_entity_cache
    Rails.cache.delete(EntityCache.instance.to_key(:emoji, shortcode, domain))
  end

  def check_image_ratio
    return if image.blank? || !/image.*/.match?(image.content_type) || image.queued_for_write[:original].blank?
    return if MAX_EMOJI_RATIO.nil? || MAX_EMOJI_RATIO < 1

    width, height = FastImage.size(image.queued_for_write[:original].path)
    return unless width.present? && height.present?

    ratio = width.to_f / height

    errors.add(:image, :invalid_image_ratio) if ratio > MAX_EMOJI_RATIO || ratio < (1.0 / MAX_EMOJI_RATIO)
  end
end
