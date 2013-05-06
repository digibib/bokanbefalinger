## Application directory layout
```
├── app                      <b>torquebox processes (running indepedently)</b>
│   ├── jobs                 <strong>scheduled jobs</strong>
│   │   ├── feeds_job.rb       <em>recache feeds once per day</em>
│   │   └── latest_job.rb      fetch latest reviews each 15 min
│   ├── processors           message queue processors
│   │   └── cache_processor.rb process the re-caching queue
│   └── services             background jobs/deamons
├── config                   configuration
│   ├── settings.rb            application settings
│   └── torquebox.rb           torquebox settings
├── lib                      various application logic
│   ├── cache.rb               abstraction over cache layer
│   ├── formatting.rb          various string formatting helpers
│   ├── refresh.rb             cache reloading methods
│   └── vocabularies.rb        rdf prefixes
├── models                   main application logic
│   ├── init.rb                application globals, load all models
│   ├── list.rb                list class
│   ├── review.rb              review class
│   ├── user.rb                reviewer (user) class
│   └── work.rb                work class
├── public                   static content
│   ├── css                    styling
│   ├── img                    images
│   └── js                     javascript
├── routes                   application routes
│   ├── init.rb                load all routes
│   ├── feed.rb                /feed
│   ├── main.rb
│   ├── manifestation.rb
│   ├── reviews.rb
│   ├── user.rb                user interaction routes
│   └── works.rb
├── views                    template views
├── test                     tests
├── app.rb                     application entry point
├── config.ru                  rackup-file, picked up by torquebox server
├── Gemfile                    dependencies
├── Gemfile.lock
├── Rakefile                   rake tasks
└── README.md                  basic info
```