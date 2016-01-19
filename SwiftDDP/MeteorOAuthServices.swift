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
                let redirect = "\(httpUrl)/_oauth/facebook&display=redirect&scope=email&state=\(state)"
                
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
    
    public static func github() -> String? {
        /*
        var loginUrl =
        'https://github.com/login/oauth/authorize' +
        '?client_id=' + config.clientId +
        '&scope=' + flatScope +
        '&redirect_uri=' + OAuth._redirectUri('github', config) +
        '&state=' + OAuth._stateParam(loginStyle, credentialToken, options && options.redirectUrl);
        */
        
        
        https://github.com/login/oauth/authorize?client_id=bdf536f4d202ed2e77af&scope=user%3Aemail&redirect_uri=http://swiftddpoauthserver.meteor.com/_oauth/github&state=eyJsb2dpblN0eWxlIjoicmVkaXJlY3QiLCJjcmVkZW50aWFsVG9rZW4iOiJjZlNfZkZFZHhvV1JTUGtEZkc5RHAydnVmR3BBZHhlQlBXemJQWmJXVjNjIiwiaXNDb3Jkb3ZhIjpmYWxzZSwicmVkaXJlY3RVcmwiOiJodHRwOi8vc3dpZnRkZHBvYXV0aHNlcnZlci5tZXRlb3IuY29tLyJ9
            
        // packages/facebook/facebook_client.js 33
        if let github = Meteor.client.loginServiceConfiguration["github"],
            let clientId = github["clientId"] {
                
                let token = randomBase64String()
                let httpUrl = MeteorOAuth.httpUrl
                let state = MeteorOAuth.stateParam(token, redirectUrl: httpUrl)
                let redirect = "\(httpUrl)/_oauth/github"


                print("Redirect: \(redirect)")
                
                let display = "touch"
                let scope = "user:email"
                
                var url = "https://github.com/login/oauth/authorize?client_id=\(clientId)"
                url += "&redirect_uri=\(redirect)"
                // url += "&display=\(display)"
                url += "&scope=\(scope)"
                url += "&state=\(state)"
                
                return url
        }
        
        return nil

    }

    
}