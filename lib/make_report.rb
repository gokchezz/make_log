require 'base64'
require 'azure'
require 'openssl'
require 'date'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

def link_object(id, encrypted_image)
  %Q[<a href="" onclick="img=document.getElementById('#{id}'); img.style.display = (img.style.display == 'none' ? 'block' : 'none');return false">
     <img height=120 src="data:image/png;base64,#{encrypted_image}"></a>]
end

def img_object(id, encrypted_image)
  %Q[<img height=600 id="#{id}" style="display: none" src="data:image/png;base64,#{encrypted_image}"/>]
end

def sign_object(encrypted_image)
  %Q[<img height=15 src="data:image/png;base64,#{encrypted_image}"/>]
end

def make_row(control_id, id, reference, screenshot, sign)
  ref_file = File.binread(reference)
  encrypted_reference_image = Base64.encode64(ref_file).tr("\n", '')
  scr_file = File.binread(screenshot)
  encrypted_screenshot = Base64.encode64(scr_file).tr("\n", '')
  sign_file = File.binread(sign)
  encrypted_sign = Base64.encode64(sign_file).tr("\n", '')
  if @row_count % 2 == 0
    @color = '#F5F9FC'
  else
    @color = '#FFFFFF'
  end
  row = File.read("#{@path}/tr")
  edited_row = ''
  row.each_line do |line|
    line = line.gsub('%color%', @color)
    line = line.gsub('%reference%', link_object(control_id, encrypted_reference_image))
    line = line.gsub('%sign%', sign_object(encrypted_sign))
    line = line.gsub('%screenshot%', link_object(id, encrypted_screenshot))
    edited_row += line
  end
  @row_count += 1
  edited_row
end

def make_img_row(control_id, id, reference, screenshot)
  ref_file = File.binread(reference)
  encrypted_reference_image = Base64.encode64(ref_file).tr("\n", '')
  scr_file = File.binread(screenshot)
  encrypted_screenshot = Base64.encode64(scr_file).tr("\n", '')
  if @row_count % 2 == 0
    @color = '#F5F9FC'
  else
    @color = '#FFFFFF'
  end
  row = File.read("#{@path}/tr")
  edited_row = ''
  row.each_line do |line|
    line = line.gsub('%color%', @color)
    line = line.gsub('%reference%', img_object(control_id, encrypted_reference_image))
    line = line.gsub('%screenshot%', img_object(id, encrypted_screenshot))
    edited_row += line
  end
  @row_count += 1
  edited_row
end

def no_error_row
  @color = '#F5F9FC'
  row = File.read("#{@path}/tr")
  edited_row = ''
  sign = "#{@path}/success-icon.png"
  sign_file = File.binread(sign)
  encrypted_sign = Base64.encode64(sign_file).tr("\n", '')
  row.each_line do |line|
    line = line.gsub('%color%', @color)
    line = line.gsub('%reference%', '************* Test ended')
    line = line.gsub('%sign%', sign_object(encrypted_sign))
    line = line.gsub('%screenshot%', 'with no error ***********')
    edited_row += line
  end
  @row_count += 1
  edited_row
end

def prepare_report(reference_path, screenshot_path, report_name, errors, result_path, device_name)
  @img_id = 0
  @row_count = 0
  report_body = ''
  @path = nil
  previous_errors = get_errors_of_previous_day(result_path, device_name)
  dirs = File.absolute_path(__FILE__).split('/')
  i = 0
  (dirs.length-1).times do
    if @path.nil?
      @path = dirs[i]
    else
      @path = "#{@path}/#{dirs[i]}"
    end
    i += 1
  end
  @path = "#{@path}/assets"
  report_template = File.read("#{@path}/report_template.html")
  report_template.each_line do |line|
    line = line.gsub('%date%', Time.now.strftime('%d.%m.%Y'))
    report_body += line
  end
  report_body << File.read("#{@path}/header_table").gsub('%header%', report_name)
  if errors.length == 0
    report_body << no_error_row
  else
    errors.each do |error|
      id = "img_#{@img_id}"
      control_id = "ctr_#{@img_id}"
      @img_id += 1
      sign = get_sign(error, previous_errors)
      screenshot_file = Dir["#{screenshot_path}/#{error}_**.png"][0]
      report_body << make_row(control_id, id, "#{reference_path}/#{error}.png", screenshot_file, sign)
      report_body << make_img_row(control_id, id, "#{reference_path}/#{error}.png", screenshot_file)
    end
  end
  report_body << File.read("#{@path}/header_table_closure")
  report_body << File.read("#{@path}/html_closure")

  out_file = File.new("#{@path}/#{report_name}.html", 'w')
  out_file.puts(report_body)
  out_file.close

  while true do
    break if Dir["#{@path}/#{report_name}.html"].length > 0
  end
  save_file_to_azure(@path, "#{report_name}.html")

  File.delete("#{@path}/#{report_name}.html")
end

def get_errors_of_previous_day(result_path, device_name)
  yesterday = Date.today - 1
  results = []
  if Dir["#{result_path}/results.json"].length != 0
    json = File.read("#{result_path}/results.json")
    json_hash = JSON.parse(json)
    json_hash.each do |j|
      if (j['date'] == yesterday.strftime('%d.%m.%Y')) && (j['device'] == device_name)
        results << j['fails']
      end
    end
  end
  results
end

def get_sign(error, previous_errors)
  sign = "#{@path}/stop-sign.png"
  sign = "#{@path}/unlemis.png" if !previous_errors.include? error
  sign
end

def save_file_to_azure(file_path, file_to_upload)
  Azure.config.storage_account_name = "smartfacecdn"
  Azure.config.storage_access_key = "dSehbw/nMHukayMsuNj15UjCmxV3rRGdZ8Sxr1uCjdgmuOkvJt6uqSWWCA+nflQbaxnqxRFEJALzlm9y0r0DOA=="
  azure_blob_service = Azure::Blob::BlobService.new
  content = File.open("#{file_path}/#{file_to_upload}", "rb") { |file| file.read }
  blob = azure_blob_service.create_block_blob('test-automation',"#{Time.now.strftime('%d-%m-%y')}/#{file_to_upload}", content)
  p "Report is saved to #{blob.name} Azure container"
end