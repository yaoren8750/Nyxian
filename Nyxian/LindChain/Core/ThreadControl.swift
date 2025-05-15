/*
 Copyright (C) 2025 SeanIsTethered
 Copyright (C) 2025 Lindsey

 This file is part of Nyxian.

 FridaCodeManager is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 FridaCodeManager is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Nyxian. If not, see <https://www.gnu.org/licenses/>.
*/

import Foundation

func getOptimalThreadCount() -> Int {
    var cpuCount: Int = 0
    var size = MemoryLayout<Int>.size
    let result = sysctlbyname("hw.logicalcpu_max", &cpuCount, &size, nil, 0)
    
    let optimalCount = (result == 0 && cpuCount > 0)
        ? cpuCount
        : ProcessInfo.processInfo.activeProcessorCount
    
    return optimalCount
}

func pthread_dispatch(_ code: @escaping () -> Void) {
    var thread: pthread_t?
    let blockPointer = UnsafeMutableRawPointer(Unmanaged.passRetained(code as AnyObject).toOpaque())
    
    pthread_create(&thread, nil, { ptr in
        let unmanaged = Unmanaged<AnyObject>.fromOpaque(ptr)
        let block = unmanaged.takeRetainedValue() as! () -> Void
        block()
        return nil
    }, blockPointer)
}

class ThreadDispatchLimiter {
    private let semaphore: DispatchSemaphore = DispatchSemaphore(value: (UserDefaults.standard.object(forKey: "cputhreads") != nil)
                                                                 ? UserDefaults.standard.integer(forKey: "cputhreads")
                                                                 : getOptimalThreadCount()
    )
    
    private let syncQueue = DispatchQueue(label: "threadLimiter.lockdown.queue", attributes: .concurrent)
    private var _isLockdown: Bool = false
    private(set) var isLockdown: Bool {
        get { syncQueue.sync { _isLockdown } }
        set { syncQueue.sync(flags: .barrier) { _isLockdown = newValue } }
    }
    var doThreading: Bool {
        get {
            if UserDefaults.standard.object(forKey: "LDEThreadedBuild") != nil {
                return UserDefaults.standard.bool(forKey: "LDEThreadedBuild")
            }
            return true
        }
    }

    func spawn(_ code: @escaping () -> Void, completion: @escaping () -> Void) {
        if self.doThreading {
            if self.isLockdown {
                completion()
                self.semaphore.signal()
                return
            }
            
            semaphore.wait()
            
            if self.isLockdown {
                completion()
                self.semaphore.signal()
                return
            }
            
            pthread_dispatch {
                code()
                completion()
                self.semaphore.signal()
            }
        } else {            
            if self.isLockdown {
                completion()
                return
            }
            
            code()
            completion()
        }
    }
    
    func lockdown() {
        self.isLockdown = true
    }
}
