# frozen_string_literal: true

require 'uri'

module Ponyhead
  autoload :ImageCache, './lib/ponyhead/image_cache'

  # e.g. http://www.ponyhead.com/deckbuilder?v1code=de52x3-sb75x3-ll152x2-nd49x2-nd98x3-ff141x3-fm159x3-sb142x3-de119x3-ll128x1-nd97x3-fm3x1-sb113x2-sb56x3-ll88x2-pw18x2-sb132x2-ff124x2-sb131x2-ll132x2-fm10x3-de96x3-fm81x2-fm141x2-nd129x1-sb141x3
  #
  # @param url [String]
  # @return [Hash{String => Integer}]
  def self.parse_decklist_url(url)
    uri = URI.parse(url)
    params = URI.decode_www_form(uri.query).to_h

    extract_deck_list(params['v1code'])
  end

  # @param v1code [String]
  # @return [Hash{String => Integer}]
  def self.extract_deck_list(v1code)
    v1code.split('-').to_h do |card_with_count|
      card, count = card_with_count.split(/x(\d)\z/)

      [card, count.to_i]
    end
  end

  # @param decklist [Hash{String => Integer}]
  # @return [Array<String>]
  def self.extend_decklist_to_images(decklist)
    decklist.flat_map do |card, count|
      metadata = ImageCache.fetch(card)

      metadata['paths'].flat_map do |image_path|
        Array.new(count) { image_path }
      end
    end
  end
end
