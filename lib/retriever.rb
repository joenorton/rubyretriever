##################################################################
#####RubyRetriever -- web crawler and file harvester
#####created by Joe Norton
#####http://softwarebyjoe.com
##LICENSING: GNU GPLv3  License##################################
#! usr/bin/ruby
require "em-synchrony"
require "em-synchrony/em-http"
require "em-synchrony/fiber_iterator"
require 'ruby-progressbar'
require 'open-uri'
require 'optparse'
require 'uri'
require 'csv'
require 'bloomfilter-rb'

require_relative('./retriever/fetch')
require_relative('./retriever/fetchfiles')
require_relative('./retriever/fetchsitemap')