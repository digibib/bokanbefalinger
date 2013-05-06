## Application directory layout
<pre>
├── <b>app</b>                        <b>torquebox processes (running independently)</b>
│   ├── <b>jobs</b>                   <b>scheduled jobs (cronjobs)</b>
│   │   ├── feeds_job.rb         <em>refresh feed caches once per day</em>
│   │   └── latest_job.rb        <em>refresh latest reviews every 15 min</em>
│   ├── <b>processors</b>             <b>message queue processors</b>
│   │   └── cache_processor.rb   <em>process the re-caching queue</em>
│   └── <b>services</b>               <b>background jobs/deamons</b>
├── <b>config</b>                     <b>configuration</b>
│   ├── settings.rb              <em>application settings</em>
│   └── torquebox.rb             <em>torquebox settings</em>
├── <b>lib</b>                        <b>various application logic</b>
│   ├── cache.rb                 <em>abstraction over cache layer</em>
│   ├── formatting.rb            <em>various string formatting helpers</em>
│   ├── refresh.rb               <em>cache reloading methods</em>
│   └── vocabularies.rb          <em>RDF prefixes</em>
├── <b>models</b>                     <b>main application logic</b>
│   ├── init.rb                  <em>application globals, load all models</em>
│   ├── list.rb                  <em>list class</em>
│   ├── review.rb                <em>review class</em>
│   ├── user.rb                  <em>reviewer (user) class</em>
│   └── work.rb                  <em>work class</em>
├── <b>public</b>                     <b>static content</b>
│   ├── css                      <em>styling</em>
│   ├── img                      <em>images</em>
│   └── js                       <em>javascript</em>
├── <b>routes</b>                     <b>application routes</b>
│   ├── init.rb                  <em>load all routes</em>
│   ├── feed.rb                  <em>feed routes (RSS)</em>
│   ├── main.rb
│   ├── manifestation.rb
│   ├── reviews.rb               <em>main review routes</em>
│   ├── user.rb                  <em>user interaction routes</em>
│   └── works.rb
├── <b>views</b>                      <b>template views</b>
├── <b>test</b>                       <b>tests</b>
├── app.rb                     <em>application entry point</em>
├── config.ru                  <em>rackup-file, picked up by torquebox server</em>
├── Gemfile                    <em>dependencies</em>
├── Gemfile.lock
├── Rakefile                   <em>rake tasks</em>
└── README.md                  <em>basic info</em>
</pre>