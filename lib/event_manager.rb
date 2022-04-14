require 'csv'
require 'erb'
require 'google/apis/civicinfo_v2'

attendees = CSV.open('../event_attendees.csv', headers: true, header_converters: :symbol)
template_letter = File.read('../form_letter.erb')
erb_template = ERB.new(template_letter)

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def gather_legislators(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
    address: zipcode,
    levels: 'country',
    roles: ['legislatorUpperBody', 'legislatorLowerBody']
    )

    legislators = legislators.officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "./output/thanks_#{id}.html"
  
  File.open(filename, 'w') do  |file|
    file.puts form_letter
  end
end

attendees.each do |attendee|
  id = attendee[0]
  name = attendee[:first_name]
  zipcode = clean_zipcode(attendee[:zipcode])
  legislators = gather_legislators(zipcode)
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)
end
