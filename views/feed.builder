xml.instruct! :xml, :version => '1.0'
case
when format.include?('application/atom+xml')
  xml.feed :xmlns => "http://www.w3.org/2005/Atom", "xmlns:dc" => "http://purl.org/dc/elements/1.1/", "xmlns:media" => "http://search.yahoo.com/mrss/" do
    xml.title title || "Bokanbefalinger feed"
    xml.id url
    xml.updated Time.parse(result["works"].first["reviews"].first["issued"].to_s).xmlschema
    xml.subtitle "Atom Feed fra bokanbefalinger.deichman.no"
    xml.link(:rel => "self", :href => url)

    result["works"].each do |work|
      review = work["reviews"].first
      xml.entry do
        xml.title review["title"]
        xml.author do
          xml.name review["reviewer"]["name"]
          xml.uri review["reviewer"]["uri"]
        end
        xml.link(:href =>"http://anbefalinger.deichman.no/anbefaling/#{review['uri'][24..-1]}")
        xml.summary review["teaser"] if review["teaser"]
        xml.content review['text'], :type => "html"
        xml.link(:href => select_cover(work), :rel => "enclosure", :type=>"image/jpg") if select_cover(work)
        xml.updated Time.parse(review["issued"].to_s).xmlschema
        xml.id review["uri"]
      end
    end
  end
else
  xml.rss :version => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1/", "xmlns:media" => "http://search.yahoo.com/mrss/" do
    xml.channel do
      xml.title title || "Bokanbefalinger feed"
      xml.description "RSS Feed fra bokanbefalinger.deichman.no"
      xml.link "http://anbefalinger.deichman.no/"

      result["works"].each do |work|
        review = work["reviews"].first
        xml.item do
          xml.title review["title"]
          xml.link "http://anbefalinger.deichman.no/anbefaling/#{review["uri"][24..-1]}"
          if review['text'] and not review['text'].empty?
            xml.description review['text']
          else
            xml.description review['teaser']
          end
          xml.enclosure(:url=>"#{select_cover(work)}", :type=>"image/jpeg") if select_cover(work)
          xml.pubDate Time.parse(review["issued"].to_s).rfc822
          xml.guid review["uri"]
        end
      end
    end
  end
end
