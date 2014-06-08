module OpenURI
  def OpenURI.redirectable?(uri1, uri2) #nesc patch otherwise OPENURI blocks redirects to and from https
    uri1.scheme.downcase == uri2.scheme.downcase ||
    (/\A(?:http|https)\z/i =~ uri1.scheme && /\A(?:http|https)\z/i =~ uri2.scheme)
  end
end