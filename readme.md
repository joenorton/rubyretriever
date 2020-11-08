RubyRetriever
==============
[![Gem Version](https://badge.fury.io/rb/rubyretriever.svg)](http://badge.fury.io/rb/rubyretriever)  [![Build Status](https://travis-ci.org/joenorton/rubyretriever.svg?branch=master)](https://travis-ci.org/joenorton/rubyretriever)  
  
By Joe Norton  

RubyRetriever is a Web Crawler, Scraper & File Harvester. Available as a command-line executable and as a crawling framework.

RubyRetriever (RR) uses asynchronous HTTP requests via [Eventmachine](https://github.com/eventmachine/eventmachine) & [Synchrony](https://github.com/igrigorik/em-synchrony) to crawl webpages *very quickly*. RR also uses a Ruby implementation of the [bloomfilter](https://github.com/igrigorik/bloomfilter-rb) in order to keep track of pages it has already crawled in a memory efficient manner.  

**v1.4.3 Update (3/24/2016)** - Fixes problem with file downloads that had query strings, the filename was being saved with the querystrings still attached. No more.

**v1.4.2 Update (3/24/2016)** - Fixes problem with named anchors (divs) being counted as links.

**v1.4.1 Update (3/24/2016)** - Update gemfile & external dependency versioning

**v1.4.0 Update (3/24/2016)** - Several bug fixes.


Mission  
-------
RubyRetriever aims to be the best command-line crawling and scraping package written in Ruby and a replacement for paid software such as Screaming Frog SEO Spider.    


Roadmap?  
Not sure. Feel free to offer your thoughts.  

Some Potential Ideas:  
* 'freeroam mode' - to go on cruising the net endlessly in fileharvest mode  
* 'dead-link finder' mode - collects links returning 404, or other error msgs    
* 'validate robots.txt' mode - outputs the bot-exposed sitemap of your site  
* more sophisticated SEO analysis? replace screaming frog? this would include checks for canonical URL, maybe some keyword density checks, content length checks, etc.    

Features  
--------  
* Asynchronous HTTP Requests thru EM & Synchrony  
* Bloom filter for tracking visited pages
* Supports HTTPS  
* Follows 301 redirects (if to same host)  
* 3 CLI modes  
	* Sitemap - Find all links on a website, output a valid XML sitemap, or just a CSV  
	* File Harvest - find all files linked to on a website, option to autodownload  
	* SEO  - collect important SEO info from every page, output to a CSV (or STDOUT)  
* Run a Custom Block on a Per-Page basis (PageIterator)  

Use cases  
---------
**As an Executable**  
With a single command at the terminal, RR can:  
1. Crawl your website and output a *valid XML sitemap* based on what it found.  
2. Crawl a target website and *download all files of a given filetype*.  
3. Crawl a target website, *collect important SEO information* such as page titles, meta descriptions and h1 tags, and write it to CSV.  

**Used in Custom scripts**  
As of version 1.3.0, with the PageIterator class you can pass a custom block that will get run against each page during a crawl, and collect the results in an array. This means you can define for yourself whatever it is you want to collect from each page during the crawl.  

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
$ rr --sitemap CSV --progress --limit 10 http://www.cnet.com
```  
OR -- SAME COMMAND  
```sh
$ rr -s csv -p -l 10 http://www.cnet.com
```  
  
This would map http://www.cnet.com until it crawled a max of 10 pages, then write the results to a CSV named cnet. Optionally, you could also use the format XML and RR would output the same URL list into a valid XML sitemap that could be submitted to Google.  
  
 **Example: File Harvesting mode**  
```sh
$ rr --files txt --verbose --limit 1 http://textfiles.com/programming/
```  
OR -- SAME COMMAND  
```sh
$ rr -f txt -v -l 1 http://textfiles.com/programming/
```  
  
This would crawl http://textfiles.com/programming/ looking for txt files for only a single page, then write out a list of filepaths to txt files to the terminal. Optionally, you could have the script autodownload all the files by adding the -a/--auto flag.

**Example: SEO mode**  
```sh
$ rr --seo --progress --limit 10 --out cnet-seo http://www.cnet.com
```  
OR -- SAME COMMAND  
```sh
$ rr -e -p -l 10 -o cnet-seo http://www.cnet.com
```  
  
This would go to http://www.cnet.com and crawl a max of 10 pages, during which it would collect the SEO fields on those pages - this currently means [url, page title, meta description, h1 text, h2 text]. It would then write the fields to a csv named cnet-seo.
  

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
  

Using as a Library (starting as of version 1.3.0)  
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
