# encoding: utf-8

class BokanbefalingerApp < Sinatra::Application

  get "/verk/*" do
    path = params[:splat].first
    redirect request.path.chop if request.path =~ /\/$/
    create_new = false

    if path =~ /\/ny$/
      # create a new review
      work = path[0..-4]
      redirect "/verk/"+work unless session[:user]
      create_new = true
    else
      work = path
      # show book info and reviews if any
    end

    work_id = "http://data.deichman.no/work/"+work
    @error_message, @work = Work.get(work_id)

    if @error_message
      @title ="Feil"
      erb :error
    elsif create_new
      @title = "Skriv ny anbefaling"
      erb :ny
    else
      @title = @work["title"]
      erb :work
    end
  end

  get "/work_by_isbn/" do
    halt 404 unless work = Work.find_by_isbn(params[:isbn])

    work
  end

end