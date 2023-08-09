# frozen_string_literal: true

class ManifestSerializer < ActiveModel::Serializer
  include RoutingHelper
  include ActionView::Helpers::TextHelper

  ICON_SIZES = %w(
    36
    48
    72
    96
    144
    192
    256
    384
    512
  ).freeze

  attributes :id, :name, :short_name,
             :icons, :theme_color, :background_color,
             :display, :start_url, :scope,
             :share_target, :shortcuts

  def id
    # This is set to `/home` because that was the old value of `start_url` and
    # thus the fallback ID computed by Chrome:
    # https://developer.chrome.com/blog/pwa-manifest-id/
    '/home'
  end

  def name
    object.title
  end

  def short_name
    object.title
  end

  def icons
    ICON_SIZES.map do |size|
      {
        src: full_pack_url("media/icons/android-chrome-#{size}x#{size}.png"),
        sizes: "#{size}x#{size}",
        type: 'image/png',
        purpose: 'any maskable',
      }
    end + [{
      src: full_pack_url('media/images/app-icon.svg'),
      sizes: 'any',
      type: 'image/svg+xml',
      purpose: 'any maskable',
    }]
  end

  def theme_color
    '#a6e819'
  end

  def background_color
    '#191b22'
  end

  def display
    'standalone'
  end

  def start_url
    '/'
  end

  def scope
    '/'
  end

  def share_target
    {
      url_template: 'share?title={title}&text={text}&url={url}',
      action: 'share',
      method: 'GET',
      enctype: 'application/x-www-form-urlencoded',
      params: {
        title: 'title',
        text: 'text',
        url: 'url',
      },
    }
  end

  def shortcuts
    [
      {
        name: 'Compose new post',
        url: '/publish',
      },
      {
        name: 'Notifications',
        url: '/notifications',
      },
      {
        name: 'Explore',
        url: '/explore',
      },
    ]
  end
end
