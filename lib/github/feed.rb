# Downloads the user feed and parses it.
# The block you pass downloads the feed for given user and this user's token
# gh = Github::Feed.new do
#   Github.get_feed user_name, token
# end
#
# gh.parse parses downloaded feed
#
# puts gh.entries[0..3].to_yaml

module Github
  require 'rexml/document'
  class Feed
    attr_reader :entries, :feed_content
    def initialize options={}
      @options = options
      @feed_content = yield if block_given?
      @feed_content =  Github.get_feed @options[:login], @options[:token]if @feed_content.nil?
      @entries = []
    end
## Interface functions ##

    def content feed=nil
      @feed_content = yield if block_given?
      @feed_content = feed unless feed.nil?
      @feed_content
    end

## Feed Parsing Functions ##

    # parses loaded feed contents into list of hashes
    # which are stores in memory cache (@entries)
    def parse(is_update=false)
      return nil unless @feed_content

      begin
        doc = REXML::Document.new(@feed_content)
      rescue => e
        puts e.to_yaml
      end
      entries = [].tap do | collection |
        doc.root.elements.select { |e| e.name =~ /entry/ }.each do | el |
          collection << el
        end
      end

      parsed = [].tap do | item |
        entries.each do | entry |
          _id = get_data_from_element(entry, 'id').gsub(/\D/, "")
          item << parse_entry(_id, entry)
        end
      end

      @entries = ( parsed + @entries ).uniq
    end

    def parse_and_update
      @feed_content = yield if block_given?
      @feed_content =  Github.get_feed @options[:login], @options[:token] unless block_given?
      parse true
    end

    # Parses one feed element into a entry containing all needed information
    # id must be retreived beforehand because of caching
    def parse_entry _id, entry
     {
        :gh_id => _id,
        :content => get_data_from_element(entry, 'content'),
        :title => get_data_from_element(entry, 'title'),
        :link => get_data_from_element(entry, 'link', :attribute, 'href'),
        :author => get_author(entry),
        :published => get_data_from_element(entry, 'published')
      }
    end


  private
    def get_data_from_element(element, name, func=:get_text, extra_param=nil)
      r=""
      element.elements.select {  | el | el.name =~ /#{name}/ }.each do | tag |
        # get_text doesn't require params, attribute does
        # probably this code should be clever and assume multiple attrs (which kinda does
        # through *operator)
        r = extra_param.nil? ? tag.send(func) : tag.send(func, extra_param)
      end
      "#{r}".strip # cast tag data to a string, so that we don't have REXML garbage
    end
    def get_author(entry)
      au = entry.elements.select { | el | el.name =~ /author/ }.map do | auth |
        {
          :name => get_data_from_element(auth, 'name'),
          :url => get_data_from_element(auth, 'uri')
        }
      end.first
    end
  end
end
