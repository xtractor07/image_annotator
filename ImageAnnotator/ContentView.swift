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
    var color: Color = .black // Default color
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
    @ObservedObject var drawingManager = DrawingManager()
    // Temporary path for real-time drawing updates
    var backgroundImage: UIImage?
    @State private var currentPathPoints: [CGPoint] = []
    @State private var selectedColor: Color = .black // Default drawing color
    @State private var showingColorPicker = false


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
                                let location = value.location
                                let drawableArea = calculateDrawableArea(imageSize: backgroundImage?.size ?? .zero, in: geometry.size)
                                if drawableArea.contains(location) {
                                    currentPathPoints.append(location)
                                }
                            }
                            .onEnded { _ in
                                if !currentPathPoints.isEmpty {
                                    let isDot = currentPathPoints.count <= 2
                                    let newPath = DrawingPath(points: currentPathPoints, isDot: isDot, color: selectedColor) // Use the selected color
                                    drawingManager.addPath(newPath)
                                    currentPathPoints.removeAll()
                                }
                            }
                    )
                }

                // Draw the paths that have been finalized
                ForEach(drawingManager.paths) { path in
                    if path.isDot {
                        Circle()
                            .fill(path.color)
                            .frame(width: 4, height: 4)
                            .position(path.points.first ?? CGPoint.zero)
                    } else {
                        Path { pathDrawing in
                            guard let firstPoint = path.points.first else { return }
                            pathDrawing.move(to: firstPoint)
                            path.points.forEach { point in
                                pathDrawing.addLine(to: point)
                            }
                        }
                        .stroke(path.color, lineWidth: 2)
                    }
                }
                
                // Draw the current path in real-time
                Path { path in
                    guard let firstPoint = currentPathPoints.first else { return }
                    path.move(to: firstPoint)
                    path.addLines(currentPathPoints)
                }
                .stroke(selectedColor, lineWidth: 2)
                
                VStack {
                        Spacer() // This pushes the controls to the bottom
                        controlPanel()
                        .frame(width: geometry.size.width)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        }
            }
        }
        .background(Color(white: 0.95).edgesIgnoringSafeArea(.all))
        .padding(.top)
        .padding(.bottom)
    }
    
    func controlPanel() -> some View {
        HStack {
            Button(action: drawingManager.undo) {
                Image(systemName: "arrow.uturn.backward")
                    .padding()
                    .background(Circle().fill(Color.white).shadow(radius: 2))
            }
            Spacer()
            Button(action: drawingManager.redo) {
                Image(systemName: "arrow.uturn.forward")
                    .padding()
                    .background(Circle().fill(Color.white).shadow(radius: 2))
            }
            Spacer()
            ColorPicker("Color", selection: $selectedColor, supportsOpacity: false)
                                .labelsHidden()
                                .padding(.vertical, 10)
                                .padding(.horizontal)
                                .background(Circle().fill(Color.white).shadow(radius: 2))
            Spacer()
            Button(action: {
                print("Will have to implement save method !!!!!!!!!!!")
            }) {
                Image(systemName: "square.and.arrow.down")
                    .padding()
                    .background(Circle().fill(Color.white).shadow(radius: 2))
            }

            Spacer()
        }
        
        .padding()
        // Additional styling as needed...
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
