//
//  DDPExponentialBackoff.swift
//  Musiikr
//
//  Created by Joseph Kitchener on 05/02/2016.
//  Copyright © 2016 Joseph Kitchener. All rights reserved.
//

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
    private var _reconnectionRetryInterval:Double!
    
    
    private var reconnectionRetryInterval:Double!
    private var maxWaitInterval:Double!
    private var multiplier:Double!
    
    
    ///Perform a closure with increasing exponential delay time up to a max wait interval
    func createBackoff(closure:()->()) {
        
        let previousRetryInterval = self.reconnectionRetryInterval
        let newRetryInterval = min(previousRetryInterval * multiplier,maxWaitInterval)
        
        self.reconnectionRetryInterval = previousRetryInterval < maxWaitInterval ? newRetryInterval: maxWaitInterval
        
        
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(self.reconnectionRetryInterval * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
//        print(reconnectionRetryInterval)
    }
    
    //Reset backoff to orignal time
    func reset(){
        reconnectionRetryInterval = _reconnectionRetryInterval
    }
    
    //Sets the backoff
    func setBackoff(retryInterval:Double,maxWaitInterval:Double,multiplier:Double){
        self.reconnectionRetryInterval = retryInterval
        self._reconnectionRetryInterval = retryInterval
        self.maxWaitInterval = maxWaitInterval
        self.multiplier = multiplier
    }
    
    
}


    