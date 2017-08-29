# The data provided by the service meteoservice.ru
require 'net/http' # send request on websites
require 'uri' # format address
require 'rexml/document' # parse xml docs
require 'json' # parse json docs

CLOUDINESS = {-1 => 'туман', 0 => 'ясно', 1 => 'малооблачно', 2 => 'облачно', 3 => 'пасмурно'}

current_path = File.dirname(__FILE__)
json_file_name = current_path + "/data/cities.json"

begin
  data = File.read(json_file_name)
rescue Errno::ENOENT
  abort "FILE NOR FOUNDED"
end

cities_hash = JSON.parse(data)

puts "В каком городе показать погоду?"
user_input = STDIN.gets.chomp

city_key = nil

cities_hash.each do |key, values|
  city_key = key if values == user_input
end

city_key = cities_hash.keys[0] if city_key.nil?

uri = URI.parse("http://xml.meteoservice.ru/export/gismeteo/point/#{city_key}.xml")
response = Net::HTTP.get_response(uri)
doc = REXML::Document.new(response.body)


city = URI.unescape(doc.root.elements['REPORT/TOWN'].attributes['sname'])
current_forecast = doc.root.elements['REPORT/TOWN'].elements.to_a[0]

min_temp = current_forecast.elements['TEMPERATURE'].attributes['min']
max_temp = current_forecast.elements['TEMPERATURE'].attributes['max']

min_wind = current_forecast.elements['WIND'].attributes['min'].to_i
max_wind = current_forecast.elements['WIND'].attributes['max'].to_i
wind = (min_wind + max_wind) / 2

clouds_index = current_forecast.elements['PHENOMENA'].attributes['cloudiness'].to_i
clouds = CLOUDINESS[clouds_index]

word_split = city.split("")
word_end = word_split[-1]

if (word_end == "а" || word_end == "ь" || word_end == "я")
  word_split.delete(word_end)
  word_split << "е"
elsif (word_end == "ы" || word_end == "о" || word_end == "у" || word_end == "и")

else
  word_split << "е"
end

city = word_split.join("")

puts "Температура в #{city}: #{min_temp}℃ - #{max_temp}℃"
puts "Скорость ветра: #{wind} м/с и #{clouds}"