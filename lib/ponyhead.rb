# frozen_string_literal: true

require 'uri'
require 'open-uri'
require 'pathname'

module Ponyhead
  # e.g. # http://www.ponyhead.com/deckbuilder?v1code=de52x3-sb75x3-ll152x2-nd49x2-nd98x3-ff141x3-fm159x3-sb142x3-de119x3-ll128x1-nd97x3-fm3x1-sb113x2-sb56x3-ll88x2-pw18x2-sb132x2-ff124x2-sb131x2-ll132x2-fm10x3-de96x3-fm81x2-fm141x2-nd129x1-sb141x3
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

  module ImageCache
    DIR = Pathname.new(File.expand_path('../tmp/images', __dir__))

    def self.fetch(card)
      if (metadata = read_cache(card))
        metadata
      else
        load_cache(card)
        read_cache(card)
      end
    end

    def self.read_cache(card)
      metadata = JSON.parse(DIR.join("#{card}.json").read)

      metadata['paths'] = metadata['file_names'].map do |file_name|
        DIR.join(file_name)
      end

      metadata
    rescue Errno::ENOENT, JSON::ParserError
      nil
    end

    def self.load_cache(card)
      assets   = download_assets(card)
      metadata = { count: assets.count, sizes: assets.map(&:last), file_names: assets.map(&:first) }

      DIR.mkpath unless DIR.exist?
      DIR.join("#{card}.json").write(JSON.dump(metadata))

      assets.each do |file_name, data, _|
        DIR.join(file_name).write(data)
      end
    end

    # @param card [String]
    # @return [Array<(String, String, (Integer, Integer))>]
    def self.download_assets(card)
      card_urls(card).filter_map do |file_name, uri|
        uri.open do |io|
          [file_name, *inspect_and_normalize_image(io.read)]
        end
      rescue OpenURI::HTTPError, FastImage::UnknownImageType, FastImage::ImageFetchFailure
        nil
      end
    end

    # @param data [String] the raw image data
    # @return [(String, (Integer, Integer))] a tuple of the image data and dimensions
    def self.inspect_and_normalize_image(data)
      size = FastImage.size(StringIO.new(data))

      # width > height
      if size[0] > size[1]
        rotated = MiniMagick::Image.read(data).rotate(-90)

        data = rotated.to_blob
        size = rotated.dimensions
      end

      [data, size]
    end

    # @param card [String]
    # @return [Array<URI>]
    def self.card_urls(card)
      file_names(card).map do |file_name|
        [file_name, URI.parse("https://ponyhead.com/img/cards/#{file_name}")]
      end
    end

    def self.file_names(card)
      ["#{card}.jpg", "#{card}b.jpg"]
    end
  end
end
