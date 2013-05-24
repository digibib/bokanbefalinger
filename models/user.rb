# encoding: UTF-8

# -----------------------------------------------------------------------------
# user.rb - user/reviewer class
# -----------------------------------------------------------------------------
# Methods to log in and out user/reviewer

# TODO: don't pass session object around, rather return a hash and set session
#       variables in the route

class User

  def self.log_in(username, password, session)
    # Logs in usersand sets user session variables.
    # Returns two values: error/nil + authorized true/false

    # 1. Check username+password: api/users/authenticate
    params = {:username => username.downcase, :password => password.downcase}
    res = API.post(:authenticate, params) { |err| return err.message, false }
    return [nil, false] unless res["authenticated"]
    # user+pass OK, set session user
    session[:user] = username

    # 2. Get source via username: api/users name=x
    params = {:accountName => username}
    res = API.get(:users, params) { |err| return err.message, false }
    # set user session variables
    session[:source_uri] = res["reviewer"]["userAccount"]["accountServiceHomepage"]
    session[:name] = res["reviewer"]["name"]
    session[:user_uri] = res["reviewer"]["uri"]
    # store lists if any
    mylists = res["reviewer"]["userAccount"]["myLists"]

    # 3. Get source api_key: api/sources source=x (or preferably from cache)
    res = Cache.get(session[:source_uri]) {
      headers = {:secret_session_key => Settings::SECRET_SESSION_KEY}
      params = {:uri => session[:source_uri]}
      res = API.get(:sources, params, headers) { |err| return err.message, false }
      Cache.set(session[:source_uri], res["source"])
      res["source"]
    }

    # Set user session variables
    session[:source_name] = res["name"]
    session[:source_homepage] = res["homepage"] || ""
    session[:api_key] = res["api_key"]
    session[:flash_info] = []
    session[:flash_error] = []
    session[:mylists] = []

    # 4. Populate mylists
    mylists.each do |list|
      res = API.get(:mylists, {:list => list}) { next }
      li = res["mylists"].first
      li["items"] = Array(li["items"]).map do |uri|
        r = Review.new(uri) { next }
        {"title" => r.book_title, "uri" => r.uri }
      end
      session[:mylists] << li
    end

    # Clear reviewer cache, to make sure we're not stuck with an old cached version
    Cache.del session[:user_uri], :reviewers

    return nil, true
  end

  def self.log_out(session)
    # Clear user session variables
    session.clear
  end

  def self.save(session, name, password, email)
    # Update user settings
    # Returns nil if success, error response if not

    params = {:api_key => session[:api_key],
            :uri => session[:user_uri],
            :accountName => email.downcase}
    params[:name] = name unless name.empty?
    params[:password] = password.downcase unless password.empty?

    res = API.put(:users, params) { |err| return err.message }

    # update user session variables
    session[:name] = res["reviewer"]["name"]
    session[:user] = res["reviewer"]["userAccount"]["accountName"]
    return nil
  end

end