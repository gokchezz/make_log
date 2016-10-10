require 'json'

def save_results(root_path, device, case_count, start_time, fails_count, report_file_path)
  result_hash = {
      :date => Time.now.strftime('%d.%m.%Y'),
      :device => device,
      :case_count => case_count,
      :start_time => Time.parse(start_time),
      :end_time => Time.now.strftime('%H:%M:%S'),
      :fails_count => fails_count,
      :report_file => report_file_path
  }
  if Dir["#{root_path}/results.json"].length == 0
    FileUtils.mkdir_p(root_path)
    file = File.new("#{root_path}/results.json", 'w')
    file.puts("[#{JSON.pretty_generate(result_hash)}]")
    file.close
  else
    json = File.read("#{root_path}/results.json")
    json_hash = JSON.parse(json)
    same_test = false
    json_hash.each do |j|
      if (j['date'] == result_hash[:date]) && (j['device'] == result_hash[:device])
        same_test = true
        j.replace(result_hash)
      end
    end
    json_hash << result_hash if !same_test
    File.open("#{root_path}/results.json",'w') do |f|
      f.puts JSON.pretty_generate(json_hash)
    end
  end
end