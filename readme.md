[RubyRetriever] (http://softwarebyjoe.com/rubyretriever/)  
==============
[![Gem Version](https://badge.fury.io/rb/rubyretriever.svg)](http://badge.fury.io/rb/rubyretriever)  [![Build Status](https://travis-ci.org/joenorton/rubyretriever.svg?branch=master)](https://travis-ci.org/joenorton/rubyretriever)  
  
By Joe Norton  

RubyRetriever is a Web Crawler, Site Mapper, File Harvester & Autodownloader.  

RubyRetriever (RR) uses asynchronous HTTP requests, thanks to [Eventmachine](https://github.com/eventmachine/eventmachine) & [Synchrony](https://github.com/igrigorik/em-synchrony), to crawl webpages *very quickly*.  Another neat thing about RR, is it uses a ruby implementation of the [bloomfilter](https://github.com/igrigorik/bloomfilter-rb) in order to keep track of pages it has already crawled.  

**v1.0 Update (6/07/2014)** - Includes major code changes, a lot of bug fixes. Much better in dealing with redirects, and issues with the host changing, etc. Also, added the SEO mode -- which grabs a number of key SEO components from every page on a site. Lastly, this update was so extensive that I could not ensure backward compatibility -- and thus, this was update 1.0!  
mission  
-------
RubyRetriever aims to be the best command-line crawling, and scraping package written in Ruby.    

features  
--------  
* Asynchronous HTTP Requests thru EM & Synchrony  
* Bloom filter for tracking pages visited.  
* 3 CLI modes: 1) Sitemap, 2) File Harvest, 3) SEO   

use-cases  
---------
RubyRetriever can do multiple things for you, with a single command at the terminal RR can:  
1. Crawl your website and output a *valid XML sitemap* based on what it found.  
2. Crawl a target website and *download all files of a given filetype*.  
3. Crawl a target website and *collect important SEO information* such as page titles, meta descriptions, h1 tags, etc. and write it to CSV.  

Help & Forks Welcome!  
  
getting started   
-----------
Install the gem
```sh
gem install rubyretriever
```  

 **Example: Sitemap mode**  
```sh
rr --sitemap CSV --progress --limit 100 http://www.cnet.com
```  
OR -- SAME COMMAND  
```sh
rr -s csv -p -l 100 http://www.cnet.com
```  
  
This would go to http://www.cnet.com and map it until it crawled a max of 100 pages, and then it would write it out to a csv named cnet. Optionally, we can also use the format XML and then rubyretriever would output that same URL list into a valid XML sitemap that can be submitted to Google -- but that is not what this current example would do.  
  
 **Example: File Harvesting mode**  
```sh
rr --files pdf --progress --limit 1000 --out hubspot http://www.hubspot.com
```  
OR -- SAME COMMAND  
```sh
rr -f pdf -p -l 100 http://www.hubspot.com
```  
  
This would go to http://www.hubspot.com and crawl it looking for filetype:PDF until it crawled a max of 100 pages, and then it would write out a list of filepaths to a csv named hubspot (based on the website host name. Optionally we could have the script then go and autodownload all the files by adding the -a/--auto flag -- however this current example would just dump to stdout a list of all the PDF's found.

**Example: SEO mode**  
```sh
rr --seo --progress --limit 100 --out cnet-seo http://www.cnet.com
```  
OR -- SAME COMMAND  
```sh
rr -e -p -l 10 -o cnet-seo http://www.cnet.com
```  
  
This would go to http://www.cnet.com and crawl a max of 100 pages, during which it would be collecting the onpage SEO fields on those pages - currently this means [url, page title, meta description, h1 text, h2 text], and then it would write it out to a csv named cnet-seo.
  

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
  
Current Requirements
------------ 
em-synchrony  
ruby-progressbar  
bloomfilter-rb  

License
-------  
See included 'LICENSE' file. It's the MIT license.