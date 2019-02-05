//
//  ViewControllerTests.swift
//  GPUImageExampleTests
//
//  Created by JohnnyB0Y on 2019/2/3.
//  Copyright © 2019 JohnnyB0Y. All rights reserved.
//

import Quick
import Nimble

class Test {
    func a() { print ("something") }
}

class TestViewController: QuickSpec {
    
    override func spec() {
        
        var viewController: ViewController!
        
        describe("Test about") {
            beforeEach {
                viewController = ViewController.init()
            }
            
            it("get test title", closure: {
                expect(viewController.getTestTitle()).to(equal("Test Title"))
            })
            
        }
        
    }
    
}
