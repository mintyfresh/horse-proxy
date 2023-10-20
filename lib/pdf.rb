# frozen_string_literal: true

module PDF
  INCH = 72
  MM   = INCH / 25.4

  CARD_WIDTH  = 63 * MM
  CARD_HEIGHT = 88 * MM
  CARD_MARGIN = 1 # px

  # Minimum 1mm of margin on each side
  PAGE_MARGIN = 2 * MM

  # Paper sizes that are large enough to fit at least one card and have at least 1mm of margin on each side
  #
  # @return [Hash{Symbol => (Integer, Integer, Integer, Integer)}]
  def self.paper_sizes
    @paper_sizes ||= HexaPDF::Type::Page::PAPER_SIZE.select do |_, (_, _, width, height)|
      width >= (CARD_WIDTH + CARD_MARGIN + PAGE_MARGIN) &&
        height >= (CARD_HEIGHT + CARD_MARGIN + PAGE_MARGIN)
    end
  end

  # @param paper_size [Symbol]
  # @return [(Integer, Integer)]
  def self.cards_per_page(paper_size)
    _, _, width, height = paper_sizes.fetch(paper_size) do
      raise ArgumentError, "Unknown paper size: #{paper_size}."
    end

    # Leave at least 1mm of margin on each side
    width  -= PAGE_MARGIN
    height -= PAGE_MARGIN

    # Leave 1px of margin between cards
    card_width  = CARD_WIDTH + CARD_MARGIN
    card_height = CARD_HEIGHT + CARD_MARGIN

    [(width / card_width).floor, (height / card_height).floor]
  end

  # @param paper_size [Symbol]
  # @param cards_x [Integer]
  # @param cards_y [Integer]
  def self.page_margins(paper_size, (cards_x, cards_y))
    _, _, width, height = paper_sizes.fetch(paper_size) do
      raise ArgumentError, "Unknown paper size: #{paper_size}."
    end

    cards_width  = cards_x * (CARD_WIDTH + CARD_MARGIN)
    cards_height = cards_y * (CARD_HEIGHT + CARD_MARGIN)

    margin_top  = (height - cards_height) / 2
    margin_left = (width - cards_width) / 2

    [margin_top, margin_left]
  end
end
