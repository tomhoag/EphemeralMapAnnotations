# Ephemeral Map Annotations

Using the SwiftUI Map can be tricky when you want specific animations to occur.  This package specifically addresses the animation of addition and removal of map annotations.

https://github.com/user-attachments/assets/a63e05d4-3ba3-4ec8-8c3a-9d1a23ef284b

### The Setup

Using `EphemeralMapAnnotations` requires a small bit of setup. 

1. Define a struct that will wrap the `CLLocationCoordinate2D`'s and make it conform to the `EphRepresentable` protocol.

	```
	struct Location: EphRepresentable {
	    // EphRepresentable requires conformance to Equatable.
	    // Add the necessary conformance function here . . 
	    
	    var id: Int
	    var coordinate: CLLocationCoordinate2D
	}
	```

2. The class or struct that declares your array of `EphRepresentable`s must conform to `EphRepresentableProvider`.  This is likely either the view that holds the `Map` or the view model of the view that holds the `Map`

	```
	struct ContentView: View, EphRepresentableProvider {
	    @State var ephemeralPlaces: [Location] = []
	    @State var stateManager = EphStateManager<Location>()
	
		<< other struct stuff>>
	}
	```
The EphStateManager requires the type being managed be specified as shown.

## The Map

Setup your `Map` as usual and add the `EphRepresentable` locations as `Annotations` by invoking `annotations` on your state manager as shown below.

```
Map(position: $cameraPosition, interactionModes: .all) {
    ForEach(stateManager.annotations, id:\.place.id) { state in
        Annotation(state.place.name, coordinate: state.place.coordinate) {
            Circle()
                .frame(width: 20)
                .foregroundColor(.red)
                .ephemeralEffect(annotationState: state)
       }
    }
}
.onEphRepresentableChange( ephemeralManager )
```

Each Annotation View should have the `.ephemeralEffect(annotationState: )` modifier added to it and the Map should have the `.onEphRepresentableChange(provider: )` modifier added to it.  The provider parameter should be set to the instance that conforms to `EphRepresentableProvider`


### See ContentView.swift for a full example.
