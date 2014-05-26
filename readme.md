[RubyRetriever] (http://www.softwarebyjoe.com/rubyretriever/)  [![Gem Version](https://badge.fury.io/rb/rubyretriever.svg)](http://badge.fury.io/rb/rubyretriever)  
==============

By Joe Norton  

RubyRetriever is a Web Crawler, Site Mapper, File Harvester & Autodownloader, and all around nice buddy to have around.  

RubyRetriever uses aynchronous HTTP requests, thanks to eventmachine and Synchrony fibers, to crawl webpages *very quickly*.  

This is the 2nd or 3rd reincarnation of the RubyRetriever autodownloader project. It started out as a executable autodownloader, intended for malware research. From there it has morphed to become a more well-rounded web-crawler and general purpose file harvesting utility.  

RubyRetriever does NOT respect robots.txt, and RubyRetriever currently - by default - launches up to 10 parallel GET requests at once. This is a feature, do not abuse it. Use at own risk.

  
USAGE 
-----------
Install the gem
```sh
gem install rubyretriever
```  
   
 **Example: Sitemap mode**  
```sh
rr --sitemap --progress --limit 1000 --output cnet http://www.cnet.com
```  
OR -- SAME COMMAND  
```sh
rr -s -p -l 1000 -o cnet http://www.cnet.com
```  
  
This would go to http://www.cnet.com and map it until it crawled a max of 1,000 pages, and then it would write it out to a csv named cnet.  
  
 **Example: File Harvesting mode**  
```sh
rr --files --ext pdf --progress --limit 1000 --output hubspot http://www.hubspot.com
```  
OR -- SAME COMMAND  
```sh
rr -f -e pdf -p -l 1000 -o hubspot http://www.hubspot.com
```  
  
This would go to http://www.hubspot.com and crawl it looking for filetype:PDF until it crawled a max of 1,000 pages, and then it would write out a list of filepaths to a csv named hubspot, and then it would go ahead and try and download each of those files to a new 'rr-downloads' folder  
  

command-line arguments
-----------------------
Usage: rr [MODE] [OPTIONS] Target_URL  

Where MODE FLAG is either:  
	-s, --sitemap  
	-f, --files
  
and OPTIONS is the applicable:  
    -o, --out FILENAME                  *Dump output to selected filename*  
    -p, --progress						*Outputs a progressbar*  
    -v, --verbose                       *Output more information*  
    -l, --limit PAGE_LIMIT_#            *set a max on the total number of crawled pages*  
    -e, --ext FILE_EXTENSION            *set a file extension to look for on crawled pages*  
    -h, --help                          *Display this screen*  
  
Current Requirements
------------ 
em-synchrony  
ruby-progressbar  
bloomfilter-rb  

License
-------  
See included 'LICENSE' file. It's the MIT license.