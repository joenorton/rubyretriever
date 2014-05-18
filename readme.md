Ruby Retriever  
==============

Web Crawler, Site Mapper, Filve Harvester, and all around nice buddy to have around.  
Created by Joe Norton  

requirements
------------
ruby  
nokogiri  
open-uri  
optparse  
uri  
csv  
  
command-line arguements
-----------------------
Usage: retriever.rb [options] Target_URL  
    -o, --out FILENAME               Dump output to selected filename  
    -v, --verbose                    Output more information  
    -l, --limit PAGE_LIMIT_#         set a max on the total number of crawled pages  
    -e, --ext FILE_EXTENSION         set a file extension to look for on crawled pages  
    -h, --help                       Display this screen  
  
test.rb
-------
Right now, the library relies on test.rb to collect options. Eventually a CLI class will be created so that this is unnecessary. I recommend just running things thru it for right now using the below example commands  
  
EXAMPLE USE  
-----------
   
 **Site Mapper**  
```sh
ruby test.rb -v -l 1000 -o cnet http://www.cnet.com
```  
  
This would go to http://www.cnet.com and map it until it crawled a max of 1,000 pages, and then it would write it out to a csv named cnet.  
  
 **File Harvesting**  
```sh
ruby test.rb -v -ext exe -l 1000 -o cnet http://www.cnet.com
```  
  
This would go to http://www.cnet.com and crawl it looking for filetype:EXE until it crawled a max of 1,000 pages, and then it would write out a list of filepaths to a csv named cnet.  
  
License
-------
GNU GPLv3 http://www.gnu.org/licenses/gpl.txt