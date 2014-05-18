Ruby Retriever  
==============

Web Crawler, Site Mapper, Filve Harvester, and all around nice buddy to have around.  
Created by Joe Norton  
  
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