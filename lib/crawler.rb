class Crawler

  def initialize(args)
    # Initialize method when a new crawler is created
    @@opts = args
    @@opts[:errors] = {
      invaliduri: "ERROR: nil value specified for URL",
      type: "ERROR: not a valid URL",
      socket: "ERROR: unable to connect to URL",
      generic: "ERROR: undefined exception",
      argument: "ERROR: could not parse UTF-8 characters"
    }
  end

  def crawl
    # main method, calls 'process_url' on every URL in the queue
    opts[:url_queue].push check(opts[:base_url])
    opts[:url_queue].each do |url|
      page = process_url(url)
      opts[:urls_crawled].push page.url
      opts[:pages].push page
    end
    print_crawl_stats
  end

  def process_url(url)
    # calls 'request_page' on a URL and calls 'get_links' on the page returned
    # then it extracts all the links and then sends each link to 'queue_link' unless 
    # 'bad_page' returns true
    return if url.size > 200
    puts "Processing #{url}" if opts[:args][:verbose]
    page = Nokogiri::HTML(request_page(url))
    unless bad_page(page.text)
      page_hash = parse_page(page, url)
      page = Page.new(page_hash) if page_hash
    end
    return page
  end

  def print_crawl_stats
    # prints statistics about the crawler
    puts "Crawled #{opts[:urls_crawled].count} pages.\n#{opts[:url_queue].count} pages in queue."
  end

  def opts
    # Simply returns the crawlers options hash
    @@opts
  end

  private

    def request_page(url)
      # Primary HTTP requestor method, folows redirects and 
      # passes exceptions to 'errors' it always returns something
      begin
        uri = URI.parse(url)
        response = Net::HTTP.get_response(uri)
        if response.code == "301"
          puts "HTTP response: #{response.code}" if opts[:args][:debug]
          uri = URI.parse(response.header['location'])
          response = Net::HTTP.get_response(uri)
        end
        if response.code == "200" && response.header['content-type'] == "text/html"
          return response.body
        end
        puts "Not requesting #{url}" if opts[:args][:debug]
      rescue StandardError => msg
        return errors(msg)
      end
    end

    def errors(msg)
      # Method used to handle exceptions in all begin/rescue statements
      # will return the string value stored in the 'opts[:errors]' hash
      case msg.class
      when URI::InvalidURIError
        opts[:errors][:invaliduri]
      when TypeError
        opts[:errors][:type]
      when SocketError
        opts[:errors][:socket]
      when ArgumentError
        opts[:errors][:argument]
      else
        opts[:errors][:generic]
      end
    end

    def parse_page(page, url)
      # extracts acctuall content (not code) from a page and performs normilizaiton
      # on all the words to determine the top 10 terms on a particular page
      begin
        get_links(url,page.css('a')).each { |link|  queue_link(link)}
        words = Array.new
        page_hash = Hash.new
        page.search('//text()').map(&:text).each do |chunk|
          chunk.split(' ').each { |word|
            word = good_word(word.downcase)
            words << word if word 
          }
        end
        words.delete_if { |x| hassymbols(x) }
        word_count = count_words(words)
        page_hash[:key_words] = word_count.sort_by { |word, count| count }[-20..-1].reverse
        page_hash[:meta_description] = page.xpath("//meta[@name='description']/@content").text
        page_hash[:url] = url
        binding.pry
        return page_hash
      rescue StandardError => msg
        return
      end
    end

    def bad_page(text)
      # checks a page.text for an error message
      opts[:errors].each do |key, value|
        if text == value
          return true
        end
      end
      # checks a page.text for nothing
      if text == ""
        return true
      end
      return false
    end

    def good_word(word)
      # checks a word to ensure it is compliant with our standards, returns true
      # if it is
      if word.size < 4 || word.size > 30
        return nil
      elsif stop_word(just_the_word(word))
        return nil
      else
        return just_the_word(word)
      end
    end

    def just_the_word(word)
      # removes simple punctuation from the end of a word
      punctuation = ['.', ',', '?', '!', ':', ';', '\'', '’']
      punctuation.each { |x| word.gsub!(x, '') }
      return word
    end

    def stop_word(word)
      # checks for a basic list of stop_words to ignore every time, a more comprehensive
      # list will be added in later to really speed things up
      stop_words = [ "the", "and", "about", "are", "com", "for", "see",
        "from", "how", "that", "this", "was", "what", "you", "which",
        "when", "where", "who", "will", "with", "www", "out", "use",
        "all", "have", "more", "only", "your", "part", "been", "any",
        "now", "those", "div", "span", "new", "trn", "divn", "var", 
        "function", "like", "not", "get", "some", "posted", "can", 
        "there", "very", "their", "else", "has", "january", "february", 
        "march", "april", "may", "june", "july", "august", "september", 
        "october", "november", "december", "than", "here", "were", "these", 
        "next", "they", "would", "know", "could", "while", "also", "every", 
        "dont", "back", "should", "good", "its", "since", "youre", "using", 
        "your", "over", "entire", "just", "each", "ever", "along", "going", 
        "really", "come", "lets" ]
      return true if stop_words.include? word
      return true if word.to_i > 0
    end

    def hassymbols(word)
      # removes non alphanumeric characters from a word
      symbols = [ '@', '#', '$', '%', '^', '&', '*', '(', ')', 
       '_', '+', '-', '=', '{', '}', '|', '[', ']', '\\', ':', ';',
       '"', '<', '>', '/', '…' ]
       symbols.each { |symbol| return true if word.include?(symbol)}
       return false
    end

    def count_words(words)
      # returns a hash containing each word and how many times it shows up
      words.each_with_object(Hash.new(0)) { |word,count| count[word] += 1 }
    end

    def get_links(url,links)
      # processes all of the links from a URL and runs various checks
      # to ensure the final result is a full URL with http/https etc
      # i.e https://www.pentestgeek.com/  it also calls 'root_url',
      # 'relativepath' and 'check' which all help to qualify a link
      clean = Array.new
      links = links.map { |link| link.attr('href') }
      links.uniq.each do |link|
        if link.nil?
          next
        elsif link[0..1] == '//'
          next
        elsif link.size > 200
          next
        elsif link[0]. == '?'
          next
        elsif link.include?('#')
          next
        elsif link[0] == '/'
          link = root_url(url,link)
        elsif relative_path(link)
          link = url + link
        end
        clean << check(link)
      end
      return clean.uniq
    end

    def root_url(url,link)
      # turns /index.html into http://www.website.com/index.hml
      return url.split('/')[0..2].join('/') + link
    end

    def relative_path(link)
      # handles links that don't lead off with a / for example
      # 'viewcontent.php'
      case link.split('/')[0]
      when 'http:'
        return false
      when 'https:'
        return false
      end
      if link[0] == '/'
        return false
      end
      return true
    end

    def check(link)
      # always adds '/' to the end of a toplevel domain link if not present already
      # i.e http://www.site.com becomes 'http://www.site.com/'
      if link.split('.').size < 4 && link[-1] != '/'
        return link + '/'
      end
      return link
    end

    def queue_link(link)
      # Adds a URL to 'opts[:url_queue]' as long as it wasn't already crawled and isn't
      # already in the queue
      if opts[:urls_crawled].include? link
        return
      elsif opts[:url_queue].include? link
        return
      elsif dont_follow(link)
        return
      else
        opts[:url_queue].push link
      end
    end

    def dont_follow(link)
      extentions = [ 'jpg', 'jpeg', 'pdf', 'gif', 'js', 'png', 'docx', 'zip', 'doc', 
      'docx', 'xls', 'xlsx', 'txt', 'bmp' ]
      if extentions.include?(link.split('.')[-1].downcase)
        return true
      end
      return false
    end

end
