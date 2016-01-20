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
import WebKit

// TODO: Handle login failure > specific actions for cancellation, for example
// TODO: Gotchas: connecting over wss, but registered domain is http... 
// TODO: Activity indicator?
// TODO: Add redirect not popup; register as web app when setting up services to instructions
// TODO: Login first with stored token

public class MeteorOAuthDialogViewController: UIViewController, WKNavigationDelegate {
    
    // App must be set to redirect, rather than popup
    // https://github.com/meteor/meteor/wiki/OAuth-for-mobile-Meteor-clients#popup-versus-redirect-flow
    
    var meteor = Meteor.client
    
    public var navigationBar:UINavigationBar!
    public var cancelButton:UIBarButtonItem!
    public var webView:WKWebView!
    public var url:NSURL!
    public var serviceName: String?
    
    override public func viewDidLoad() {
        
        navigationBar = UINavigationBar() // Offset by 20 pixels vertically to take the status bar into account
        let navigationItem = UINavigationItem()
        
        navigationItem.title = "Login"

        if let name = serviceName {
            navigationItem.title = "Login with \(name)"
        }
        
        
        cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: "close")
        navigationItem.rightBarButtonItem = cancelButton
        navigationBar!.items = [navigationItem]
                
        // Configure WebView
        let request = NSURLRequest(URL:url)
        webView = WKWebView()
        webView.navigationDelegate = self
        webView.loadRequest(request)
        
        self.view.addSubview(webView)
        self.view.addSubview(navigationBar)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        navigationBar.frame = CGRectMake(0, 0, self.view.frame.size.width, 64)
        webView.frame = CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64)
    }
    
    func close() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    func signIn(token: String, secret: String) {
        let params = ["oauth":["credentialToken": token, "credentialSecret": secret]]
        Meteor.client.login(params) { result, error in
            print("Meteor login attempt \(result), \(error)")
            self.close()
        }
    }
    
    //
    //
    //  WKNavigationDelegate Methods
    //
    //
    
    /* Start the network activity indicator when the web view is loading */
    public func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    /* Stop the network activity indicator when the loading finishes */
    public func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation){
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        
        // This works to get the credentialSecret, credentialToken, redirectUrl etc.
        webView.evaluateJavaScript("JSON.parse(document.getElementById('config').innerHTML)",
            completionHandler: { (html: AnyObject?, error: NSError?) in
                if let json = html {
                    if let secret = json["credentialSecret"] as? String,
                        token = json["credentialToken"] as? String {
                            webView.stopLoading() // Is there a possible race condition here?
                            self.signIn(token, secret: secret)
                    }
                } else {
                    print("There was no json here")
                }
                
                // TODO: What if there's an error?, if the login fails
        })
    }
    
    
}