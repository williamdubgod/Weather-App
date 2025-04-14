import Foundation
import CoreLocation

struct City {
    let lat: String
    let lon: String
    let name: String
    let state: String?
    
    init(lat: String, lon: String, name: String, state: String? = nil) {
        self.lat = lat
        self.lon = lon
        self.name = name
        self.state = state
    }
}

class Service {
    
    private let baseURL: String = "https://api.openweathermap.org/data/3.0/onecall"
    private let geoURL: String = "https://api.openweathermap.org/geo/1.0/direct"
    private let apiKey: String = "38aa136612fe29744589296fd34fe97b"
    private let session = URLSession.shared
    
    func fetchData(city: City, _ completion: @escaping (Result<ForecastResponse, Error>) -> Void) {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "lat", value: city.lat),
            URLQueryItem(name: "lon", value: city.lon),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "metric")
        ]
        
        guard let url = components?.url else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.cannotParseResponse)))
                return
            }
            
            do {
                let forecastResponse = try JSONDecoder().decode(ForecastResponse.self, from: data)
                completion(.success(forecastResponse))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    func searchCities(name: String, completion: @escaping (Result<[City], Error>) -> Void) {
        guard !name.isEmpty else {
            completion(.success([]))
            return
        }
        
        var components = URLComponents(string: geoURL)
        components?.queryItems = [
            URLQueryItem(name: "q", value: name),
            URLQueryItem(name: "limit", value: "10"),
            URLQueryItem(name: "appid", value: apiKey)
        ]
        
        guard let url = components?.url else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.cannotParseResponse)))
                return
            }
            
            do {
                let locations = try JSONDecoder().decode([LocationResponse].self, from: data)
                let cities = locations.map {
                    City(
                        lat: String($0.lat),
                        lon: String($0.lon),
                        name: $0.name,
                        state: $0.state ?? $0.country
                    )
                }
                completion(.success(cities))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}

// MARK: - Modelos de Dados
struct ForecastResponse: Codable {
    let current: Forecast
    let hourly: [Forecast]
    let daily: [DailyForecast]
}

struct Forecast: Codable {
    let dt: Int
    let temp: Double
    let humidity: Int
    let windSpeed: Double
    let weather: [Weather]
    
    enum CodingKeys: String, CodingKey {
        case dt, temp, humidity, weather
        case windSpeed = "wind_speed"
    }
}

struct Weather: Codable {
    let id: Int
    let main, description, icon: String
}

struct DailyForecast: Codable {
    let dt: Int
    let temp: Temp
    let weather: [Weather]
}

struct Temp: Codable {
    let day, min, max, night: Double
    let eve, morn: Double
}

struct LocationResponse: Codable {
    let name: String
    let lat: Double
    let lon: Double
    let country: String
    let state: String?
}
