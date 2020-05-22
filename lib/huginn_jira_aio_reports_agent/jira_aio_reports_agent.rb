require 'addressable/uri'

module Agents
  class JiraAIOReportsAgent < Agent
    include WebRequestConcern
    include FormConfigurable

    description <<-MD
       The Jira Agent pull AIO report.
        
      `aio_url` is the address of the jira AIO Instance you want to trigger
    
      `aio_token` is the Rest API Token for the jira AIO Instance (Found under AIO Reports->My Reports->AIO API in jira)

      `aio_report_id` is the ID of the report generate by the system. (Under AIO Reports->My Reports->AIO API , click on the first endpoint)

      `format` format you wish to use.

      MD

    def default_options
      {
        'jira_url' => 'https://www.aioreports.com/aio-app',
        'jira_token' => 'YzM1M2M4MGYtNmNlZS00MGM3LWJiNTctMjAwODE5YjFhZDA1&ID=107564&format=json',
        'report_id' => '107564',
        'format' => 'json'
      }
    end

    form_configurable :jira_url, type: :text
    form_configurable :jira_token, type: :text
    form_configurable :report_id, type: :text
    form_configurable :format, type: :text

    SCHEMES = %w(http https)
    
    def valid_url?(url)
      parsed = Addressable::URI.parse(url) or return false
      SCHEMES.include?(parsed.scheme)
      rescue Addressable::URI::InvalidURIError
        false
    end
    
    def validate_options
      errors.add(:base, "jira URL Missing") unless options['jira_url'].present?
      errors.add(:base, "jira Task Missing") unless options['jira_token'].present?
      errors.add(:base, "Report ID Missing") unless options['report_id'].present?
      errors.add(:base, "Report Format Missing") unless options['format'].present?
    end

    def working?
      return false if recent_error_logs?
      
      if interpolated['expected_receive_period_in_days'].present?
        return false unless last_receive_at && last_receive_at > interpolated['expected_receive_period_in_days'].to_i.days.ago
      end
    end

    def check
      receive(interpolated)
    end

    def receive(incoming_events)
      incoming_events.each do |event|  
        handle(event)
      end
    end

    def handle(event)
      jira_url = interpolated(event)["jira_url"]+'/' + '/rest-api/report/export?token=' + ["jira_token"] + '&ID=' +  interpolated(event)["report_id"] + '&format=' + ["format"]
      if not valid_url?(jira_url)
        log("Invalid URL #{jira_url}")
        return
      end
        
      aio_headers = {'Content-Type'  => 'application/json; charset=utf-8', 'X-Api-Key' => interpolated(event)["jira_token"] }
      aio_body = ''
      response = faraday.run_request(:put, jira_url, aio_body, aio_headers)
      case response.status
        when 200
          log("Successfully Trigger Report Id  of AIO " + interpolated(event)["report_id"])
        when 401
          log("Invalid Authentication Token Body: #{response.body}")
          return  
        when 404
          log("AIO  Doesn't Exist: " + interpolated(event)["report_id"] + " Body: #{response.body}")
          return
        when 405 
          log("AIO is disabled:  " + interpolated(event)["report_id"] + " Body: #{response.body}")
          return
        else
          log("Invalid Response from jira: Status: #{response.status} Body: #{response.body}")
          return
      end
      if boolify(interpolated['report_id'])
        create_event payload: event.payload.merge(
          fisheeye_response: {
            body: response.body,
            headers: response.headers,
            status: response.status
          }
        )
      else
      create_event payload: {jira_response: {body: response.body, headers: response.headers, status: response.status}}
      end
    end
  end
end
