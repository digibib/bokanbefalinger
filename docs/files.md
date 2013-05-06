## Application directory layout
<pre>
├── <b>app</b>                   torquebox processes (running indepedently)
│   ├── <b>jobs</b>              scheduled jobs
│   │   ├── feeds_job.rb         <em>recache feeds once per day</em>
│   │   └── latest_job.rb        <em>fetch latest reviews each 15 min</em>
│   ├── <b>processors</b>        message queue processors
│   │   └── cache_processor.rb   <em>process the re-caching queue</em>
│   └── <b>services</b>          background jobs/deamons
├── <b>config</b>                configuration
│   ├── settings.rb              <em>application settings</em>
│   └── torquebox.rb             <em>torquebox settings</em>
├── <b>lib</b>                   various application logic
│   ├── cache.rb                 <em>abstraction over cache layer</em>
│   ├── formatting.rb            <em>various string formatting helpers</em>
│   ├── refresh.rb               <em>cache reloading methods</em>
│   └── vocabularies.rb          <em>rdf prefixes</em>
├── <b>models</b>                main application logic
│   ├── init.rb                  <em>application globals, load all models</em>
│   ├── list.rb                  <em>list class</em>
│   ├── review.rb                <em>review class</em>
│   ├── user.rb                  <em>reviewer (user) class</em>
│   └── work.rb                  <em>work class</em>
├── <b>public</b>                static content
│   ├── css                      <em>styling</em>
│   ├── img                      <em>images</em>
│   └── js                       <em>javascript</em>
├── <b>routes</b>                application routes
│   ├── init.rb                  <em>load all routes</em>
│   ├── feed.rb                  <em>/feed</em>
│   ├── main.rb
│   ├── manifestation.rb
│   ├── reviews.rb
│   ├── user.rb                  <em>user interaction routes</em>
│   └── works.rb
├── <b>views</b>                 template views
├── <b>test</b>                  tests
├── app.rb                       <em>application entry point</em>
├── config.ru                    <em>rackup-file, picked up by torquebox server</em>
├── Gemfile                      <em>dependencies</em>
├── Gemfile.lock
├── Rakefile                     <em>rake tasks</em>
└── README.md                    <em>basic info</em>
</pre>