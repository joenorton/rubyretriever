require 'htmlentities'
#
module SourceString
  refine String do
    def decode_html
      HTMLEntities.new.decode(self)
    end

    def encode_utf8_and_replace
      encode('UTF-8', invalid: :replace, undef: :replace)
    end
  end
end
