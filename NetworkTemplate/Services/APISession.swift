//
//  APISession.swift
//  LocalformanceBeta
//
//  Created by Admin on 27/05/2021.
//

import Combine
import Foundation

var cancellable: AnyCancellable?

class APISession: NSObject, NetworkService {
    lazy var decoder: JSONDecoder = {
        let jd = JSONDecoder()
        // jd.dateDecodingStrategy = .secondsSince1970
        return jd
    }()

    lazy var session: URLSession = {
        print("ici")
        return .init(configuration: .default, delegate: self, delegateQueue: nil)
    }()

    func execute(_ request: URLRequest) -> AnyPublisher<Data, NetworkServiceError> {
        print("requête : \(request); \(request.httpMethod!); \(String(data: request.httpBody ?? Data(), encoding: .utf8)!)")
        guard let _ = request.url else {
            return Fail(error: NetworkServiceError.invalidRequest).eraseToAnyPublisher()
        }
        return session.dataTaskPublisher(for: request)
            .tryMap { (data, response) -> Data in
                guard let response = response as? HTTPURLResponse else {
                    throw NetworkServiceError.unknownError
                }
                print(String(data: data, encoding: .utf8)!)
                switch response.statusCode {
                case 200 ... 299: return data
                default: throw self.httpError(response.statusCode)
                }
            }
            .mapError { error in
                self.handleError(error)
            }
            .eraseToAnyPublisher()
    }
}


extension APISession {
    func upload(
        request: URLRequest,
        fileURL: URL
    ) -> AnyPublisher<FileResponse, NetworkServiceError> {
        return session.uploadTaskPublisher(request: request, fileURL: fileURL)
            .tryMap { (data, response, progress) -> FileResponse in
                guard let data = data, let response = response else { return FileResponse.progress(percentage: progress) }
                guard let response = response as? HTTPURLResponse else {
                    throw NetworkServiceError.unknownError
                }
                print(String(data: data, encoding: .utf8)!)
                switch response.statusCode {
                case 200 ... 299: return .data(data)
                default: throw self.httpError(response.statusCode)
                }
            }
            .mapError { error in
                self.handleError(error)
            }
            .eraseToAnyPublisher()
    }

    func download(
        request: URLRequest
    ) -> AnyPublisher<FileResponse, NetworkServiceError> {
        return session.downloadTaskPublisher(request: request)
            .tryMap { (data, response, progress) -> FileResponse in
                guard response != nil else { return FileResponse.progress(percentage: progress) }
                guard let data = data else { throw NetworkServiceError.readingDownloadedFileError }
                guard let response = response as? HTTPURLResponse else {
                    throw NetworkServiceError.unknownError
                }
                switch response.statusCode {
                case 200 ... 299: return .data(data)
                default: throw self.httpError(response.statusCode)
                }
            }
            .mapError { error in
                self.handleError(error)
            }
            .eraseToAnyPublisher()
    }
}

extension APISession: URLSessionTaskDelegate, URLSessionDelegate {
        func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
            DispatchQueue.main.async {
//                self.savedCompletionHandler?()
//                self.savedCompletionHandler = nil
            }
        }
}

// extension APISession: URLSessionTaskDelegate, URLSessionDownloadDelegate {
//    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
//        print("finish")
//    }
//
//    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
//        print("fini")
//    }
//
//    func urlSession(
//        _ session: URLSession,
//        task: URLSessionTask,
//        didSendBodyData bytesSent: Int64,
//        totalBytesSent: Int64,
//        totalBytesExpectedToSend: Int64
//     ) {
//        progress.send((
//            id: task.taskIdentifier,
//            progress: task.progress.fractionCompleted
//        ))
//     }
//
//    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
//        print("lol")
//        //let percentage: Double = Double(totalBytesWritten)/Double(totalBytesExpectedToWrite)
//        progress.send((
//            id: downloadTask.taskIdentifier,
//            progress: downloadTask.progress.fractionCompleted
//        ))
//    }
// }
