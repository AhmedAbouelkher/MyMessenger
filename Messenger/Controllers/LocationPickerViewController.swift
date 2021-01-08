//
//  LocationPickerViewController.swift
//  Messenger
//
//  Created by Ahmed on 1/6/21.
//  Copyright © 2021 Ahmed. All rights reserved.
//

import UIKit
import MapKit

class LocationPickerViewController: UIViewController {
    
    public var completion: ((CLLocationCoordinate2D) -> Void)?
    
    private var coordinates: CLLocationCoordinate2D?
    private var isPickable = true
    
    private let map: MKMapView = {
       let map = MKMapView()
        map.isUserInteractionEnabled = true
        return map
    }()
    
    init(coordinates: CLLocationCoordinate2D?) {
        self.coordinates = coordinates
        if coordinates != nil {
            self.isPickable = false
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemBackground
        
        navigationItem.backButtonTitle = "Back"

        
        if isPickable {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "paperplane"),
                style: .done,
                target: self,
                action: #selector(didTapSend)
            )
            
            let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapOnMap))
            gesture.numberOfTouchesRequired = 1
            gesture.numberOfTapsRequired = 1
            map.addGestureRecognizer(gesture)
        } else {
            guard let coordinate = self.coordinates else { return }
            let pin = MKPointAnnotation()
            pin.coordinate = coordinate
            map.addAnnotation(pin)
        }
        view.addSubview(map)
        map.delegate = self
    }
    
    @objc private func didTapOnMap(_ gesture: UITapGestureRecognizer) {
        let locationInView = gesture.location(in: map)
        let coordinates = map.convert(locationInView, toCoordinateFrom: map)
        self.coordinates = coordinates
        
        map.annotations.forEach { map.removeAnnotation($0) }
        
        let pin = MKPointAnnotation()
        pin.coordinate = coordinates
        map.addAnnotation(pin)
    }
    
    @objc private func didTapSend() {
        guard let coords = self.coordinates else {
            return
        }
        navigationController?.popViewController(animated: true)
        self.completion?(coords)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        map.frame = view.bounds
    }
    
}

extension LocationPickerViewController : MKMapViewDelegate{
}
