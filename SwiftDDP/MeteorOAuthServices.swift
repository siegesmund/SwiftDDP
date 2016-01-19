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


public class MeteorOAuthServices {
    
    public static func twitter() -> String {
        
        let httpUrl = MeteorOAuth.httpUrl
        let token = randomBase64String()
        let state = MeteorOAuth.stateParam(token, redirectUrl: httpUrl)
        
        return "\(httpUrl)/_oauth/twitter/?requestTokenAndRedirect=true&state=\(state)"
    
    }
    
    public static func facebook() -> String? {
        
        // packages/facebook/facebook_client.js 33
        if let facebook = Meteor.client.loginServiceConfiguration["facebook"],
            let appId = facebook["appId"] {
            
                let token = randomBase64String()
                let httpUrl = MeteorOAuth.httpUrl
                let state = MeteorOAuth.stateParam(token, redirectUrl: httpUrl)
                let redirect = "http://swiftddpoauthserver.meteor.com/_oauth/facebook&display=redirect&scope=email&state=\(state)"
                
                let display = "touch"
                let scope = "email"
                
                var url = "https://www.facebook.com/v2.2/dialog/oauth?client_id=\(appId)"
                url += "&redirect_uri=\(redirect)"
                url += "&display=\(display)"
                url += "&scope=\(scope)"
                url += "&state=\(state)"
                
                return url
        }
        
        return nil
    }

    
}