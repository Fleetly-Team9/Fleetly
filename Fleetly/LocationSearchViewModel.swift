//
//  LocationSearchViewModel.swift
//  Fleetly
//
//  Created by User@Param on 26/04/25.
//
import SwiftUI
import MapKit

class LocationSearchViewModel: NSObject, ObservableObject {
    @Published var fromSearchResults: [MKLocalSearchCompletion] = []
    @Published var toSearchResults: [MKLocalSearchCompletion] = []
    @Published var selectedPickupLocation: MKMapItem?
    @Published var selectedDropoffLocation: MKMapItem?
    
    private var searchCompleter = MKLocalSearchCompleter()
    private var isSearchingFrom = true // Track which field is being searched
    
    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
    }
    
    func searchForLocations(_ query: String, isFrom: Bool) {
        if query.isEmpty {
            if isFrom {
                fromSearchResults = []
            } else {
                toSearchResults = []
            }
            return
        }
        
        isSearchingFrom = isFrom // Update search context
        searchCompleter.queryFragment = query
    }
    
    func selectLocation(_ searchCompletion: MKLocalSearchCompletion, isPickup: Bool) {
        let searchRequest = MKLocalSearch.Request(completion: searchCompletion)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { [weak self] response, error in
            guard let response = response, let firstItem = response.mapItems.first else {
                print("Error searching for location: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                if isPickup {
                    self?.selectedPickupLocation = firstItem
                    self?.fromSearchResults = [] // Clear from results
                } else {
                    self?.selectedDropoffLocation = firstItem
                    self?.toSearchResults = [] // Clear to results
                }
            }
        }
    }
}

extension LocationSearchViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            if self.isSearchingFrom {
                self.fromSearchResults = completer.results
            } else {
                self.toSearchResults = completer.results
            }
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error.localizedDescription)")
    }
}
