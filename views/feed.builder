xml.instruct! :xml, :version => '1.0'
case 
when format.include?('application/rss+xml')
  xml.feed :version => "2.0", :xmlns => "http://www.w3.org/2005/Atom", "xmlns:dc" => "http://purl.org/dc/elements/1.1/", "xmlns:media" => "http://search.yahoo.com/mrss/" do
    xml.title "Bokanbefalinger feed"
    xml.description "Atom Feed fra bokanbefalinger.deichman.no"
    xml.link "http://anbefalinger.deichman.no/"
    
    result["works"].each do |work|
      review = work["reviews"].first
      xml.entry do
        xml.title review["title"]
        xml.author review["reviewer"]
        xml.link "http://anbefalinger.deichman.no/anbefaling/#{review['uri']}"
        #xml.summary review["teaser"]
        xml.content do
          xml.cdata! "<img src=\"#{work['cover_url']}\"/> #{review['text']}"
        end
        xml.updated Time.parse(review["created"].to_s).rfc822()
        xml.id "anbefalinger.deichman.no/anbefaling/#{review["uri"]}"
      end
    end    
  end
else
  xml.rss :version => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1/", "xmlns:media" => "http://search.yahoo.com/mrss/" do
    xml.channel do
      xml.title "Bokanbefalinger feed"
      xml.description "RSS Feed fra bokanbefalinger.deichman.no"
      xml.link "http://anbefalinger.deichman.no/"
      
      result["works"].each do |work|
        review = work["reviews"].first
        xml.item do
          xml.title review["title"]
          xml.summary review["teaser"]
          xml.image work["cover_url"]
          xml.link "http://anbefalinger.deichman.no/anbefaling/#{review["uri"]}"
          xml.description "<img src=\"#{work['cover_url']}\" align=\"left\" width=\"120\" /> #{review['text']}"
          xml.enclosure(:url=>"#{work['cover_url']}", :type=>"image/jpeg")
          xml.pubDate Time.parse(review["created"].to_s).rfc822()
          xml.guid "anbefalinger.deichman.no/anbefaling/#{review["uri"]}"
        end
      end
    end
  end
end
