require 'capybara'
require 'capybara/poltergeist'

include Capybara::DSL

@domain = 'http://www.nature.com'
Capybara.app_host = @domain
Capybara.run_server = false
Capybara.current_driver = :poltergeist

visit URI.encode('http://www.nature.com/openresearch/about-open-access/policies-journals/#Open access licensing')
p page.status_code
visit URI.encode("http://www.nature.com/openresearch/about-open-access/policies-journals/#Compliance with funders' open access mandates")
p page.status_code
visit URI.encode("http://www.nature.com/openresearch/about-open-access/policies-journals/#Compliance with funders' open access mandates")
p page.status_code
