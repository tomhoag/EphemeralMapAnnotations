//
//  EphAnimationConstants.swift
//  EphemeralMapAnnotations
//
//  Created by Tom Hoag on 3/27/25.
//


import SwiftUI
import MapKit

/**
 Constants used for animation timing and behavior throughout the ephemeral annotation system.
 */
public enum EphAnimationConstants {
    public static let duration: CGFloat = 0.5
    public static let addingAnimation = Animation.spring(duration: duration, bounce: 0.5)
    public static let removingAnimation = Animation.easeInOut(duration: duration)
}

/**
 Base protocol defining read-only requirements for map annotations.

 This protocol provides the fundamental properties needed to identify and position
 an annotation on a map. It requires conformance to `Hashable` and `Equatable`
 for unique identification and comparison of annotations.
 */
public protocol EphDerivable: Hashable, Equatable {
    var id: Int { get }
    var coordinate: CLLocationCoordinate2D { get }
}

/**
 Protocol defining mutable requirements for map annotations.

 Extends `EphDerivable` to add mutability to the base properties, allowing
 annotations to be updated during their lifecycle.
 */
public protocol EphRepresentable: EphDerivable {
    var id: Int { get set }
    var coordinate: CLLocationCoordinate2D { get set }
}

/**
 Protocol for types that provide collections of map annotations.

 Implementing types must specify the concrete type of annotations they provide
 through the associated type `EphRepresentableType`.

 Example implementation:
 ```swift
 struct MyProvider: EphRepresentableProvider {
     typealias EphRepresentableType = MyAnnotationType
     @State var places: [MyAnnotationType] = []
 }
 ```
 */
public protocol EphRepresentableProvider {
    associatedtype EphRepresentableType: EphRepresentable
    var places: [EphRepresentableType] { get set }
}

/**
 Class managing the visibility state of a map annotation.

 This observable class tracks whether an annotation should be visible on the map
 and whether it's in the process of being removed. It works in conjunction with
 animation modifiers to provide smooth transitions.

 - Important: This class is ObservableObject and can be used with @StateObject or @ObservedObject.
 Changing to @Observable is not recommended as it leads to unexpected behavior.
 */
public class EphAnnotationState<P: EphRepresentable>: ObservableObject {
    public let place: P
    @Published public var isVisible: Bool
    @Published public var isRemoving: Bool

    /**
     Creates a new annotation state.

     - Parameters:
        - place: The annotation to manage
        - isVisible: Initial visibility state
        - isRemoving: Initial removal state
     */
    public init(place: P, isVisible: Bool = false, isRemoving: Bool = false) {
        self.place = place
        self.isVisible = isVisible
        self.isRemoving = isRemoving
    }
}

/**
 ViewModifier that manages the lifecycle of map annotations.

 Handles the addition and removal of annotations with appropriate animations.
 Automatically cleans up removed annotations after their exit animation completes.
 */
public struct EphRepresentableChangeModifier<Provider: EphRepresentableProvider>: ViewModifier {
    public let provider: Provider
    @Binding public var previousPlaces: [Provider.EphRepresentableType]?
    @Binding public var annotationStates: [EphAnnotationState<Provider.EphRepresentableType>]
    public var animationDuration: CGFloat = EphAnimationConstants.duration

    public func body(content: Content) -> some View {
        content
            .onChange(of: provider.places) { _, newPlaces in
                guard let previousPlaces = self.previousPlaces else {
                    self.previousPlaces = newPlaces
                    annotationStates = newPlaces.map { EphAnnotationState(place: $0) }
                    return
                }

                let currentIds = Set(newPlaces.map { $0.id })
                let oldIds = Set(previousPlaces.map { $0.id })

                let newStates = newPlaces.filter { !oldIds.contains($0.id) }
                    .map { EphAnnotationState(place: $0) }
                annotationStates.append(contentsOf: newStates)

                for state in annotationStates where !currentIds.contains(state.place.id) {
                    state.isRemoving = true
                    state.isVisible = false
                }

                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(animationDuration))
                    annotationStates.removeAll { !currentIds.contains($0.place.id) }
                }

                self.previousPlaces = newPlaces
            }
    }
}

/**
 ViewModifier that applies ephemeral animation effects to a view.

 Handles the fade in/out and scale animations for views as they appear and disappear.
 */
public struct EphemeralEffectModifier<P: EphRepresentable>: ViewModifier {
    @ObservedObject public var annotationState: EphAnnotationState<P>
    public var addingAnimation: Animation = EphAnimationConstants.addingAnimation
    public var removingAnimation: Animation = EphAnimationConstants.removingAnimation

    public func body(content: Content) -> some View {
        content
            .opacity(annotationState.isVisible ? 1 : 0)
            .scaleEffect(annotationState.isVisible ? 1 : 0)
            .animation(
                annotationState.isRemoving ?
                    removingAnimation :
                    addingAnimation,
                value: annotationState.isVisible
            )
            .onAppear {
                if !annotationState.isRemoving {
                    annotationState.isVisible = true
                }
            }
    }
}

public extension View {
    /**
     Applies the ephemeral map annotation change modifier to a view.

     - Parameters:
        - provider: The source of annotation data
        - previousPlaces: Binding to track the previous state of annotations
        - annotationStates: Binding to the current annotation states
        - animationDuration: The duration of the longer of the two (adding, removing) animations used in the ephemeralEffect modifier. If no animations are specified there, this parameter should not be passed in.
     */
    func onEphRepresentableChange<Provider: EphRepresentableProvider>(
        provider: Provider,
        previousPlaces: Binding<[Provider.EphRepresentableType]?>,
        annotationStates: Binding<[EphAnnotationState<Provider.EphRepresentableType>]>,
        animationDuration: CGFloat = EphAnimationConstants.duration
    ) -> some View {
        modifier(EphRepresentableChangeModifier(
            provider: provider,
            previousPlaces: previousPlaces,
            annotationStates: annotationStates,
            animationDuration: animationDuration
        ))
    }

    /**
     Applies ephemeral animation effects to a view.

     - Parameter annotationState: The state controlling the view's animations
     */
    func ephemeralEffect<P: EphRepresentable>(
        annotationState: EphAnnotationState<P>,
        addingAnimation: Animation = EphAnimationConstants.addingAnimation,
        removingAnimation: Animation = EphAnimationConstants.removingAnimation
    ) -> some View {
        modifier(
            EphemeralEffectModifier(
                annotationState: annotationState,
                addingAnimation: addingAnimation,
                removingAnimation: removingAnimation
            )
        )
    }
}
