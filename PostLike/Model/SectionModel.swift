//
//  SectionModel.swift
//  PostLike
//
//  Created by taichi on 2022/01/28.
//  Copyright © 2022 taichi. All rights reserved.
//

import Foundation
import RxDataSources

//typealias SampleSectionModel = AnimatableSectionModel<SectionID, SampleSectionItem>

public struct AnimatableSectionModel<Section:IdentifiableType, ItemType: IdentifiableType & Equatable> {
    public var model: Section
    public var items: [Item]
    
    public init(model: Section,items: [ItemType]) {
        self.model = model
        self.items = items
    }
}

extension AnimatableSectionModel: AnimatableSectionModelType {
    public typealias Item = ItemType
    public typealias Identity = Section.Identity
    
    public var identity: Section.Identity {
        return model.identity
    }
    
    public init(original: AnimatableSectionModel, items: [ItemType]) {
        self.model = original.model
        self.items = items
    }
    
    public var hashValue: Int {
        return self.model.identity.hashValue
    }
}



//enum SampleSectionItem: IdentifiableType, Equatable {
//    
//    
//}



























