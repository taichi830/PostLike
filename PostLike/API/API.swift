//
//  API.swift
//  PostLike
//
//  Created by taichi on 2022/04/29.
//  Copyright © 2022 taichi. All rights reserved.
//

import InstantSearchClient
import RxSwift


final class AlgoliaAPI {
    
    static let shared = AlgoliaAPI()
    
    func callAlgolia(text: String) -> Observable<[Result]> {
        return Observable.create { observer in
            
            let appID = AccessTokens.appID
            let apiKey = AccessTokens.searchKey
            let indexName = AccessTokens.indexName
            let client = Client(appID: appID, apiKey: apiKey)
            let index = client.index(withName: indexName)
            let query = Query(query: text)
            index.search(query, completionHandler: { (content,err) -> Void in
                do {
                    guard let content = content else { fatalError("no content") }
                    let data = try JSONSerialization.data(withJSONObject: content, options: .prettyPrinted)
                    let response = try JSONDecoder().decode(Hits.self, from: data)
                    observer.onNext(response.hits)
                    observer.onCompleted()
                } catch {
                    guard let err = err else { return }
                    print(err)
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
        
    }
    
    
    
}
