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

struct DrawingCanvas: View {
    @State private var paths: [DrawingPath] = []
    // Temporary path for real-time drawing updates
    @State private var currentPathPoints: [CGPoint] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // Append new point to the current path in real-time
                                currentPathPoints.append(value.location)
                            }
                            .onEnded { value in
                                // Determine if it's a dot based on the number of points
                                let isDot = currentPathPoints.count <= 2
                                let newPath = DrawingPath(points: currentPathPoints, isDot: isDot)
                                paths.append(newPath)
                                // Reset current path points for the next gesture
                                currentPathPoints.removeAll()
                            }
                    )

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
        .background(Color(white: 0.95).edgesIgnoringSafeArea(.all))
    }
}

struct ContentView: View {
    var body: some View {
        DrawingCanvas()
    }
}

#Preview {
    ContentView()
}
