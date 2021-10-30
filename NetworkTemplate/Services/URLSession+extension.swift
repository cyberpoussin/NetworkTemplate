//
//  URLSession+extension.swift
//  NetworkTemplate
//
//  Created by Admin on 21/10/2021.
//

import Combine
import Foundation

enum Either<Left, Right> {
    case left(Left)
    case right(Right)

    var left: Left? {
        switch self {
        case let .left(value):
            return value
        case .right:
            return nil
        }
    }

    var right: Right? {
        switch self {
        case let .right(value):
            return value
        case .left:
            return nil
        }
    }
}

extension URLSession {
    func dataTaskPublisherWithProgress(for url: URL) -> AnyPublisher<Either<Progress, (data: Data, response: URLResponse)>, URLError> {
        typealias TaskEither = Either<Progress, (data: Data, response: URLResponse)>
        let completion = PassthroughSubject<(data: Data, response: URLResponse), URLError>()
        let task = dataTask(with: url) { data, response, error in
            if let data = data, let response = response {
                completion.send((data, response))
                completion.send(completion: .finished)
            } else if let error = error as? URLError {
                completion.send(completion: .failure(error))
            } else {
                fatalError("This should be unreachable, something is clearly wrong.")
            }
        }
        task.resume()
        return task.publisher(for: \.progress.completedUnitCount)
            .compactMap { [weak task] _ in task?.progress }
            .setFailureType(to: URLError.self)
            .map(TaskEither.left)
            .merge(with: completion.map(TaskEither.right))
            .eraseToAnyPublisher()
    }

    func uploadTaskPublisher(
        request: URLRequest,
        fileURL: URL
    ) -> AnyPublisher<(Data?, URLResponse?, Double), Error> {
        let subject: PassthroughSubject<(Data?, URLResponse?, Double), Error> = .init()
        let task: URLSessionUploadTask = uploadTask(
            with: request,
            fromFile: fileURL
        ) { data, response, error in
            if let error = error {
                subject.send(completion: .failure(error))
            } else {
                subject.send((data, response, 1))
                subject.send(completion: .finished)
            }
        }
        let sent = task.publisher(for: \.countOfBytesSent)
            .throttle(for: .milliseconds(100), scheduler: DispatchQueue.main, latest: true)
            .removeDuplicates() // adjust
        let expectedToSend = task.publisher(for: \.countOfBytesExpectedToSend, options: [.initial, .new])
            .throttle(for: .milliseconds(100), scheduler: DispatchQueue.main, latest: true)

        task.resume()
        return Publishers.CombineLatest(sent, expectedToSend)
            .setFailureType(to: Error.self)
            .map { received, expected in
                print("received : \(received) and expected: \(expected)")
                guard expected != 0 else { return (nil, nil, 0) }
                return (nil, nil, Double(received) / Double(expected))
            }
            .merge(with: subject)
            .handleEvents(receiveCancel: {
                task.cancel()
            })
            .eraseToAnyPublisher()
    }

    func downloadTaskPublisher(
        request: URLRequest
    ) -> AnyPublisher<(Data?, URLResponse?, Double), Error> {
        let subject: PassthroughSubject<(Data?, URLResponse?, Double), Error> = .init()
        let task: URLSessionDownloadTask = downloadTask(
            with: request
        ) { url, response, error in
            if let error = error {
                subject.send(completion: .failure(error))
                return
            }
            guard let url = url, let data = try? Data(contentsOf: url, options: [.dataReadingMapped, .uncached]) else {
                let error = URLError(.fileDoesNotExist)
                // not the most appropriate error message, but at a low-level that's exactly the error
                subject.send(completion: .failure(error))
                return
            }
            subject.send((data, response, 1))
            subject.send(completion: .finished)
        }
        let receivedPublisher = task.publisher(for: \.countOfBytesReceived)
            .throttle(for: .milliseconds(100), scheduler: DispatchQueue.main, latest: true) // adjust
        let expectedPublisher = task.publisher(for: \.countOfBytesExpectedToReceive, options: [.initial, .new])
            .throttle(for: .milliseconds(100), scheduler: DispatchQueue.main, latest: true)
        task.resume()
        return Publishers.CombineLatest(receivedPublisher, expectedPublisher)
            .setFailureType(to: Error.self)
            .map { received, expected in
                print("received : \(received) and expected: \(expected)")
                guard expected != 0 else { return (nil, nil, 0) }
                return (nil, nil, Double(received) / Double(expected))
            }
            .merge(with: subject)
            .handleEvents(receiveCancel: {
                task.cancel()
            })
            .eraseToAnyPublisher()
    }
}
