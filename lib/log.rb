require 'base64'

class Log
  def initialize(project_name, display_name)
    @index = 0
    @passed_scenarios = []
    @project_name = project_name
    @display_name = display_name
  end
  def get_index
    @index
  end
  def append_failure(number)
    report_row = ''
    report_row << '<tr><td colspan="2">'
    report_row << '<h3 style="font-family:verdana; color:red;">'
    report_row << "Failure ##{number}"
    report_row << '</h3>'
    report_row << '</td></tr>'
    report_row
  end
  def append_line(key, value)
    report_row = ''
    report_row << '<tr><td width="30%">'
    report_row << key
    if value == 'Passed'
      report_row << ' </td><td  style="color:green;">'
    else
      report_row << ':  </td><td width="70%">'
    end
    report_row << value
    report_row << '</td></tr>'
    report_row
  end
  def make_log(scenario, step_count, example_index, running_driver)
    failure_log = ''
    @scenario = scenario.test_steps[0].source[1]
    feature = scenario.test_steps[0].source[0]
    if @scenario.keyword == 'Scenario Outline'
      failed_step = @scenario.steps[step_count]
      examples = @scenario.examples_tables[0].example_rows[example_index-1]
      failed_step = examples.expand(failed_step.name)
    else
      failed_step = @scenario.children[step_count].name
    end
    error_message = scenario.exception.to_s.gsub(/[<>]/, '-')
    timestamp = "#{Time.now.strftime('%d%b')}"
    screenshot_name = "#{@index+1}_#{timestamp}_#{@scenario.name.gsub(' ', '_')}.png"
    screenshot_path = File.expand_path("tmp/#{screenshot_name}")
    if running_driver.nil?
      Capybara.page.save_screenshot(screenshot_path)
    elsif File.file?("#{running_driver}")
      screenshot_path = running_driver
    else
      running_driver.save_screenshot(screenshot_path)
    end
    @index += 1
    failure_log << append_failure(@index)
    failure_log << append_line('Feature name', feature.name)
    failure_log << append_line('Unable to', @scenario.name)
    failure_log << append_line('Failing step', failed_step)
    failure_log << append_line('Report html', %Q[<a href="http://192.168.2.173:8447/job/#{@project_name}/cucumber-html-reports/">Click here..</a>])
    failure_log << append_line('Rspec Error message', error_message)
    f = File.binread(screenshot_path)
    encripted_image = Base64.encode64(f).tr("\n", '')
    failure_log << append_line('Screenshot', %Q[<a href="data:image/png;base64,#{encripted_image}"><img height=120 src="data:image/png;base64,#{encripted_image}"></a>])
  end
  def append_success
    report_row = ''
    report_row << '<tr><td colspan="2">'
    report_row << '<h3 style="font-family:verdana; color:green;">'
    report_row << 'Passed Scenarios:'
    report_row << '</h3>'
    report_row << '</td></tr>'
    report_row
  end
  def append_passed_scenario(scenario)
    ast_scenario = scenario.test_steps[0].source[1]
    @passed_scenarios << ast_scenario
  end
  def finalize(report_body)
    if @passed_scenarios.length != 0
      report_body << append_success
      @passed_scenarios.each do |scenario|
        report_body << append_line(scenario.name, 'Passed')
      end
    end
    report_body << '</table></body></html>'
    date_stamp = "#{Time.now.strftime("%d%b")}"
    File.open(File.expand_path("../#{@project_name}/#{date_stamp}_#{@display_name.tr(' ', '_')}_result.html"), 'w+') {|f| f.write("#{report_body}") }
  end
end