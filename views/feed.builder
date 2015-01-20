xml.instruct! :xml, :version => '1.0'
case
when format.include?('application/atom+xml')
  xml.feed :xmlns => "http://www.w3.org/2005/Atom", "xmlns:dc" => "http://purl.org/dc/elements/1.1/", "xmlns:media" => "http://search.yahoo.com/mrss/" do
    xml.title title || "Bokanbefalinger feed"
    xml.id url
    xml.updated Time.parse(result.first.issued.to_s).xmlschema
    xml.subtitle "Atom Feed fra bokanbefalinger.deichman.no"
    xml.link(:rel => "self", :href => url)

    result.each do |review|
      xml.entry do
        xml.title "#{review.book_title} av #{review.book_authors.map { |a| a["name"] }.join(', ')}"
        xml.author do
          xml.name review.reviewer["name"]
          xml.uri review.reviewer["uri"]
        end
        xml.link(:href =>"http://anbefalinger.deichman.no/anbefaling/#{review.uri[24..-1]}")
        xml.summary review.teaser if review.teaser and not review.teaser.empty?
        xml.content review.text, :type => "html"
        if review.book_cover do
          xml.media :title, "bokomslag"
          xml.media :thumbnail, :url=>"#{review.book_cover}"
          xml.link(:href => review.book_cover, :rel => "enclosure", :type=>"image/jpg")
        end
        xml.updated Time.parse(review.issued.to_s).xmlschema
        xml.id "http://anbefalinger.deichman.no/anbefaling/#{review.uri[24..-1]}"
      end
    end
  end
else
  xml.rss :version => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1/", "xmlns:media" => "http://search.yahoo.com/mrss/" do
    xml.channel do
      xml.title title || "Bokanbefalinger feed"
      xml.description "RSS Feed fra bokanbefalinger.deichman.no"
      xml.link "http://anbefalinger.deichman.no/"

      result.each do |review|
        xml.item do
          xml.title "#{review.book_title} av #{review.book_authors.map { |a| a["name"] }.join(', ')}"
          xml.link "http://anbefalinger.deichman.no/anbefaling/#{review.uri[24..-1]}"
          if review.text and not review.text.empty?
            xml.description review.text
          else
            xml.description review.teaser
          end
          xml.enclosure(:url=>"#{review.book_cover}", :type=>"image/jpeg") if review.book_cover
          xml.pubDate Time.parse(review.issued.to_s).rfc822
          xml.author "#{review.reviewer['name']} / #{review.source['name']}"
          xml.guid "http://anbefalinger.deichman.no/anbefaling/#{review.uri[24..-1]}"
        end
      end
    end
  end
end
