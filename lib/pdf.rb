# frozen_string_literal: true

module PDF
  INCH = 72
  MM   = INCH / 25.4

  class Writer
    HEADER = "%PDF-1.7\n%\xe2\x93\x82\xe2\x93\x81\xe2\x93\x85\n"

    def initialize
      @current_offset = 0
      @object_offsets = {}
      @output_buffer  = StringIO.new

      write(HEADER)
    end

    def add(number, data)
      @object_offsets[number] = @current_offset
      write("#{number} 0 obj\n#{data}\nendobj\n")
    end

    def flush(root)
      xref_offset = @current_offset
      write("xref\n")
      xref_start = 0
      xref_count = 1
      xref_section = "0000000000 65536 f \n"

      @object_offsets.sort.each do |number, offset|
        if (number != xref_start + xref_count)
          write("#{xref_start} #{xref_count}\n#{xref_section}")
          xref_start = 0
          xref_count = 0
          xref_section = ""
        end

        xref_count += 1
        xref_section += "%010d 00000 n \n" % offset
      end

      write("#{xref_start} #{xref_count}\n#{xref_section}")
      xref_size = @object_offsets.size + 1
      write("trailer\n<< /Size #{xref_size}\n/Root #{root} 0 R\n>>\n")
      write("startxref\n#{xref_offset}\n%%EOF\n")
    end

    def to_s
      @output_buffer.string
    end

  private

    # @param data [String]
    # @return [void]
    def write(data)
      @current_offset += data.bytesize
      @output_buffer << data
    end
  end

  def self.pdf_stream(data, params = nil)
    length = data.bytesize

    if params
      dict = "<< #{params}\n/Length #{length}\n>>"
    else
      dict = "<< /Length #{length} >>"
    end

    "#{dict}\nstream\n#{data}\nendstream\n"
  end
end
