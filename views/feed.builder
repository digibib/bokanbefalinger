xml.instruct! :xml, :version => '1.0'
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Bokanbefalinger feed"
    xml.description "Feed fra bokanbefalinger.deichman.no"
    xml.link "http://anbefalinger.deichman.no/"
    
    result["works"].each do |work|
      review = work["reviews"].first
      xml.item do
        xml.title review["title"]
        xml.image work["cover_url"]
        xml.link "http://anbefalinger.deichman.no/anbefaling/#{review["uri"]}"
        xml.description review["text"]
        xml.pubDate Time.parse(review["created"].to_s).rfc822()
        xml.guid "anbefalinger.deichman.no/anbefaling/#{review["uri"]}"
      end
    end
  end
end
