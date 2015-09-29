
import Foundation
import CryptoSwift


// These are implemented as an extension because they're not a part of the DDP spec
extension DDP.Client {
    
    // callback is optional. If present, called with an error object as the first argument and,
    // if no error, the _id as the second.
    public func insert(collection:String, doc:NSArray, callback: OnComplete?) {
        let arg = "/\(collection)/insert"
        self.method(arg, params: doc, callback: callback)
    }
    
    // Insert without specifying a callback
    public func insert(collection:String, doc:NSArray) {
        insert(collection, doc:doc) {result, error in if let e = error { print("[DDP] \(e)") }}
    }
    
    public func update(collection:String, doc:NSArray?, callback: OnComplete?) {
        let arg = "/\(collection)/update"
        method(arg, params: doc, callback: callback)
    }
    
    // Update without specifying a callback
    public func update(collection:String, doc:NSArray) {
        update(collection, doc:doc) {result, error in if let e = error { print("[DDP] \(e)") }}
    }
    
    public func remove(collection:String, doc:NSArray, callback: OnComplete?) {
        let arg = "/\(collection)/remove"
        method(arg, params: doc, callback: callback)
    }
    
    // Remove without specifying a callback
    public func remove(collection:String, doc:NSArray) {
        remove(collection, doc:doc) {result, error in if let e = error { print("[DDP] \(e)") }}
    }
    
    private func login(params: NSDictionary, callback: OnComplete?) {
        method("login", params: NSArray(arrayLiteral: params)) { result, error in
            guard let e = error else {
                if let r = result {
                    if let data = r["result"] as! NSDictionary? {
                        if let id = data["id"] as! String? {
                            self.userData.setObject(id, forKey: "id")
                            if let token = data["token"] as! String? { self.userData.setObject(token, forKey: "token") }
                            if let tokenExpires = data["tokenExpires"] as! NSDictionary? {
                                if let date = tokenExpires["$date"] as! Int? {
                                    let timestamp = NSTimeInterval(Double(date)) / 1000.0
                                    let tokenExpires = NSDate(timeIntervalSince1970: timestamp)
                                    self.userData.setObject(tokenExpires, forKey: "tokenExpires")
                                }
                            }
                        }
                    }
                }
                if let c = callback { c(result:result, error:error) }
                return
            }
            
            log.debug("[DDP] login error: \(e)")
            if let c = callback { c(result:result, error:error) }
        }
    }
    
    // Login with email and password
    public func loginWithPassword(email: String, password: String, callback: OnComplete?) {
        if !(loginWithToken(callback)) {
            let params = ["user":["email":email], "password":["digest":password.sha256()!, "algorithm":"sha-256"]] as NSDictionary
            login(params, callback:callback)
        }
    }
    
    // Does the date comparison account for TimeZone?
    public func loginWithToken(callback:OnComplete?) -> Bool {
        if let token = userData.stringForKey("token"),
           let tokenDate = userData.objectForKey("tokenExpires") {
                if (tokenDate.compare(NSDate()) == NSComparisonResult.OrderedDescending) {
                    let params = ["resume":token] as NSDictionary
                    login(params, callback:callback)
                    return true
                }
        }
        return false
    }
    
    public func logout() {
        method("logout", params:nil) {result, error in }
    }
    
    public convenience init(url: String, email:String, password:String) {
        self.init(url:url)
        connect() { session in
            self.loginWithPassword(email, password: password) { result, error in if (error != nil) { print(error) } }
        }
    }
}
