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

public class MeteorOAuth {
    
    static let meteor = Meteor.client
    
    static var httpUrl:String = {
        let url = MeteorOAuth.getHTTPUrl(Meteor.client.url)
        return url
    }()
    
    // Forms a HTTP url from a Meteor websocket url
    static func getHTTPUrl(websocketUrl: String) -> String {
        // remove websocket; should rewrite this so that it takes only
        // websocket from the end of the string
        let path = websocketUrl.componentsSeparatedByString("/websocket")[0]
        
        let components = path.componentsSeparatedByString("://")
        let applicationLayerProtocol = components[0]
        
        assert(applicationLayerProtocol == "ws" || applicationLayerProtocol == "wss")
        
        let domainName = components[1]
        
        if applicationLayerProtocol == "ws" {
            return "http://\(domainName)"
        }
        
        return "https://\(domainName)"
    }
    
    // Construct the state parameter
    static func stateParam(credentialToken: String, redirectUrl: String) -> String {
                
        let objectString = "{\"redirectUrl\":\"\(redirectUrl)\",\"loginStyle\":\"redirect\",\"isCordova\":\"false\",\"credentialToken\":\"\(credentialToken)\"}"
        return toBase64(objectString)
    }

}
