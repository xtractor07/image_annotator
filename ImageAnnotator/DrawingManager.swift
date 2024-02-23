//
//  DrawingManager.swift
//  ImageAnnotator
//
//  Created by Kumar Aman on 23/02/24.
//

import Foundation

class DrawingManager: ObservableObject {
    @Published var paths: [DrawingPath] = []
    private var undonePaths: [DrawingPath] = []

    func addPath(_ path: DrawingPath) {
        paths.append(path)
        undonePaths.removeAll()
    }

    func undo() {
        guard let lastPath = paths.popLast() else { return }
        undonePaths.append(lastPath)
    }

    func redo() {
        guard let pathToRedo = undonePaths.popLast() else { return }
        paths.append(pathToRedo)
    }

    func clear() {
        paths.removeAll()
        undonePaths.removeAll()
    }
}
