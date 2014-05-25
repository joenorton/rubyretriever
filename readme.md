Ruby Retriever  
==============

Web Crawler, Site Mapper, File Harvester, and all around nice buddy to have around.  
Written in Ruby  

requirements
------------ 
open-uri  
optparse  
uri  
csv  
em-synchrony  
em-synchrony/em-http  
em-synchrony/fiber_iterator  
ruby-progressbar  
  
EXAMPLE USE  
-----------
```sh
git clone http://github.com/joenorton/rubyretriever  
cd rubyretriever  
./rr [MODE] [OPTIONS] Target_URL  
```  
   
 **Site Mapper**  
```sh
./rr --sitemap --progress --limit 1000 --output cnet http://www.cnet.com
```  
OR -- SAME COMMAND  
```sh
./rr -s -p -l 1000 -o cnet http://www.cnet.com
```  
  
This would go to http://www.cnet.com and map it until it crawled a max of 1,000 pages, and then it would write it out to a csv named cnet.  
  
 **File Harvesting**  
```sh
./rr --fileharvest --ext exe --progress --limit 1000 --output cnet http://www.cnet.com
```  
OR -- SAME COMMAND  
```sh
./rr -fh -e exe -p -l 1000 -o cnet http://www.cnet.com
```  
  
This would go to http://www.cnet.com and crawl it looking for filetype:EXE until it crawled a max of 1,000 pages, and then it would write out a list of filepaths to a csv named cnet.  
  

command-line arguments
-----------------------
Usage: ./rr [MODE] [OPTIONS] Target_URL  

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
  
License
-------
GNU GPLv3 http://www.gnu.org/licenses/gpl.txt