import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var model = ConversionModel()
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            DropZoneView(model: model, isTargeted: isDropTargeted)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

            if !model.items.isEmpty {
                itemGrid
            } else {
                Spacer()
            }

            FooterView(model: model)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 14)
        }
        .background { meshBackground.ignoresSafeArea() }
        .frame(minWidth: 720, minHeight: 560)
        .overlay {
            if isDropTargeted {
                dropOverlay.ignoresSafeArea().allowsHitTesting(false)
                    .transition(.opacity.animation(.easeInOut(duration: 0.12)))
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted, perform: handleDrop)
        .alert("Conversion Complete", isPresented: $model.showCompletionAlert) {
            if model.lastConversionResult.failed == 0 {
                Button("Show in Finder") { model.revealOutputDirectory() }
                Button("OK", role: .cancel) { }
            } else {
                Button("OK", role: .cancel) { }
            }
        } message: {
            let r = model.lastConversionResult
            if r.failed == 0 {
                Text("\(r.succeeded) \(r.succeeded == 1 ? "file" : "files") converted successfully.")
            } else {
                Text("\(r.succeeded) converted, \(r.failed) failed.")
            }
        }
    }

    // MARK: - Background

    private var meshBackground: some View {
        MeshGradient(
            width: 3, height: 3,
            points: [
                SIMD2<Float>(0.00, 0.00), SIMD2<Float>(0.50, 0.00), SIMD2<Float>(1.00, 0.00),
                SIMD2<Float>(0.00, 0.50), SIMD2<Float>(0.55, 0.45), SIMD2<Float>(1.00, 0.50),
                SIMD2<Float>(0.00, 1.00), SIMD2<Float>(0.50, 1.00), SIMD2<Float>(1.00, 1.00),
            ],
            colors: [
                Color(red: 0.11, green: 0.11, blue: 0.14),
                Color(red: 0.10, green: 0.10, blue: 0.16),
                Color(red: 0.09, green: 0.10, blue: 0.18),
                Color(red: 0.12, green: 0.10, blue: 0.15),
                Color(red: 0.10, green: 0.10, blue: 0.15),
                Color(red: 0.08, green: 0.10, blue: 0.17),
                Color(red: 0.10, green: 0.09, blue: 0.13),
                Color(red: 0.09, green: 0.09, blue: 0.14),
                Color(red: 0.08, green: 0.09, blue: 0.16),
            ]
        )
    }

    // MARK: - Grid

    private var itemGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 164, maximum: 220), spacing: 14)],
                spacing: 14
            ) {
                ForEach(model.items) { item in
                    ItemTileView(item: item) {
                        withAnimation(.spring(response: 0.3)) { model.remove(id: item.id) }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Drop overlay

    private var dropOverlay: some View {
        ZStack {
            Color.white.opacity(0.08)
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(.white.opacity(0.75), lineWidth: 2.5)
                .padding(10)
            VStack(spacing: 10) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white)
                Text("Drop to add")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Drop handling

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                _ = provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { @Sendable data, _ in
                    guard let data, let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                    Task { @MainActor in
                        if url.hasDirectoryPath { model.addDirectory(url) }
                        else { model.addFiles([url]) }
                    }
                }
            }
        }
        return true
    }
}
