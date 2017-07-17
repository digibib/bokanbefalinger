# encoding: UTF-8

# -----------------------------------------------------------------------------
# settings.rb - application settings
# -----------------------------------------------------------------------------

module Settings

  # External data sources:

  SPARQL = "http://virtuoso:8890/sparql/"
  SPARUL = "http://virtuoso:8890/sparql-auth/"
  USER = "dba"
  PASSWORD = "dba"
  AUTH_METHOD = "digest"
  SECRET_SESSION_KEY = ENV['SECRET_SESSION_KEY']
  API = "http://api:9393/api/"
  GRAPHS = {:review => "http://data.deichman.no/reviews",
            :book => "lsext",
            :api => "http://data.deichman.no/sources",
            :base => "http://data.deichman.no" }

  # Formatting:

  REVIEWS_PER_PAGE = 25

  # Contents:

  EXAMPLEFEEDS =
  [{:title => "Anbefalinger av bøker for voksne",
    :feed => "http://anbefalinger.deichman.no/feed?audience=http%3A%2F%2Fdata.deichman.no%2Faudience#adult"},
   {:title => "Anbefalinger av bøker for barn og ungdom",
   :feed => "http://anbefalinger.deichman.no/feed?audience=http%3A%2F%2Fdata.deichman.no%2Faudience#juvenile&audience=http%3A%2F%2Fdata.deichman.no%2Faudience#ages0to2&audience=http%3A%2F%2Fdata.deichman.no%2Faudience#ages3to5&audience=http%3A%2F%2Fdata.deichman.no%2Faudience#ages6to8&audience=http%3A%2F%2Fdata.deichman.no%2Faudience#ages9to10&audience=http%3A%2F%2Fdata.deichman.no%2Faudience#ages11to12&audience=http%3A%2F%2Fdata.deichman.no%2Faudience#ages13to15"},
   {:title => "Anbefalte fantasybøker for barn og ungdom",
    :feed => "http://anbefalinger.deichman.no/feed?audience=http%3A%2F%2Fdata.deichman.no%2Faudience%23juvenile&audience=http%3A%2F%2Fdata.deichman.no%2Faudience%23ages3To5&audience=http%3A%2F%2Fdata.deichman.no%2Faudience%23ages6To8&audience=http%3A%2F%2Fdata.deichman.no%2Faudience%23ages9To10&audience=http%3A%2F%2Fdata.deichman.no%2Faudience%23ages11To12&audience=http%3A%2F%2Fdata.deichman.no%2Faudience%23ages13To15&genres=http%3A%2F%2Fdata.deichman.no%2Fgenre%2Fg10313500&genres=http%3A%2F%2Fdata.deichman.no%2Fgenre%2Fg25345100"},
   {:title => "Anbefalte bøker på nynorsk",
    :feed => "http://anbefalinger.deichman.no/feed?languages=http%3A%2F%2Flexvo.org%2Fid%2Fiso639-3%2Fnno"},
   {:title => "Tynne bøker (under 200 sider) for voksne",
    :feed => "http://anbefalinger.deichman.no/feed?audience=http%3A%2F%2Fdata.deichman.no%2Faudience#adult&pagesfrom=0&pagesto=200"},
   {:title => "Anbefalinger av Karin Fossums krimbøker",
     :feed => "http://anbefalinger.deichman.no/feed?authors=http%3A%2F%2Fdata.deichman.no%2Fperson%2Fh26297400&genres=http%3A%2F%2Fdata.deichman.no%2Fgenre%2Fg12533800"},
   {:title => "Anbefalinger av bøker om Henrik Ibsen",
   :feed => "http://anbefalinger.deichman.no/feed?persons=http%3A%2F%2Fdata.deichman.no%2Fperson%2Fh14668800"},
   {:title => "Bøker av amerikanske forfattere",
    :feed => "http://anbefalinger.deichman.no/feed?nationalities=http%3A%2F%2Fdata.deichman.no%2Fnationality#am"},
   {:title => "Anbefalte engelske bøker",
    :feed =>  "http://anbefalinger.deichman.no/feed?languages=http%3A%2F%2Flexvo.org%2Fid%2Fiso639-3%2Feng"},
   {:title => "Anbefalte julebøker",
   :feed => "http://anbefalinger.deichman.no/feed?subjects=http%3A%2F%2Fdata.deichman.no%2Fsubject%2Fsa2866cd6efaa65c92278d4771a9eaec7&subjects=http%3A%2F%2Fdata.deichman.no%2Fsubject%2Fs2c434a7ab7f3e76f25f3cc9b0ce39d09&subjects=http%3A%2F%2Fdata.deichman.no%2Fsubject%2Fsa6275c0ce7b7b9526120b084fb37a178"},
   {:title => "Anbefalte novellesamlinger",
   :feed => "http://anbefalinger.deichman.no/feed?formats=http%3A%2f%2fdata.deichman.no%2fliteraryForm#shortStory"}]
end
