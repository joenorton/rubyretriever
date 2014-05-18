Ruby Retriever  
==============

Web Crawler, Site Mapper, Filve Harvester, and all around nice buddy to have around.  
Created by Joe Norton  
  
command-line arguements
-----------------------
Usage: retriever.rb [options] Target_URL  
    -o, --out FILENAME               Dump output to selected filename  
    -v, --verbose                    Output more information  
    -l, --limit PAGE_LIMIT_#         set a max on the total number of crawled pages  
    -e, --ext FILE_EXTENSION         set a file extension to look for on crawled pages  
    -h, --help                       Display this screen  
  
EXAMPLE USE  
-----------
   
 **Site Mapper**  
 ```ruby
 test = Retriever::FetchSitemap.new(q, options)
 ```  
 *Terminal:  ruby test.rb -v -l 1000 -o cnet http://www.cnet.com*  
  
  
 **File Harvesting**  
```ruby
test = Retriever::FetchFiles.new(q, options)
```  
*Teriminal:  ruby test.rb -v -ext exe -l 1000 -o cnet http://www.cnet.com*  

test.rb
-------
Right now, the library relies on test.rb to collect options. Eventually a CLI class will be created so that this is unnecessary.  

License
-------
GNU GPLv3 http://www.gnu.org/licenses/gpl.txt