//
//  MovieViewModel.swift
//  mansTV
//
//  Created by Matiss on 21/05/2018.
//  Copyright © 2018 DIVI Grupa. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import StoreKit
import shortcutEngine

class MovieViewModel {
    // OBSERVABLES
    var isLoading = BehaviorSubject<Bool>(value: false)
    var isLoadingStream = BehaviorSubject<Bool>(value: false)
    
    var titleText: BehaviorSubject<String>
    var originalText: BehaviorSubject<String>
    var currentSeasonText: BehaviorSubject<Int>
    var priceText: BehaviorSubject<String>
    var durationText: BehaviorSubject<String>
    var yearText: BehaviorSubject<String>
    var ratingText: BehaviorSubject<String>
    var languagesText: BehaviorSubject<String>
    var subtitlesText: BehaviorSubject<String>
    var genresText: BehaviorSubject<String>
    var directorsText: BehaviorSubject<String>
    var actorsText: BehaviorSubject<String>
    var annotationText: BehaviorSubject<String>
    
    var titleLabelSize: BehaviorSubject<CGSize>
    var originalLabelSize: BehaviorSubject<CGSize>
    var currentLabelSize: BehaviorSubject<CGSize>
    var priceLabelSize: BehaviorSubject<CGSize>
    var durationLabelSize: BehaviorSubject<CGSize>
    var yearLabelSize: BehaviorSubject<CGSize>
    var ratingLabelSize: BehaviorSubject<CGSize>
    var languagesLabelSize: BehaviorSubject<CGSize>
    var subtitlesLabelSize: BehaviorSubject<CGSize>
    var genresLabelSize: BehaviorSubject<CGSize>
    var directorsLabelSize: BehaviorSubject<CGSize>
    var actorsLabelSize: BehaviorSubject<CGSize>
    var annotationLabelSize: BehaviorSubject<CGSize>
    
    var movieURL: BehaviorSubject<URL>
  
    private var movie: Movie?
    fileprivate var movieID: String!
    private var categoryID: String? = nil
    
    var recomendedMovies: Driver<[Movie]>
    var seasonMovies: Driver<[Movie]>
    private var streamList: [VodStream] = []
    
    fileprivate var products: [SKProduct]? = nil
    fileprivate var premiumMovieProduct: SKProduct? {
        get {
            guard let products = self.products else {
                return nil
            }
            
            if let moviePrice = self.movie?.price {
                for product in products {
                    if (moviePrice as Decimal) <= (product.price as Decimal) {
                        return product
                    }
                }
                return products.last
            } else {
                return products.last
            }
        }
    }
    
    private let dataHelper: DataHelper
    
    var actual: Bool? = true

    init(movieID: String, categoryID: String?, dataHelper: DataHelper) {
        self.movieID = movieID
        self.categoryID = categoryID
        self.dataHelper = dataHelper
        getMovie(movieID: self.movieID)
    }

    fileprivate func getMovie(movieID: String) {
        self.isLoading.value = true
        DataHelper.getMovie(movieID, includeActualEpisode: true, completeCallback: { ( item: ContentObject)  in
            DispatchQueue.main.async {
                if let returnedMovie = item as? Movie {
                    if let actual_episode = returnedMovie.actual_episode, self.actual == true {
                        self.movie = actual_episode
                    } else {
                        self.movie = returnedMovie
                    }
                }
                self.loadRecommendations()
                self.loadEpisodes()
                self.setLabelsTitlesAndSizes()
                self.isLoading.value = false
            }
        }, errorCallback: {
            DispatchQueue.main.async {
                self.isLoading.value = false
            }
        })
    }
    
    fileprivate func setLabelsTitlesAndSizes() {
        if let title_original = movie?.title, title_original != movie?.titleLocalized {
            titleText = BehaviorSubject<String>(value: title_original)
        } else {
            titleLabelSize = BehaviorSubject<CGSize>(value: CGSize(width: 0, height: 0))
        }
        
        if let title_local = movie?.titleLocalized {
            originalText = BehaviorSubject<String>(value: title_local)
        } else {
            originalLabelSize = BehaviorSubject<CGSize>(value: CGSize(width: 0, height: 0))
        }
        
        if LoginHelper.isLoggedIn && (movie?.isPremiere)! && !(movie?.isPaid)! {
            if let product = premiumMovieProduct {
                priceText = BehaviorSubject<String>(value: product.localizedPrice()! + "NOMĀT")
            }
        } else {
            priceLabelSize = BehaviorSubject<CGSize>(value: CGSize(width: 0, height: 0))
        }
        
        if let seasons = movie?.seasons, !seasons.isEmpty {
            currentSeasonText = BehaviorSubject<Int>(value: seasons)
        } else {
            currentLabelSize = BehaviorSubject<CGSize>(value: CGSize(width: 0, height: 0))
        }
        
        if let length = movie?.length, length != "0" {
            durationText = BehaviorSubject<String>(value: length)
        } else {
            durationLabelSize = BehaviorSubject<CGSize>(value: CGSize(width: 0, height: 0))
        }
        
        if let year = movie?.year, year.characters.count > 0 {
            yearText = BehaviorSubject<String>(value: year)
        } else {
            yearLabelSize = BehaviorSubject<CGSize>(value: CGSize(width: 0, height: 0))
        }
        
        if let rating = movie?.imdb_rating, rating != "0" {
            ratingText = BehaviorSubject<String>(value: rating)
        } else {
            ratingLabelSize = BehaviorSubject<CGSize>(value: CGSize(width: 0, height: 0))
        }
        
        if movie!.languages.count > 0 {
            var labelText: String = ""
            for (index,language) in (movie?.languages.enumerated())! {
                labelText += language.title ?? ""
                
                if index != (movie?.languages.count)! - 1 {
                    labelText += ", "
                }
            }
            languagesText = BehaviorSubject<String>(value: labelText)
        } else {
            languagesLabelSize = BehaviorSubject<CGSize>(value: CGSize(width: 0, height: 0))
        }
        
        if movie!.subtitles.count > 0 {
            var labelText: String = ""
            for (index,subtitle) in (movie?.subtitles.enumerated())! {
                labelText += subtitle.title ?? ""
                
                if index != (movie?.subtitles.count)! - 1 {
                    labelText += ", "
                }
            }
            subtitlesText = BehaviorSubject<String>(value: labelText)
        } else {
            subtitlesLabelSize = BehaviorSubject<CGSize>(value: CGSize(width: 0, height: 0))
        }
        
        if self.movie != nil {
            var labelText: String = ""
            if let genres = movie?.genres, genres.count > 0 {
                labelText = genres.joined(separator: ", ")
            } else {
                labelText = (movie?.genre)!
            }
            genresText = BehaviorSubject<String>(value: labelText)
        } else {
            genresLabelSize = BehaviorSubject<CGSize>(value: CGSize(width: 0, height: 0))
        }
        
        if let directors = movie?.directors, directors.count > 0 {
            var infoLabel: String = ""
            if directors.count == 1 {
                infoLabel = "Režisors"
            } else {
                infoLabel = "Režisori"
            }
            directorsText = BehaviorSubject<String>(value: directors.joined(separator: ", "))
        } else {
            genresLabelSize = BehaviorSubject<CGSize>(value: CGSize(width: 0, height: 0))
        }
        
        if let actors = movie?.actors, actors.count > 0 {
            actorsText = BehaviorSubject<String>(value: actors.prefix(5).joined(separator: ", ") + (actors.count > 5 ? " [...]" : ""))
        } else {
            actorsLabelSize = BehaviorSubject<CGSize>(value: CGSize(width: 0, height: 0))
        }
        
        if let annotation = movie?.annotation, annotation.characters.count > 0 {
            annotationText = BehaviorSubject<String>(value: annotation.trimAnnotation())
        } else {
            annotationLabelSize = BehaviorSubject<CGSize>(value: CGSize(width: 0, height: 0))
        }
        
    }
    
    fileprivate func setActionImage() {
        var imageUrl: String = ""
        if !movie!.isFree && !LoginHelper.hasVod && !movie!.isPremiere {
            imageUrl = "locked"
        } else {
            imageUrl = "play_button"
        }
    }

    fileprivate func loadEpisodes() {
        if let season_nr = movie?.activeSeason, let series_id = movie?.series_id {
            
            DataHelper.getMoviesEpisodes(series_id, season_nr: season_nr, completeCallback: self.episodesReturned, errorCallback: self.episodesFailed)
            
        }
    }
    
    fileprivate func loadRecommendations() {
        guard let movie = self.movie else {
            return
        }
        
        if self.recomendedMovies.isEmpty {
            // load recomendations from backend
            self.isLoading.value = true
            if let categoryId = categoryID {
                DataHelper.getRecomendedContentByCategory(movie.id, categoryId: categoryId, excludeSeriesID: movie.series_id, completeCallback: recommendedMoviesReturned, errorCallback: {})
            } else {
                DataHelper.getRecomendedContentByVods(movie.id, completeCallback: recommendedMoviesReturned, errorCallback: {})

            }
        }
    }
    
    fileprivate func episodesReturned(_ movies: Driver<[Movie]>) {
        self.seasonMovies = movies
        DispatchQueue.main.async {
            self.isLoading.value = false
        }
    }
    
    fileprivate func recommendedMoviesReturned(_ result: Driver<[Movie]>) {
        self.recomendedMovies = result.filter({ $0 is Movie })
    }

    func changeMovie() {
        self.recomendedMovies.removeAll()
        self.seasonMovies.removeAll()
        if let movie = movie {
            self.getMovie(movieID: movie.id)
        }
        actual = false
    }
    
    @objc public func mainImageAction() {
        if LoginHelper.isLoggedIn && (movie?.isPremiere)! && !(movie?.isPaid)! {
            self.purchaseAction()
        } else {
            self.playMovie()
        }
    }
    
    func playMovie()
    {
        guard let movie = movie else {
            return
        }
        
        if !self.isLoadingStream {
            if !movie.isFree && !LoginHelper.isLoggedIn {
                var message: String
                if !movie.isPremiere {
                    message = MSG_MOIVE_NEED_LOGIN
                } else {
                    message = MSG_MOIVE_NEED_LOGIN_PURCHASE
                }
                //ask if user wants to login in
            } else {
                self.isLoadingStream.value = true
                
                DataHelper.GetToken(for: movie, completeCallback: tokenGranted, errorCallback: tokenFailed, holder: UIViewController())
            }
        }
    }
    
    func tokenGranted(_ token: String, _: String)
    {
        guard let movie = movie else {
            return
        }
        
        if !movie.isPremiere && !movie.isFree && !LoginHelper.hasVod {
            // no right to watch movie
            DispatchQueue.main.async {
                self.isLoadingStream.value = false
            }
        } else {
            //get vod stream url
            DataHelper.getMovieStream(movie.id!, token: token, completeCallback: streamGranted, errorCallback: streamFailed)
        }
    }
    
    func streamGranted(_ streamList: [VodStream], id: String)
    {
        guard let movie = movie else {
            return
        }
        if movie.id == id {
            DispatchQueue.main.async {
                self.streamList = streamList
                var streamUrl: String? = nil
                
                for stream in streamList {
                    for streamSubtitle in stream.subtitles {
                        for subtitle in movie.subtitles {
                            if subtitle.id == streamSubtitle.id {
                                subtitle.url = streamSubtitle.url
                                break
                            }
                        }
                    }
                }
                
                if let selectedLanguage = movie.selectedLanguage {
                    for stream in streamList {
                        if let streamLanguage = stream.language, streamLanguage.code == selectedLanguage.code,
                            let stream_Url = stream.streamUrl {
                            
                            streamUrl = stream_Url
                            break
                        }
                    }
                } else {
                    streamUrl = streamList.first!.streamUrl!
                }
                self.isLoadingStream = false
            }
        }
    }
    
    @objc public func backAction() {
        self.removePlayer()
    }
    
    @objc public func trailerAction() {
        
        if let youTubeId = self.movie?.trailer {
            self.movieView.addYoutubePLayer(url: youtubeID)
        }
    }
    
    @objc internal func purchaseAction() {
        if let product = self.premiumMovieProduct {
            self.isLoading.value = true
            // start buying product
            IAP.buyProduct(product)
        }
    }
    
    @objc public func likeButtonAction(isSelected: Bool) {
        guard LoginHelper.isLoggedIn else {
            return
        }
        
        let newValue: Bool?
        if isSelected {
            newValue = nil
        } else {
            newValue = false
        }
        
        changeUserLikeSatuss(newValue)
        
        
    }
    
    @objc public func dislikeButtonAction(isSelected: Bool) {
        guard LoginHelper.isLoggedIn else {
            return
        }

        let newValue: Bool?
        if isSelected {
            newValue = nil
        } else {
            newValue = false
        }
        
        changeUserLikeSatuss(newValue)
    }
    
    @objc public func watchLaterButtonAction(isSelected: Bool) {
        guard LoginHelper.isLoggedIn else {
            return
        }
        
        changeWatchLaterStatus()
        if isSelected {
            DataHelper.removeWatchLater(movie: movie!)
        } else {
            DataHelper.setWatchLater(movie: movie!)
        }
        
    }
    
    func changeWatchLaterStatus() {
        movie?.is_watch_later = !(movie?.is_watch_later)!
    }
    
    @objc public func subtitlesAction(_ sender: UITapGestureRecognizer) {
        //turpināt šeit
        guard let movie = movie, movie.languages.count > 0 else {
            return
        }
        var subtitles = [String]()
        for subtitle in movie.subtitles {
            if let title = subtitle.titleShort {
                subtitles.append(title)
            }
        }
    }
    
    func removeSubtitles() {
        self.movie?.selectedSubtitle = nil
    }
    
    func selectSubtitle(selectedSubtitle: String) {
        if let subtitles = movie?.subtitles {
            for subs in subtitles {
                if subs.titleShort == selectedSubtitle {
                    self.movie?.selectedSubtitle = subs
                }
            }
        }
    }

    @objc public func languageAction(_ sender: UITapGestureRecognizer) {
        guard let movie = movie, movie.languages.count > 0 else {
            return
        }
        var languages = [String]()
        for language in movie.languages {
            if let title = language.titleShort {
                languages.append(title)
            }
        }
    }
    
    func selectLanguage(selectedLanguage: String) {
        if let languages = movie?.languages {
            for lang in languages {
                if lang.titleShort == selectedLanguage {
                    self.movie?.selectedLanguage = lang
                }
            }
        }
        
    }
    
    func changeUserLikeSatuss(_ newValue: Bool?) {
        guard let movie = self.movie else {
            return
        }
        
        if let newValue = newValue {
            if newValue {
                movie.likeCount += 1
                
                if let userLikes = movie.userLikes, !userLikes {
                    movie.dislikeCount -= 1
                }
            } else {
                movie.dislikeCount += 1
                
                if let userLikes = movie.userLikes, userLikes {
                    movie.likeCount -= 1
                }
            }
        } else {
            // set to neutral
            if let userLikes = movie.userLikes {
                if userLikes {
                    movie.likeCount -= 1
                } else {
                    movie.dislikeCount -= 1
                }
            }
        }
        
        movie.userLikes = newValue
        
        //
        let type: VodRate.Status
        
        if let newValue = newValue {
            if newValue {
                type = .like
            } else {
                type = .dislike
            }
        } else {
            type = .neutral
        }
        
        sendRateToAnalytics(type)
        
        //send to backend
        DataHelper.SendVodRate(movieID: movie.id!, rate: type)
    }
    
    func sendRateToAnalytics(_ rate: VodRate.Status)
    {
        //add to analytic play action
        GoogleAnalyticsHelper.AddEvnet("SOCIAL (VOD)", action: self.movie!.AnalyticsTitle, label: "Soc_Type: " + String(describing: rate))
    }
    
    @objc public func seasonSwitchTap() {
        if let seasons = movie?.seasons {
            for season in seasons {
                var returnSeasons = [Int]()
                returnSeasons.append(season)
            }
        }
    }
    
    @objc internal func expandabelLabelTap(_ sender: UITapGestureRecognizer) {
        if let label = sender.view as? UILabel, let type = expandableLabel(rawValue: label.tag) {
            var returnText: String = ""
            let oldSize = label.frame.size
            
            switch type {
            case .actors:
                if let actors = movie?.actors, actors.count > 5 {
                    
                    let longList = actors.joined(separator: ", ")
                    
                    if label.text == longList {
                        returnText = actors.prefix(5).joined(separator: ", ") + " [...]"
                    } else {
                        returnText = longList
                    }
                }
                
                break
            case .description:
                if let annotation = movie?.annotation {
                    let shortAnnotation = annotation.trimAnnotation()
                    if label.text == shortAnnotation {
                        returnText = annotation
                    } else {
                        returnText = shortAnnotation
                    }
                }
                
                break
            }
            
            label.sizeToFit()
            let newSize = label.frame.size
            
            if newSize != oldSize {
                let diff = newSize.height - oldSize.height
                for control in label.superview!.subviews {
                    if control.frame.origin.y > label.frame.origin.y + oldSize.height {
                        control.frame.origin = CGPoint(x: control.frame.origin.x, y: control.frame.origin.y + diff)
                    }
                    
                }
            }
            
        }
    }
    
    func switchSeason (_ selectedSeason: Int) {
        // save in model
        movie!.activeSeason = selectedSeason
        
        // reload episodes in collection view
        self.loadEpisodes()
    }
    
    func saveContinueWatching(currentItem: AVPlayerItem) {
        if LoginHelper.isLoggedIn {
            if let movie = self.movie {
                if currentItem.duration > currentItem.currentTime() && CMTimeGetSeconds(currentItem.currentTime()) > 20 {
                    // if not the end - set continue watching
                    let currentTime:TimeInterval = CMTimeGetSeconds(currentItem.currentTime())
                    movie.saveContinueWatching(Int(round(currentTime)))
                } else {
                    // has reached the end - reset continue watching
                    movie.resetContinueWatching()
                }
            }
        }
    }
    
}
