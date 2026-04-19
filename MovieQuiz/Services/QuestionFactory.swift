//
//  QuestionFactory.swift
//  MovieQuiz
//
//  Created by Dmitrii Pogonia on 18.03.2026.
//

import UIKit

private enum PosterLoadError: LocalizedError {
    
    case noMovies
    
    var errorDescription: String? {
        switch self {
        case .noMovies:
            return "Нет фильмов для отображения."
        }
    }
}

/// Кадр: готовый постер + рейтинг для мгновенного показа вопроса (без сети в рантайме).
private struct PreloadedFrame {
    let imageData: Data
    let rating: Float
}

final class QuestionFactory: QuestionFactoryProtocol {
    
    private static let moviePreloadTimeout: TimeInterval = 10
    private static let targetPosterCount = 10
    /// Параллельных загрузок постеров (уникальные фильмы подтягиваются из очереди по мере завершения).
    private static let maxConcurrentPosterFetches = 8
    
    private let moviesLoader: MoviesLoaderProtocol
    private let imageNetwork: NetworkRoutingProtocol
    weak var delegate: QuestionFactoryDelegate?
    internal var movies: [MostPopularMovie] = []
    
    private var preloadedFrames: [PreloadedFrame] = []
    /// Индексы кадров, уже показанных в текущем раунде (10 вопросов без повторов).
    private var usedFrameIndicesInRound: Set<Int> = []
    private var didFinishPreload = false
    private var timeoutWorkItem: DispatchWorkItem?
    private let stateLock = NSLock()
    
    init(
        moviesLoader: MoviesLoaderProtocol,
        imageNetwork: NetworkRoutingProtocol = NetworkClient(),
        delegate: QuestionFactoryDelegate?
    ) {
        self.moviesLoader = moviesLoader
        self.imageNetwork = imageNetwork
        self.delegate = delegate
    }
    
    func requestNextQuestion() {
        DispatchQueue.global().async { [weak self] in
            guard let self else { return }
            let frame: PreloadedFrame? = self.stateLock.withLock {
                let frames = self.preloadedFrames
                guard !frames.isEmpty else { return nil }
                let available = (0..<frames.count).filter { !self.usedFrameIndicesInRound.contains($0) }
                guard let index = available.randomElement() else { return nil }
                self.usedFrameIndicesInRound.insert(index)
                return frames[index]
            }
            guard let frame else {
                DispatchQueue.main.async {
                    self.delegate?.didFailToLoadPoster(with: PosterLoadError.noMovies)
                }
                return
            }
            let randomNum = Int.random(in: 6...9)
            let isGreaterQuestion = Bool.random()
            let text = "Рейтинг этого фильма \(isGreaterQuestion ? "больше" : "меньше") чем \(randomNum)?"
            let correctAnswer = isGreaterQuestion
                ? (frame.rating > Float(randomNum))
                : (frame.rating < Float(randomNum))
            let question = QuizQuestion(image: frame.imageData, text: text, correctAnswer: correctAnswer)
            DispatchQueue.main.async {
                self.delegate?.didReceiveNextQuestion(question: question)
            }
        }
    }
    
    func loadData() {
        stateLock.withLock {
            cancelPreloadTimeout()
            didFinishPreload = false
            preloadedFrames = []
            usedFrameIndicesInRound = []
            movies = []
        }
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.finishPreload(using: .timeoutOrIncomplete)
        }
        stateLock.withLock { timeoutWorkItem = workItem }
        DispatchQueue.global(qos: .userInitiated).asyncAfter(
            deadline: .now() + Self.moviePreloadTimeout,
            execute: workItem
        )
        
        let loadStart = Date()
        moviesLoader.loadMovies { [weak self] result in
            guard let self else { return }
            let elapsed = Date().timeIntervalSince(loadStart)
            let remaining = max(0, Self.moviePreloadTimeout - elapsed)
            if remaining < 0.1 {
                self.finishPreload(using: .timeoutOrIncomplete)
                return
            }
            switch result {
            case .success(let list):
                self.stateLock.withLock { self.movies = list.items }
                self.fetchPostersInParallel(
                    from: list.items,
                    loadStart: loadStart
                )
            case .failure:
                self.finishPreload(using: .timeoutOrIncomplete)
            }
        }
    }
    
    private enum PreloadFinish {
        case successFromAPI([PreloadedFrame])
        case timeoutOrIncomplete
    }
    
    private func finishPreload(using kind: PreloadFinish) {
        var shouldNotify = false
        stateLock.lock()
        if didFinishPreload {
            stateLock.unlock()
            return
        }
        didFinishPreload = true
        cancelPreloadTimeout()
        switch kind {
        case .successFromAPI(let frames) where frames.count == Self.targetPosterCount:
            preloadedFrames = frames
            shouldNotify = true
        case .successFromAPI:
            preloadedFrames = Self.buildFallbackFrames()
            shouldNotify = true
        case .timeoutOrIncomplete:
            preloadedFrames = Self.buildFallbackFrames()
            shouldNotify = true
        }
        stateLock.unlock()
        if shouldNotify {
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.didLoadDataFromServer()
            }
        }
    }
    
    private func cancelPreloadTimeout() {
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
    }
    
    /// Ключ для сравнения «один и тот же фильм» при дедупликации очереди и принятых кадров.
    private static func deduplicationKey(for movie: MostPopularMovie) -> String {
        movie.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    /// Один фильм — один кандидат на загрузку (без повторов названия в очереди).
    private static func uniqueMoviePairsShuffled(
        _ pairs: [(MostPopularMovie, URL)]
    ) -> [(MostPopularMovie, URL)] {
        var seenKeys = Set<String>()
        var out: [(MostPopularMovie, URL)] = []
        for pair in pairs.shuffled() {
            let key = deduplicationKey(for: pair.0)
            if seenKeys.insert(key).inserted {
                out.append(pair)
            }
        }
        return out
    }
    
    private func fetchPostersInParallel(
        from allMovies: [MostPopularMovie],
        loadStart: Date
    ) {
        let withURL: [(MostPopularMovie, URL)] = allMovies.compactMap { m in
            guard let u = m.resizedImageURL else { return nil }
            return (m, u)
        }
        let queue = Self.uniqueMoviePairsShuffled(withURL)
        guard !queue.isEmpty else {
            finishPreload(using: .timeoutOrIncomplete)
            return
        }
        
        var collected: [PreloadedFrame] = []
        var seenTitles = Set<String>()
        var queueIndex = 0
        var inFlight = 0
        let fetchLock = NSLock()
        
        func dequeue() -> (MostPopularMovie, URL)? {
            guard queueIndex < queue.count else { return nil }
            let item = queue[queueIndex]
            queueIndex += 1
            return item
        }
        
        func tryFinishIfExhausted() {
            fetchLock.lock()
            let exhausted = queueIndex >= queue.count && inFlight == 0
            let count = collected.count
            fetchLock.unlock()
            if exhausted, count < Self.targetPosterCount {
                finishPreload(using: .timeoutOrIncomplete)
            }
        }
        
        func pump() {
            while true {
                fetchLock.lock()
                if collected.count >= Self.targetPosterCount {
                    let ten = Array(collected.prefix(Self.targetPosterCount))
                    fetchLock.unlock()
                    finishPreload(using: .successFromAPI(ten))
                    return
                }
                let elapsed = Date().timeIntervalSince(loadStart)
                if elapsed >= Self.moviePreloadTimeout {
                    fetchLock.unlock()
                    tryFinishIfExhausted()
                    return
                }
                if inFlight >= Self.maxConcurrentPosterFetches {
                    fetchLock.unlock()
                    return
                }
                guard let (movie, url) = dequeue() else {
                    let flight = inFlight
                    fetchLock.unlock()
                    if flight == 0 {
                        tryFinishIfExhausted()
                    }
                    return
                }
                inFlight += 1
                fetchLock.unlock()
                
                imageNetwork.fetch(url: url) { [weak self] result in
                    guard let self else { return }
                    fetchLock.lock()
                    inFlight -= 1
                    if Date().timeIntervalSince(loadStart) < Self.moviePreloadTimeout,
                       case .success(let data) = result,
                       !data.isEmpty,
                       UIImage(data: data) != nil,
                       collected.count < Self.targetPosterCount {
                        let key = Self.deduplicationKey(for: movie)
                        if seenTitles.insert(key).inserted {
                            let rating = Float(movie.rating) ?? 0
                            collected.append(PreloadedFrame(imageData: data, rating: rating))
                        }
                    }
                    let haveTen = collected.count >= Self.targetPosterCount
                    let snapshot = haveTen ? Array(collected.prefix(Self.targetPosterCount)) : nil
                    fetchLock.unlock()
                    if let ten = snapshot, ten.count == Self.targetPosterCount {
                        self.finishPreload(using: .successFromAPI(ten))
                        return
                    }
                    pump()
                    tryFinishIfExhausted()
                }
            }
        }
        
        pump()
    }
    
    private static func buildFallbackFrames() -> [PreloadedFrame] {
        let items: [(imageName: String, rating: Float)] = [
            ("The Godfather", 9.2),
            ("The Dark Knight", 9.0),
            ("Kill Bill", 8.2),
            ("The Avengers", 8.0),
            ("Deadpool", 8.0),
            ("The Green Knight", 6.6),
            ("Old", 5.8),
            ("The Ice Age Adventures of Buck Wild", 4.3),
            ("Tesla", 5.1),
            ("Vivarium", 5.8)
        ]
        var result: [PreloadedFrame] = []
        var seenAssetNames = Set<String>()
        var seenImageData = Set<Data>()
        for item in items {
            guard result.count < targetPosterCount else { break }
            guard seenAssetNames.insert(item.imageName).inserted else { continue }
            guard let image = UIImage(named: item.imageName) else { continue }
            let data = image.jpegData(compressionQuality: 1.0) ?? image.pngData() ?? Data()
            guard !data.isEmpty else { continue }
            guard seenImageData.insert(data).inserted else { continue }
            result.append(PreloadedFrame(imageData: data, rating: item.rating))
        }
        return result
    }
}

private extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}
