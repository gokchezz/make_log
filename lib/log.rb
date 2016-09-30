require 'base64'

class Log
  def initialize(project_name, display_name)
    @index = 0
    @passed_scenarios = []
    @project_name = project_name
    @log = %Q[<html><head></head><body><table width="1000" align="center" border="0"><tr><td colspan="2" align="center">
    <h2 style="text-align:center; font-family:verdana;">#{display_name} Test Result</h2></td></tr>]
    @display_name = display_name
  end
  def get_index
    @index
  end
  def append_failure(number)
    @log << '<tr><td colspan="2">'
    @log << '<h3 style="font-family:verdana; color:red;">'
    @log << "Failure ##{number}"
    @log << '</h3>'
    @log << '</td></tr>'
  end
  def append_line(key, value)
    @log << '<tr><td width="30%">'
    @log << key
    if value == 'Passed'
      @log << ' </td><td  style="color:green;">'
    else
      @log << ':  </td><td width="70%">'
    end
    @log << value
    @log << '</td></tr>'
  end
  def make_log(scenario, step_count, example_index, running_driver)
    @scenario = scenario.test_steps[0].source[1]
    feature = scenario.test_steps[0].source[0]
    if @scenario.keyword == 'Scenario Outline'
      failed_step = @scenario.steps[step_count]
      examples = @scenario.examples_tables[0].example_rows[example_index-1]
      failed_step = examples.expand(failed_step.name)
    else
      failed_step = @scenario.children[step_count].name
    end
    error_message = scenario.exception.to_s
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
    append_failure(@index)
    append_line('Feature name', feature.name)
    append_line('Unable to', @scenario.name)
    append_line('Failing step', failed_step)
    append_line('Report html', %Q[<a href="http://192.168.2.173:8447/job/#{@project_name}/cucumber-html-reports/">Click here..</a>])
    append_line('Rspec Error message', error_message)
    f = File.binread(screenshot_path)
    encripted_image = Base64.encode64(f).tr("\n", '')
    append_line('Screenshot', %Q[<a href="data:image/png;base64,#{encripted_image}"><img height=120 src="data:image/png;base64,#{encripted_image}"></a>])
  end
  def append_success
    @log << '<tr><td colspan="2">'
    @log << '<h3 style="font-family:verdana; color:green;">'
    @log << 'Passed Scenarios:'
    @log << '</h3>'
    @log << '</td></tr>'
  end
  def append_passed_scenario(scenario)
    ast_scenario = scenario.test_steps[0].source[1]
    @passed_scenarios << ast_scenario
  end
  def finalize
    if @passed_scenarios.length != 0
      append_success
      @passed_scenarios.each do |scenario|
        append_line(scenario.name, 'Passed')
      end
    end
    @log << '</table></body></html>'
    date_stamp = "#{Time.now.strftime("%d%b")}"
    File.open(File.expand_path("../#{@project_name}/#{date_stamp}_#{@display_name.tr(' ', '_')}_result.html"), 'w+') {|f| f.write("#{@log}") }
  end
end