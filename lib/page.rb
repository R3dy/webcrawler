class Page
  
  attr_accessor :url, :meta_description, :key_words

  def initialize(args)
    # initialize a new page
    self.url = args[:url]
    self.meta_description = args[:meta_description]
    self.key_words = args[:key_words]
  end

end