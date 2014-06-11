#
module OpenURI
  # nesc patch otherwise OPENURI blocks redirects to and from https
  def self.redirectable?(uri1, uri2)
    uri1.scheme.downcase == uri2.scheme.downcase ||
    (/\A(?:http|https)\z/i =~ uri1.scheme && /\A(?:http|https)\z/i =~ uri2.scheme)
  end
end
