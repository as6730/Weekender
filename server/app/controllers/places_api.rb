require 'rest-client'
require 'json'

class PlacesUtils

  ENDPOINT = "https://maps.googleapis.com/maps/api/place"

  api_keys = [
    "AIzaSyB6aCRNMXBNIlT4dUXI_c47Dgd8UeZ3mDQ",
    "AIzaSyCnFz8z-DNPsSYQ3oaEhwe8ykzmePykpAE",
    "AIzaSyAYqO0CjsXnVRlSYMx1mzIlbodfKbl-_Og",
    "AIzaSyCAYxLd1mMSwPMaL-KIw-__oj64IlufcnA",
    "AIzaSyDZ25jrrjL_b5-sCsc2gRK9zDkUd-R6OAo",
    "AIzaSyBY_oLHUmf8-C9b7hkRtYC34ThjuNyliDw",
    "AIzaSyB6aCRNMXBNIlT4dUXI_c47Dgd8UeZ3mDQ",
    "AIzaSyCEbuWklDLV0973ygPglKadB6sGnY4gFC4",
    "AIzaSyD8i-bcDlTzDJXaj-mNo1l7CCvts845_w8",
    "AIzaSyCiowQGzYIH10U5WRDb4aaM8_qLhYdT4Q8"
  ]
  API_KEY = api_keys.last

  def self.get_places(places_count, lat, lon, date, type, place_properties, keyword = "", radius = 1000)
    if type === "restaurant"
      request = RestClient::Request.execute(
       method: :get,
       url: "#{ENDPOINT}/nearbysearch/json?key=#{API_KEY}&location=#{lat},#{lon}&radius=#{radius}&keyword=#{keyword}&type=#{type}&rankby=prominence"
      )
    else
      request = RestClient::Request.execute(
       method: :get,
       url: "#{ENDPOINT}/nearbysearch/json?key=#{API_KEY}&location=#{lat},#{lon}&radius=#{radius}&type=#{type}&rankby=prominence"
      )
    end

    results = JSON.parse(request)["results"]
    places_ids = PlacesUtils.get_top_places(20, results)

    if places_ids.length == 0
      return []
    end

    random_ids = PlacesUtils.get_random_keys(places_ids, places_count)
    places = []
    random_ids.each do |id|
      places << PlacesUtils.get_place_from_id(id, place_properties, date, type, keyword)
    end

    places
  end

  def self.get_top_places(place_count, places)
    i = 0
    ids  = []

    while i < places.length && i < place_count
      ids << places[i]["place_id"]
      i += 1
    end

    ids
  end

  def self.get_random_keys(place_ids, amt)
    random_ids = []

    while random_ids.length < amt
      random_idx = rand(0...place_ids.length)
      unless random_ids.include?(place_ids[random_idx])
        random_ids << place_ids[random_idx]
      end
    end

    random_ids
  end

  def self.get_place_from_id(place_id, properties, date, type, keyword)
    request = RestClient::Request.execute(
       method: :get,
       url: "#{ENDPOINT}/details/json?key=#{API_KEY}&placeid=#{place_id}"
    )
    result = JSON.parse(request)["result"]
    place = {}

    if result["photos"] != nil && !result["photos"][0].empty?
      photos_obj = result["photos"][0]
      photo_result = PlacesUtils.get_photo(photos_obj)
      place["photo_url"] = photo_result
    end

    properties.each do |property|
      if property === "opening_hours"
        if (result["opening_hours"] == nil)
          place[property] = ["All Day"]
        else
          place[property] = result[property]["weekday_text"]
        end
      elsif property === "geometry"
        place["location"] = result[property]["location"]
      else
        place[property] = result[property]
      end
    end

    date_time = PlacesUtils.set_start_and_end_time(type, date, keyword)
    place["date_time"] = date_time
    place["date"] = date
    place
  end

  def self.get_photo(result_photos)
    photo_reference = result_photos["photo_reference"]
    max_width = result_photos["width"]
    max_height= result_photos["height"]
    "https://maps.googleapis.com/maps/api/place/photo?key=#{API_KEY}&maxwidth=#{max_width}&maxheight=#{max_height}&photoreference=#{photo_reference}"
  end

  def self.set_start_and_end_time(type, date, keyword)
    time = {}

    if type === "restaurant"
      if keyword === "brunch"
        time["start"] = "08:00:00"
        time["end"] = "09:00:00"
      elsif keyword === "lunch"
        time["start"] = "12:30:00"
        time["end"] = "13:30:00"
      elsif keyword === "dinner"
        time["start"] = "19:00:00"
        time["end"] = "20:30:00"
      end
    elsif type === "museum"
      time["start"] = "9:30:00"
      time["end"] = "12:00:00"
    elsif type === "bar"
      time["start"] = "21:00:00"
      time["end"] = "23:59:00"
    elsif type === "park"
      time["start"] = "14:30:00"
      time["end"] = "16:30:00"
    end

    time
  end
end
