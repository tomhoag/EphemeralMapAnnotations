//
//  View+Ephemeral.swift
//  MapAnimations
//
//  Created by Tom Hoag on 3/27/25.
//

import SwiftUI

// MARK: Constants

/**
 Constants used for animation timing and behavior throughout the ephemeral system.
 */
public enum EphAnimationConstants {
    /// Duration of animations in seconds
    public static let duration: CGFloat = 0.5
    /// Spring animation used when adding annotations
    public static let addingAnimation = Animation.spring(duration: duration, bounce: 0.5)
    /// Ease in-out animation used when removing annotations
    public static let removingAnimation = Animation.easeInOut(duration: duration)
}

// MARK: EphemeralChangeModifer

/**
 ViewModifier that manages the lifecycle of map annotations.

 Handles the addition and removal of annotations with appropriate animations.
 Automatically cleans up removed annotations after their exit animation completes.
 */
public struct EphemoralChangeModifier<ER: Ephemeral>: ViewModifier {
    let ephemeralPlaces: [ER]
    let ephemeralManager: EphemeralManager<ER>
    var animationDuration: CGFloat = EphAnimationConstants.duration
    @State private var cleanupTask: Task<Void, Never>?

    public func body(content: Content) -> some View {
        content
            .onChange(of: ephemeralPlaces) { _, newPlaces in
                guard let previousPlaces = ephemeralManager.previousPlaces else {
                    ephemeralManager.previousPlaces = newPlaces
                    ephemeralManager.items = newPlaces.map { EphemeralItem(place: $0) }
                    return
                }

                let changes = calculateChanges(oldPlaces: previousPlaces, newPlaces: newPlaces)

                // Add new states
                ephemeralManager.items.append(contentsOf: changes.toAdd.map { EphemeralItem(place: $0) })

                // Mark states for removal
                for state in ephemeralManager.items where changes.toRemove.contains(state.place.id) {
                    state.prepareForRemoval()
                }

                // Cancel and remove existing task
                cleanupTask?.cancel()

                // Start new cleanup
                cleanupTask = Task {
                    try? await Task.sleep(for: .seconds(animationDuration))
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        ephemeralManager.items.removeAll { changes.toRemove.contains($0.place.id) }
                    }
                }

                ephemeralManager.previousPlaces = newPlaces
            }
            .onDisappear {
                cleanupTask?.cancel()
            }
    }

    private struct Changes<ER: Ephemeral> {
        let toAdd: [ER]
        let toRemove: Set<ER.ID>
    }

    private func calculateChanges<ER: Ephemeral>(oldPlaces: [ER], newPlaces: [ER]) -> Changes<ER> {
        let oldDict = Dictionary(uniqueKeysWithValues: oldPlaces.map { ($0.id, $0) })
        let newDict = Dictionary(uniqueKeysWithValues: newPlaces.map { ($0.id, $0) })

        let toAdd = newPlaces.filter { place in
            !oldDict.keys.contains(place.id)
        }
        let toRemove = Set(oldDict.keys).subtracting(newDict.keys)

        return Changes(toAdd: toAdd, toRemove: toRemove)
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
    func onEphemoralChange<ER: Ephemeral>(
        ephemeralPlaces: [ER],
        ephemeralManager: EphemeralManager<ER>,
        animationDuration: CGFloat = EphAnimationConstants.duration
    ) -> some View {
        modifier(EphemoralChangeModifier(
            ephemeralPlaces: ephemeralPlaces,
            ephemeralManager: ephemeralManager,
            animationDuration: animationDuration
        ))
    }
}

// MARK: EphemeralEffectModifer

/**
 ViewModifier that applies ephemeral animation effects to an annotation views as they appear and disappear.
 */
public struct EphemeralEffectModifier<E: Ephemeral>: ViewModifier {
    @ObservedObject var ephemeralItem: EphemeralItem<E>
    var addingAnimation: Animation = EphAnimationConstants.addingAnimation
    var removingAnimation: Animation = EphAnimationConstants.removingAnimation

    public func body(content: Content) -> some View {
        content
            .opacity(ephemeralItem.isVisible ? 1 : 0)
            .scaleEffect(ephemeralItem.isVisible ? 1 : 0)
            .animation(
                ephemeralItem.isRemoving ?
                    removingAnimation :
                    addingAnimation,
                value: ephemeralItem.isVisible
            )
            .onAppear {
                if !ephemeralItem.isRemoving {
                    ephemeralItem.makeVisible()
                }
            }
    }
}

public extension View {
    /**
     Applies ephemeral animation effects to a view.

     - Parameter annotationState: The state controlling the view's animations
     */
    func ephemeralEffect<E: Ephemeral>(
        ephemeralItem: EphemeralItem<E>,
        addingAnimation: Animation = EphAnimationConstants.addingAnimation,
        removingAnimation: Animation = EphAnimationConstants.removingAnimation
    ) -> some View {
        modifier(
            EphemeralEffectModifier(
                ephemeralItem: ephemeralItem,
                addingAnimation: addingAnimation,
                removingAnimation: removingAnimation
            )
        )
    }
}
