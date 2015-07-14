# Crawler
A simple webpage crawler to detect broken links

# Requirements
Ruby
Bundler

# Install
Copy project then go to the directory and run

    bundle install

# Run
Run the following in cmd

    ruby crawler.rb http://www.nature.com http://www.nature.com/openresearch nature
    
1st argument is the domain – crawler will only visit links that have this domain (I.e won’t bother checking links to other sites)

2nd argument is starting point URL

3rd is a check for certain text is present on the page, providing this argument is optional

Inside the script is a variable called @max_level – you can set this to how deep you want the crawler to go on. I planing to make this settable as an argument too but didn’t get round to doing it.
