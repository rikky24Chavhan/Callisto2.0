//
//  MockURLSession.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 4/10/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation

// MARK: - URLSession

class MockURLSession: URLSession, MockURLSessionUploadTaskDelegate {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?

    var taskCompletionHandlers: [URLSessionTask : (Data?, URLResponse?, Error?) -> Void] = [:]

    override func uploadTask(with request: URLRequest, from bodyData: Data?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTask {
        let task = MockURLSessionUploadTask(delegate: self)
        taskCompletionHandlers[task] = completionHandler
        return task
    }

    func mockUploadTaskDidResume(_ task: MockURLSessionUploadTask) {
        let completionHandler = taskCompletionHandlers[task]
        completionHandler?(mockData, mockResponse, mockError)
        taskCompletionHandlers[task] = nil
    }
}

// MARK: - URLSessionTasks

protocol MockURLSessionUploadTaskDelegate: class {
    func mockUploadTaskDidResume(_ task: MockURLSessionUploadTask)
}

class MockURLSessionUploadTask: URLSessionUploadTask {
    weak var delegate: MockURLSessionUploadTaskDelegate?

    init(delegate: MockURLSessionUploadTaskDelegate) {
        self.delegate = delegate
    }

    override func resume() {
        delegate?.mockUploadTaskDidResume(self)
    }
}
