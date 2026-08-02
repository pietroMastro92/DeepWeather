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
            Text("Location")
                .font(.callout)

            TextField("Search city…", text: $query)
                .textFieldStyle(.roundedBorder)
                .onChange(of: query) { _, newValue in
                    scheduleSearch(newValue)
                }

            savedStatus
            searchStatus
        }
    }

    private var savedStatus: some View {
        Group {
            if let saved = store.savedLocation {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(.secondary)
                        .padding(.top, 1)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(saved.name)
                            .font(.callout)
                        Text(saved.detail)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Automatic", action: useAutomatic)
                        .buttonStyle(.link)
                        .font(.caption)
                        .help("Use automatic location (IP)")
                }
            } else {
                Text("Using automatic location (IP).")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var searchStatus: some View {
        Group {
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
                            select(result)
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
        query = ""
        results = []
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
