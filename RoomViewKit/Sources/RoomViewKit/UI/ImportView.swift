import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isImporterPresented = false
    @State private var importErrorMessage: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            SceneContainerView(root: PlaceholderRoomBuilder.buildRoom())

            VStack(spacing: 8) {
                if let importErrorMessage {
                    Text(importErrorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Button("Import USDZ Scan") {
                    importErrorMessage = nil
                    isImporterPresented = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .fileImporter(isPresented: $isImporterPresented, allowedContentTypes: [.usdz]) { result in
            switch result {
            case .success(let url):
                do {
                    _ = try ScanImporter.importScan(from: url, into: modelContext)
                } catch {
                    importErrorMessage = "Import failed: \(error.localizedDescription)"
                }
            case .failure(let error):
                importErrorMessage = error.localizedDescription
            }
        }
    }
}
