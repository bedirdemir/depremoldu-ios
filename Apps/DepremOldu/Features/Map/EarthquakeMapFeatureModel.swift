import Foundation
import Observation
import DepremOlduDomain
import DepremOlduFaults

@Observable
@MainActor
final class EarthquakeMapFeatureModel {
    enum FaultState: Equatable {
        case idle
        case loading
        case ready(FaultDataset)
        case failed
    }

    private let faultProvider: any FaultDatasetProviding
    private var faultTask: Task<Void, Never>?

    var showsFaultLines = false
    private(set) var faultState: FaultState = .idle
    var selectedEarthquakeID: Earthquake.ID?

    init(faultProvider: any FaultDatasetProviding) {
        self.faultProvider = faultProvider
    }

    isolated deinit {
        faultTask?.cancel()
    }

    var faultDataset: FaultDataset? {
        if case let .ready(dataset) = faultState {
            return dataset
        }
        return nil
    }

    var isFaultLoading: Bool {
        faultState == .loading
    }

    var showsFaultLegend: Bool {
        showsFaultLines && faultDataset != nil
    }

    func loadFaultsIfNeeded() {
        guard faultState == .idle else { return }
        faultState = .loading
        let provider = faultProvider
        faultTask = Task { @MainActor [weak self] in
            let result = await Task.detached(priority: .utility) {
                try? await provider.loadDataset()
            }.value
            guard let self, self.faultState == .loading else { return }
            if let result {
                self.faultState = .ready(result)
            } else {
                self.faultState = .failed
            }
            self.faultTask = nil
        }
    }

    func toggleFaultLines() {
        showsFaultLines.toggle()
    }
}
