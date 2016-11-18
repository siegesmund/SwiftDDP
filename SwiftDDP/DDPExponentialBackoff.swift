//
//  DDPExponentialBackoff.swift
//  
//
//  Created by Joseph Kitchener on 05/02/2016.
//  Copyright © 2016 Joseph Kitchener. All rights reserved.
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

///Retry connection requests to the server. The retries exponentially increase the waiting time up to a certain threshold. The idea is that if the server is down temporarily, it is not overwhelmed with requests hitting at the same time when it comes back up.

class DDPExponentialBackoff {
    
    
    init(retryInterval:Double = 0.01,maxWaitInterval:Double = 5,multiplier:Double = 1.5){
        
        self.reconnectionRetryInterval = retryInterval
        self._reconnectionRetryInterval = retryInterval
        self.maxWaitInterval = maxWaitInterval
        self.multiplier = multiplier
    }
    
    //Cached original interval time
    fileprivate var _reconnectionRetryInterval:Double = 0
    
    
    fileprivate var reconnectionRetryInterval:Double
    fileprivate var maxWaitInterval:Double
    fileprivate var multiplier:Double
    
    
    ///Perform a closure with increasing exponential delay time up to a max wait interval
    func createBackoff(_ closure:@escaping ()->()) {
        
        let previousRetryInterval = self.reconnectionRetryInterval
        let newRetryInterval = min(previousRetryInterval * multiplier,maxWaitInterval)
        
        self.reconnectionRetryInterval = previousRetryInterval < maxWaitInterval ? newRetryInterval: maxWaitInterval
        
        
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(self.reconnectionRetryInterval * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
//        print(reconnectionRetryInterval)
    }
    
    //Reset backoff to orignal time
    func reset(){
        reconnectionRetryInterval = _reconnectionRetryInterval
    }
    
    //Sets the backoff
    func setBackoff(_ retryInterval:Double,maxWaitInterval:Double,multiplier:Double){
        self.reconnectionRetryInterval = retryInterval
        self._reconnectionRetryInterval = retryInterval
        self.maxWaitInterval = maxWaitInterval
        self.multiplier = multiplier
    }
    
    
}


    
