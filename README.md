# Webcrawler.rb

This is purely an educational tool for practicing web crawling.  It
doesn't do anything very useful as is.

## Install
~~~
bundle install
~~~

## Help
~~~
[ # ] $ ./webcrawler.rb -h
./webcrawler.rb -h [host] -p [port]

    -t, --target [Website]           Website to crawl i.e www.site.com
    -d, --debug                      Enabled full debug mode, lots of output
    -v, --verbose                    Enables verbose output

[ # ] $
~~~

## Example Usage
~~~
[ # ] $ ./webcrawler.rb -v -t https://www.pentestgeek.com
Processing https://www.pentestgeek.com/
Processing http://www.pentestgeek.com/
Processing https://www.pentestgeek.com/about-us/
Processing https://www.pentestgeek.com/tools/
~~~