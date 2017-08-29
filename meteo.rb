# The data provided by the service meteoservice.ru
require 'net/http' # send request on websites
require 'uri' # format address
require 'rexml/document' # parse xml docs
require 'json' # parse json docs
require 'open-uri'
require 'nokogiri'
require 'unicode'
require_relative 'unicode-settings.rb'

CLOUDINESS = {-1 => 'туман', 0 => 'ясно', 1 => 'малооблачно', 2 => 'облачно', 3 => 'пасмурно'}

current_path = File.dirname(__FILE__)
json_file_name = current_path + "/data/cities.json"

begin
  data = File.read(json_file_name)
rescue Errno::ENOENT
  abort "FILE NOT FOUNDED"
end

cities_hash = JSON.parse(data)

puts "В каком городе показать погоду?"
user_input = STDIN.gets.chomp

city_key = nil

cities_hash.each do |key, values|
  city_key = key if values.capitalize == user_input.capitalize
end

if city_key.nil?
  first_big_word = user_input.split("")[0].upcase
  word_downcase = user_input.downcase

  url_sin = "http://synonymonline.ru/#{first_big_word}/#{word_downcase}"
  url_sin = URI.escape(url_sin)

  begin
    html = open(url_sin)
    doc_sin = Nokogiri::HTML(html)

    synonyms = []

    doc_sin.css('.synonyms-list li span').each do |list|
      synonyms << list.text
    end

    cities_hash.each do |key, values|
      synonyms.each do |value|
        city_key = key if values.capitalize == value.capitalize
      end
    end
  rescue OpenURI::HTTPError
  end
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
elsif (word_end == "ы" || word_end == "о" || word_end == "у" || word_end == "и" || word_end == "й")

else
  word_split << "е"
end

city = word_split.join("")

puts "Температура в #{city}: #{min_temp}℃ - #{max_temp}℃"
puts "Скорость ветра: #{wind} м/с и #{clouds}"