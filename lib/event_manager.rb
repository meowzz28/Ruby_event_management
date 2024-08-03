require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def clean_phone_number(phone_number)
  phone_number.gsub!(/[^\d]/, '')
  if phone_number.length == 10
    phone_number
  elsif phone_number.length == 11 && phone_number[0] == 1
    phone_number[1..10]
  else
    "Invalid phone number"
  end
end


def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def find_maximum(array)
  array.max_by{|i| array.count(i)}
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)
contents_size = CSV.read('event_attendees.csv').length - 1
hour_array = []
day_array = []
template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  reg_date = row[:regdate]
  legislators = legislators_by_zipcode(zipcode)
  phone_number = clean_phone_number(row[:homephone])
  reg_hour = Time.strptime(reg_date, '%M/%d/%y %k:%M').strftime('%k')
  hour_array.push(reg_hour)
  reg_day = Time.strptime(reg_date, '%M/%d/%y %k:%M').strftime('%A')
  day_array.push(reg_day)
  puts phone_number
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id,form_letter)
end

puts "Most Active Hour  : #{find_maximum(hour_array)}.00"
puts "Most Active Day  : #{find_maximum(day_array)}"

