//
//  SearchViewController.swift
//  MyNetflix
//
//  Created by joonwon lee on 2020/04/02.
//  Copyright © 2020 com.joonwon. All rights reserved.
//

import UIKit
import Kingfisher
import AVFoundation
import Firebase

class SearchViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var resultCollectionView: UICollectionView!
    
    let db = Database.database().reference().child("searchHistory")
    var movies :[Movie] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

//MARK: CollectionView DataSource
extension SearchViewController: UICollectionViewDataSource{
    //몇개 넘어오는지
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return movies.count
    }
    //어떻게 표현할건지
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "resultCell", for: indexPath) as? resultCell else {
            return UICollectionViewCell()
        }
        let movie = movies[indexPath.item]
        
        //imagepath(String) -> image
        let url = URL(string: movie.thumbnailPath)!
        cell.movieThumbnail.kf.setImage(with: url)
        
        cell.backgroundColor = .red
        return cell
        
    }
}
//MARK: CollectionView Delegate
extension SearchViewController: UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // movie
        // playerVC 띄우기
        // playerVC에 movie 전달
        let movie = movies[indexPath.item]
        
        let url = URL(string: movie.previewURL)!
        let item = AVPlayerItem(url: url)
        
        let sb = UIStoryboard.init(name: "Player", bundle: nil)
        let vc = sb.instantiateViewController(identifier: "PlayerViewController") as! PlayerViewController
        vc.modalPresentationStyle = .fullScreen
        
        vc.player.replaceCurrentItem(with: item)
        present(vc, animated: false, completion: nil)
    }
}

//MARK: CollectionViewDelegateFlowLayout
extension SearchViewController: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let margin: CGFloat = 8
        let itemSpacing :CGFloat = 10
        
        let width = (collectionView.bounds.width - margin * 2 - itemSpacing * 2) / 3
        let height = width * 10 / 7
        return CGSize(width: width, height: height)
    }
}

class resultCell : UICollectionViewCell {
    @IBOutlet weak var movieThumbnail: UIImageView!
}


// serachBarDelegate
extension SearchViewController: UISearchBarDelegate {
    
    // 키보드가 올라 왔을때, 내려가게 처리
    private func dismissKeyboard(){
        searchBar.resignFirstResponder()
    }
    
    //serach button 클릭했을때 메소드
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //검색 시작
        
        // 키보드가 올라 왔을때, 내려가게 처리
        dismissKeyboard()
        
        // 검색어가 있는지
        guard let searchTerm = searchBar.text, searchTerm.isEmpty == false else { return }
        
        // 네트워킹을 통한 검색
        // - 목표 : 서치텀을 이용하여 네트워킹을 통해 영화 검색
        //  - 검색 API가 필요 : success
        //  - 결과를 받아올 모델 Movie, Respone : success
        //  - 결과를 받아와서, CollectionView로 표현해주자 : success
        
        SearchAPI.search(searchTerm) { (movies) in
            print("넘어온 개수 ::: \(movies.count), 첫번째 제목 :: \(movies.first?.title)")
            // collectionVIew로 표현
            DispatchQueue.main.async {
                self.movies = movies
                self.resultCollectionView.reloadData()
                let timestamp = Date().timeIntervalSince1970.rounded()
                self.db.childByAutoId().setValue(["term": searchTerm, "timestamp": timestamp])
            }
        }
        
        print("검색어 ::: \(searchTerm)")
    }
}

// > 검색 API가 필요
class SearchAPI {
    //@escaping :: 컴플리션 안에 있는 코드 블럭이 메소드 바깥에서 실행된다. 될수있다.
    static func search(_ term: String, completion: @escaping ([Movie]) -> Void ){
        let session = URLSession(configuration: .default)
        
        var urlComponents = URLComponents(string: "https://itunes.apple.com/search?")!
        let mediaQuery = URLQueryItem(name: "media", value: "movie")
        let entityQuery = URLQueryItem(name: "entity", value: "movie")
        let termQuery = URLQueryItem(name: "term", value: term)
        urlComponents.queryItems?.append(mediaQuery)
        urlComponents.queryItems?.append(entityQuery)
        urlComponents.queryItems?.append(termQuery)
        
        let requestURL = urlComponents.url!
        
        //네트워킹
        let dataTask = session.dataTask(with: requestURL) { data, response, error in
            let successRange = 200..<300
            guard error == nil ,
                  let statusCode = (response as? HTTPURLResponse)?.statusCode,
                  successRange.contains(statusCode) else {
                completion([]) // 넘어온 데이터가 없다
                return
            }
             
            guard let resultData = data else {
                completion([])
                return
                
            }
            //data -> [Movie]
            let movies = SearchAPI.parsMovies(resultData)
            completion(movies)
            
        }
        dataTask.resume()
    }
    static func parsMovies(_ data: Data) -> [Movie] {
        let decoder = JSONDecoder()
        do{
            let response = try decoder.decode(Response.self, from: data)
            let movies = response.movies
            return movies
        }catch let error{
            print("parsing error::: \(error.localizedDescription)")
            return []
        }
    }
}

struct Response : Codable{
    let resultCount : Int
    let movies: [Movie]

    enum CodingKeys: String, CodingKey {
        case resultCount
        case movies = "results"
    }
    
}

struct Movie : Codable {
    let title           : String
    let director        : String
    let thumbnailPath   : String
    let previewURL      : String
    
    enum CodingKeys: String, CodingKey {
        case title          = "trackName"
        case director       = "artistName"
        case thumbnailPath  = "artworkUrl100"
        case previewURL     = "previewUrl"
    }
}
