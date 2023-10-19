# frozen_string_literal: true

require './lib/pdf'
require './lib/ponyhead'

require 'open-uri'

configure do
  mime_type :pdf, 'application/pdf'
end

get '/' do
  'Hello world! 7'
end

get '/generate-pdf' do
  decklist = Ponyhead.parse_decklist_url(params[:deck])
  images = Ponyhead.extend_decklist_to_images(decklist)

  page_size = params.fetch(:page_size, :Letter).to_sym
  page_size = :Letter unless HexaPDF::Type::Page::PAPER_SIZE.key?(page_size)

  cards_per_page = PDF.cards_per_page(page_size)
  margin = PDF.page_margins(page_size, cards_per_page)

  buffer = StringIO.new
  HexaPDF::Composer.create(buffer, page_size:, margin:) do |composer|
    images.each do |image|
      composer.image(image.open, width: PDF::CARD_WIDTH, height: PDF::CARD_HEIGHT,
                                 margin: [0, 0, 1, 1], position: :float)
    end
  end

  content_type :pdf
  buffer.string
end
