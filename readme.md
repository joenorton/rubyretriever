 Ruby Retriever
 ==============

 EXAMPLE USE
 -----------
 
 **Site Mapper**
	test = Retriever::FetchSitemap.new(q, options)
 *Terminal:  ruby test.rb -v -l 1000 -o cnet http://www.cnet.com


 **File Harvesting**
	test = Retriever::FetchFiles.new(q, options)
*Teriminal:  ruby test.rb -v -ext exe -l 1000 -o cnet http://www.cnet.com