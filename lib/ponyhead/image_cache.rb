# frozen_string_literal: true

require 'uri'
require 'open-uri'
require 'pathname'

module Ponyhead
  module ImageCache
    DIR = Pathname.new(File.expand_path('../../tmp/images', __dir__))

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
