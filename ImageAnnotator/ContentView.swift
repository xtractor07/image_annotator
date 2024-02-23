//
//  ContentView.swift
//  ImageAnnotator
//
//  Created by Kumar Aman on 22/02/24.
//

import SwiftUI

struct DrawingPath: Identifiable {
    let id = UUID()
    var points: [CGPoint] = []
    var isDot: Bool = false
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}


struct DrawingCanvas: View {
    @State private var paths: [DrawingPath] = []
    // Temporary path for real-time drawing updates
    var backgroundImage: UIImage?
    @State private var currentPathPoints: [CGPoint] = []

    var body: some View {

        GeometryReader { geometry in
            ZStack {
                if backgroundImage != nil {
                    Image(uiImage: backgroundImage!)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // Calculate drawable area each time the gesture changes
                                let drawableArea = calculateDrawableArea(imageSize: backgroundImage?.size ?? .zero, in: geometry.size)
                                let location = value.location
                                
                                // Check if the location is within the drawable area
                                if drawableArea.contains(location) {
                                    currentPathPoints.append(location)
                                }
                            }
                            .onEnded { value in
                                if !currentPathPoints.isEmpty {
                                    let isDot = currentPathPoints.count <= 2
                                    paths.append(DrawingPath(points: currentPathPoints, isDot: isDot))
                                    currentPathPoints.removeAll()
                                }
                            }
                    )
                }

                // Draw the paths that have been finalized
                ForEach(paths) { path in
                    if path.isDot {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 4, height: 4)
                            .position(path.points.first ?? CGPoint.zero)
                    } else {
                        Path { pathDrawing in
                            guard let firstPoint = path.points.first else { return }
                            pathDrawing.move(to: firstPoint)
                            pathDrawing.addLines(path.points)
                        }
                        .stroke(Color.black, lineWidth: 2)
                    }
                }
                
                // Draw the current path in real-time
                Path { path in
                    guard let firstPoint = currentPathPoints.first else { return }
                    path.move(to: firstPoint)
                    path.addLines(currentPathPoints)
                }
                .stroke(Color.black, lineWidth: 2)
            }
        }
        .padding(.top)
        .padding(.bottom)
        .background(Color(white: 0.95).edgesIgnoringSafeArea(.all))
    }
    
    func calculateDrawableArea(imageSize: CGSize, in containerSize: CGSize) -> CGRect {
        let imageAspectRatio = imageSize.width / imageSize.height
        let containerAspectRatio = containerSize.width / containerSize.height
        
        var drawableArea = CGRect.zero
        
        if imageAspectRatio > containerAspectRatio {
            // Image is wider than the container; it will be constrained by width
            let scaledHeight = containerSize.width / imageAspectRatio
            let yOffset = (containerSize.height - scaledHeight) / 2
            drawableArea = CGRect(x: 0, y: yOffset, width: containerSize.width, height: scaledHeight)
        } else {
            // Image is taller than the container; it will be constrained by height
            let scaledWidth = containerSize.height * imageAspectRatio
            let xOffset = (containerSize.width - scaledWidth) / 2
            drawableArea = CGRect(x: xOffset, y: 0, width: scaledWidth, height: containerSize.height)
        }
        
        return drawableArea
    }
}

struct ContentView: View {
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var isPresentingDrawingView = false

    var body: some View {
        NavigationStack {
            VStack {
                Button("Select Image") {
                    showingImagePicker = true
                }
            }
            .navigationDestination(isPresented: $isPresentingDrawingView) {
                if let inputImage = inputImage {
                    DrawingCanvas(backgroundImage: inputImage) // Directly pass UIImage
                        .edgesIgnoringSafeArea(.all)
                }
            }
            .sheet(isPresented: $showingImagePicker, onDismiss: prepareForNavigation) {
                ImagePicker(selectedImage: $inputImage)
            }
        }
    }

    func prepareForNavigation() {
        if inputImage != nil {
            isPresentingDrawingView = true
        }
    }
}

#Preview {
    ContentView()
}
