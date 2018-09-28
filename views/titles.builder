xml.instruct! :xml, :version => '1.0'
case
when format.include?('application/atom+xml')
  xml.feed :xmlns => "http://www.w3.org/2005/Atom", "xmlns:dc" => "http://purl.org/dc/elements/1.1/", "xmlns:media" => "http://search.yahoo.com/mrss/" do
    xml.title title || "Nye titler på Deichman"
    xml.id url
    xml.updated Time.parse(result.first[:created]).xmlschema
    xml.subtitle "Atom feed med siste titler i katalogen"
    xml.link(:rel => "self", :href => url)

    result.each do |book|
      xml.entry do
        xml.title book[:creator] ? "#{book[:creator].first.to_s} - #{book[:title].first.to_s}" : "#{book[:title].first.to_s}"
        if book[:description]
          xml.description book[:description].first.to_s
        end
        if book[:image]
          xml.media :title, "bokomslag"
          xml.media :thumbnail, :url=>"#{book[:image].first.to_s}"
          xml.link(:href => book[:image].first.to_s, :rel => "enclosure", :type=>"image/jpg")
        end
        xml.id book[:uri]
      end
    end
  end
else
  xml.rss :version => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1/", "xmlns:media" => "http://search.yahoo.com/mrss/" do
    xml.channel do
      xml.title title || "Nye titler på Deichman"
      xml.description "RSS feed med siste titler i katalogen"
      xml.link "http://anbefalinger.deichman.no/nye_titler"

      result.each do |book|
        xml.item do
          xml.title book[:creator] ? "#{book[:creator].first.to_s} - #{book[:title].first.to_s}" : "#{book[:title].first.to_s}"
          if book[:description]
            xml.description book[:description].first.to_s
          end
          xml.enclosure(:url=>"#{book[:image].first.to_s}", :type=>"image/jpeg") if book[:image]
          xml.pubDate Time.parse(book[:created].first.to_s).rfc822
          xml.link book[:uri]
          xml.guid book[:uri]
        end
      end
    end
  end
end
