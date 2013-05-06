# encoding: utf-8

class BokanbefalingerApp < Sinatra::Application

  get "/work_by_isbn/" do
    error, work = Work.by_isbn(params[:isbn].gsub(/[^0-9xX]/, ""))
    halt 404 if error

    work.to_json
  end

end