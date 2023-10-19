# frozen_string_literal: true

module PDF
  INCH = 72
  MM   = INCH / 25.4

  CARD_WIDTH  = 63 * MM
  CARD_HEIGHT = 88 * MM
  CARD_MARGIN = 1 # px

  # @param page_size [Symbol]
  # @return [(Integer, Integer)]
  def self.cards_per_page(page_size)
    _, _, width, height = HexaPDF::Type::Page::PAPER_SIZE.fetch(page_size) do
      raise ArgumentError, "Unknown page size: #{page_size}."
    end

    # Leave at least 1mm of margin on each side
    width  -= 2 * MM
    height -= 2 * MM

    # Leave 1px of margin between cards
    card_width  = CARD_WIDTH + CARD_MARGIN
    card_height = CARD_HEIGHT + CARD_MARGIN

    [(width / card_width).floor, (height / card_height).floor]
  end

  # @param page_size [Symbol]
  # @param cards_x [Integer]
  # @param cards_y [Integer]
  def self.page_margins(page_size, (cards_x, cards_y))
    _, _, width, height = HexaPDF::Type::Page::PAPER_SIZE.fetch(page_size) do
      raise ArgumentError, "Unknown page size: #{page_size}."
    end

    cards_width  = cards_x * (CARD_WIDTH + CARD_MARGIN)
    cards_height = cards_y * (CARD_HEIGHT + CARD_MARGIN)

    margin_top  = (height - cards_height) / 2
    margin_left = (width - cards_width) / 2

    [margin_top, margin_left]
  end
end
