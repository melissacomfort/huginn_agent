require 'addressable/uri'

module Agents
  class JiraAutoResponderAgent < Agent
    include WebRequestConcern

    description <<-MD
       The Jira Agent pull AIO report.
        
      - `issue_url` is the address of the issue in jira.
      - `username` and `password` are optional, and may need to be specified if your Jira instance is read-protected
      - `timeout` is an optional parameter that specifies how long the request processing may take in minutes.

      The agent does periodic queries and emits the events containing the updated issues in JSON format.

      NOTE: upon the first execution, the agent will fetch everything available by the JQL query. So if it's not desirable, limit the `jql` query by date.
    MD

    default_schedule "every_5m"
    MAX_EMPTY_REQUESTS = 10

    def default_options
      {
        'username' => '',
        'password' => '',
        'issue_url' => 'https://jira.atlassian.com/rest/api/2/issue/80127',
        'expected_update_period_in_days' => '7',
        'timeout' => '1'
      }
    end

    def validate_options
      errors.add(:base, "you need to specify password if user name is set") if options['username'].present? and not options['password'].present?
      errors.add(:base, "you need to specify your jira URL") unless options['jira_url'].present?
      errors.add(:base, "you need to specify the expected update period") unless options['expected_update_period_in_days'].present?
      errors.add(:base, "you need to specify request timeout") unless options['timeout'].present?
    end

    def working?
      event_created_within?(interpolated['expected_update_period_in_days']) && !recent_error_logs?
    end

    def check
      receive(interpolated)
    end

    private
    def receive(incoming_events)
      incoming_events.each do |event|
        handle(event)
      end
    end

    def handle(event)
      last_run = nil
      current_run = Time.now.utc.iso8601
      last_run = Time.parse(memory[:last_run]) if memory[:last_run]
      issues = get_issues(last_run)

      issues.each do |issue|
        updated = Time.parse(issue['fields']['updated'])

        # this check is more precise than in get_issues()
        # see get_issues() for explanation
        if not last_run or updated > last_run
          create_event :payload => issue
        end
      end

      memory[:last_run] = current_run
    end

    def request_url()
      "#{interpolated[:jira_url]}"
    end

    def request_options
      ropts = {headers: {"User-Agent" => user_agent}}

      if !interpolated[:username].empty?
        ropts = ropts.merge({:basic_auth => {:username => interpolated[:username], :password => interpolated[:password]}})
      end

      ropts
    end

    def get(url, options)
      response = HTTParty.get(url, options)

      if response.code == 400
        raise RuntimeError.new("Jira error: #{response['errorMessages']}")
      elsif response.code == 403
        raise RuntimeError.new("Authentication failed: Forbidden (403)")
      elsif response.code != 200
        raise RuntimeError.new("Request failed: #{response}")
      end

      response
    end

    def get_issues(since)
      startAt = 0
      issues = []

      start_time = Time.now

      request_limit = 0
      loop do
        response = get(request_url(), request_options)

        if response['issues'].length == 0
          request_limit += 1
        end

        if request_limit > MAX_EMPTY_REQUESTS
          raise RuntimeError.new("There is no progress while fetching issues")
        end

        if Time.now > start_time + interpolated['timeout'].to_i * 60
          raise RuntimeError.new("Timeout exceeded while fetching issues")
        end

        issues += response['issues']
        startAt += response['issues'].length

        break if startAt >= response['total']
      end

      issues
    end
  end
end
