require 'csv'
require 'erb'
require 'google/apis/civicinfo_v2'

attendees = CSV.open('../event_attendees.csv', headers: true, header_converters: :symbol)
template_letter = File.read('../form_letter.erb')
erb_template = ERB.new(template_letter)

def clean_phone_number(phone_num)
  phone_num = phone_num.to_s.gsub(/[^0-9]/, '')
  error_msg = 'Invaid number'

  phone_num = error_msg if phone_num.length < 10 || phone_num.length > 11

  if phone_num.length == 11
    phone_num = phone_num[0] == '1' ? phone_num[1..11] : error_msg
  end

  phone_num
end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

# Used to gather the legislator of a attendee, using the attendee's zip code
def gather_legislators(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  # In case zip code is invalid or if attendee didn't provide zip code to query
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

# Create a directory called 'output' and store thank you letters within it
def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "./output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

attendees.each do |attendee|
  id = attendee[0]
  name = attendee[:first_name]
  phone_number = clean_phone_number(attendee[:homephone])
  zipcode = clean_zipcode(attendee[:zipcode])
  legislators = gather_legislators(zipcode)
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)
end
