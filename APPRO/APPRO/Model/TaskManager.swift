//
//  TaskManager.swift
//  APPRO
//
//  Created by Damin on 11/29/24.
//

import Foundation

actor TaskManager {
    private(set) var tasks: [Task<Void, Never>] = []
    
    func addTask(_ task: Task<Void, Never>) {
        tasks.append(task)
    }
    
    func cancelAllTasks() {
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
    }
}
