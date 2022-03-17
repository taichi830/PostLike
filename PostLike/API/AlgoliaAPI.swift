//
//  AlgoliaAPI.swift
//  PostLike
//
//  Created by taichi on 2022/03/17.
//  Copyright © 2022 taichi. All rights reserved.
//

import InstantSearchClient
import RxSwift


final class AlgoliaAPI {
    
    static let shared = AlgoliaAPI()
    
    func callAlgolia(text: String) -> Observable<[Post_Like]> {
        return Observable.create { observer in
            #if DEBUG
            let appID = "AT9Z5755AK"
            let apiKey = "91c505ad021fe4eaf299f4a9d15fbd2b"
            let indexName = "PostLike_dev"
            #else
            let appID = "GICHEEECDF"
            let apiKey = "e66bef3d0dd124854d5137007a5aafc2"
            let indexName = "rooms"
            #endif
            
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


