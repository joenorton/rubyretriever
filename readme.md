[RubyRetriever] (http://softwarebyjoe.com/rubyretriever/)  
==============
[![Gem Version](https://badge.fury.io/rb/rubyretriever.svg)](http://badge.fury.io/rb/rubyretriever)  [![Build Status](https://travis-ci.org/joenorton/rubyretriever.svg?branch=master)](https://travis-ci.org/joenorton/rubyretriever)  
  
By Joe Norton  

RubyRetriever is a Web Crawler, Site Mapper, File Harvester & Autodownloader.  

RubyRetriever (RR) uses asynchronous HTTP requests via [Eventmachine](https://github.com/eventmachine/eventmachine) & [Synchrony](https://github.com/igrigorik/em-synchrony) to crawl webpages *very quickly*. RR also uses a Ruby implementation of the [bloomfilter](https://github.com/igrigorik/bloomfilter-rb) in order to keep track of pages it has already crawled.  

**v1.0 Update (6/07/2014)** - Includes major code changes and a lot of bug fixes. It's now much better in dealing with redirects, issues with the host changing, etc. Also added the SEO mode, which grabs a number of key SEO components from every page on a site. Lastly, this update was so extensive that I could not ensure backward compatibility; thus, this was update 1.0!

Mission  
-------
RubyRetriever aims to be the best command-line crawling and scraping package written in Ruby.    

Features  
--------  
* Asynchronous HTTP Requests thru EM & Synchrony  
* Bloom filter for tracking visited pages  
* 3 CLI modes
	* Sitemap
	* File Harvest
	* SEO   

Use cases  
---------
RubyRetriever can do multiple things for you. As an Executable
With a single command at the terminal, RR can:  
1. Crawl your website and output a *valid XML sitemap* based on what it found.  
2. Crawl a target website and *download all files of a given filetype*.  
3. Crawl a target website, *collect important SEO information* such as page titles, meta descriptions and h1 tags, and write it to CSV.  

Help & Forks Welcome!  
  
Getting started   
-----------
Install the gem
```sh
$ gem install rubyretriever
```  
  

Using the Executable  
--------------------
 **Example: Sitemap mode**  
```sh
$ rr --sitemap CSV --progress --limit 100 http://www.cnet.com
```  
OR -- SAME COMMAND  
```sh
$ rr -s csv -p -l 100 http://www.cnet.com
```  
  
This would map http://www.cnet.com until it crawled a max of 100 pages, then write the results to a CSV named cnet. Optionally, you could also use the format XML and RR would output the same URL list into a valid XML sitemap that could be submitted to Google.  
  
 **Example: File Harvesting mode**  
```sh
$ rr --files pdf --progress --limit 1000 --out hubspot http://www.hubspot.com
```  
OR -- SAME COMMAND  
```sh
$ rr -f pdf -p -l 100 http://www.hubspot.com
```  
  
This would crawl http://www.hubspot.com looking for filetype:PDF until it hit a max of 100 pages, then write out a list of filepaths to a CSV named hubspot (based on the website host name). Optionally, you could have the script autodownload all the files by adding the -a/--auto flag.

**Example: SEO mode**  
```sh
$ rr --seo --progress --limit 100 --out cnet-seo http://www.cnet.com
```  
OR -- SAME COMMAND  
```sh
$ rr -e -p -l 10 -o cnet-seo http://www.cnet.com
```  
  
This would go to http://www.cnet.com and crawl a max of 100 pages, during which it would collect the SEO fields on those pages - this currently means [url, page title, meta description, h1 text, h2 text]. It would then write the fields to a csv named cnet-seo.
  

command-line arguments
-----------------------
Usage: rr [MODE FLAG] [OPTIONS] Target_URL  

Where MODE FLAG is required, and is either:  
	-s, --sitemap FORMAT  (only accepts CSV or XML atm)  
	-f, --files FILETYPE  
	-e, --seo  
  
and OPTIONS is the applicable:  
    -o, --out FILENAME                  *Dump fetch data as CSV*  
    -p, --progress						*Outputs a progressbar*  
    -v, --verbose                       *Output more information*  
    -l, --limit PAGE_LIMIT_#            *set a max on the total number of crawled pages*  
    -h, --help                          *Display this screen*  
  

Using as a Library (starting as of version 1.3.0 -- yet to be released)  
------------------

If you want to collect something, other than that which the executable allows, on a 'per page' basis then you want to use the PageIterator class. Then you can run whatever block you want against each individual page's source code located during the crawl.   

Sample Script using **PageIterator**  
```ruby
require 'retriever'
opts = {
  'maxpages' => 1
}
t = Retriever::PageIterator.new('http://www.basecamp.com', opts) do |page|
  [page.url, page.title]
end
puts t.result.to_s
```

```sh
>> [["http://www.basecamp.com", "Basecamp is everyone’s favorite project management app."]]  
```  
Available methods on the page iterator:  
* **#url** - returns full URL of current page  
* **#source** - returns raw page source code  
* **#title** - returns html decoded verson of curent page title  
* **#desc** - returns html decoded verson of curent page meta description  
* **#h1**  - returns html decoded verson of current page's h1 tag  
* **#h2**  - returns html decoded verson of current page's h2 tag
* **#links** - returns array of all links on the page  
* **#parse_internal** - returns array of current page's internal (same host) links  
* **#parse_internal_visitable** - returns #parse_internal plus added filtering of only links that are visitable  
* **#parse_seo** - returns array of current page's html decoded title, desc, h1 and h2  
* **#parse_files** - returns array of downloaded files of type supplied as RR options (fileharvest options)  


Current Requirements
------------ 
em-synchrony  
ruby-progressbar  
bloomfilter-rb  
addressable  
htmlentities  

License
-------  
See included 'LICENSE' file. It's the MIT license.
