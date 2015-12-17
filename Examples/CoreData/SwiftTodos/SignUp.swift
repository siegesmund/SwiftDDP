
import UIKit
import SwiftDDP

class SignUp: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var password2Field: UITextField!
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func joinNow(sender: UIButton) {
        guard let email = emailField.text where (email != ""),
              let password = passwordField.text where (password != ""),
              let password2 = password2Field.text where ((password2 != "") && (password2 == password)) else {
                print("Invalid entry. Please check email and passwords.")
                return
        }
        
        Meteor.signupWithEmail(email, password: password) { result, error in
            if (error == nil) {
                Meteor.client.loginWithToken() { result, error in
                    if (error == nil) {
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                }
            }
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
