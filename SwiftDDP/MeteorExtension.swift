//
//  MeteorExtension.swift
//  SwiftDDP
//
//  Created by 市川雄二 on 2018/10/05.
//  Copyright © 2018 Peter Siegesmund. All rights reserved.
//

import Foundation
import UIKit

extension Meteor {
    internal static func loginWithService<T: UIViewController>(_ service: String, clientId: String, viewController: T) {
        
        // Resume rather than
        //        if Meteor.client.loginWithToken(nil) == false {
        //            var url:String!
        //
        //            switch service {
        //            case "twitter":
        //                url = MeteorOAuthServices.twitter()
        //
        //            case "facebook":
        //                url =  MeteorOAuthServices.facebook(clientId)
        //
        //            case "github":
        //                url = MeteorOAuthServices.github(clientId)
        //
        //            case "google":
        //                url = MeteorOAuthServices.google(clientId)
        //
        //            default:
        //                url = nil
        //            }
        //
        //            let oauthDialog = MeteorOAuthDialogViewController()
        //            oauthDialog.serviceName = service.capitalizedString
        //            oauthDialog.url = NSURL(string: url)
        //            viewController.presentViewController(oauthDialog, animated: true, completion: nil)
        //
        //        } else {
        //            log.debug("Already have valid server login credentials. Logging in with preexisting login token")
        //        }
        
    }
    
    /**
     Logs a user into the server using Twitter
     
     - parameter viewController:    A view controller from which to launch the OAuth modal dialog
     */
    
    open static func loginWithTwitter<T: UIViewController>(_ viewController: T) {
        Meteor.loginWithService("twitter", clientId: "", viewController: viewController)
    }
    
    /**
     Logs a user into the server using Facebook
     
     - parameter viewController:    A view controller from which to launch the OAuth modal dialog
     - parameter clientId:          The apps client id, provided by the service (Facebook, Google, etc.)
     */
    
    open static func loginWithFacebook<T: UIViewController>(_ clientId: String, viewController: T) {
        Meteor.loginWithService("facebook", clientId: clientId, viewController: viewController)
    }
    
    /**
     Logs a user into the server using Github
     
     - parameter viewController:    A view controller from which to launch the OAuth modal dialog
     - parameter clientId:          The apps client id, provided by the service (Facebook, Google, etc.)
     */
    
    open static func loginWithGithub<T: UIViewController>(_ clientId: String, viewController: T) {
        Meteor.loginWithService("github", clientId: clientId, viewController: viewController)
    }
    
    /**
     Logs a user into the server using Google
     
     - parameter viewController:    A view controller from which to launch the OAuth modal dialog
     - parameter clientId:          The apps client id, provided by the service (Facebook, Google, etc.)
     */
    
    open static func loginWithGoogle<T: UIViewController>(_ clientId: String, viewController: T) {
        Meteor.loginWithService("google", clientId: clientId, viewController: viewController)
    }
}
