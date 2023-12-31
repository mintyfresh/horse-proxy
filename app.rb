# frozen_string_literal: true

require './lib/pdf'
require './lib/ponyhead'

require 'open-uri'

configure do
  mime_type :pdf, 'application/pdf'
end

get '/' do
  erb :index
end

get '/generate-pdf' do
  decklist = Ponyhead.parse_decklist_url(params[:deck])
  image_paths = Ponyhead.convert_decklist_to_image_paths(decklist)

  paper_size = params.fetch(:paper_size, :Letter).to_sym
  paper_size = :Letter unless PDF.paper_sizes.key?(paper_size)

  cards_per_page = PDF.cards_per_page(paper_size)
  margin = PDF.page_margins(paper_size, cards_per_page)

  buffer = StringIO.new
  HexaPDF::Composer.create(buffer, page_size: paper_size, margin:) do |composer|
    image_paths.each do |path|
      composer.image(path.to_s, width: PDF::CARD_WIDTH, height: PDF::CARD_HEIGHT,
                                margin: [0, 0, PDF::CARD_MARGIN, PDF::CARD_MARGIN],
                                position: :float)
    end
  end

  content_type :pdf
  buffer.string
end
