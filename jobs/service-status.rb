require 'net/http'
require 'json'

SERVICES_NAMES = {
    "FR-COS" => "finrem-case-orchestration-service",
    "FR-NS" =>  "finrem-notification-service",
    "FR-DGCS" =>  "finrem-document-generator-client",
    "FR-EMCA" =>  "finrem-evidence-management-client",
    "FR-PS" =>  "finrem-payment-service"
}

def request_finrem_service_status(url)
  uri = URI(url)

  result = Net::HTTP.start(uri.host, uri.port) do |http|
    request = Net::HTTP::Get.new uri
    http.request request
  end

  if result
    return JSON.parse(result.body)
  end
  # If something wrong happened then tiles won't be refreshed.
  # puts 'An error occurred.'
  puts 'an error occurred'
  puts result.body
  # puts result
end

def filter_dependencies(result)
  return result.select {|service, val| service != 'refreshScope' and service != 'diskSpace' and service != 'hystrix' and service != 'status'}
end

def collect_all_dependencies(filter_services)
  return filter_services.map {|service, val| {
      'name' => service,
      'status' => get_status_text(val['status']),
      'url' => val['details'] ? val['details']['uri'] : val['uri']
  }}
end

def service_status(service)
  test_runs = request_finrem_service_status(SERVICES[service])
  result = test_runs['details'] ? test_runs['details'] : test_runs

  if result
    all_dependencies = collect_all_dependencies(filter_dependencies(result))
    puts 'depend services'
    puts  all_dependencies

    return {
        "name" => SERVICES_NAMES[service],
        "status" => get_status_text(test_runs['status']),
        "url" => SERVICES[service],
        "dependencies" => all_dependencies
    }
  end
end
