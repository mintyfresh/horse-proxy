# frozen_string_literal: true

require './lib/pdf'
require './lib/ponyhead'
require './lib/print_and_play'

require 'open-uri'

configure do
  mime_type :pdf, 'application/pdf'
end

get '/' do
  'Hello world! 7'
end

get '/print-and-play' do
  deck = Ponyhead.parse_decklist_url(params[:deck])

  logger.info "Scanning #{deck.count} cards for images..."

  images = deck.flat_map do |card, count|
    images = []

    metadata = Ponyhead::ImageCache.fetch(card)
    metadata['paths'].each_with_index do |path, index|
      images << [card, path, count, metadata['sizes'][index]]
    end

    images
  end

  logger.info "Found #{images.count} images."
  logger.info "Generating PDF..."

  writer = PDF::Writer.new
  next_on = 1

  catalog_on = next_on
  next_on += 1

  pages_on = next_on
  next_on += 1

  writer.add(catalog_on, "<< /Type /Catalog\n/Pages #{pages_on} 0 R\n>>")

  all_images = []

  images.each do |card, path, count, (width, height)|
    name = "/Im#{card}"
    data = path.read

    image_on = next_on
    next_on += 1

    params = "/Type /XObject\n/Subtype /Image\n/Width #{width}\n/Height #{height}\n" \
             "/ColorSpace /DeviceRGB\n/BitsPerComponent 8\n/Filter /DCTDecode"

    writer.add(image_on, PDF.pdf_stream(data, params))

    count.times do
      all_images << [name, image_on]
    end
  end

  page_width = nil
  page_height = nil

  if params[:paper] == 'A4'
    page_width = 210 * PDF::MM
    page_height = 297 * PDF::MM
  else
    page_width = 8.5 * PDF::INCH
    page_height = 11 * PDF::INCH
  end

  card_width = 63 * PDF::MM
  card_height = 88 * PDF::MM
  card_spacing = 1

  page_ons = []
  all_images.each_slice(9) do |image_ons|
    content = []
    page_xobjs = []

    image_ons.each_with_index do |(name, image_on), i|
      x = ((page_width - (card_width * 3) - (card_spacing * 2)) / 2) + ((i % 3) * (card_width + card_spacing))
      y = ((page_height + card_height + (card_spacing * 2)) / 2) - ((i / 3) * (card_height + card_spacing))

      content << "q\n%.2f 0 0 %.2f %.2f %.2f cm\n%s Do\nQ" % [card_width, card_height, x, y, name]
      page_xobjs << "#{name} #{image_on} 0 R "
    end

    page_on = next_on
    page_ons << "#{page_on} 0 R"
    next_on += 1

    content_on = next_on
    next_on += 1

    writer.add(page_on, "<< /Type /Page\n/Parent #{pages_on} 0 R\n/MediaBox [0 0 #{page_width} #{page_height}]\n/Contents #{content_on} 0 R\n/Resources << /ProcSet [/PDF /ImageC]\n/XObject << #{page_xobjs.uniq.join('')}>>\n>>\n>>")
    writer.add(content_on, PDF.pdf_stream(content.join("\n")))
  end

  writer.add(pages_on, "<< /Type /Pages\n/Kids [#{page_ons.join(' ')}]\n/Count #{page_ons.count}\n>>")
  writer.flush(catalog_on)

  content_type :pdf
  writer.to_s
end
