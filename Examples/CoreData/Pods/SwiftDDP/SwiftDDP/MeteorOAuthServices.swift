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
        let redirect = "\(httpUrl)/_oauth/twitter"
        let state = MeteorOAuth.stateParam(token, redirectUrl: redirect)
        
        return "\(httpUrl)/_oauth/twitter/?requestTokenAndRedirect=true&state=\(state)"
    
    }
    
    public static func facebook(appId: String) -> String {
        
        let token = randomBase64String()
        let httpUrl = MeteorOAuth.httpUrl
        let redirect = "\(httpUrl)/_oauth/facebook"
        let state = MeteorOAuth.stateParam(token, redirectUrl: redirect)
        
        let scope = "email"
        
        var url = "https://m.facebook.com/v2.2/dialog/oauth?client_id=\(appId)"
        url += "&redirect_uri=\(redirect)"
        url += "&scope=\(scope)"
        url += "&state=\(state)"
        
        return url
      
    }
    
    public static func github(clientId: String) -> String {
        
        let token = randomBase64String()
        let httpUrl = MeteorOAuth.httpUrl
        let redirect = "\(httpUrl)/_oauth/github"
        let state = MeteorOAuth.stateParam(token, redirectUrl: redirect)
        
        let scope = "user:email"
        
        var url = "https://github.com/login/oauth/authorize?client_id=\(clientId)"
        url += "&redirect_uri=\(redirect)"
        url += "&scope=\(scope)"
        url += "&state=\(state)"
        
        return url
    }
    
    public static func google(clientId: String) -> String {
        
        let token = randomBase64String()
        let httpUrl = MeteorOAuth.httpUrl
        let redirect = "\(httpUrl)/_oauth/google"
        let state = MeteorOAuth.stateParam(token, redirectUrl: redirect)

        let scope = "email"
        
        var url = "https://accounts.google.com/o/oauth2/auth?response_type=code&client_id=\(clientId)"
        url += "&redirect_uri=\(redirect)"
        url += "&scope=\(scope)"
        url += "&state=\(state)"
        
        return url
    }


    
}