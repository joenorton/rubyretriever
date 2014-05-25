RubyRetriever  
==============

Now an official RubyGem!
```sh
gem install rubyretriever  
```  

Web Crawler, Site Mapper, File Harvester & Autodownloader, and all around nice buddy to have around.  
Soon to add some high level scraping options.  

RubyRetriever uses aynchronous HTTP requests, thanks to eventmachine and Synchrony fibers, to crawl webpages *very quickly*.  

This is the 2nd or 3rd reincarnation of the RubyRetriever autodownloader project. It started out as a executable autodownloader, intended for malware research. From there it has morphed to become a more well-rounded web-crawler and general purpose file harvesting utility.  

RubyRetriever does NOT respect robots.txt, and RubyRetriever currently - by default - launches up to 10 parallel GET requests at once. This is a feature, do not abuse it. Use at own risk.

  
EXAMPLE USE  
-----------
```sh
gem install rubyretriever  
rr [OPTIONS] Target_URL  
```  
   
 **Site Mapper**  
```sh
rr --sitemap --progress --limit 1000 --output cnet http://www.cnet.com
```  
OR -- SAME COMMAND  
```sh
rr -s -p -l 1000 -o cnet http://www.cnet.com
```  
  
This would go to http://www.cnet.com and map it until it crawled a max of 1,000 pages, and then it would write it out to a csv named cnet.  
  
 **File Harvesting**  
```sh
rr --fileharvest --ext exe --progress --limit 1000 --output cnet http://www.cnet.com
```  
OR -- SAME COMMAND  
```sh
rr -fh -e exe -p -l 1000 -o cnet http://www.cnet.com
```  
  
This would go to http://www.cnet.com and crawl it looking for filetype:EXE until it crawled a max of 1,000 pages, and then it would write out a list of filepaths to a csv named cnet.  
  

command-line arguments
-----------------------
Usage: rr [MODE] [OPTIONS] Target_URL  

Where MODE FLAG is either:  
	-s, --sitemap  
	-fh, --fileharvest  
  
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

License
-------
GNU GPLv3 http://www.gnu.org/licenses/gpl.txt