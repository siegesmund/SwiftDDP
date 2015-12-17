
import UIKit
import SwiftDDP


class SignIn: UIViewController {

    // let meteor = (UIApplication.sharedApplication().delegate as! AppDelegate).meteor
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var errorField: UILabel!
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func signIn(sender: AnyObject) {
        errorField.text = ""
        if let password = passwordField?.text where (password != ""),
           let email = emailField?.text where (email != "") {
            Meteor.loginWithPassword(email, password: password) { result, error in
                if (error == nil) {
                    self.dismissViewControllerAnimated(true, completion: nil)
                } else {
                    if let reason = error?.reason {
                        self.errorField.text = reason
                    }
                }
            }
        } else {
            print("sign condition for password etc not fulfilled")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
