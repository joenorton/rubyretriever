[RubyRetriever] (http://www.softwarebyjoe.com/rubyretriever/)  
==============
[![Gem Version](https://badge.fury.io/rb/rubyretriever.svg)](http://badge.fury.io/rb/rubyretriever)  [![Build Status](https://travis-ci.org/joenorton/rubyretriever.svg?branch=master)](https://travis-ci.org/joenorton/rubyretriever)  
  
By Joe Norton  

RubyRetriever is a Web Crawler, Site Mapper, File Harvester & Autodownloader, and all around nice buddy to have around.  

RubyRetriever uses aynchronous HTTP requests, thanks to eventmachine and Synchrony fibers, to crawl webpages *very quickly*.  

RubyRetriever does NOT respect robots.txt, and RubyRetriever currently - by default - launches up to 10 parallel GET requests at once. This is a feature, do not abuse it. Use at own risk.  

  
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
rr --files pdf --progress --limit 1000 --output hubspot http://www.hubspot.com
```  
OR -- SAME COMMAND  
```sh
rr -f pdf -p -l 1000 http://www.hubspot.com
```  
  
This would go to http://www.hubspot.com and crawl it looking for filetype:PDF until it crawled a max of 1,000 pages, and then it would write out a list of filepaths to a csv named hubspot (based on the website host name. Optionally we could have the script then go and autodownload all the files by adding the -a/--auto flag -- however this current example would just dump to stdout a list of all the PDF's found.
  

command-line arguments
-----------------------
Usage: rr [MODE FLAG] [OPTIONS] Target_URL  

Where MODE FLAG is required, and is either:  
	-s, --sitemap FORMAT  (only accepts CSV or XML atm)  
	-f, --files FILETYPE  
  
and OPTIONS is the applicable:  
    -o, --out FILENAME                  *Dump output to selected filename --being phased out*  
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