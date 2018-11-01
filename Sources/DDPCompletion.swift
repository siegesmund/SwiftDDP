// Copyright (c) 2016 Peter Siegesmund <peter.siegesmund@icloud.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

/**
Completion is a wrapper for DDP callbacks that ensures that callbacks are executed
on the same queue on which the original method was called. If the current queue is
not available, execution defaults to the main queue.
*/

public struct Completion {
    
    var executionQueue:OperationQueue? = OperationQueue.current
    var methodCallback:DDPMethodCallback?
    var connectedCallback:DDPConnectedCallback?
    var callback:DDPCallback?
    
    init(methodCallback:@escaping DDPMethodCallback) {
        self.methodCallback = methodCallback
    }
    
    init(connectedCallback:@escaping DDPConnectedCallback) {
        self.connectedCallback = connectedCallback
    }
    
    init(callback:@escaping DDPCallback) {
        self.callback = callback
    }
    
    func execute(_ result:Any?, error:DDPError?) {
        
        if let callback = methodCallback {
            if let queue = executionQueue {
                queue.addOperation() {
                    callback(result, error)
                }
            } else {
                OperationQueue.main.addOperation() {
                    callback(result, error)
                }
            }
        }
    }
    
    func execute(_ session:String) {
        
        if let callback = connectedCallback {
            if let queue = executionQueue {
                queue.addOperation() {
                    callback(session)
                }
            } else {
                OperationQueue.main.addOperation() {
                    callback(session)
                }
            }
        }
    }
    
    func execute() {
        
        if let callback = self.callback {
            if let queue = executionQueue {
                queue.addOperation() {
                    callback()
                }
            } else {
                OperationQueue.main.addOperation() {
                    callback()
                }
            }
        }
    }
    
}
