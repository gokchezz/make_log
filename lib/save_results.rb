require 'json'

def create_results_json(root_path, result_hash)
  FileUtils.mkdir_p(root_path)
  file = File.new("#{root_path}/results.json", 'w')
  file.puts("[#{JSON.pretty_generate(result_hash)}]")
  file.close
end

def save_results(root_path, device, case_count, start_time, fails, report_file_path)
  result_hash = {
      :date => Time.now.strftime('%d.%m.%Y'),
      :device => device,
      :case_count => case_count,
      :start_time => start_time,
      :end_time => Time.now.strftime('%H:%M:%S'),
      :fails => fails,
      :report_file => report_file_path
  }
  if Dir["#{root_path}/results.json"].length == 0
    create_results_json(root_path, result_hash)
  else
    json = File.read("#{root_path}/results.json")
    json_hash = JSON.parse(json)
    same_test = false
    json_hash.each do |j|
      if (j['date'] == result_hash[:date]) && (j['device'] == result_hash[:device]) && (j['report_file'] == result_hash[:report_file])
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

def save_results_on_existing_file(root_path, device, case_count, start_time, fails, report_file_path)
  result_hash = {
      :date => Time.now.strftime('%d.%m.%Y'),
      :device => device,
      :case_count => case_count,
      :start_time => start_time,
      :end_time => Time.now.strftime('%H:%M:%S'),
      :fails => fails,
      :report_file => report_file_path
  }
  json = File.read("#{root_path}/results.json")
  json_hash = JSON.parse(json)
  same_test = false
  json_hash.each do |j|
    if (j['date'] == result_hash[:date]) && (j['device'] == result_hash[:device]) && (j['report_file'] == result_hash[:report_file])
      same_test = true
      j.replace(result_hash)
    end
  end
  json_hash << result_hash if !same_test
  File.open("#{root_path}/results.json",'w') do |f|
    f.puts JSON.pretty_generate(json_hash)
  end
end