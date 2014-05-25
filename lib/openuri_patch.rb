##################################################################
#####openuri_patch.rb -- part of the RubyRetriever project
#####             
#####created by Joe Norton
#####http://softwarebyjoe.com
##LICENSING: GNU GPLv3  License###################################
module OpenURI
  class <<self
    def OpenURI.redirectable?(uri1, uri2)
      # fixed to allow redirects from http -> https
      # it's not a security issue but for some reason OpenURI blocks this by default
      uri1.scheme.downcase == uri2.scheme.downcase ||
      (/\A(?:https*|ftp)\z/i =~ uri1.scheme && /\A(?:https*|ftp)\z/i =~ uri2.scheme)
    end
  end
end
