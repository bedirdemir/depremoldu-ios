import SwiftUI
import MapKit
import DepremOlduDomain
import DepremOlduFaults

struct EarthquakeMapItem: Identifiable, Equatable {
    let earthquake: Earthquake
    let coordinate: CLLocationCoordinate2D

    var id: String { earthquake.id }

    var magnitudeClass: MagnitudeClass { earthquake.magnitudeClass }

    static func == (lhs: EarthquakeMapItem, rhs: EarthquakeMapItem) -> Bool {
        lhs.id == rhs.id
    }
}

extension GeoCoordinate {
    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct EarthquakeMapBridge: UIViewRepresentable {
    let items: [EarthquakeMapItem]
    let faultDataset: FaultDataset?
    let showsFaultLines: Bool

    static let initialRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.13, longitude: 35.211),
        span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
    )

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.register(
            EarthquakeAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: EarthquakeAnnotationView.reuseIdentifier
        )
        mapView.delegate = context.coordinator
        mapView.mapType = .mutedStandard
        mapView.pointOfInterestFilter = .excludingAll
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        mapView.showsCompass = true
        mapView.showsScale = false
        mapView.setRegion(Self.initialRegion, animated: false)
        context.coordinator.attach(mapView)
        context.coordinator.update(
            items: items,
            faultDataset: faultDataset,
            showsFaultLines: showsFaultLines
        )
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.update(
            items: items,
            faultDataset: faultDataset,
            showsFaultLines: showsFaultLines
        )
    }

    @MainActor
    final class Coordinator: NSObject, MKMapViewDelegate {
        private weak var mapView: MKMapView?

        private var itemsByID: [String: EarthquakeMapItem] = [:]
        private var itemIDs: [String] = []
        private var annotationByID: [String: EarthquakeMapAnnotation] = [:]
        private var calloutHosts: [String: UIHostingController<EarthquakeCalloutRoot>] = [:]

        private var faultSignature: FaultSignature?
        private var faultOverlays: [MKOverlay] = []
        private var styleByOverlay: [ObjectIdentifier: FaultOverlayStyle] = [:]
        private var rendererByOverlay: [ObjectIdentifier: MKMultiPolylineRenderer] = [:]

        func attach(_ mapView: MKMapView) {
            self.mapView = mapView
        }

        func update(
            items: [EarthquakeMapItem],
            faultDataset: FaultDataset?,
            showsFaultLines: Bool
        ) {
            updateAnnotations(items: items)
            updateFaults(dataset: faultDataset, showsFaultLines: showsFaultLines)
        }

        private func updateAnnotations(items: [EarthquakeMapItem]) {
            guard let mapView else { return }
            let ids = items.map(\.id)
            guard ids != itemIDs else { return }

            if !annotationByID.isEmpty {
                mapView.removeAnnotations(Array(annotationByID.values))
            }

            itemsByID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
            itemIDs = ids
            annotationByID = [:]
            calloutHosts = [:]
            var annotations: [EarthquakeMapAnnotation] = []
            annotations.reserveCapacity(items.count)
            for item in items {
                let annotation = EarthquakeMapAnnotation(item: item)
                annotationByID[item.id] = annotation
                annotations.append(annotation)
            }
            mapView.addAnnotations(annotations)
        }

        private func updateFaults(dataset: FaultDataset?, showsFaultLines: Bool) {
            guard let mapView else { return }
            let signature = FaultSignature(
                lineCount: dataset?.lines.count ?? 0,
                version: dataset?.version ?? 0,
                isVisible: showsFaultLines
            )
            guard signature != faultSignature else { return }
            faultSignature = signature

            if !faultOverlays.isEmpty {
                mapView.removeOverlays(faultOverlays)
                faultOverlays = []
                styleByOverlay = [:]
                rendererByOverlay = [:]
            }
            guard showsFaultLines, let dataset else { return }

            var overlays: [MKOverlay] = []
            for confidence in FaultConfidence.allCases {
                for rate in FaultRate.allCases {
                    let coordinates = dataset.lines
                        .filter { $0.confidence == confidence && $0.rate == rate }
                        .map { line in
                            line.coordinates.map(\.clCoordinate)
                        }
                    guard !coordinates.isEmpty else { continue }
                    let polylines = coordinates.map { points -> MKPolyline in
                        var mutablePoints = points
                        return MKPolyline(coordinates: &mutablePoints, count: mutablePoints.count)
                    }
                    let multiPolyline = MKMultiPolyline(polylines)
                    styleByOverlay[ObjectIdentifier(multiPolyline)] = FaultOverlayStyle(
                        confidence: confidence,
                        rate: rate
                    )
                    overlays.append(multiPolyline)
                }
            }
            faultOverlays = overlays
            mapView.addOverlays(overlays, level: .aboveRoads)
            updateFaultLineWidths()
        }

        private func updateFaultLineWidths() {
            guard let mapView else { return }
            let zoom = Self.zoomLevel(for: mapView.region.span)
            for (identifier, renderer) in rendererByOverlay {
                guard let style = styleByOverlay[identifier] else { continue }
                renderer.lineWidth = FaultMapStylePolicy.lineWidth(rate: style.rate, zoom: zoom)
            }
        }

        private static func zoomLevel(for span: MKCoordinateSpan) -> Double {
            guard span.longitudeDelta.isFinite, span.longitudeDelta > 0 else { return 5 }
            return log2(360.0 / span.longitudeDelta)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
            guard let annotation = annotation as? EarthquakeMapAnnotation else { return nil }
            let view = mapView.dequeueReusableAnnotationView(
                withIdentifier: EarthquakeAnnotationView.reuseIdentifier,
                for: annotation
            )
            guard let annotationView = view as? EarthquakeAnnotationView else { return nil }
            annotationView.apply(annotation, isSelected: false)
            annotationView.canShowCallout = true
            annotationView.detailCalloutAccessoryView = hostedCallout(for: annotation)
            return annotationView
        }

        private func hostedCallout(for annotation: EarthquakeMapAnnotation) -> UIView {
            if let host = calloutHosts[annotation.id] {
                host.rootView = EarthquakeCalloutRoot(earthquake: annotation.earthquake)
                return host.view
            }
            let host = UIHostingController(
                rootView: EarthquakeCalloutRoot(earthquake: annotation.earthquake)
            )
            host.view.backgroundColor = .clear
            calloutHosts[annotation.id] = host
            return host.view
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer {
            guard let multiPolyline = overlay as? MKMultiPolyline,
                  let style = styleByOverlay[ObjectIdentifier(multiPolyline)] else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let renderer = MKMultiPolylineRenderer(multiPolyline: multiPolyline)
            let color = UIColor(Color(faultHex: FaultMapStylePolicy.colorName(for: style.confidence)))
                .withAlphaComponent(FaultMapStylePolicy.lineOpacity)
            renderer.strokeColor = color
            let zoom = mapView.region.span.longitudeDelta.isFinite && mapView.region.span.longitudeDelta > 0
                ? log2(360.0 / mapView.region.span.longitudeDelta)
                : 5
            renderer.lineWidth = FaultMapStylePolicy.lineWidth(rate: style.rate, zoom: zoom)
            rendererByOverlay[ObjectIdentifier(multiPolyline)] = renderer
            return renderer
        }

        func mapView(_ mapView: MKMapView, didSelect annotation: any MKAnnotation) {
            guard let annotation = annotation as? EarthquakeMapAnnotation else { return }
            if let view = mapView.view(for: annotation) as? EarthquakeAnnotationView {
                view.apply(annotation, isSelected: true)
            }
        }

        func mapView(_ mapView: MKMapView, didDeselect annotation: any MKAnnotation) {
            guard let annotation = annotation as? EarthquakeMapAnnotation else { return }
            if let view = mapView.view(for: annotation) as? EarthquakeAnnotationView {
                view.apply(annotation, isSelected: false)
            }
        }

        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            updateFaultLineWidths()
        }
    }
}

private struct FaultSignature: Equatable {
    let lineCount: Int
    let version: Int
    let isVisible: Bool
}

private struct FaultOverlayStyle {
    let confidence: FaultConfidence
    let rate: FaultRate
}

final class EarthquakeMapAnnotation: NSObject, MKAnnotation {
    let id: String
    let magnitudeClass: MagnitudeClass
    let title: String?
    let earthquake: Earthquake
    dynamic var coordinate: CLLocationCoordinate2D

    init(item: EarthquakeMapItem) {
        id = item.id
        magnitudeClass = item.magnitudeClass
        title = nil
        earthquake = item.earthquake
        coordinate = item.coordinate
        super.init()
    }
}

final class EarthquakeAnnotationView: MKAnnotationView {
    static let reuseIdentifier = "earthquake-annotation"

    private let borderWidth: CGFloat = 2.5

    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        canShowCallout = false
        collisionMode = .circle
        displayPriority = .required
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func apply(_ annotation: EarthquakeMapAnnotation, isSelected: Bool) {
        let radius = annotation.magnitudeClass.markerRadius
        let diameter = radius * 2 + borderWidth * 2
        if frame.size != CGSize(width: diameter, height: diameter) {
            frame = CGRect(x: 0, y: 0, width: diameter, height: diameter)
            layer.cornerRadius = diameter / 2
        }
        backgroundColor = UIColor(annotation.magnitudeClass.palette.accent)
        layer.borderWidth = isSelected ? borderWidth + 1 : borderWidth
        layer.borderColor = UIColor.black.withAlphaComponent(0.8).cgColor
        transform = isSelected ? CGAffineTransform(scaleX: 1.35, y: 1.35) : .identity
        centerOffset = .zero
        accessibilityLabel = "\(annotation.earthquake.formattedMagnitude) büyüklüğünde deprem, \(annotation.earthquake.region)"
    }
}
