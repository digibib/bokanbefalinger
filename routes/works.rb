# encoding: utf-8

class BokanbefalingerApp < Sinatra::Application

  get "/verk/*" do
    path = params[:splat].first

    if path =~ /\/ny$/
      # create a new review
      work = path[0..-4]
    else
      work = path
      # show book info and reviews if any
    end

    work_id = "http://data.deichman.no/work/"+work
    @work, @error_message = Work.get(work_id)

    if @error_message
      @title ="Feil"
      erb :error
    else
      @title = @work["title"]
      erb :work
    end
  end

end