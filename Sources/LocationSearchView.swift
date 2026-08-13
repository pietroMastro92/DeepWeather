import SwiftUI

struct LocationSearchView: View {
    @Bindable var store: WeatherStore
    @State private var query = ""
    @State private var results: [GeoResult] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    private let client = GeocodingClient()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SavedLocationsList(
                locations: store.savedLocations,
                selectedLocationID: store.selectedLocationID,
                onSelectAutomatic: useAutomatic,
                onSelect: { store.selectSavedLocation($0) },
                onRemove: { store.removeLocation(id: $0) }
            )

            Divider()

            TextField("Search city…", text: $query)
                .textFieldStyle(.roundedBorder)
                .onChange(of: query) { _, newValue in
                    scheduleSearch(newValue)
                }

            LocationSearchStatus(
                query: query,
                results: results,
                isSearching: isSearching,
                onSelect: select
            )
        }
    }

    private func scheduleSearch(_ value: String) {
        searchTask?.cancel()
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            results = []
            isSearching = false
            return
        }
        isSearching = true
        searchTask = Task { [client] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            let found = (try? await client.search(trimmed)) ?? []
            guard !Task.isCancelled else { return }
            results = found
            isSearching = false
        }
    }

    private func select(_ result: GeoResult) {
        store.selectLocation(result)
        query = ""
        results = []
    }

    private func useAutomatic() {
        store.resetToAutomaticLocation()
    }
}

private struct SavedLocationsList: View {
    let locations: [SavedLocation]
    let selectedLocationID: String?
    let onSelectAutomatic: () -> Void
    let onSelect: (String) -> Void
    let onRemove: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            LocationRowView(
                title: "Automatic (IP)",
                subtitle: "Detected from your connection",
                systemImage: "location",
                isSelected: selectedLocationID == nil,
                onSelect: onSelectAutomatic,
                onRemove: nil
            )

            ForEach(locations) { location in
                LocationRowView(
                    title: location.name,
                    subtitle: location.detail,
                    systemImage: "mappin",
                    isSelected: location.id == selectedLocationID,
                    onSelect: { onSelect(location.id) },
                    onRemove: { onRemove(location.id) }
                )
            }
        }
    }
}

private struct LocationSearchStatus: View {
    let query: String
    let results: [GeoResult]
    let isSearching: Bool
    let onSelect: (GeoResult) -> Void

    var body: some View {
        if isSearching {
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                Text("Searching…")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        } else if !results.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(results) { result in
                    LocationResultRow(result: result) {
                        onSelect(result)
                    }
                }
            }
        } else if !query.isEmpty {
            Text("No results.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct LocationRowView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isSelected: Bool
    let onSelect: () -> Void
    let onRemove: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onSelect) {
                HStack(spacing: 8) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : systemImage)
                        .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                        .frame(width: 18)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(title)
                            .font(.callout)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        if !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Remove \(title)")
            }
        }
    }
}

private struct LocationResultRow: View {
    let result: GeoResult
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(result.name)
                        .font(.callout)
                    Text(result.detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "plus.circle")
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
