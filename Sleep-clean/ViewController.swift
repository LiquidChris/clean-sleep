//
//  ViewController.swift
//  Sleep-clean
//
//  Created by slmrc on 5/22/23.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func didTapButton() {
        present(SecondViewController(), animated: true)
    }
    
}

class SecondViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .blue
    }
}
