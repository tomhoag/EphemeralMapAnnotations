# Ephemeral Map Annotations

Using the SwiftUI Map can be tricky when you want specific animations to occur.  This package specifically addresses the animation of addition and removal of map annotations.

### The Setup



The animation requires that the `CLLocationCoordinate2D`'s used to create `MapAnnotations` be wrapped in an struct that conforms to `EphRepresentable`.

```
struct Locations: EphRepresentable {
    // EphRepresentable requires conformance to Identifiable and Equatable.
    // Add the necessary conformance functions here . . 
    
    var id: Int
    var coordinate: CLLocationCoordinate2D
}
```

There are a couple additional vars required in the view that holds the Map:

```
@State private var previousPlaces: [Location]?
@State private var annotationStates: [EphAnnotationState<Location>] = []
```
    
In the View that holds your Locations, you will need to typealias your Locations to `EphRepresentableType` and type your `locations` array as EphRepresentable Type:

```
typealias EphRepresentableType = Location
@State var locations: [EphRepresentableType] = []
```

Your locations array can be held in the view that holds the map, or if you prefer it can be held in the view's model. You only need to be able to reference the provider in the map modifier.

### The Map Modifier

As your locations update, animate their removal and addition using the `.onEphRepresentableChange` modifiler on the Map.

```
Map(position: $cameraPosition, interactionModes: .all) {
                ForEach(annotationStates, id: \.place.id) { state in
                    Annotation(state.place.name, coordinate: state.place.coordinate) {
                    	EphSystemImageAnnotationView<Locations>(annotationState: state)
                }
            }
            .padding()
            .onAppear {
                Task { @MainActor in
                    updateLocations()
                    cameraPosition = .region(mapRegion)
                }
            }
            .onEphRepresentableChange(
                provider: self,
                previousPlaces: $previousPlaces,
                annotationStates: $annotationStates
            )
```
The provider property should be set to the instance or struct that holds the reference to your array of [EphRepresentable] -- likely the view that holds the map or the views model.

## Customizing the Map Annotation
