//
//  Movie.swift
//  mansTV
//
//  Created by DIVI Grupa on 18/05/16.
//  Copyright © 2016 DIVI Grupa. All rights reserved.
//

import Foundation
import UIKit

open class Movie: ContentObject {
    
    public override init() {
        super.init()
        isLandscape = false
    }
    
    @objc open var title: String?
    @objc open var titleLocalized: String?
    @objc open var posterUrl: String?
    @objc open var pictureLargeUrl: String?
    @objc open var imdb_rating: String?
    @objc open var genres: [String]?
    @objc open var imdb_link: String?
    @objc open var length: String?
    @objc open var year: String?
    @objc open var annotation: String?
    @objc open var genre: String?
    @objc open var continue_watching_time: Int = 0
    @objc open var trailer: String?
    @objc open var is_watch_later: Bool = false
    @objc open var price: NSDecimalNumber?
    @objc open var isPaid: Bool = false
    
    @objc open var directors: [String]?
    @objc open var actors: [String]?
    @objc open var subtitles: [StreamSubtitle] = [StreamSubtitle]()
    @objc open var languages: [StreamLanguage] = [StreamLanguage]()
    @objc open var selectedLanguage: StreamLanguage?
    @objc open var selectedSubtitle: StreamSubtitle?
    
    @objc open var isSubscription: Bool = false
    @objc open var isPremiere: Bool = false
    
    open var isSeries: Bool {
        get {
            return series_id != nil
        }
    }
    
    @objc open var series_id: String?
    @objc open var season_nr: Int = 0 {
        didSet {
            _activeSeason = season_nr
        }
    }
    @objc open var episode_nr: Int = 0
    @objc open var series_name: String?
    @objc open var episode_name: String?
    
    // contains the last watched movies element for series
    @objc open var actual_episode: Movie?
    
    // contains movies data about next episode - relevant in series
    @objc open var next_episode: Movie?
    
    open var shortEpisodesName: String {
        get {
            let episode_nr = String(format: "%02d", self.episode_nr)
            let season_nr = String(format: "%02d", self.season_nr)
            
            return "S\(season_nr)E\(episode_nr)"
        }
    }
    
    @objc open var seasons: [Int]? {
        didSet {
            //sort self and set first as current active
            if seasons != nil {
                seasons!.sort()
            }
        }
    }
    
    //holds the last selected season
    fileprivate var _activeSeason: Int?
    open var activeSeason: Int? {
        get {
            if let _activeSeason = _activeSeason {
                return _activeSeason
            } else {
                if let seasons = seasons, seasons.count > 0 {
                    return seasons[0]
                } else {
                    return nil
                }
            }
        }
        set {
            _activeSeason = newValue
        }
    }
    
    @objc open var isFree: Bool {
        get {
            return !isSubscription && !isPremiere
        }
    }
    
    open var userLikes: Bool? = nil
    
    @objc open var likeCount: Int = 0
    @objc open var dislikeCount: Int = 0
    
    open static var placeholderPosterImage: UIImage? {
        get {
            return UIImage(named: "placeholder_movie_poster")
        }
    }
    
    @objc open var default_language: StreamLanguage? {
        didSet {
            self.selectedLanguage = default_language
        }
    }
    
    @objc open var default_subtitle_language: StreamSubtitle? {
        didSet {
            self.selectedSubtitle = default_subtitle_language
        }
    }
    
    @objc open var default_quality: StreamQuality?
    
    // from : to
    override open func mapping() -> Dictionary<String, String>? {
        return  [
            "poster-url": "posterUrl",
            "poster-large-url": "pictureLargeUrl",
            "title-localized" : "titleLocalized",
            "imdb-rating" : "imdb_rating",
            "imdb-link" : "imdb_link",
            "is-subscription" : "isSubscription",
            "is-premium" : "isPremiere",
            "language" : "languages",
            "series-id": "series_id",
            "season-nr" : "season_nr",
            "episode-nr": "episode_nr",
            "series-name": "series_name",
            "episode-name": "episode_name",
            "like": "likeCount",
            "dislike": "dislikeCount",
            "continue-watching-time": "continue_watching_time",
            "is-watch-later": "is_watch_later",
            "current-episode": "actual_episode",
            "next": "next_episode",
            "default-language": "default_language",
            "default-subtitle-language": "default_subtitle_language",
            "default-quality": "default_quality",
            "description": "annotation",
            "is-paid": "isPaid"
        ]
    }
    
    open func getLanguageByPosition(_ index: Int) -> StreamLanguage?
    {
        if self.languages.count > index {
            return self.languages[index]
        } else {
            return nil
        }
    }
    
    open func getLanguageByCode(_ code: String) -> StreamLanguage?
    {
        for language in languages {
            if language.code == code {
                return language
            }
        }
        
        return nil
    }
    
    open var AnalyticsTitle: String {
        get {
            return "Title: " + (title ?? "") + ", VOD ID: " + id
        }
    }
    
    open func saveContinueWatching(_ newValue: Int) {
        if newValue > CONTINUE_WATCHING_BARRIER {
            self.continue_watching_time = newValue
            DataHelper.setContinueWatching(id, seconds: newValue, type: self.type)
        } else {
            resetContinueWatching()
        }
    }
    
    open func resetContinueWatching() {
        self.continue_watching_time = 0
        DataHelper.resetContinueWatching(id, type: self.type)
    }
    
    open var hasContinueWatchingTime : Bool {
        get {
            return self.continue_watching_time > CONTINUE_WATCHING_BARRIER
        }
    }
    
    /// MARK: original images (full size and quality)
    open func GetPosterImageAsync(_ completed: @escaping (UIImage?, String) -> Void) {
        GetImageAsync(path: self.posterUrl, placeholder: Movie.placeholderPosterImage, completed: completed)
    }
    
    open func GetLargeImageAsync(_ completed: @escaping (UIImage?, String) -> Void) {
        GetImageAsync(path: self.pictureLargeUrl, placeholder: Movie.placeholderPosterImage, completed: completed)
    }
    
    /// MARK: resized and downgraded images for perfomance
    open func GetResizedPosterImageAsync(size: CGSize, completed: @escaping (UIImage?, String) -> Void) {
        GetImageAsync(path: self.posterUrl, placeholder: Movie.placeholderPosterImage, size: size, completed: completed)
    }
    
    open func GetResizedLargeImageAsync(size: CGSize, completed: @escaping (UIImage?, String) -> Void) {
        GetImageAsync(path: self.pictureLargeUrl, placeholder: Movie.placeholderPosterImage, size: size, completed: completed)
    }
}

func == (lhs: Movie, rhs: Movie) -> Bool {
    return lhs.id == rhs.id
        && lhs.isSubscription == rhs.isSubscription
        && lhs.posterUrl == rhs.posterUrl
        && lhs.title == rhs.title
}

func != (lhs: Movie, rhs: Movie) -> Bool {
    return lhs.id != rhs.id
        || lhs.isSubscription != rhs.isSubscription
        || lhs.posterUrl != rhs.posterUrl
        || lhs.title != rhs.title
}

func != (lhs: [Movie], rhs: [Movie]) -> Bool {
    for (index, movie) in lhs.enumerated() {
        if rhs.count <= index {
            return true
        }
        
        if rhs[index] != movie {
            return true
        }
    }
    
    return rhs.count != lhs.count
}
