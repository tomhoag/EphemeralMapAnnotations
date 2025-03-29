//
//  EphemeralMapAnnotations.swift
//
//  Created by Tom Hoag on 3/23/25.
//

import SwiftUI
import MapKit

/**
 Protocol defining mutable requirements for map annotations.
 */
public protocol Ephemeral: Equatable, Identifiable {
    associatedtype ID: Hashable
    var id: ID { get set }
    var coordinate: CLLocationCoordinate2D { get set }
}

@MainActor @Observable
public class EphemeralManager<ER: Ephemeral> {
    public var previousPlaces: [ER]?
    public var items: [EphemeralItem<ER>] = []

    public init() {}
}

/**
 Class managing the visibility state of a map annotation view.

 This observable class tracks whether an annotation should be visible on the map
 and whether it's in the process of being removed. It works in conjunction with
 animation modifiers to provide smooth transitions.

 - Important: This class is @ObservableObject and can be used with @StateObject or @ObservedObject.
 Changing to @Observable leads to unexpected behavior.
 */
public class EphemeralItem<ER: Ephemeral>: ObservableObject {
    /// The annotation being managed
    public let place: ER
    /// Current visibility state
    @Published public private(set) var isVisible: Bool
    /// Whether the annotation is being removed
    @Published public private(set) var isRemoving: Bool

    /**
     Creates a new annotation state.

     - Parameters:
        - place: The annotation to manage
        - isVisible: Initial visibility state
        - isRemoving: Initial removal state
     */
    public init(place: ER, isVisible: Bool = false, isRemoving: Bool = false) {
        self.place = place
        self.isVisible = isVisible
        self.isRemoving = isRemoving
    }

    public func makeVisible() {
        isVisible = true
    }

    public func makeInvisible() {
        isVisible = false
    }

    public func prepareForRemoval() {
        isRemoving = true
        makeInvisible()
    }
}
